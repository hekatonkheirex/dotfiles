pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

// Apple Calendar events from a public iCloud link, via scripts/ics_events.py.
// Fetches only while the agenda page is showing, for the month grid's range.
QtObject {
  id: root

  property bool active: false
  property string rangeStart: ""
  property string rangeEnd: ""
  property var events: []
  property string status: "loading"
  property string message: ""
  property bool refreshPending: false
  property int exitCode: -1

  onActiveChanged: if (root.active) root.refresh()
  onRangeStartChanged: if (root.active) debounce.restart()
  onRangeEndChanged: if (root.active) debounce.restart()

  function refresh() {
    if (!root.rangeStart || !root.rangeEnd) return
    if (proc.running) {
      root.refreshPending = true
      return
    }
    root.exitCode = -1
    proc.running = true
  }

  function applyOutput(output) {
    if (root.exitCode !== 0 && root.exitCode !== -1) return
    try {
      var info = JSON.parse(output)
      if (!info || typeof info !== "object" || Array.isArray(info)) throw new Error("Expected a JSON object")
      root.status = info.status
      root.message = info.message || ""
      root.events = info.events || []
    } catch (error) {
      root.status = "error"
      root.message = "Calendar script returned invalid JSON."
      print("CalendarService parse error:", error)
    }
  }

  property var proc: Process {
    command: [
      "python3",
      Quickshell.env("HOME") + "/.config/quickshell/scripts/ics_events.py",
      root.rangeStart,
      root.rangeEnd
    ]
    running: false
    onExited: function(code) {
      root.exitCode = code
      if (code !== 0) {
        root.status = "error"
        root.message = "Calendar script failed (exit code " + code + "). " + err.text.trim()
      }
      if (root.refreshPending) {
        root.refreshPending = false
        root.refresh()
      }
    }
    stdout: StdioCollector { onStreamFinished: root.applyOutput(text.trim()) }
    stderr: StdioCollector { id: err }
  }

  // Month arrows step fast; fetch once they stop.
  property var debounce: Timer {
    interval: 300
    onTriggered: root.refresh()
  }

  property var refreshTimer: Timer {
    interval: 15 * 60000
    running: root.active
    repeat: true
    onTriggered: root.refresh()
  }
}
