pragma Singleton
import QtQml
import Quickshell
import Quickshell.Io
import "MicState.js" as MicState

// Default-source mute state for the top-center microphone tab (her
// microphone.sh): one `pactl subscribe` reader, filtered to source events, runs
// while Settings.micIndicator is on. A change of default source posts a
// low-urgency "Recording device" notice. Every command goes through
// `commandFor`, so the render stage substitutes fixtures.
QtObject {
  id: root

  readonly property bool enabled: Settings.micIndicator
  property bool ready: false
  property bool muted: false
  property bool hidden: false         // middle click: until the mute state changes
  property string source: ""
  property string deviceName: ""
  property bool dirty: false

  property var commandFor: function(kind, args) {
    switch (kind) {
    case "source": return ["pactl", "get-default-source"]
    case "mute": return ["pactl", "get-source-mute", args.source]
    case "sources": return ["pactl", "list", "sources"]
    case "subscribe": return ["pactl", "subscribe"]
    case "toggle": return ["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"]
    case "notify": return ["notify-send", "-u", "low", "-a", "quickshell-mic", "Recording device", args.body]
    }
    return ["true"]
  }

  function toggle() { Quickshell.execDetached(root.commandFor("toggle", {})) }
  function hide() { root.hidden = true }

  // Coalesces bursts: one query chain at a time, one rerun when events arrived.
  function update() {
    if (!root.enabled) return
    if (sourceProc.running || muteProc.running || sourcesProc.running) { root.dirty = true; return }
    root.dirty = false
    sourceProc.command = root.commandFor("source", {})
    sourceProc.running = true
  }

  function finish() {
    if (root.dirty) root.update()
  }

  onEnabledChanged: {
    if (root.enabled) { root.update(); return }
    root.ready = false
    root.hidden = false
  }
  Component.onCompleted: root.update()

  property Process sourceProc: Process {
    stdout: StdioCollector {
      onStreamFinished: {
        var name = String(text).trim()
        if (name === "") { root.ready = false; root.finish(); return }
        var changed = root.source !== "" && root.source !== name
        root.source = name
        muteProc.command = root.commandFor("mute", { source: name })
        muteProc.running = true
        if (changed) {
          sourcesProc.command = root.commandFor("sources", {})
          sourcesProc.running = true
        }
      }
    }
  }

  property Process muteProc: Process {
    stdout: StdioCollector {
      onStreamFinished: {
        var m = MicState.parseMute(text)
        if (m === null) { root.ready = false } else {
          if (root.ready && m !== root.muted) root.hidden = false
          root.muted = m
          root.ready = true
        }
        root.finish()
      }
    }
  }

  property Process sourcesProc: Process {
    stdout: StdioCollector {
      onStreamFinished: {
        root.deviceName = MicState.parseDescription(text, root.source)
        if (root.deviceName !== "")
          Quickshell.execDetached(root.commandFor("notify", { body: root.deviceName }))
        root.finish()
      }
    }
  }

  property Process watcher: Process {
    command: root.commandFor("subscribe", {})
    running: root.enabled
    stdout: SplitParser {
      onRead: function(line) { if (MicState.isSourceEvent(line)) root.update() }
    }
    onRunningChanged: if (!running && root.enabled) retry.start()
  }

  property Timer retry: Timer {
    interval: 1000
    onTriggered: { if (root.enabled && !root.watcher.running) root.watcher.running = true }
  }
}
