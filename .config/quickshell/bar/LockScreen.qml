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
  onLockedChanged: {
    if (locked) {
      fprintdProcess.running = true
    } else {
      fprintdProcess.running = false
      fprintdRetry.stop()
    }
  }
  readonly property color accentColor: Colors.primary
  // Lock screen sits on a fixed dark photo scrim independent of the desktop's
  // light/dark mode, so text stays fixed white for legibility rather than
  // following Colors.fgSurface (which would go near-black in light mode).
  readonly property color textColor: "#FFFFFF"
  readonly property color mutedText: Qt.rgba(1, 1, 1, 0.7)
  readonly property color errorColor: Colors.destructive

  readonly property string home: Quickshell.env("HOME")
  property date now: new Date()

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  property string lockPassword: ""
  property string lockInputText: ""
  property string lockError: ""
  property bool authenticated: false

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

        AnimatedBackground {
          anchors.fill: parent
          running: root.locked
        }

        Rectangle {
          anchors.fill: parent
          color: Qt.rgba(0, 0, 0, 0.15)
        }

        Rectangle {
          anchors.fill: parent
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
              radius: 48
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
                radius: 48
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
            text: {
              var d = root.now
              return d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
            }
            color: textColor
            font.family: Config.fontFamily
            font.pixelSize: 72
            font.weight: Font.Bold
            style: Text.Sunken
            styleColor: Qt.rgba(0, 0, 0, 0.3)
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
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

          Item { height: 8 }

          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: 48
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.2)

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
            visible: root.lockError.length > 0
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
              onClicked: Quickshell.execDetached(["systemctl", "suspend"])
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
              onClicked: Quickshell.execDetached(["systemctl", "reboot"])
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
              onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
            }
          }
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

      AnimatedBackground {
        anchors.fill: parent
        running: root.locked
      }

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.15)
      }

      Rectangle {
        anchors.fill: parent
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
          text: {
            var d = root.now
            return d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
          }
          color: root.textColor
          font.family: Config.fontFamily
          font.pixelSize: 72
          font.weight: Font.Bold
          style: Text.Sunken
          styleColor: Qt.rgba(0, 0, 0, 0.3)
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
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

        Item { height: 8 }

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 280
          height: 48
          radius: 12
          color: Qt.rgba(1, 1, 1, 0.12)
          border.width: 1
          border.color: Qt.rgba(1, 1, 1, 0.2)

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
          visible: root.lockError.length > 0
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
