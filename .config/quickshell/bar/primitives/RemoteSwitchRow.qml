// bar/primitives/RemoteSwitchRow.qml
// ListItem + SwitchControl backed by a niri_config CLI field. Reads the
// current value once when the row becomes visible; every toggle writes
// through the CLI and reverts the control if the write fails.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."
import "../../config"

ListItem {
  id: root

  property string cliFile: ""       // "outputs" | "inputs" | "decorations"
  property string cliField: ""      // e.g. "touchpad-tap"
  property var extraArgs: []         // e.g. ["eDP-1"] for per-output fields
  property bool checked: false
  property bool live: true
  property string statusMessage: ""
  signal writeFailed(string message)

  height: 60
  Layout.fillWidth: true

  SwitchControl {
    checked: root.checked
    enabled: !writeProc.running
    activeColor: Colors.primary
    surfaceContainerHigh: Colors.surfaceContainerHigh
    surfaceContainerHighest: Colors.surfaceContainerHighest
    outline: Colors.styleOutlineStrong
    motionDuration: Config.motionMedium
    reducedMotion: Config.reducedMotion
    accessibleName: root.title
    onToggled: root.setValue(!root.checked)
  }

  Process {
    id: readProc
    running: false
    workingDirectory: Quickshell.env("HOME") + "/.config/quickshell"
    stdout: StdioCollector {
      onStreamFinished: {
        var v = text.trim().toLowerCase()
        if (v === "true" || v === "false") root.checked = (v === "true")
      }
    }
    stderr: StdioCollector { id: readError }
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) root.writeFailed(root.processError(readError.text, exitCode))
    }
  }

  Process {
    id: writeProc
    running: false
    workingDirectory: Quickshell.env("HOME") + "/.config/quickshell"
    property bool pendingValue: false
    stderr: StdioCollector { id: writeError }
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        root.checked = !writeProc.pendingValue
        root.statusMessage = root.processError(writeError.text, exitCode)
        root.writeFailed(root.statusMessage)
      }
    }
  }

  function processError(raw, exitCode) {
    var message = (raw || "").trim()
    return message !== "" ? message : "Niri config command failed (exit " + exitCode + ")"
  }

  function reload() {
    if (!root.live) return
    readProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "read", root.cliField].concat(root.extraArgs)
    readProc.running = false
    readProc.running = true
  }

  function setValue(value) {
    if (!root.live || writeProc.running) return
    readProc.running = false
    root.checked = value
    writeProc.pendingValue = value
    writeProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "write", root.cliField, value ? "true" : "false"].concat(root.extraArgs)
    writeProc.running = false
    writeProc.running = true
  }

  onLiveChanged: if (root.live) root.reload()
  Component.onCompleted: if (root.live) root.reload()
}
