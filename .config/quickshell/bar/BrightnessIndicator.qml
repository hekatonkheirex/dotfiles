import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  signal clicked(var mouse)

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: config ? config.widgetSize : 50

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
    running: true
    stdout: SplitParser {
      onRead: function(data) {
        root.fetchBrightness()
      }
    }
    onRunningChanged: {
      if (!running) brightnessWatcherRetry.start()
    }
  }

  Timer {
    id: brightnessWatcherRetry
    interval: 1000
    onTriggered: brightnessWatcher.running = true
  }

  Component.onCompleted: root.fetchBrightness()

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
      leftMargin: 6
      rightMargin: 6
    }
    radius: config ? config.borderRadius : 14
    clip: true
    color: colors_ ? (mouseArea.containsMouse ? colors_.surfaceContainerHighest : colors_.surfaceContainerHigh) : "#2B2930"
    border.color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: config ? config.animationDuration : 150 }
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    text: root.iconLabel
    color: colors_ ? colors_.primary : "#D0BCFF"
    font.family: config ? config.iconFont : "Material Symbols Outlined"
    font.pixelSize: config ? config.iconSize : 22
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 4
    text: root.initialized ? Math.round(root.pct) + "%" : ""
    color: colors_ ? colors_.primary : "#D0BCFF"
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
    onWheel: function(wheel) {
      var delta = wheel.angleDelta.y > 0 ? (config ? config.brightnessStep : 5) : -(config ? config.brightnessStep : 5)
      root.setBrightness(root.pct + delta)
    }
  }
}
