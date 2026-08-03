import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"

Item {
  id: root

  property bool active: false
  property bool horizontal: false

  signal clicked(var mouse)

  Layout.preferredWidth: Config.widgetSize
  Layout.preferredHeight: Config.widgetSize

  property bool btOn: false
  property string btDeviceMac: ""
  property string btDeviceBattery: ""

  Process {
    id: btQuery
    command: ["sh", "-c", "echo $(bluetoothctl show 2>/dev/null | grep 'Powered:' | awk '{print $2}')___$(MAC=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f2) && [ -n \"$MAC\" ] && echo \"$MAC\" || echo \"\")___$(MAC=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f2) && [ -n \"$MAC\" ] && bluetoothctl info \"$MAC\" 2>/dev/null | grep \"Battery Percentage:\" | awk -F '[()]' '{print $2}' || echo \"\")"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        var clean = text.trim()
        var parts = clean.split("___")
        root.btOn = parts[0] === "yes"
        root.btDeviceMac = parts.length > 1 ? parts[1] : ""
        root.btDeviceBattery = parts.length > 2 ? parts[2].trim() : ""
      }
    }
  }

  Timer {
    id: pollTimer
    interval: 5000 // 5s
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: btQuery.running = true
  }

  onVisibleChanged: {
    if (visible) btQuery.running = true
  }

  Component.onCompleted: {
    if (root.visible) btQuery.running = true
  }

  readonly property string iconLabel: {
    if (!root.btOn) return "bluetooth_disabled"
    if (root.btDeviceMac !== "") return "bluetooth_connected"
    return "bluetooth"
  }

  Rectangle {
    id: bgOverlay
    anchors {
      fill: parent
      leftMargin: root.horizontal ? 0 : 6
      rightMargin: root.horizontal ? 0 : 6
      topMargin: root.horizontal ? 6 : 0
      bottomMargin: root.horizontal ? 6 : 0
    }
    radius: root.horizontal ? height / 2 : width / 2
    clip: true
    color: {
      var overlay = mouseArea.pressed ? Colors.pressOverlay : (mouseArea.containsMouse ? Colors.hoverOverlay : Qt.rgba(0, 0, 0, 0))
      return Qt.tint(root.active ? Colors.primary : Colors.surfaceContainerHigh, overlay)
    }
    border.color: {
      if (root.active) return "transparent"
      return Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
    }
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: Config.animationDuration}
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    text: root.iconLabel
    color: {
      if (root.active) return Colors.fgPrimary
      return Colors.primary
    }
    font.family: Config.iconFont
    font.pixelSize: Config.iconSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 4
    text: {
      if (!root.btOn) return "Off"
      if (root.btDeviceMac !== "") {
        if (root.btDeviceBattery !== "") {
          return root.btDeviceBattery + "%"
        }
        return "On"
      }
      return "On"
    }
    color: {
      if (root.active) return Colors.fgPrimary
      return Colors.primary
    }
    font.family: Config.fontFamily
    font.pixelSize: (Config.fontPixelSize - 2)
    font.weight: Font.Medium
    horizontalAlignment: Text.AlignHCenter
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.clicked(mouse)
    }
  }
}
