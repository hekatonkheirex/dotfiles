import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import "primitives"
import "../config"

PanelWindow {
  id: root

  property int anchorY: 0

  signal dismissed()

  property bool isHorizontal: false
  signal toggleHorizontal()

  property int activePowerIndex: -1
  property var powerOptions: [
    { label: "Log Out", cmd: ["sh", Quickshell.env("HOME") + "/.config/quickshell/scripts/safe-logout.sh"] },
    { label: "Shut Down", cmd: ["systemctl", "poweroff"] },
    { label: "Restart", cmd: ["systemctl", "reboot"] },
    { label: "Sleep", cmd: ["systemctl", "suspend"] }
  ]
  property double openTime: 0

  function changeWallpaper() {
    Quickshell.execDetached(["sh", "-c",
      "wall_dir=\"$HOME/Pictures/Walls\"; " +
      "selected=$(find \"$wall_dir\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | shuf -n 1); " +
      "[ -n \"$selected\" ] && exec bash \"$HOME/.config/quickshell/scripts/apply-wallpaper.sh\" \"${selected##*/}\""])
  }

  implicitWidth: Config.popupWidth
  visible: false
  implicitHeight: Math.min(contentColumn.implicitHeight + 32, 500)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: Config.barWidth + 4
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))

  property bool caffeineOn: false

  Process {
    id: idleCheck
    command: ["sh", "-c", "pgrep -x swayidle >/dev/null 2>&1 && echo active || echo inactive"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.caffeineOn = text.trim() !== "active"
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
      radius: Config.borderRadius
      color: Colors.surfaceContainerHigh
      clip: true
      border.width: 1
      border.color: Colors.outlineVariant

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
          duration: Config.motionLong
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
          to: 0
          duration: Config.motionLong
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: bg
          property: "opacity"
          from: 0.0
          to: 1.0
          duration: Config.motionMedium
          easing.type: Easing.OutCubic
        }
      }

      Column {
        id: contentColumn
        anchors {
          fill: parent
          margins: Config.popupPadding
        }
        spacing: 14

        Text {
          text: "Quick Settings"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: (Config.fontPixelSize + 8)
          font.weight: Font.Bold
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
        }

        Row {
          spacing: 12
          width: parent.width

          ActionButton {
            id: layoutBtn
            width: (parent.width - 3 * 12) / 4
            height: width
            iconLabel: root.isHorizontal ? "horizontal_split" : "vertical_split"
            selected: root.isHorizontal
            onActivated: root.toggleHorizontal()
          }

          ActionButton {
            id: wallBtn
            width: (parent.width - 3 * 12) / 4
            height: width
            iconLabel: "wallpaper"
            iconColor: Colors.primary
            onActivated: root.changeWallpaper()
          }

          ActionButton {
            id: idleBtn
            width: (parent.width - 3 * 12) / 4
            height: width
            iconLabel: "coffee"
            selected: root.caffeineOn
            onActivated: {
              if (root.caffeineOn) {
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh"])
                root.caffeineOn = false
              } else {
                Quickshell.execDetached(["killall", "swayidle"])
                root.caffeineOn = true
              }
            }
          }

          ActionButton {
            id: dmBtn
            width: (parent.width - 3 * 12) / 4
            height: width
            iconLabel: ["brightness_auto", "light_mode", "dark_mode"][Colors.themePreference]
            selected: Colors.darkMode || Colors.themePreference === 1
            onActivated: {
              Colors.themePreference = (Colors.themePreference + 1) % 3
              var modes = ["auto", "light", "dark"]
              Quickshell.execDetached(["/bin/sh", "-c", "$HOME/.local/bin/sync-theme-mode.sh " + modes[Colors.themePreference]])
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
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
              activeFocusOnTab: true

              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  Quickshell.execDetached(modelData.cmd)
                  if (modelData.label !== "Sleep") root.dismissed()
                  event.accepted = true
                }
              }

              width: (parent.width - 3 * 8) / 4
              height: width
              radius: 20
              color: (pwArea.containsMouse || active) ? (Colors.primary) : (Colors.surfaceContainer)
              border.color: (pwArea.containsMouse || active) ? "transparent" : (Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15))
              border.width: 1

              Behavior on color {
                ColorAnimation { duration: Config.animationDuration}
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
                  color: (pwArea.containsMouse || active) ? (Colors.fgPrimary) : (Colors.fgSurfaceVariant)
                  font.family: Config.iconFont
                  font.pixelSize: (Config.iconSize + 4)
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.label
                  color: (pwArea.containsMouse || active) ? (Colors.fgPrimary) : (Colors.fgSurfaceVariant)
                  font.family: Config.fontFamily
                  font.pixelSize: (Config.fontPixelSize - 1)
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
                  parent.forceActiveFocus()
                  Quickshell.execDetached(modelData.cmd)
                  if (modelData.label !== "Sleep") root.dismissed()
                }
              }

              Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: 24
                color: "transparent"
                border.width: parent.activeFocus ? 2 : 0
                border.color: Colors.primary
                visible: parent.activeFocus
              }
            }
          }
        }

      }
    }
  }
}
