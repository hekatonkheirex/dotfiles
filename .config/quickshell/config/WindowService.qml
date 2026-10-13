pragma Singleton
import QtQml
import Quickshell.Io
import "WindowState.js" as WindowState

// niri event-stream state for the elena dock. The stream runs only while the
// elena style is active; stopping it for any reason resets the state so a
// stale "workspace empty" can never show the dock under another style.
QtObject {
  id: root

  property var state: WindowState.empty()
  readonly property var windows: root.state.windows
  readonly property var focusedWindowId: root.state.focusedWindowId
  readonly property bool workspaceEmpty: WindowState.workspaceEmpty(root.state)
  readonly property bool running: Config.elenaTheme

  property int retryMs: 1000
  // True between a stream ending under elena and the retry firing. Part of the
  // Process.running binding so a restart never needs an imperative assignment
  // (which would break the elenaTheme binding for good).
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
    running: Config.elenaTheme && !root.backoff
    stdout: SplitParser {
      onRead: function(line) { root.feed(line) }
    }
    onRunningChanged: {
      if (running) return
      root.state = WindowState.empty()
      if (Config.elenaTheme) {
        root.backoff = true
        retry.restart()
      }
    }
  }

  property Timer retry: Timer {
    interval: root.retryMs
    repeat: false
    onTriggered: root.backoff = false
  }

  onRunningChanged: if (!running) { backoff = false; retry.stop() }
}
