import QtQuick
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: Config.nothingDesign ? Colors.fgSurface : Colors.brightness
  accessibleName: "Brightness"
  tooltipText: "Brightness"

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
      onRead: function(data) { root.fetchBrightness() }
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

  onVisibleChanged: {
    if (visible) root.fetchBrightness()
  }

  Component.onCompleted: {
    if (root.visible) root.fetchBrightness()
  }

  iconLabel: {
    if (!root.initialized) return "brightness_medium"
    if (root.pct <= 10) return "brightness_empty"
    if (root.pct <= 40) return "brightness_low"
    if (root.pct <= 70) return "brightness_medium"
    return "brightness_high"
  }
  labelText: root.initialized ? Math.round(root.pct) + "%" : ""

  onWheel: function(wheel) {
    var delta = wheel.angleDelta.y > 0 ? Config.brightnessStep : -Config.brightnessStep
    root.setBrightness(root.pct + delta)
  }
}
