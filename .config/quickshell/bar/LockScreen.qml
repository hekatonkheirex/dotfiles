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
  onLockedChanged: {
    if (locked) {
      fprintdProcess.running = true
      currentWallpaperProc.running = Settings.lockUseWallpaper
    } else {
      fprintdProcess.running = false
      fprintdRetry.stop()
      currentWallpaperProc.running = false
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

  readonly property string home: Quickshell.env("HOME")
  property date now: new Date()
  property string wallpaperSource: ""
  property bool wallpaperReady: false

  Process {
    id: currentWallpaperProc
    command: ["sh", "-c", "awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1"]
    running: root.locked && Settings.lockUseWallpaper
    stdout: StdioCollector {
      onStreamFinished: {
        var value = text.trim()
        root.wallpaperReady = false
        if (value.indexOf("file://") === 0) root.wallpaperSource = value
        else if (value.indexOf("/") === 0) root.wallpaperSource = "file://" + value
        else if (value !== "") root.wallpaperSource = "file://" + root.home + "/Pictures/Walls/" + value
        else root.wallpaperSource = ""
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
    function onLockUseWallpaperChanged() {
      root.wallpaperReady = false
      currentWallpaperProc.running = Settings.lockUseWallpaper && root.locked
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
    root.locked = true
    sessionLock.locked = true
  }

  function unlockSession() {
    authenticated = true
    clearPassword()
    root.locked = false
    sessionLock.locked = false
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
    onLockedChanged: {
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
          anchors.fill: parent
          source: root.wallpaperSource
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          visible: Settings.lockUseWallpaper && root.wallpaperReady
        }

        AnimatedBackground {
          anchors.fill: parent
          running: root.locked
          flatMode: root.flatLockMode
          flatColor: root.flatBackground
          visible: !Settings.lockUseWallpaper || !root.wallpaperReady
        }

        Rectangle {
          anchors.fill: parent
          color: Qt.rgba(0, 0, 0, 0.15)
        }

        Rectangle {
          anchors.fill: parent
          visible: !root.flatLockMode || (Settings.lockUseWallpaper && root.wallpaperReady)
          gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.5) }
            GradientStop { position: 0.5; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
          }
        }

        Column {
          anchors.centerIn: parent
          spacing: 16

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: 96
              height: 96
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
                font.pixelSize: 36
                font.weight: Font.Bold
                visible: profileImage.status !== Image.Ready
              }
            }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !Config.nothingEvolution
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
            visible: !Config.nothingEvolution
            text: {
              var d = root.now
              var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
              var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
              return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear()
            }
            color: mutedText
            font.family: Config.fontFamily
            font.pixelSize: 20
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            visible: Settings.lockShowMedia && root.lockMprisTitle !== ""

            Text {
              text: root.lockMprisStatus === "Playing" ? "pause" : "play_arrow"
              font.family: Config.iconFont
              font.pixelSize: 16
              color: mutedText
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: root.lockMprisTitle + (root.lockMprisArtist ? " - " + root.lockMprisArtist : "")
              color: mutedText
              font.family: Config.fontFamily
              font.pixelSize: 14
              elide: Text.ElideRight
              width: Math.min(implicitWidth, 320)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Item { height: 8 }

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: 48
            radius: root.inputRadius
            color: root.inputFill
            border.width: Config.themeBorderWidth
            border.color: root.inputBorder

            TextInput {
              anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
              color: textColor
              font.family: Config.fontFamily
              font.pixelSize: 18
              text: root.lockInputText
              echoMode: TextInput.Password
              passwordCharacter: "\u25CF"
              focus: root.locked
              activeFocusOnPress: true
              cursorVisible: true
              verticalAlignment: Qt.AlignVCenter
              selectByMouse: true

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
            font.pixelSize: 15
            font.weight: Font.Bold
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
            font.pixelSize: 14
            opacity: 0.8
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            IconButton {
              size: 40
              iconSize: 20
              iconLabel: "power_settings_new"
              iconColor: mutedText
              outlined: true
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
              outlined: true
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
              outlined: true
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
      anchors.left: true
      anchors.right: true
      anchors.top: true
      anchors.bottom: true

      Image {
        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: Settings.lockUseWallpaper && root.wallpaperReady
      }

      AnimatedBackground {
        anchors.fill: parent
        running: root.locked
        flatMode: root.flatLockMode
        flatColor: root.flatBackground
        visible: !Settings.lockUseWallpaper || !root.wallpaperReady
      }

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.15)
      }

      Rectangle {
        anchors.fill: parent
        visible: !root.flatLockMode || (Settings.lockUseWallpaper && root.wallpaperReady)
        gradient: Gradient {
          orientation: Gradient.Vertical
          GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.5) }
          GradientStop { position: 0.5; color: "transparent" }
          GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
        }
      }

      Column {
        anchors.centerIn: parent
        spacing: 16

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          visible: !Config.nothingEvolution
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
          visible: !Config.nothingEvolution
          text: {
            var d = root.now
            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
            return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear()
          }
          color: root.mutedText
          font.family: Config.fontFamily
          font.pixelSize: 20
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 8
          visible: Settings.lockShowMedia && root.lockMprisTitle !== ""

          Text {
            text: root.lockMprisStatus === "Playing" ? "pause" : "play_arrow"
            font.family: Config.iconFont
            font.pixelSize: 16
            color: root.mutedText
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: root.lockMprisTitle + (root.lockMprisArtist ? " - " + root.lockMprisArtist : "")
            color: root.mutedText
            font.family: Config.fontFamily
            font.pixelSize: 14
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 320)
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Item { height: 8 }

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 280
          height: 48
          radius: root.inputRadius
          color: root.inputFill
          border.width: Config.themeBorderWidth
          border.color: root.inputBorder

          TextInput {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
            color: root.textColor
            font.family: Config.fontFamily
            font.pixelSize: 18
            text: root.lockInputText
            echoMode: TextInput.Password
            passwordCharacter: "\u25CF"
            focus: true
            activeFocusOnPress: true
            cursorVisible: true
            verticalAlignment: Qt.AlignVCenter
            selectByMouse: true

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
          font.pixelSize: 15
          font.weight: Font.Bold
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
          font.pixelSize: 14
          opacity: 0.8
        }
      }
    }
  }
}
