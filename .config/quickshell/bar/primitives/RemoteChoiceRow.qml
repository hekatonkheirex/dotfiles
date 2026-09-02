// bar/primitives/RemoteChoiceRow.qml
// Label + themed radio options backed by a niri_config CLI field. Intended for
// string enums where only one option can be active at a time.
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
  property var options: []
  property int optionColumns: 2
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
    Layout.alignment: Qt.AlignVCenter
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
    Layout.alignment: Qt.AlignVCenter
  }

  GridLayout {
    id: optionsGrid
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    columns: Math.max(1, Math.min(root.optionColumns, root.options.length || 1))
    columnSpacing: Config.themeOptionGap
    rowSpacing: Config.themeOptionGap

    Repeater {
      model: root.options

      delegate: ListItem {
        required property var modelData

        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredHeight: 44
        enabled: !writeProc.running
        leadingIcon: root.value === modelData.value
          ? "radio_button_checked"
          : "radio_button_unchecked"
        title: modelData.label
        selected: root.value === modelData.value
        accessibleName: root.label + ": " + modelData.label
        accessibleDescription: selected ? "Selected" : "Select " + modelData.label
        Accessible.role: Accessible.RadioButton
        Accessible.checkable: true
        Accessible.checked: selected
        Accessible.selectable: true
        Accessible.focusable: true
        Accessible.focused: activeFocus
        onClicked: root.commit(modelData.value)
      }
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
    readProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "read", root.cliField]
      .concat(root.extraArgs)
    readProc.running = false
    readProc.running = true
  }

  function commit(newValue) {
    if (!root.live || writeProc.running || newValue === root.value) return
    readProc.running = false
    writeProc.pendingValue = root.value
    root.value = newValue
    writeProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "write", root.cliField, newValue]
      .concat(root.extraArgs)
    writeProc.running = false
    writeProc.running = true
  }

  onLiveChanged: if (root.live) root.reload()
  Component.onCompleted: if (root.live) root.reload()
}
