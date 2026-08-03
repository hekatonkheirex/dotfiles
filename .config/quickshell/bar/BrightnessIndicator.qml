import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"

Item {
  id: root

  property bool horizontal: false

  signal clicked(var mouse)

  Layout.preferredWidth: Config.widgetSize
  Layout.preferredHeight: Config.widgetSize

  property real pct: 0
  property bool initialized: false

  Process {
    id: getProc
    command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var val = parseFloat(text.trim())
        if (!isNaN(val)) {
          root.pct = val
          root.initialized = true
        }
      }
    }
  }

  function fetchBrightness() { getProc.running = true }

  function setBrightness(val) {
    root.pct = Math.max(0, Math.min(100, val))
    Quickshell.execDetached(["brightnessctl", "set", Math.round(root.pct) + "%"])
  }

  Process {
    id: brightnessWatcher
    command: ["sh", "-c", "inotifywait -m -e modify /sys/class/backlight/*/brightness"]
    running: root.visible
    stdout: SplitParser {
      onRead: function(data) {
        root.fetchBrightness()
      }
    }
    onRunningChanged: {
      if (!running && root.visible) brightnessWatcherRetry.start()
    }
  }

  Timer {
    id: brightnessWatcherRetry
    interval: 1000
    onTriggered: {
      if (root.visible) brightnessWatcher.running = true
    }
  }

  property bool active: false

  onVisibleChanged: {
    if (visible) root.fetchBrightness()
  }

  Component.onCompleted: {
    if (root.visible) root.fetchBrightness()
  }

  property string iconLabel: {
    if (!root.initialized) return "brightness_medium"
    if (root.pct <= 10) return "brightness_empty"
    if (root.pct <= 40) return "brightness_low"
    if (root.pct <= 70) return "brightness_medium"
    return "brightness_high"
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
      return Qt.tint(root.active ? Colors.brightness : Colors.surfaceContainerHigh, overlay)
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
      return Colors.brightness
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
    text: root.initialized ? Math.round(root.pct) + "%" : ""
    color: {
      if (root.active) return Colors.fgPrimary
      return Colors.brightness
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
    onWheel: function(wheel) {
      var delta = wheel.angleDelta.y > 0 ? (Config.brightnessStep) : -(Config.brightnessStep)
      root.setBrightness(root.pct + delta)
    }
  }
}
