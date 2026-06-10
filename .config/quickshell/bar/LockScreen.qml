import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  property bool locked: false
  readonly property color accentGreen: "#BEE8C7"
  readonly property color textColor: "#FFFFFF"
  readonly property color mutedText: Qt.rgba(1, 1, 1, 0.7)
  readonly property color errorColor: "#ea1821"

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

  function lockScreen() {
    lockPassword = ""
    lockInputText = ""
    lockError = ""
    authenticated = false
    root.locked = true
    sessionLock.locked = true
  }

  function unlockSession() {
    authenticated = true
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

  FileTrigger {
    triggerFile: "/tmp/qslock-trigger"
    onTriggered: root.lockScreen()
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
        root.lockError = "Wrong password. Try again."
        root.lockPassword = ""
        root.lockInputText = ""
      }
    }
    onError: (error) => {
      root.lockError = "Authentication error. Try again."
      root.lockPassword = ""
      root.lockInputText = ""
    }
  }

  Process {
    id: fprintdProcess
    command: ["fprintd-verify", root.username()]
    running: root.locked

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && root.locked && !root.authenticated) {
        root.unlockSession()
      } else if (root.locked && !root.authenticated) {
        fprintdRetry.start()
      }
    }
  }

  Timer {
    id: fprintdRetry
    interval: 300
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
        fprintdProcess.running = true
      }
      root.locked = locked
    }
    surface: Component {
      WlSessionLockSurface {
        color: "#000000"

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
          source: Qt.resolvedUrl("../resources/lock_bg.png")
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }

        Rectangle {
          anchors.fill: parent
          color: Qt.rgba(0, 0, 0, 0.45)
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
            border.color: accentGreen
            color: colors_ ? colors_.primaryContainer : "#1E4F3E"

            Image {
              id: profileImage
              anchors.fill: parent
              source: "file://" + root.home + "/Pictures/profile.jpg"
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
            }

            Text {
              anchors.centerIn: parent
              text: root.username().charAt(0).toUpperCase()
              color: colors_ ? colors_.fgPrimaryContainer : "#BEE8C7"
              font.family: "Google Sans Flex"
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
            font.family: "Google Sans Flex"
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
            font.family: "Google Sans Flex"
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
              font.family: "Google Sans Flex"
              font.pixelSize: 18
              text: root.lockInputText
              echoMode: TextInput.Password
              passwordCharacter: "\u25CF"
              focus: root.locked
              activeFocusOnPress: true
              cursorVisible: true
              verticalAlignment: Qt.AlignVCenter

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
            font.family: "Google Sans Flex"
            font.pixelSize: 15
            font.weight: Font.Bold
            visible: root.lockError.length > 0
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "or touch the fingerprint sensor"
            color: mutedText
            font.family: "Google Sans Flex"
            font.pixelSize: 14
            opacity: 0.8
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            Rectangle {
              width: 40; height: 40; radius: 20
              color: "transparent"
              border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.3)
              Text {
                anchors.centerIn: parent
                text: "power_settings_new"
                color: mutedText
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                }
              }
            }

            Rectangle {
              width: 40; height: 40; radius: 20
              color: "transparent"
              border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.3)
              Text {
                anchors.centerIn: parent
                text: "restart_alt"
                color: mutedText
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                }
              }
            }

            Rectangle {
              width: 40; height: 40; radius: 20
              color: "transparent"
              border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.3)
              Text {
                anchors.centerIn: parent
                text: "power_off"
                color: mutedText
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                }
              }
            }
          }
        }
      }
    }
  }

  Loader {
    active: !config.isNiri && root.locked
    sourceComponent: PanelWindow {
      color: "#000000"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-lock"
      WlrLayershell.layer: WlrLayer.Overlay
      anchors.left: true
      anchors.right: true
      anchors.top: true
      anchors.bottom: true

      Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../resources/lock_bg.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }

      Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
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
          color: "#FFFFFF"
          font.family: "Google Sans Flex"
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
          color: Qt.rgba(1, 1, 1, 0.7)
          font.family: "Google Sans Flex"
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
            color: "#FFFFFF"
            font.family: "Google Sans Flex"
            font.pixelSize: 18
            text: root.lockInputText
            echoMode: TextInput.Password
            passwordCharacter: "\u25CF"
            focus: true
            activeFocusOnPress: true
            cursorVisible: true
            verticalAlignment: Qt.AlignVCenter

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
          color: "#ea1821"
          font.family: "Google Sans Flex"
          font.pixelSize: 15
          font.weight: Font.Bold
          visible: root.lockError.length > 0
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "or touch the fingerprint sensor"
          color: Qt.rgba(1, 1, 1, 0.7)
          font.family: "Google Sans Flex"
          font.pixelSize: 14
          opacity: 0.8
        }
      }
    }
  }
}
