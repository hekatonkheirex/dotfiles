pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "AudioLevel.js" as AudioLevel

// Audio level for the bar's signal wave. cava runs only while a player reports
// Playing and the bar asks for it; silence and idle both read as level 0.
QtObject {
  id: root

  // Set by the bar while a wave is on screen and motion is allowed.
  property bool wanted: false
  property real low: 0
  property real high: 0

  readonly property bool running: root.wanted && MediaService.status === "Playing"
  property bool processEnabled: true

  onRunningChanged: {
    if (!root.running) {
      root.low = 0
      root.high = 0
      retry.stop()
    }
  }

  property var cava: Process {
    command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/config/cava.ini"]
    running: root.running && root.processEnabled
    stdout: SplitParser {
      onRead: function(data) {
        var vals = AudioLevel.parse(data)
        if (vals.length === 0) return
        var b = AudioLevel.bands(vals)
        root.low = AudioLevel.follow(root.low, b.low)
        root.high = AudioLevel.follow(root.high, b.high)
      }
    }
    onRunningChanged: {
      if (!running && root.running) retry.start()
    }
  }

  property var retry: Timer {
    interval: 2000
    onTriggered: {
      if (!root.running) return
      root.processEnabled = false
      root.processEnabled = true
    }
  }
}
