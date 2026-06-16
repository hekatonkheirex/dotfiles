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

  property bool isHorizontal: false
  signal toggleHorizontal()

  property int activePowerIndex: -1
  property var powerOptions: [
    { label: "Log Out", cmd: ["sh", Quickshell.env("HOME") + "/.local/bin/safe-logout.sh"] },
    { label: "Shut Down", cmd: ["systemctl", "poweroff"] },
    { label: "Restart", cmd: ["systemctl", "reboot"] },
    { label: "Sleep", cmd: ["systemctl", "suspend"] }
  ]
  property double openTime: 0

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

  property bool idleOn: false

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
      idleCheck.running = true
      entryAnimation.start()
      root.activePowerIndex = -1
      mainItem.forceActiveFocus()
      root.openTime = Date.now()
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

  Item {
    id: mainItem
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) {
        if (Date.now() - root.openTime > 150) {
          root.dismissed()
        }
        event.accepted = true
      } else if (event.key === Qt.Key_Left) {
        var len = root.powerOptions.length;
        root.activePowerIndex = (root.activePowerIndex === -1) ? 0 : (root.activePowerIndex === len - 1 ? 0 : root.activePowerIndex + 1);
        event.accepted = true
      } else if (event.key === Qt.Key_Right) {
        var len = root.powerOptions.length;
        root.activePowerIndex = (root.activePowerIndex === -1) ? len - 1 : (root.activePowerIndex === 0 ? len - 1 : root.activePowerIndex - 1);
        event.accepted = true
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        if (root.activePowerIndex >= 0 && root.activePowerIndex < root.powerOptions.length) {
          var opt = root.powerOptions[root.activePowerIndex];
          Quickshell.execDetached(opt.cmd);
          if (opt.label !== "Sleep") root.dismissed();
          event.accepted = true
        }
      }
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: config ? config.borderRadius : 14
      color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
      clip: true
      border.width: 1
      border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)

      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: 0; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

      ParallelAnimation {
        id: entryAnimation
        NumberAnimation {
          target: scaleTransform
          properties: "xScale,yScale"
          from: 0.85
          to: 1.0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
          to: 0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: bg
          property: "opacity"
          from: 0.0
          to: 1.0
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

      Column {
        id: contentColumn
        anchors {
          fill: parent
          margins: config ? config.popupPadding : 16
        }
        spacing: 14

        Text {
          text: "Quick Settings"
          color: colors_ ? colors_.fgSurface : "#FFFFFF"
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
            id: layoutBtn
            width: (parent.width - 3 * 12) / 4
            height: width
            radius: 20
            color: root.isHorizontal ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.surfaceContainer : "#211F26")
            border.color: root.isHorizontal ? "transparent" : (colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15))
            border.width: 1

            Behavior on color {
              ColorAnimation { duration: config ? config.animationDuration : 150 }
            }

            Column {
              anchors.centerIn: parent
              spacing: 4

              Text {
                id: layoutToggleBtn
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.isHorizontal ? "horizontal_split" : "vertical_split"
                color: root.isHorizontal ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                font.family: config ? config.iconFont : "Material Symbols Outlined"
                font.pixelSize: config ? (config.iconSize + 4) : 26
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.toggleHorizontal()
              }
            }
          }

          Rectangle {
            id: wallBtn
            width: (parent.width - 3 * 12) / 4
            height: width
            radius: 20
            color: colors_ ? (wallMouse.containsMouse ? colors_.surfaceContainerHighest : colors_.surfaceContainer) : "#211F26"
            border.color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
            border.width: 1

            Behavior on color {
              ColorAnimation { duration: config ? config.animationDuration : 150 }
            }

            Column {
              anchors.centerIn: parent
              spacing: 4

              Text {
                id: wallToggle
                anchors.horizontalCenter: parent.horizontalCenter
                text: "wallpaper"
                color: colors_ ? colors_.primary : "#D0BCFF"
                font.family: config ? config.iconFont : "Material Symbols Outlined"
                font.pixelSize: config ? (config.iconSize + 4) : 26
              }
            }

            MouseArea {
              id: wallMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Quickshell.execDetached(["sh", "-c", Quickshell.env("HOME") + "/.local/bin/wall"])
              }
            }
          }

          Rectangle {
            id: idleBtn
            width: (parent.width - 3 * 12) / 4
            height: width
            radius: 20
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
                color: root.idleOn ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
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
            height: width
            radius: 20
            color: colors_ ? (colors_.darkMode || colors_.themePreference === 1 ? colors_.primary : colors_.surfaceContainer) : "#211F26"
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
                color: colors_ ? (colors_.darkMode || colors_.themePreference === 1 ? colors_.fgPrimary : colors_.fgSurfaceVariant) : "#CAC4D0"
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
            model: root.powerOptions

            delegate: Rectangle {
              required property var modelData
              required property int index

              readonly property bool active: index === root.activePowerIndex

              width: (parent.width - 3 * 8) / 4
              height: width
              radius: 20
              color: (pwArea.containsMouse || active) ? (colors_ ? colors_.primary : "#D0BCFF") : (colors_ ? colors_.surfaceContainer : "#211F26")
              border.color: (pwArea.containsMouse || active) ? "transparent" : (colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15))
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
                  color: (pwArea.containsMouse || active) ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                  font.family: config ? config.iconFont : "Material Symbols Outlined"
                  font.pixelSize: config ? (config.iconSize + 4) : 26
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.label
                  color: (pwArea.containsMouse || active) ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
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
                onEntered: root.activePowerIndex = index
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
