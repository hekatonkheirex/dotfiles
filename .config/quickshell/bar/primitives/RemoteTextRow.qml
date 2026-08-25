// bar/primitives/RemoteTextRow.qml
// Label + TextFieldControl backed by a niri_config CLI field, for string
// values (e.g. cursor theme name). Commits on Enter or on losing focus.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"

RowLayout {
  id: root

  property string cliFile: ""
  property string cliField: ""
  property var extraArgs: []
  property string label: ""
  property string value: ""
  signal writeFailed(string message)

  Layout.fillWidth: true
  spacing: Config.spacingMedium

  Text {
    text: root.label
    color: Colors.fgSurfaceVariant
    font.family: Config.fontFamily
    font.pixelSize: Config.textBodySize
    Layout.preferredWidth: 120
  }

  TextFieldControl {
    id: field
    Layout.fillWidth: true
    text: root.value
    accessibleName: root.label
    onAccepted: root.commit(text)
    input.onActiveFocusChanged: {
      if (!input.activeFocus) root.commit(field.text)
    }
  }

  Process {
    id: readProc
    running: false
    workingDirectory: Quickshell.env("HOME") + "/.config/quickshell"
    stdout: StdioCollector {
      onStreamFinished: {
        var v = text.trim()
        if (v !== "") { root.value = v; field.text = v }
      }
    }
  }

  Process {
    id: writeProc
    running: false
    workingDirectory: Quickshell.env("HOME") + "/.config/quickshell"
    property string pendingValue: ""
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "") {
          root.value = writeProc.pendingValue
          field.text = writeProc.pendingValue
          root.writeFailed(text.trim())
        }
      }
    }
  }

  function reload() {
    readProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "read", root.cliField].concat(root.extraArgs)
    readProc.running = false
    readProc.running = true
  }

  function commit(newValue) {
    if (newValue === root.value) return
    writeProc.pendingValue = root.value
    root.value = newValue
    writeProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "write", root.cliField, newValue].concat(root.extraArgs)
    writeProc.running = false
    writeProc.running = true
  }

  Component.onCompleted: root.reload()
}
