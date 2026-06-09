import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property int anchorY: 0

  signal dismissed()

  implicitWidth: config ? config.popupWidth : 340
  implicitHeight: Math.min(contentColumn.implicitHeight + 32, 500)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: config ? config.barWidth + 4 : 48
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))

  property bool wifiOn: false
  property string wifiSSID: ""
  property bool btOn: false
  property string btDevice: ""
  property bool idleOn: false

  Process {
    id: wifiQuery
    command: ["sh", "-c", "echo $(nmcli radio wifi)___$(nmcli -t -f active,ssid dev wifi list 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2)"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = text.trim().split("___")
        root.wifiOn = parts[0] === "enabled"
        root.wifiSSID = parts.length > 1 && parts[1] ? parts[1] : ""
      }
    }
  }

  Process {
    id: btQuery
    command: ["sh", "-c", "echo $(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}')___$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-)"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = text.trim().split("___")
        root.btOn = parts[0] === "yes"
        root.btDevice = parts.length > 1 && parts[1] ? parts[1] : ""
      }
    }
  }

  function pollAll() { wifiQuery.running = true; btQuery.running = true }

  Timer {
    interval: 2000
    running: root.visible
    repeat: true
    onTriggered: root.pollAll()
  }

  Process {
    id: idleCheck
    command: ["sh", "-c", "pgrep -x swayidle >/dev/null 2>&1 && echo active || echo inactive"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.idleOn = text.trim() !== "active"
      }
    }
  }

  onVisibleChanged: {
    if (visible) {
      pollAll()
      idleCheck.running = true
      if (config && config.isNiri) root.requestActivate()
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.dismissed()

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: config ? config.borderRadius : 14
      color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
      clip: true

      Column {
        id: contentColumn
        anchors {
          fill: parent
          margins: config ? config.popupPadding : 16
        }
        spacing: 14

        Text {
          text: "Quick Settings"
          color: colors_ ? colors_.onSurface : "#FFFFFF"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 8) : 18
          font.weight: Font.Bold
        }

        Rectangle {
          width: parent.width
          height: 1
          color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
        }

        Row {
          spacing: 12
          width: parent.width

          Rectangle {
            id: wifiBtn
            width: (parent.width - 3 * 12) / 4
            height: 80
            radius: config ? config.borderRadius : 14
            color: root.wifiOn ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.surfaceContainer : "#211F26")
            border.color: root.wifiOn ? "transparent" : (colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15))
            border.width: 1

            Behavior on color {
              ColorAnimation { duration: config ? config.animationDuration : 150 }
            }

            Column {
              anchors.centerIn: parent
              spacing: 4

              Text {
                id: toggleBtn
                anchors.horizontalCenter: parent.horizontalCenter
                text: "wifi"
                color: root.wifiOn ? (colors_ ? colors_.onPrimary : "#FFFFFF") : (colors_ ? colors_.onSurfaceVariant : "#CAC4D0")
                font.family: config ? config.iconFont : "Material Symbols Outlined"
                font.pixelSize: config ? (config.iconSize + 4) : 26
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                  Quickshell.execDetached(["nm-connection-editor"])
                } else {
                  Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"])
                  root.wifiOn = !root.wifiOn
                }
              }
            }
          }

          Rectangle {
            id: btBtn
            width: (parent.width - 3 * 12) / 4
            height: 80
            radius: config ? config.borderRadius : 14
            color: root.btOn ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.surfaceContainer : "#211F26")
            border.color: root.btOn ? "transparent" : (colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15))
            border.width: 1

            Behavior on color {
              ColorAnimation { duration: config ? config.animationDuration : 150 }
            }

            Column {
              anchors.centerIn: parent
              spacing: 4

              Text {
                id: btToggle
                anchors.horizontalCenter: parent.horizontalCenter
                text: "bluetooth"
                color: root.btOn ? (colors_ ? colors_.onPrimary : "#FFFFFF") : (colors_ ? colors_.onSurfaceVariant : "#CAC4D0")
                font.family: config ? config.iconFont : "Material Symbols Outlined"
                font.pixelSize: config ? (config.iconSize + 4) : 26
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                  Quickshell.execDetached(["blueman-manager"])
                } else {
                  Quickshell.execDetached(["bluetoothctl", "power", root.btOn ? "off" : "on"])
                  root.btOn = !root.btOn
                }
              }
            }
          }

          Rectangle {
            id: idleBtn
            width: (parent.width - 3 * 12) / 4
            height: 80
            radius: config ? config.borderRadius : 14
            color: root.idleOn ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.surfaceContainer : "#211F26")
            border.color: root.idleOn ? "transparent" : (colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15))
            border.width: 1

            Behavior on color {
              ColorAnimation { duration: config ? config.animationDuration : 150 }
            }

            Column {
              anchors.centerIn: parent
              spacing: 4

              Text {
                id: idleToggle
                anchors.horizontalCenter: parent.horizontalCenter
                text: "coffee"
                color: root.idleOn ? (colors_ ? colors_.onPrimary : "#FFFFFF") : (colors_ ? colors_.onSurfaceVariant : "#CAC4D0")
                font.family: config ? config.iconFont : "Material Symbols Outlined"
                font.pixelSize: config ? (config.iconSize + 4) : 26
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.idleOn) {
                  Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh"])
                  root.idleOn = false
                } else {
                  Quickshell.execDetached(["killall", "swayidle"])
                  root.idleOn = true
                }
              }
            }
          }

          Rectangle {
            id: dmBtn
            width: (parent.width - 3 * 12) / 4
            height: 80
            radius: config ? config.borderRadius : 14
            color: colors_ && colors_.darkMode ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.surfaceContainer : "#211F26")
            border.color: colors_ && colors_.darkMode ? "transparent" : (colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15))
            border.width: 1

            Behavior on color {
              ColorAnimation { duration: config ? config.animationDuration : 150 }
            }

            Column {
              anchors.centerIn: parent
              spacing: 4

              Text {
                id: dmToggle
                anchors.horizontalCenter: parent.horizontalCenter
                text: colors_ ? ["brightness_auto", "light_mode", "dark_mode"][colors_.themePreference] : "dark_mode"
                color: colors_ && colors_.darkMode ? (colors_ ? colors_.onPrimary : "#FFFFFF") : (colors_ ? colors_.onSurfaceVariant : "#CAC4D0")
                font.family: config ? config.iconFont : "Material Symbols Outlined"
                font.pixelSize: config ? (config.iconSize + 4) : 26
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (colors_) colors_.themePreference = (colors_.themePreference + 1) % 3
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
        }

        Row {
          spacing: 8
          width: parent.width
          layoutDirection: Qt.RightToLeft

          Repeater {
            model: [
              { label: "Log Out", cmd: ["sh", Quickshell.env("HOME") + "/.local/bin/safe-logout.sh"] },
              { label: "Shut Down", cmd: ["systemctl", "poweroff"] },
              { label: "Restart", cmd: ["systemctl", "reboot"] },
              { label: "Sleep", cmd: ["systemctl", "suspend"] }
            ]

            delegate: Rectangle {
              required property var modelData
              width: (parent.width - 3 * 8) / 4
              height: 80
              radius: config ? config.borderRadius : 14
              color: pwArea.containsMouse ? (colors_ ? colors_.surfaceContainerHighest : "#36343B") : (colors_ ? colors_.surfaceContainer : "#211F26")
              border.color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
              border.width: 1

              Behavior on color {
                ColorAnimation { duration: config ? config.animationDuration : 150 }
              }

              Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: {
                    var icons = { "Sleep": "bedtime", "Restart": "restart_alt", "Shut Down": "power_settings_new", "Log Out": "logout" }
                    return icons[modelData.label] || "power_settings_new"
                  }
                  color: colors_ ? colors_.onSurfaceVariant : "#CAC4D0"
                  font.family: config ? config.iconFont : "Material Symbols Outlined"
                  font.pixelSize: config ? (config.iconSize + 4) : 26
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.label
                  color: colors_ ? colors_.onSurfaceVariant : "#CAC4D0"
                  font.family: config ? config.fontFamily : "Google Sans Flex"
                  font.pixelSize: config ? (config.fontPixelSize - 1) : 10
                  font.weight: Font.Medium
                }
              }

              MouseArea {
                id: pwArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  Quickshell.execDetached(modelData.cmd)
                  if (modelData.label !== "Sleep") root.dismissed()
                }
              }
            }
          }
        }
      }
    }
  }
}
