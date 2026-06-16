import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property bool active: false
  property bool horizontal: false

  signal clicked(var mouse)

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: config ? config.widgetSize : 50

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
      if (root.active) return colors_ ? colors_.primary : "#D0BCFF"
      if (mouseArea.containsMouse) return colors_ ? colors_.surfaceContainerHighest : "#36343B"
      return colors_ ? colors_.surfaceContainerHigh : "#2B2930"
    }
    border.color: {
      if (root.active) return "transparent"
      return colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
    }
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: config ? config.animationDuration : 150 }
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    text: root.iconLabel
    color: {
      if (root.active) return colors_ ? colors_.fgPrimary : "#0F3C2C"
      return colors_ ? colors_.primary : "#D0BCFF"
    }
    font.family: config ? config.iconFont : "Material Symbols Outlined"
    font.pixelSize: config ? config.iconSize : 22
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
      if (root.active) return colors_ ? colors_.fgPrimary : "#0F3C2C"
      return colors_ ? colors_.primary : "#D0BCFF"
    }
    font.family: config ? config.fontFamily : "Google Sans Flex"
    font.pixelSize: config ? (config.fontPixelSize - 2) : 8
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
