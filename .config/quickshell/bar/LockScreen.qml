import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import "primitives"
import "themes/nothing" as Nothing
import "../config"

Item {
  id: root

  property bool locked: false
  // Read the compositor-owned state directly as well as the local mirror so
  // bar surfaces stay hidden while the protocol state is changing.
  readonly property bool compositorLocked: Config.isNiri && sessionLock.locked
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
  readonly property color accentColor: Config.nothingEvolution ? Colors.styleAccent : Colors.primary
  // Lock screen sits on a fixed dark photo scrim independent of the desktop's
  // light/dark mode, so text stays fixed light for legibility rather than
  // following Colors.fgSurface (which flips with darkMode and would go
  // near-black in light mode). Read the dark-scheme on_surface role through
  // Colors so Nothing keeps its fixed text while other styles track Matugen.
  readonly property color textColor: Colors.paletteRole("dark", "on_surface", Colors.d_onSurface)
  readonly property color mutedText: Qt.rgba(textColor.r, textColor.g, textColor.b, 0.7)
  readonly property color errorColor: Colors.destructive
  readonly property bool flatLockMode: Config.nothingDesign || Config.neoBrutalism || Config.ghostTheme
  readonly property color flatBackground: root.flatLockMode
    ? (Colors.darkMode ? Colors.background : Colors.inverseSurface)
    : Colors.bg
  readonly property real inputRadius: Config.neoBrutalism ? Config.shapeCompact : Config.shapeMedium
  readonly property color inputFill: Config.ghostTheme
    ? Qt.rgba(Colors.ghostCyan.r, Colors.ghostCyan.g, Colors.ghostCyan.b, 0.10)
    : (Config.neoBrutalism
      ? Qt.rgba(textColor.r, textColor.g, textColor.b, 0.10)
      : Qt.rgba(1, 1, 1, 0.12))
  readonly property color inputBorder: Config.ghostTheme
    ? Colors.styleOutlineStrong
    : (Config.neoBrutalism
      ? Qt.rgba(textColor.r, textColor.g, textColor.b, 0.72)
      : Qt.rgba(1, 1, 1, 0.2))
  readonly property int lockAvatarSize: 96
  readonly property int lockFieldWidth: Config.liquidGlassTheme ? 320 : 280
  readonly property int lockFieldHeight: Config.liquidGlassTheme ? 52 : 48
  readonly property real lockFieldRadius: Config.liquidGlassTheme ? Config.shapeLarge : root.inputRadius
  readonly property color lockFieldFill: Config.liquidGlassTheme ? Colors.liquidGlassControl : root.inputFill
  readonly property color lockFieldBorder: Config.liquidGlassTheme ? Colors.liquidGlassEdge : root.inputBorder
  readonly property int liquidGlassClockSize: Math.max(92, Settings.lockClockSize)
  // The macOS lock identity uses a stable blue instead of the wallpaper's
  // generated accent, so the account marker stays recognizable on every photo.
  readonly property color liquidGlassAvatarColor: "#2f80ed"

  readonly property string home: Quickshell.env("HOME")
  property date now: new Date()
  readonly property string liquidGlassDateText: {
    var d = root.now
    var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate()
  }
  readonly property string liquidGlassTimeText: {
    var d = root.now
    var hours = d.getHours()
    if (!Settings.clock24h) hours = hours % 12 || 12
    return (Settings.clock24h ? hours.toString().padStart(2, "0") : hours.toString())
      + ":" + d.getMinutes().toString().padStart(2, "0")
  }
  property string wallpaperSource: ""
  property bool wallpaperReady: false
  // Liquid Glass follows Apple's lock-screen treatment: its photo backdrop is
  // part of the style, while the shared wallpaper preference remains an
  // opt-in for the other styles.
  readonly property bool wallpaperRequested: Settings.lockUseWallpaper || Config.liquidGlassTheme
  readonly property bool wallpaperVisible: root.wallpaperRequested && root.wallpaperReady
  readonly property bool wallpaperBlurred: root.wallpaperVisible && Config.liquidGlassTheme
  readonly property int wallpaperBlurMax: 64

  Process {
    id: currentWallpaperProc
    command: ["sh", "-c", "awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1"]
    // Query while Liquid Glass is active so the lock surface has the current
    // wallpaper ready on its first frame instead of flashing the fallback.
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
    function onThemeStyleChanged() {
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
  property bool liquidGlassLoginPrompted: false
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
    liquidGlassLoginPrompted = false
    authenticated = false
    cancelPowerAction()
    root.locked = true
    updateReloadWatchState()
    if (Config.isNiri) sessionLock.locked = true
  }

  function unlockSession() {
    authenticated = true
    clearPassword()
    liquidGlassLoginPrompted = false
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

  Component {
    id: liquidGlassLockLayout

    FocusScope {
      anchors.fill: parent
      // Keep the outer focus scope active after the identity is clicked so the
      // newly-created password input can receive focus on the first click.
      focus: root.locked
      activeFocusOnTab: true

      Keys.onPressed: function(event) {
        if (!root.liquidGlassLoginPrompted
            && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
          root.liquidGlassLoginPrompted = true
          event.accepted = true
        }
      }

      Timer {
        id: liquidGlassPasswordFocusTimer
        interval: 0
        repeat: false
        onTriggered: {
          if (root.liquidGlassLoginPrompted
              && liquidGlassPasswordField.item
              && liquidGlassPasswordField.item.input) {
            liquidGlassPasswordField.item.input.forceActiveFocus()
          }
        }
      }

      Connections {
        target: root
        function onLiquidGlassLoginPromptedChanged() {
          if (root.liquidGlassLoginPrompted) {
            liquidGlassPasswordFocusTimer.restart()
          }
        }
      }

      Column {
        anchors {
          top: parent.top
          horizontalCenter: parent.horizontalCenter
          topMargin: Math.max(96, Math.round(parent.height * 0.20))
        }
        spacing: Config.spacingSmall

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.liquidGlassDateText
          color: root.textColor
          font.family: Config.fontFamily
          font.pixelSize: Math.max(18, Config.typeHeadlineSmallSize + 2)
          font.weight: Font.DemiBold
          font.letterSpacing: 0.1
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.liquidGlassTimeText
          color: root.textColor
          font.family: Config.fontFamily
          font.pixelSize: root.liquidGlassClockSize
          font.weight: Font.Light
          font.letterSpacing: -1.2
          style: Text.Normal
        }
      }

      Column {
        anchors {
          horizontalCenter: parent.horizontalCenter
          bottom: parent.bottom
          bottomMargin: Math.max(40, Math.round(parent.height * 0.05))
        }
        width: 320
        spacing: Config.spacingSmall

        Item {
          width: parent.width
          height: root.lockAvatarSize + Config.spacingMedium * 2 + 38

          Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Config.spacingMedium

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: root.lockAvatarSize
              height: root.lockAvatarSize
              radius: width / 2
              clip: true
              color: root.liquidGlassAvatarColor
              border.width: 1
              border.color: Qt.rgba(1, 1, 1, 0.34)

              Image {
                id: liquidGlassProfileImage
                anchors.fill: parent
                source: "file://" + root.home + "/Pictures/profile.jpg"
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
              }

              Text {
                anchors.centerIn: parent
                text: root.username().charAt(0).toUpperCase()
                color: "white"
                font.family: Config.fontFamily
                font.pixelSize: 40
                font.weight: Font.Normal
                visible: liquidGlassProfileImage.status !== Image.Ready
              }
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.username()
              color: root.textColor
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyLargeSize
              font.weight: Font.DemiBold
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Click to log in"
              color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.66)
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              visible: !root.liquidGlassLoginPrompted
            }
          }

          MouseArea {
            anchors.fill: parent
            enabled: !root.liquidGlassLoginPrompted
            cursorShape: Qt.PointingHandCursor
            onClicked: root.liquidGlassLoginPrompted = true
          }
        }

        Loader {
          id: liquidGlassPasswordField
          active: root.liquidGlassLoginPrompted
          visible: active
          focus: active
          width: parent.width
          height: active ? 52 : 0
          onLoaded: {
            if (item && item.input) item.input.forceActiveFocus()
          }
          sourceComponent: Component {
            FocusScope {
              id: liquidGlassPasswordScope
              width: 320
              height: 52
              focus: true
              property alias input: passwordInput

              Component.onCompleted: passwordInput.forceActiveFocus()

              Rectangle {
                anchors.fill: parent
                radius: Config.shapeLarge
                color: Colors.liquidGlassControl
                border.width: 1
                border.color: Colors.liquidGlassEdge
              }

              GlassSheen {
                anchors.fill: parent
                radius: Config.shapeLarge
              }

              TextInput {
                id: passwordInput
                anchors {
                  fill: parent
                  leftMargin: Config.spacingLarge
                  rightMargin: Config.spacingLarge
                }
                color: root.textColor
                font.family: Config.fontFamily
                font.pixelSize: Config.typeBodyLargeSize
                text: root.lockInputText
                echoMode: TextInput.Password
                passwordCharacter: "\u25CF"
                focus: true
                activeFocusOnPress: true
                cursorVisible: true
                verticalAlignment: Qt.AlignVCenter
                selectByMouse: true

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
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.lockError
          color: root.errorColor
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodyMediumSize
          visible: root.lockError.length > 0
        }
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
        root.liquidGlassLoginPrompted = false
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
          blurEnabled: root.wallpaperBlurred
          blur: root.wallpaperBlurred ? 1.0 : 0.0
          blurMax: root.wallpaperBlurMax
        }

        AnimatedBackground {
          anchors.fill: parent
          running: root.locked
          motionEnabled: !Config.liquidGlassTheme
          flatMode: root.flatLockMode || Config.liquidGlassTheme
          flatColor: Config.liquidGlassTheme ? Colors.d_background : root.flatBackground
          visible: !root.wallpaperVisible
        }

        Rectangle {
          anchors.fill: parent
          color: Config.liquidGlassTheme
            ? Qt.rgba(0, 0, 0, 0.14)
            : Qt.rgba(0, 0, 0, 0.15)
        }

        Rectangle {
          anchors.fill: parent
          visible: !Config.liquidGlassTheme && (!root.flatLockMode || root.wallpaperVisible)
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
          visible: !Config.liquidGlassTheme

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: root.lockAvatarSize
              height: root.lockAvatarSize
              radius: width / 2
              clip: true
              border.width: Config.liquidGlassTheme ? 1 : 3
              border.color: Config.liquidGlassTheme ? Colors.liquidGlassEdgeStrong : accentColor
              color: Config.liquidGlassTheme ? Colors.liquidGlassRaised : Colors.primaryContainer

              Image {
                id: profileImage
                anchors.fill: parent
                source: "file://" + root.home + "/Pictures/profile.jpg"
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
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
                color: Config.liquidGlassTheme ? textColor : Colors.fgPrimaryContainer
                font.family: Config.fontFamily
                font.pixelSize: Config.typeDisplaySmallSize
                font.weight: Config.typeStrongWeight
                font.letterSpacing: Config.typeDisplayTracking
                visible: profileImage.status !== Image.Ready
              }
            }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.username()
            color: textColor
            font.family: Config.fontFamily
            font.pixelSize: Config.typeHeadlineSmallSize
            font.weight: Config.typeStrongWeight
            visible: Config.liquidGlassTheme
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !Config.nothingEvolution && !Config.liquidGlassTheme
            height: Config.liquidGlassTheme ? 0 : implicitHeight
            text: {
              var d = root.now
              return d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
            }
            color: textColor
            font.family: Config.nothingDesign ? Config.dotFontFamily : Config.fontFamily
            font.pixelSize: Settings.lockClockSize
            font.weight: Config.nothingDesign
              ? Font.Normal
              : (Config.neoBrutalism ? Font.DemiBold : Font.Bold)
            font.letterSpacing: Config.neoBrutalism ? 0.8 : 0
            style: root.flatLockMode ? Text.Normal : Text.Sunken
            styleColor: root.flatLockMode ? "transparent" : Qt.rgba(0, 0, 0, 0.3)
          }

          Nothing.ClockFace {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Config.nothingEvolution && root.locked
            face: Settings.lockClockFace
            now: root.now
            clockSize: Settings.lockClockSize
            primaryColor: root.accentColor
            secondaryColor: root.mutedText
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !Config.nothingEvolution && !Config.liquidGlassTheme
            height: Config.liquidGlassTheme ? 0 : implicitHeight
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
            border.width: Config.liquidGlassTheme ? 1 : Config.themeBorderWidth
            border.color: root.lockFieldBorder

            GlassSheen {
              anchors.fill: parent
              radius: parent.radius
            }

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
              visible: Config.liquidGlassTheme && root.lockInputText === ""
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
              font.pixelSize: Config.typeBodyLargeSize
              font.letterSpacing: Config.typeBodyTracking
              text: root.lockInputText
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
            opacity: root.flatLockMode && root.lockError.length === 0 ? 0 : 1
            visible: root.flatLockMode ? opacity > 0 : root.lockError.length > 0

            Behavior on opacity {
              NumberAnimation {
                duration: root.flatLockMode ? Config.motionShort : 0
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
              borderColor: Config.liquidGlassTheme ? Colors.liquidGlassEdgeStrong : Qt.rgba(1, 1, 1, 0.3)
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

        Loader {
          anchors.fill: parent
          active: Config.liquidGlassTheme
          visible: active
          focus: active
          activeFocusOnTab: active
          sourceComponent: liquidGlassLockLayout
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
        visible: false
      }

      MultiEffect {
        anchors.fill: parent
        source: fallbackWallpaperImage
        visible: root.wallpaperVisible
        autoPaddingEnabled: false
        blurEnabled: root.wallpaperBlurred
        blur: root.wallpaperBlurred ? 1.0 : 0.0
        blurMax: root.wallpaperBlurMax
      }

      AnimatedBackground {
        anchors.fill: parent
        running: root.locked
        motionEnabled: !Config.liquidGlassTheme
        flatMode: root.flatLockMode || Config.liquidGlassTheme
        flatColor: Config.liquidGlassTheme ? Colors.d_background : root.flatBackground
        visible: !root.wallpaperVisible
      }

      Rectangle {
        anchors.fill: parent
        color: Config.liquidGlassTheme
          ? Qt.rgba(0, 0, 0, 0.14)
          : Qt.rgba(0, 0, 0, 0.15)
      }

      Rectangle {
        anchors.fill: parent
        visible: !Config.liquidGlassTheme && (!root.flatLockMode || root.wallpaperVisible)
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
        visible: !Config.liquidGlassTheme

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          visible: !Config.nothingEvolution && !Config.liquidGlassTheme
          height: Config.liquidGlassTheme ? 0 : implicitHeight
          text: {
            var d = root.now
            return d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
          }
          color: root.textColor
          font.family: Config.nothingDesign ? Config.dotFontFamily : Config.fontFamily
          font.pixelSize: Settings.lockClockSize
          font.weight: Config.nothingDesign
            ? Font.Normal
            : (Config.neoBrutalism ? Font.DemiBold : Font.Bold)
          font.letterSpacing: Config.neoBrutalism ? 0.8 : 0
          style: root.flatLockMode ? Text.Normal : Text.Sunken
          styleColor: root.flatLockMode ? "transparent" : Qt.rgba(0, 0, 0, 0.3)
        }

        Nothing.ClockFace {
          anchors.horizontalCenter: parent.horizontalCenter
          visible: Config.nothingEvolution && root.locked
          face: Settings.lockClockFace
          now: root.now
          clockSize: Settings.lockClockSize
          primaryColor: root.accentColor
          secondaryColor: root.mutedText
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          visible: !Config.nothingEvolution && !Config.liquidGlassTheme
          height: Config.liquidGlassTheme ? 0 : implicitHeight
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

        Loader {
          active: Config.liquidGlassTheme
          visible: active
          anchors.horizontalCenter: parent.horizontalCenter
          sourceComponent: Component {
            Column {
              width: 320
              spacing: Config.spacingSmall

              Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.lockAvatarSize
                height: root.lockAvatarSize
                radius: width / 2
                clip: true
                color: Colors.liquidGlassRaised
                border.width: 1
                border.color: Colors.liquidGlassEdgeStrong

                Image {
                  id: fallbackProfileImage
                  anchors.fill: parent
                  source: "file://" + root.home + "/Pictures/profile.jpg"
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  visible: status === Image.Ready
                }

                Text {
                  anchors.centerIn: parent
                  text: root.username().charAt(0).toUpperCase()
                  color: root.textColor
                  font.family: Config.fontFamily
                  font.pixelSize: Config.typeDisplaySmallSize
                  font.weight: Config.typeStrongWeight
                  font.letterSpacing: Config.typeDisplayTracking
                  visible: fallbackProfileImage.status !== Image.Ready
                }
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.username()
                color: root.textColor
                font.family: Config.fontFamily
                font.pixelSize: Config.typeHeadlineSmallSize
                font.weight: Config.typeStrongWeight
              }
            }
          }
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
          border.width: Config.liquidGlassTheme ? 1 : Config.themeBorderWidth
          border.color: root.lockFieldBorder

          GlassSheen {
            anchors.fill: parent
            radius: parent.radius
          }

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
            visible: Config.liquidGlassTheme && root.lockInputText === ""
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
            font.pixelSize: Config.typeBodyLargeSize
            font.letterSpacing: Config.typeBodyTracking
            text: root.lockInputText
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
          opacity: root.flatLockMode && root.lockError.length === 0 ? 0 : 1
          visible: root.flatLockMode ? opacity > 0 : root.lockError.length > 0

          Behavior on opacity {
            NumberAnimation {
              duration: root.flatLockMode ? Config.motionShort : 0
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

        Loader {
          active: Config.liquidGlassTheme
          visible: active
          anchors.horizontalCenter: parent.horizontalCenter
          sourceComponent: Component {
            Row {
              spacing: Config.spacingExtraLarge

              IconButton {
                size: 40
                iconSize: 20
                iconLabel: "power_settings_new"
                iconColor: root.mutedText
                variant: "outlined"
                borderColor: Colors.liquidGlassEdgeStrong
                accessibleName: "Suspend computer"
                tooltipText: "Suspend computer"
                onClicked: root.requestPowerAction("Suspend", ["systemctl", "suspend"])
              }

              IconButton {
                size: 40
                iconSize: 20
                iconLabel: "restart_alt"
                iconColor: root.mutedText
                variant: "outlined"
                borderColor: Colors.liquidGlassEdgeStrong
                accessibleName: "Restart computer"
                tooltipText: "Restart computer"
                onClicked: root.requestPowerAction("Restart", ["systemctl", "reboot"])
              }

              IconButton {
                size: 40
                iconSize: 20
                iconLabel: "power_off"
                iconColor: root.mutedText
                variant: "outlined"
                borderColor: Colors.liquidGlassEdgeStrong
                accessibleName: "Power off computer"
                tooltipText: "Power off computer"
                onClicked: root.requestPowerAction("Power off", ["systemctl", "poweroff"])
              }
            }
          }
        }
      }

      Loader {
        anchors.fill: parent
        active: Config.liquidGlassTheme
        visible: active
        focus: active
        activeFocusOnTab: active
        sourceComponent: liquidGlassLockLayout
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
        dialogBorderColor: Colors.liquidGlassEdgeStrong
        cancelColor: Colors.liquidGlassControl
        cancelTextColor: root.textColor
        confirmColor: root.accentColor
        confirmTextColor: Colors.fgPrimary
        onConfirmed: root.confirmPowerAction()
        onCancelled: root.cancelPowerAction()
      }
    }
  }
}
