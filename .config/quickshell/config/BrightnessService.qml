pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property real pct: 0
  property bool initialized: false
  property bool indicatorActive: false
  property bool popupActive: false
  property bool watcherEnabled: true

  readonly property bool active: indicatorActive || popupActive

  function poll() {
    if (!root.active) return
    query.running = false
    query.running = true
  }

  function setBrightness(value) {
    root.pct = Math.max(0, Math.min(100, value))
    Quickshell.execDetached([
      "brightnessctl", "set", Math.round(root.pct) + "%"
    ])
  }

  function restartWatcher() {
    if (!root.active) return
    root.watcherEnabled = false
    root.watcherEnabled = true
  }

  onActiveChanged: {
    if (root.active) root.poll()
    else watcherRetry.stop()
  }

  property var query: Process {
    command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var value = parseFloat(text.trim())
        if (!isNaN(value)) {
          root.pct = value
          root.initialized = true
        }
      }
    }
  }

  property var watcher: Process {
    command: ["sh", "-c", "inotifywait -m -e modify /sys/class/backlight/*/brightness"]
    running: root.active && root.watcherEnabled
    stdout: SplitParser {
      onRead: function(data) { root.poll() }
    }
    onRunningChanged: {
      if (!running && root.active && root.watcherEnabled) watcherRetry.start()
    }
  }

  property var watcherRetry: Timer {
    interval: 1000
    onTriggered: root.restartWatcher()
  }
}
