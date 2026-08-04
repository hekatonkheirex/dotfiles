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
  property bool horizontal: false

  signal dismissed()

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

  property bool btOn: false

  Process {
    id: statusQuery
    command: ["bluetoothctl", "show"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        root.btOn = out.indexOf("Powered: yes") >= 0
        if (root.btOn) {
          listQuery.running = true
        } else {
          btListModel.clear()
        }
      }
    }
  }

  Process {
    id: listQuery
    command: ["sh", "-c", "bluetoothctl devices Connected 2>/dev/null | while read -r line; do MAC=$(echo \"$line\" | cut -d' ' -f2); NAME=$(echo \"$line\" | cut -d' ' -f3-); BATT=$(bluetoothctl info \"$MAC\" 2>/dev/null | grep \"Battery Percentage:\" | awk -F '[()]' '{print $2}'); if [ -n \"$BATT\" ]; then echo \"$MAC|||$NAME|||$BATT\"; else echo \"$MAC|||$NAME|||\"; fi; done"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        btListModel.clear()
        if (out.length > 0) {
          var lines = out.split("\n")
          for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("|||")
            if (parts.length >= 2) {
              var macVal = parts[0]
              var nameVal = parts[1]
              var battVal = parts.length > 2 ? parts[2].trim() : ""
              btListModel.append({ mac: macVal, name: nameVal, battery: battVal })
            }
          }
        }
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 1000
    repeat: false
    onTriggered: statusQuery.running = true
  }

  onVisibleChanged: {
    if (visible) {
      statusQuery.running = true
      entryAnimation.start()
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

    FocusDismiss {
      target: root
      onDismissed: root.dismissed()
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
        Translate { id: transY; y: 0 },
        Scale { id: scaleTransform; origin.x: root.horizontal ? bg.width / 2 : 0; origin.y: root.horizontal ? 0 : bg.height / 2; xScale: 1.0; yScale: 1.0 }
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
          from: root.horizontal ? 0 : -30
          to: 0
          duration: Config.motionLong
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transY
          property: "y"
          from: root.horizontal ? -30 : 0
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
          margins: 12
        }
        spacing: 12

        RowLayout {
          width: parent.width
          spacing: 12

          Text {
            Layout.fillWidth: true
            text: "Bluetooth"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: (Config.fontPixelSize + 8)
            font.weight: Font.Bold
          }

          IconButton {
            iconLabel: "refresh"
            size: 28
            iconSize: 20
            enabled: !listQuery.running
            accessibleName: "Refresh Bluetooth devices"
            tooltipText: "Refresh Bluetooth devices"
            onClicked: listQuery.running = true
          }

          SwitchControl {
            id: btSwitch
            checked: root.btOn
            activeColor: Colors.primary
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Bluetooth enabled"
            
            onToggled: {
              var newState = !root.btOn
              Quickshell.execDetached(["bluetoothctl", "power", newState ? "on" : "off"])
              root.btOn = newState
              refreshTimer.start()
            }
          }
        }

        PopupDivider {}

        // Bluetooth is Off
        ColumnLayout {
          width: parent.width
          spacing: 8
          visible: !root.btOn

          Item {
            Layout.preferredHeight: 12
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "bluetooth_disabled"
            color: Colors.fgSurfaceVariant
            font.family: Config.iconFont
            font.pixelSize: 48
            opacity: 0.25
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Bluetooth is turned off"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: (Config.fontPixelSize + 4)
            font.weight: Font.Bold
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Enable Bluetooth to view connected devices."
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: (Config.fontPixelSize + 1)
          }
        }

        // Bluetooth is On
        ColumnLayout {
          width: parent.width
          spacing: 8
          visible: root.btOn

          ListModel {
            id: btListModel
          }

          ListView {
            id: listView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(300, contentHeight)
            model: btListModel
            clip: true
            spacing: 4
            delegate: btItemDelegate
            boundsBehavior: Flickable.StopAtBounds
          }

          Text {
            Layout.fillWidth: true
            text: "No connected devices found"
            visible: btListModel.count === 0 && !listQuery.running
            horizontalAlignment: Text.AlignHCenter
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize + 2
          }
        }
      }
    }
  }

  Component {
    id: btItemDelegate

    ListItem {
      id: itemRow
      width: listView.width
      leadingIcon: "bluetooth"
      leadingIconColor: Colors.primary
      title: model.name
      subtitle: model.mac
      accessibleName: model.name + " Bluetooth device"

      Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        visible: model.battery !== "" && !itemRow.hovered

        Text {
          text: model.battery + "%"
          color: Colors.primary
          font.family: Config.fontFamily
          font.pixelSize: Config.fontPixelSize + 1
          font.weight: Font.Bold
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          text: {
            var b = parseInt(model.battery)
            if (isNaN(b)) return "battery_unknown"
            if (b <= 10) return "battery_alert"
            if (b <= 20) return "battery_1_bar"
            if (b <= 40) return "battery_2_bar"
            if (b <= 60) return "battery_3_bar"
            if (b <= 80) return "battery_4_bar"
            if (b <= 95) return "battery_5_bar"
            return "battery_full"
          }
          color: Colors.primary
          font.family: Config.iconFont
          font.pixelSize: 18
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      IconButton {
        size: 28
        iconSize: 20
        iconLabel: "link_off"
        visible: itemRow.hovered
        iconColor: Colors.error
        accessibleName: "Disconnect " + model.name
        tooltipText: accessibleName
        onClicked: {
          Quickshell.execDetached(["bluetoothctl", "disconnect", model.mac])
          refreshTimer.start()
        }
      }
    }
  }
}
