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

  property real volume: 0.5
  property bool muted: false

  Process {
    id: audioQuery
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        var m = /Volume:\s*([\d.]+)/.exec(out)
        if (m) root.volume = parseFloat(m[1])
        root.muted = out.indexOf("[MUTED]") >= 0
      }
    }
  }

  function pollAudio() { audioQuery.running = true }

  function setVolume(val) {
    root.volume = Math.max(0, Math.min(1, val))
    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(root.volume)])
  }

  Process {
    id: audioWatcher
    command: ["pactl", "subscribe"]
    running: root.visible
    stdout: SplitParser {
      onRead: function(data) {
        if (data.indexOf("sink") >= 0) {
          root.pollAudio()
        }
      }
    }
    onRunningChanged: {
      if (!running && root.visible) audioWatcherRetry.start()
    }
  }

  Timer {
    id: audioWatcherRetry
    interval: 1000
    onTriggered: {
      if (root.visible) audioWatcher.running = true
    }
  }

  onVisibleChanged: {
    if (visible) root.pollAudio()
  }

  Component.onCompleted: {
    if (root.visible) root.pollAudio()
  }

  property bool active: false

  readonly property string iconLabel: {
    if (root.muted) return "volume_off"
    if (root.volume <= 0) return "volume_mute"
    return "volume_up"
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
      if (root.muted) return Colors.error
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
    text: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
    color: {
      if (root.active) return Colors.fgPrimary
      if (root.muted) return Colors.error
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
    onWheel: function(wheel) {
      var delta = wheel.angleDelta.y > 0 ? (Config.volumeStep) / 100 : -(Config.volumeStep) / 100
      root.setVolume(root.volume + delta)
    }
  }
}
