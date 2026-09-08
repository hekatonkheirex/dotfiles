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
  property string leadingIcon: ""
  property bool live: true
  property string value: ""
  signal writeFailed(string message)

  Layout.fillWidth: true
  spacing: Config.spacingMedium

  Text {
    visible: root.leadingIcon !== ""
    text: root.leadingIcon
    color: Colors.fgSurfaceVariant
    font.family: Config.iconFont
    font.pixelSize: Config.iconSize
    font.variableAxes: Config.iconVariableAxes(0, Config.iconSize)
    Layout.preferredWidth: 20
  }

  Text {
    text: root.label
    color: Colors.fgSurfaceVariant
    font.family: Config.fontFamily
    font.pixelSize: Config.typeBodyMediumSize
    font.letterSpacing: Config.typeBodyTracking
    lineHeight: Config.typeBodyMediumLineHeight
    lineHeightMode: Text.FixedHeight
    Layout.preferredWidth: Math.max(Config.settingsRowLabelWidth, implicitWidth)
    Layout.minimumWidth: Math.max(Config.settingsRowLabelWidth, implicitWidth)
  }

  TextFieldControl {
    id: field
    Layout.fillWidth: true
    enabled: !writeProc.running
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
        root.value = v === "unset" ? "" : v
        field.text = root.value
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
    property string pendingValue: ""
    stderr: StdioCollector { id: writeError }
    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        root.value = writeProc.pendingValue
        field.text = writeProc.pendingValue
        root.writeFailed(root.processError(writeError.text, exitCode))
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

  function commit(newValue) {
    if (!root.live || writeProc.running) return
    if (newValue === root.value) return
    readProc.running = false
    writeProc.pendingValue = root.value
    root.value = newValue
    writeProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "write", root.cliField, newValue].concat(root.extraArgs)
    writeProc.running = false
    writeProc.running = true
  }

  onLiveChanged: if (root.live) root.reload()
  Component.onCompleted: if (root.live) root.reload()
}
