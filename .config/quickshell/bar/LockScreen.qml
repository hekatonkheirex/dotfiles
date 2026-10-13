import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import "primitives"
import "../config"

Item {
  id: root

  property bool locked: false
  // Quickshell 0.3.2 can omit lockedChanged on unlock. Read secure first so
  // its notification invalidates this binding and lets the bar map again.
  readonly property bool compositorLocked: Config.isNiri && sessionLock.secure && sessionLock.locked
  // Keep secure first here too: locked can also miss its start notification.
  readonly property bool secure: Config.isNiri && sessionLock.secure && sessionLock.locked
  onLockedChanged: {
    updateReloadWatchState()
    if (locked) {
      fprintdProcess.running = true
      currentWallpaperProc.running = root.wallpaperRequested
    } else {
      fprintdProcess.running = false
      fprintdRetry.stop()
      currentWallpaperProc.running = root.wallpaperRequested
    }
  }
  readonly property color accentColor: Colors.primary
  // Lock screen sits on a fixed dark photo scrim independent of the desktop's
  // light/dark mode, so text stays fixed light for legibility rather than
  // following Colors.fgSurface (which flips with darkMode and would go
  // near-black in light mode). Read the dark-scheme on_surface role directly.
  readonly property color textColor: Colors.paletteRole("dark", "on_surface", Colors.d_onSurface)
  readonly property color mutedText: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.7)
  readonly property color errorColor: Colors.destructive
  readonly property color flatBackground: Colors.bg
  readonly property real inputRadius: Config.shapeMedium
  readonly property color inputFill: Qt.rgba(1, 1, 1, 0.12)
  readonly property color inputBorder: Qt.rgba(1, 1, 1, 0.2)
  readonly property int lockAvatarSize: 96
  readonly property int lockFieldWidth: 280
  readonly property int lockFieldHeight: 48
  readonly property real lockFieldRadius: root.inputRadius
  readonly property color lockFieldFill: root.inputFill
  readonly property color lockFieldBorder: root.inputBorder

  readonly property string home: Quickshell.env("HOME")
  property date now: new Date()
  property string wallpaperSource: ""
  property bool wallpaperReady: false
  readonly property bool wallpaperRequested: Settings.lockUseWallpaper
  readonly property bool wallpaperVisible: root.wallpaperRequested && root.wallpaperReady
  readonly property int wallpaperBlurMax: 64

  Process {
    id: currentWallpaperProc
    command: ["sh", "-c", "awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1"]
    running: root.wallpaperRequested
    stdout: StdioCollector {
      onStreamFinished: {
        var value = text.trim()
        var nextSource = ""
        if (value.indexOf("file://") === 0) nextSource = value
        else if (value.indexOf("/") === 0) nextSource = "file://" + value
        else if (value !== "") nextSource = "file://" + root.home + "/Pictures/Walls/" + value

        // Locking rechecks the active wallpaper. Do not invalidate an already
        // decoded image when awww returns the same path; Image will not emit
        // another status change for an unchanged source.
        if (nextSource === root.wallpaperSource) return
        root.wallpaperReady = false
        root.wallpaperSource = nextSource
      }
    }
  }

  Image {
    id: wallpaperProbe
    source: root.wallpaperSource
    asynchronous: true
    // Probe only reports readiness; decode tiny.
    sourceSize: Qt.size(64, 64)
    visible: false
    onStatusChanged: {
      if (status === Image.Ready) root.wallpaperReady = true
      else if (status === Image.Error) root.wallpaperReady = false
    }
  }

  Connections {
    target: Settings
    function refreshWallpaper() {
      root.wallpaperReady = false
      currentWallpaperProc.running = root.wallpaperRequested
    }
    function onLockUseWallpaperChanged() {
      refreshWallpaper()
    }
  }

  Timer {
    interval: 1000
    running: root.locked
    repeat: true
    onTriggered: root.now = new Date()
  }

  property string lockMprisStatus: "NoPlayer"
  property string lockMprisTitle: ""
  property string lockMprisArtist: ""

  Process {
    id: lockMprisProcess
    command: ["python3", "-u", root.home + "/.config/quickshell/scripts/mpris_monitor.py"]
    running: root.locked && Settings.lockShowMedia
    stdout: SplitParser {
      onRead: function(data) {
        try {
          var info = JSON.parse(data.trim());
          root.lockMprisStatus = info.status;
          root.lockMprisTitle = info.title;
          root.lockMprisArtist = info.artist;
        } catch (e) {}
      }
    }
    onRunningChanged: {
      if (!running && root.locked && Settings.lockShowMedia) lockMprisRetry.start()
    }
  }

  Timer {
    id: lockMprisRetry
    interval: 3000
    onTriggered: {
      if (root.locked && Settings.lockShowMedia) lockMprisProcess.running = true
    }
  }

  property string lockPassword: ""
  property string lockInputText: ""
  property string lockError: ""
  property bool authenticated: false
  property string pendingPowerLabel: ""
  property var pendingPowerCommand: []

  function username() {
    return Quickshell.env("USER") || "user"
  }

  function updateReloadWatchState() {
    // Destroying a WlSessionLock while it is active leaves the compositor in
    // its secure fallback state. Do not let a file change start a reload in
    // that window; unlock restores the normal watcher behavior.
    Quickshell.watchFiles = !(root.locked || sessionLock.locked)
  }

  function clearPassword() {
    lockPassword = ""
    lockInputText = ""
    lockPam.pendingPassword = ""
  }

  function lockScreen() {
    clearPassword()
    lockError = ""
    authenticated = false
    cancelPowerAction()

    // Mango's layer-shell fallback is only a visual overlay, not a Wayland
    // session lock. Use the standalone locker there so compositor shortcuts
    // cannot bypass authentication.
    if (!Config.isNiri) {
      Quickshell.execDetached(["swaylock", "-f"])
      return
    }

    root.locked = true
    updateReloadWatchState()
    sessionLock.locked = true
  }

  function unlockSession() {
    authenticated = true
    clearPassword()
    root.locked = false
    if (Config.isNiri) sessionLock.locked = false
    updateReloadWatchState()
    Quickshell.execDetached(["loginctl", "unlock-session"])
  }

  function tryLockAuth() {
    if (lockPassword.length === 0) return
    lockPam.user = root.username()
    lockPam.pendingPassword = lockPassword
    lockError = ""
    lockPam.start()
  }

  function requestPowerAction(label, command) {
    if (!root.locked) return
    root.pendingPowerLabel = label
    root.pendingPowerCommand = command
  }

  function cancelPowerAction() {
    root.pendingPowerLabel = ""
    root.pendingPowerCommand = []
  }

  function confirmPowerAction() {
    var command = root.pendingPowerCommand
    root.cancelPowerAction()
    if (command && command.length > 0) Quickshell.execDetached(command)
  }

  PamContext {
    id: lockPam
    property string pendingPassword: ""

    config: "system-auth"

    onResponseRequiredChanged: {
      if (responseRequired && pendingPassword !== "") {
        respond(pendingPassword)
        pendingPassword = ""
      }
    }

    onCompleted: (result) => {
      if (result === PamResult.Success) {
        root.unlockSession()
      } else {
        root.clearPassword()
        root.lockError = "Wrong password. Try again."
      }
    }
    onError: (error) => {
      root.clearPassword()
      root.lockError = "Authentication error. Try again."
    }
  }

  Process {
    id: fprintdProcess
    command: ["fprintd-verify", root.username()]
    running: false

    property var startTime: 0

    onRunningChanged: {
      if (running) {
        startTime = Date.now()
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && root.locked && !root.authenticated) {
        root.unlockSession()
      } else if (root.locked && !root.authenticated) {
        var elapsed = Date.now() - startTime
        if (elapsed < 1500) {
          // If the process exited very quickly, the device might be busy,
          // unplugged, or recovering from sleep. Use a 5s cooldown.
          fprintdRetry.interval = 5000
        } else {
          // Normal retry (e.g. wrong finger scanned).
          fprintdRetry.interval = 2000
        }
        fprintdRetry.start()
      }
    }
  }

  Timer {
    id: fprintdRetry
    interval: 2000
    onTriggered: {
      if (root.locked && !root.authenticated) {
        fprintdProcess.running = true
      }
    }
  }


  WlSessionLock {
    id: sessionLock
    // Keep the local mirror synchronized with compositor-owned state before
    // the bar evaluates its visibility binding. Active lock reloads are
    // blocked above because destroying WlSessionLock while locked violates
    // the Wayland session-lock protocol.
    Component.onCompleted: {
      if (Config.isNiri) root.locked = sessionLock.locked
      root.updateReloadWatchState()
    }
    onLockedChanged: {
      if (!Config.isNiri) return
      if (locked) {
        root.lockPassword = ""
        root.lockInputText = ""
        root.lockError = ""
        root.authenticated = false
      } else {
        root.cancelPowerAction()
      }
      root.locked = locked
    }
    surface: Component {
      WlSessionLockSurface {
        color: Colors.scrim

        PinchHandler { target: null }
        WheelHandler { target: null }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons
          hoverEnabled: true
          onWheel: (wheel) => { wheel.accepted = true }
        }

        Image {
          id: nativeWallpaperImage
          anchors.fill: parent
          source: root.wallpaperSource
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
          // MultiEffect renders the source into its own texture. Leaving the
          // raw image visible would let the unblurred edge bleed through.
          visible: false
        }

        MultiEffect {
          anchors.fill: parent
          source: nativeWallpaperImage
          visible: root.wallpaperVisible
          // The lock surface is exactly the output size, so blur padding
          // would be clipped at the top and bottom edges.
          autoPaddingEnabled: false
          blurEnabled: false
          blur: 0.0
          blurMax: root.wallpaperBlurMax
        }

        AnimatedBackground {
          anchors.fill: parent
          running: root.locked
          motionEnabled: true
          flatMode: false
          flatColor: root.flatBackground
          visible: !root.wallpaperVisible
        }

        Rectangle {
          anchors.fill: parent
          color: Qt.rgba(0, 0, 0, 0.15)
        }

        Rectangle {
          anchors.fill: parent
          visible: true
          gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.5) }
            GradientStop { position: 0.5; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
          }
        }

        Column {
          anchors.centerIn: parent
          spacing: Config.spacingLarge
          visible: true

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: root.lockAvatarSize
              height: root.lockAvatarSize
              radius: width / 2
              clip: true
              border.width: 3
              border.color: accentColor
              color: Colors.primaryContainer

              Image {
                id: profileImage
                anchors.fill: parent
                source: "file://" + root.home + "/Pictures/profile.jpg"
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(256, 256)
                visible: false
              }

              Rectangle {
                id: profileMask
                anchors.fill: parent
                radius: parent.width / 2
                color: "black"
                visible: false
                layer.enabled: true
              }

              MultiEffect {
                id: profileImageEffect
                anchors.fill: parent
                source: profileImage
                visible: true
                maskEnabled: true
                maskSource: profileMask
              }

              Text {
                anchors.centerIn: parent
                text: root.username().charAt(0).toUpperCase()
                color: Colors.fgPrimaryContainer
                font.family: Config.fontFamily
                font.pixelSize: Config.typeDisplaySmallSize
                font.weight: Config.typeStrongWeight
                font.letterSpacing: Config.typeDisplayTracking
                visible: profileImage.status !== Image.Ready
              }
            }


          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: true
            height: implicitHeight
            text: {
              var d = root.now
              return d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
            }
            color: textColor
            font.family: Config.fontFamily
            font.pixelSize: Settings.lockClockSize
            font.weight: Font.Bold
            font.letterSpacing: 0
            style: Text.Sunken
            styleColor: Qt.rgba(0, 0, 0, 0.3)
          }


          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: true
            height: implicitHeight
            text: {
              var d = root.now
              var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
              var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
              return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear()
            }
            color: mutedText
            font.family: Config.fontFamily
            font.pixelSize: Config.typeHeadlineSmallSize
            font.letterSpacing: Config.typeHeadlineTracking
            lineHeight: Config.typeHeadlineSmallLineHeight
            lineHeightMode: Text.FixedHeight
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Config.spacingSmall
            visible: Settings.lockShowMedia && root.lockMprisTitle !== ""

            IconGlyph {
              iconLabel: root.lockMprisStatus === "Playing" ? "pause" : "play_arrow"
              iconSize: 16
              iconColor: mutedText
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: root.lockMprisTitle + (root.lockMprisArtist ? " - " + root.lockMprisArtist : "")
              color: mutedText
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodyMediumLineHeight
              lineHeightMode: Text.FixedHeight
              elide: Text.ElideRight
              width: Math.min(implicitWidth, 320)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Item { height: Config.spacingSmall }

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.lockFieldWidth
            height: root.lockFieldHeight
            radius: root.lockFieldRadius
            color: root.lockFieldFill
            border.width: Config.themeBorderWidth
            border.color: root.lockFieldBorder


            Text {
              anchors {
                left: parent.left
                leftMargin: Config.spacingLarge
                verticalCenter: parent.verticalCenter
              }
              text: "Password"
              color: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.56)
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyLargeSize
              font.letterSpacing: Config.typeBodyTracking
              visible: root.lockInputText === ""
              z: 1
            }

            TextInput {
              anchors {
                fill: parent
                leftMargin: Config.spacingLarge
                rightMargin: Config.spacingLarge
              }
              color: textColor
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyLargeSize + 4
              font.letterSpacing: 4
              text: root.lockInputText
              clip: true
              echoMode: TextInput.Password
              passwordCharacter: "\u25CF"
              focus: root.locked
              activeFocusOnPress: true
              cursorVisible: true
              verticalAlignment: Qt.AlignVCenter
              selectByMouse: true
              z: 2

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                acceptedButtons: Qt.NoButton
              }

              onTextChanged: {
                root.lockPassword = text
                root.lockInputText = text
                root.lockError = ""
              }

              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  root.tryLockAuth()
                }
              }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.lockError
            color: errorColor
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyLargeSize
            font.weight: Config.typeStrongWeight
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyLargeLineHeight
            lineHeightMode: Text.FixedHeight
            opacity: 1
            visible: (root.lockError.length > 0)

            Behavior on opacity {
              NumberAnimation {
                duration: 0
                easing.type: Easing.OutCubic
              }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "or touch the fingerprint sensor"
            color: mutedText
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelLargeSize
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelLargeLineHeight
            lineHeightMode: Text.FixedHeight
            opacity: 0.8
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Config.spacingExtraLarge

            IconButton {
              size: 40
              iconSize: 20
              iconLabel: "power_settings_new"
              iconColor: mutedText
              variant: "outlined"
              borderColor: Qt.rgba(1, 1, 1, 0.3)
              accessibleName: "Suspend computer"
              tooltipText: "Suspend computer"
              onClicked: root.requestPowerAction("Suspend", ["systemctl", "suspend"])
            }

            IconButton {
              size: 40
              iconSize: 20
              iconLabel: "restart_alt"
              iconColor: mutedText
              variant: "outlined"
              borderColor: Qt.rgba(1, 1, 1, 0.3)
              accessibleName: "Restart computer"
              tooltipText: "Restart computer"
              onClicked: root.requestPowerAction("Restart", ["systemctl", "reboot"])
            }

            IconButton {
              size: 40
              iconSize: 20
              iconLabel: "power_off"
              iconColor: mutedText
              variant: "outlined"
              borderColor: Qt.rgba(1, 1, 1, 0.3)
              accessibleName: "Power off computer"
              tooltipText: "Power off computer"
              onClicked: root.requestPowerAction("Power off", ["systemctl", "poweroff"])
            }
          }
        }


        PowerConfirmation {
          id: lockPowerConfirmation
          anchors.fill: parent
          opened: root.pendingPowerLabel !== ""
          actionLabel: root.pendingPowerLabel
          actionDescription: root.pendingPowerLabel !== ""
            ? "This will " + root.pendingPowerLabel.toLowerCase() + " the computer."
            : ""
          scrimColor: Qt.rgba(0, 0, 0, 0.58)
          dialogColor: Qt.rgba(0, 0, 0, 0.88)
          dialogTextColor: root.textColor
          dialogSecondaryTextColor: root.mutedText
          dialogBorderColor: Qt.rgba(1, 1, 1, 0.3)
          cancelColor: Qt.rgba(1, 1, 1, 0.12)
          cancelTextColor: root.textColor
          confirmColor: root.accentColor
          confirmTextColor: Colors.fgPrimary
          onConfirmed: root.confirmPowerAction()
          onCancelled: root.cancelPowerAction()
        }
      }
    }
  }

  Loader {
    active: !Config.isNiri && root.locked
    sourceComponent: PanelWindow {
      color: Colors.scrim
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-lock"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.focusable: true
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      anchors.left: true
      anchors.right: true
      anchors.top: true
      anchors.bottom: true

      Image {
        id: fallbackWallpaperImage
        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
        visible: false
      }

      MultiEffect {
        anchors.fill: parent
        source: fallbackWallpaperImage
        visible: root.wallpaperVisible
        autoPaddingEnabled: false
        blurEnabled: false
        blur: 0.0
        blurMax: root.wallpaperBlurMax
      }

      AnimatedBackground {
        anchors.fill: parent
        running: root.locked
        motionEnabled: true
        flatMode: false
        flatColor: root.flatBackground
        visible: !root.wallpaperVisible
      }

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.15)
      }

      Rectangle {
        anchors.fill: parent
        visible: true
        gradient: Gradient {
          orientation: Gradient.Vertical
          GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.5) }
          GradientStop { position: 0.5; color: "transparent" }
          GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
        }
      }

      Column {
        anchors.centerIn: parent
        spacing: Config.spacingLarge
        visible: true

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          visible: true
          height: implicitHeight
          text: {
            var d = root.now
            return d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
          }
          color: root.textColor
          font.family: Config.fontFamily
          font.pixelSize: Settings.lockClockSize
          font.weight: Font.Bold
          font.letterSpacing: 0
          style: Text.Sunken
          styleColor: Qt.rgba(0, 0, 0, 0.3)
        }


        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          visible: true
          height: implicitHeight
          text: {
            var d = root.now
            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
            return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear()
          }
          color: root.mutedText
          font.family: Config.fontFamily
          font.pixelSize: Config.typeHeadlineSmallSize
          font.letterSpacing: Config.typeHeadlineTracking
          lineHeight: Config.typeHeadlineSmallLineHeight
          lineHeightMode: Text.FixedHeight
        }


        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Config.spacingSmall
          visible: Settings.lockShowMedia && root.lockMprisTitle !== ""

          IconGlyph {
            iconLabel: root.lockMprisStatus === "Playing" ? "pause" : "play_arrow"
            iconSize: 16
            iconColor: root.mutedText
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: root.lockMprisTitle + (root.lockMprisArtist ? " - " + root.lockMprisArtist : "")
            color: root.mutedText
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 320)
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Item { height: Config.spacingSmall }

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: root.lockFieldWidth
          height: root.lockFieldHeight
          radius: root.lockFieldRadius
          color: root.lockFieldFill
          border.width: Config.themeBorderWidth
          border.color: root.lockFieldBorder


          Text {
            anchors {
              left: parent.left
              leftMargin: Config.spacingLarge
              verticalCenter: parent.verticalCenter
            }
            text: "Password"
            color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.56)
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyLargeSize
            font.letterSpacing: Config.typeBodyTracking
            visible: root.lockInputText === ""
            z: 1
          }

          TextInput {
            anchors {
              fill: parent
              leftMargin: Config.spacingLarge
              rightMargin: Config.spacingLarge
            }
            color: root.textColor
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyLargeSize + 4
            font.letterSpacing: 4
            text: root.lockInputText
            clip: true
            echoMode: TextInput.Password
            passwordCharacter: "\u25CF"
            focus: true
            activeFocusOnPress: true
            cursorVisible: true
            verticalAlignment: Qt.AlignVCenter
            selectByMouse: true
            z: 2

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.IBeamCursor
              acceptedButtons: Qt.NoButton
            }

            onTextChanged: {
              root.lockPassword = text
              root.lockInputText = text
              root.lockError = ""
            }

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.tryLockAuth()
              }
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.lockError
          color: Colors.destructive
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodyLargeSize
          font.weight: Config.typeStrongWeight
          font.letterSpacing: Config.typeBodyTracking
          lineHeight: Config.typeBodyLargeLineHeight
          lineHeightMode: Text.FixedHeight
          opacity: 1
          visible: (root.lockError.length > 0)

          Behavior on opacity {
            NumberAnimation {
              duration: 0
              easing.type: Easing.OutCubic
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "or touch the fingerprint sensor"
          color: root.mutedText
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelLargeSize
          font.letterSpacing: Config.typeLabelTracking
          lineHeight: Config.typeLabelLargeLineHeight
          lineHeightMode: Text.FixedHeight
          opacity: 0.8
        }

      }


      PowerConfirmation {
        id: fallbackLockPowerConfirmation
        anchors.fill: parent
        opened: root.pendingPowerLabel !== ""
        actionLabel: root.pendingPowerLabel
        actionDescription: root.pendingPowerLabel !== ""
          ? "This will " + root.pendingPowerLabel.toLowerCase() + " the computer."
          : ""
        scrimColor: Qt.rgba(0, 0, 0, 0.58)
        dialogColor: Qt.rgba(0, 0, 0, 0.88)
        dialogTextColor: root.textColor
        dialogSecondaryTextColor: root.mutedText
        dialogBorderColor: Qt.rgba(Colors.fgSurface.r, Colors.fgSurface.g, Colors.fgSurface.b, Colors.darkMode ? 0.30 : 0.22)
        cancelColor: Qt.rgba(Colors.surfaceContainerHigh.r, Colors.surfaceContainerHigh.g, Colors.surfaceContainerHigh.b, Colors.darkMode ? 0.95 : 0.85)
        cancelTextColor: root.textColor
        confirmColor: root.accentColor
        confirmTextColor: Colors.fgPrimary
        onConfirmed: root.confirmPowerAction()
        onCancelled: root.cancelPowerAction()
      }
    }
  }
}
