import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property bool horizontal: false

  signal clicked(var mouse)

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: config ? config.widgetSize : 50

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
      if (root.muted) return colors_ ? colors_.error : "#F2B8B5"
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
    text: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
    color: {
      if (root.active) return colors_ ? colors_.fgPrimary : "#0F3C2C"
      if (root.muted) return colors_ ? colors_.error : "#F2B8B5"
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
    onWheel: function(wheel) {
      var delta = wheel.angleDelta.y > 0 ? (config ? config.volumeStep : 5) / 100 : -(config ? config.volumeStep : 5) / 100
      root.setVolume(root.volume + delta)
    }
  }
}
