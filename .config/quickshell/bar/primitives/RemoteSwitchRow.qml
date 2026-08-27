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
  }

  Process {
    id: writeProc
    running: false
    workingDirectory: Quickshell.env("HOME") + "/.config/quickshell"
    property bool pendingValue: false
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "") {
          root.checked = !writeProc.pendingValue
          root.statusMessage = text.trim()
          root.writeFailed(text.trim())
        }
      }
    }
  }

  function reload() {
    if (!root.live) return
    readProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "read", root.cliField].concat(root.extraArgs)
    readProc.running = false
    readProc.running = true
  }

  function setValue(value) {
    if (!root.live) return
    root.checked = value
    writeProc.pendingValue = value
    writeProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "write", root.cliField, value ? "true" : "false"].concat(root.extraArgs)
    writeProc.running = false
    writeProc.running = true
  }

  onLiveChanged: if (root.live) root.reload()
  Component.onCompleted: if (root.live) root.reload()
}
