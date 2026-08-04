import QtQuick
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: Colors.primary
  accessibleName: "Audio"
  tooltipText: "Audio volume"

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
        if (data.indexOf("sink") >= 0) root.pollAudio()
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

  iconLabel: {
    if (root.muted) return "volume_off"
    if (root.volume <= 0) return "volume_mute"
    return "volume_up"
  }
  labelText: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
  iconColor: root.muted && !root.active ? Colors.error : (root.active ? Colors.fgPrimary : Colors.primary)
  labelColor: root.muted && !root.active ? Colors.error : (root.active ? Colors.fgPrimary : Colors.primary)

  onWheel: function(wheel) {
    var delta = wheel.angleDelta.y > 0 ? Config.volumeStep / 100 : -Config.volumeStep / 100
    root.setVolume(root.volume + delta)
  }
}
