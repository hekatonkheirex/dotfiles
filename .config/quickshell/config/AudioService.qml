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
  property real observedVolume: 0.5
  property bool observedMuted: false
  property real observedMicVolume: 0.5
  property bool observedMicMuted: false
  property bool indicatorActive: false
  property bool popupActive: false
  property bool watcherEnabled: true

  readonly property bool sinkActive: indicatorActive || popupActive
  readonly property bool micActive: popupActive

  function pollSink() {
    if (!root.sinkActive || sinkControl.running || sinkVolumePending || sinkMutePending || sinkQuery.running) return
    root.sinkQueryEpoch++
    sinkQuery.running = true
  }

  function pollMic() {
    if (!root.micActive || micControl.running || micVolumePending || micMutePending || micQuery.running) return
    root.micQueryEpoch++
    micQuery.running = true
  }

  function poll() {
    root.pollSink()
    root.pollMic()
  }

  function runSinkControl() {
    if (sinkControl.running) return
    if (sinkVolumePending) {
      sinkVolumePending = false
      sinkControl.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(root.volume)]
    } else if (sinkMutePending) {
      sinkMutePending = false
      sinkControl.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root.muted ? "1" : "0"]
    } else {
      root.pollSink()
      return
    }
    root.sinkQueryEpoch++
    sinkControl.running = true
  }

  function runMicControl() {
    if (micControl.running) return
    if (micVolumePending) {
      micVolumePending = false
      micControl.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", String(root.micVolume)]
    } else if (micMutePending) {
      micMutePending = false
      micControl.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", root.micMuted ? "1" : "0"]
    } else {
      root.pollMic()
      return
    }
    root.micQueryEpoch++
    micControl.running = true
  }

  function setVolume(value) {
    root.volume = Math.max(0, Math.min(1, value))
    sinkVolumePending = true
    root.runSinkControl()
  }

  function toggleMute() {
    root.muted = !root.muted
    sinkMutePending = true
    root.runSinkControl()
  }

  function setMicVolume(value) {
    root.micVolume = Math.max(0, Math.min(1, value))
    micVolumePending = true
    root.runMicControl()
  }

  function toggleMicMute() {
    root.micMuted = !root.micMuted
    micMutePending = true
    root.runMicControl()
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

  property bool sinkVolumePending: false
  property bool sinkMutePending: false
  property bool micVolumePending: false
  property bool micMutePending: false
  property int sinkQueryEpoch: 0
  property int micQueryEpoch: 0
  property var sinkControl: Process {
    command: []
    running: false
    onExited: root.runSinkControl()
  }
  property var micControl: Process {
    command: []
    running: false
    onExited: root.runMicControl()
  }

  property var sinkQuery: Process {
    property int epoch: 0
    onRunningChanged: {
      if (running) epoch = root.sinkQueryEpoch
      else if (epoch !== root.sinkQueryEpoch) root.pollSink()
    }
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        if (sinkQuery.epoch !== root.sinkQueryEpoch || sinkControl.running || sinkVolumePending || sinkMutePending) return
        var output = text.trim()
        var match = /Volume:\s*([\d.]+)/.exec(output)
        if (match) {
          root.observedVolume = root.volume = parseFloat(match[1])
          root.observedMuted = root.muted = output.indexOf("[MUTED]") >= 0
        }
      }
    }
  }

  property var micQuery: Process {
    property int epoch: 0
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
    running: false
    onRunningChanged: {
      if (running) epoch = root.micQueryEpoch
      else if (epoch !== root.micQueryEpoch) root.pollMic()
    }
    stdout: StdioCollector {
      onStreamFinished: {
        if (micQuery.epoch !== root.micQueryEpoch || micControl.running || micVolumePending || micMutePending) return
        var output = text.trim()
        var match = /Volume:\s*([\d.]+)/.exec(output)
        if (match) {
          root.observedMicVolume = root.micVolume = parseFloat(match[1])
          root.observedMicMuted = root.micMuted = output.indexOf("[MUTED]") >= 0
        }
      }
    }
  }

  property var watcher: Process {
    command: ["pactl", "subscribe"]
    running: root.sinkActive && root.watcherEnabled
    stdout: SplitParser {
      onRead: function(data) {
        if ((data.indexOf("sink") >= 0 || data.indexOf("source") >= 0) &&
            (!sinkQuery.running || !micQuery.running)) root.poll()
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

