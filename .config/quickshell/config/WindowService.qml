pragma Singleton
import QtQml
import Quickshell.Io
import "WindowState.js" as WindowState

// niri event-stream state for the elena dock. The stream always runs; when it
// ends, the state resets (so a stale "workspace empty" never shows the dock)
// and a retry restarts it after retryMs.
QtObject {
  id: root

  property var state: WindowState.empty()
  readonly property var windows: root.state.windows
  readonly property var focusedWindowId: root.state.focusedWindowId
  readonly property bool workspaceEmpty: WindowState.workspaceEmpty(root.state)

  property int retryMs: 1000
  // True between a stream ending and the retry firing. Part of the
  // Process.running binding so a restart never needs an imperative assignment
  // (which would break the binding for good).
  property bool backoff: false

  function feed(line) {
    var text = String(line).trim()
    if (text === "") return
    try {
      var next = WindowState.applyEvent(root.state, JSON.parse(text))
      if (next !== root.state) root.state = next
    } catch (e) {
      // One malformed line must not stop the stream.
    }
  }

  property Process stream: Process {
    command: ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) exec niri msg -j event-stream"]
    running: !root.backoff
    stdout: SplitParser {
      onRead: function(line) { root.feed(line) }
    }
    onRunningChanged: {
      if (running) return
      root.state = WindowState.empty()
      root.backoff = true
      retry.restart()
    }
  }

  property Timer retry: Timer {
    interval: root.retryMs
    repeat: false
    onTriggered: root.backoff = false
  }
}
