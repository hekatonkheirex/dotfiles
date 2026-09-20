pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property real volume: 0.5
  property bool muted: false
  property real micVolume: 0.5
  property bool micMuted: false
  property bool indicatorActive: false
  property bool popupActive: false
  property bool watcherEnabled: true

  readonly property bool sinkActive: indicatorActive || popupActive
  readonly property bool micActive: popupActive

  function pollSink() {
    if (!root.sinkActive) return
    sinkQuery.running = false
    sinkQuery.running = true
  }

  function pollMic() {
    if (!root.micActive) return
    micQuery.running = false
    micQuery.running = true
  }

  function poll() {
    root.pollSink()
    root.pollMic()
  }

  function setVolume(value) {
    root.volume = Math.max(0, Math.min(1, value))
    Quickshell.execDetached([
      "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(root.volume)
    ])
  }

  function toggleMute() {
    root.muted = !root.muted
    Quickshell.execDetached([
      "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root.muted ? "1" : "0"
    ])
  }

  function setMicVolume(value) {
    root.micVolume = Math.max(0, Math.min(1, value))
    Quickshell.execDetached([
      "wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", String(root.micVolume)
    ])
  }

  function toggleMicMute() {
    root.micMuted = !root.micMuted
    Quickshell.execDetached([
      "wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", root.micMuted ? "1" : "0"
    ])
  }

  function restartWatcher() {
    if (!root.sinkActive) return
    root.watcherEnabled = false
    root.watcherEnabled = true
  }

  onSinkActiveChanged: {
    if (root.sinkActive) root.pollSink()
    else watcherRetry.stop()
  }

  onMicActiveChanged: {
    if (root.micActive) root.pollMic()
  }

  property var sinkQuery: Process {
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var output = text.trim()
        var match = /Volume:\s*([\d.]+)/.exec(output)
        if (match) root.volume = parseFloat(match[1])
        root.muted = output.indexOf("[MUTED]") >= 0
      }
    }
  }

  property var micQuery: Process {
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var output = text.trim()
        var match = /Volume:\s*([\d.]+)/.exec(output)
        if (match) root.micVolume = parseFloat(match[1])
        root.micMuted = output.indexOf("[MUTED]") >= 0
      }
    }
  }

  property var watcher: Process {
    command: ["pactl", "subscribe"]
    running: root.sinkActive && root.watcherEnabled
    stdout: SplitParser {
      onRead: function(data) {
        if (data.indexOf("sink") >= 0 || data.indexOf("source") >= 0) root.poll()
      }
    }
    onRunningChanged: {
      if (!running && root.sinkActive && root.watcherEnabled) watcherRetry.start()
    }
  }

  property var watcherRetry: Timer {
    interval: 1000
    onTriggered: root.restartWatcher()
  }
}
