// bar/primitives/RemoteChoiceRow.qml
// Label + drop-down backed by a niri_config CLI field. Intended for string
// enums where only one option can be active at a time.
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
  property bool live: true
  property string value: ""
  signal writeFailed(string message)

  Layout.fillWidth: true
  spacing: Config.spacingMedium

  IconGlyph {
    visible: root.leadingIcon !== ""
    iconLabel: root.leadingIcon
    iconColor: Colors.fgSurfaceVariant
    iconSize: Config.iconSize
    Layout.preferredWidth: 20
    Layout.alignment: Qt.AlignTop
    Layout.topMargin: 6
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
    Layout.alignment: Qt.AlignTop
    Layout.topMargin: 7
  }

  // Drop-down: a field showing the current choice; the options open inline
  // below it (no popup window, so the sidebar's edges never clip them).
  ColumnLayout {
    id: choice
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.alignment: Qt.AlignTop
    spacing: 2
    property bool expanded: false
    readonly property string currentLabel: {
      for (var i = 0; i < root.options.length; i++)
        if (root.options[i].value === root.value) return root.options[i].label
      return root.value
    }

    Rectangle {
      id: field
      Layout.fillWidth: true
      Layout.preferredHeight: 32
      radius: Config.shapeMedium
      color: Colors.surface
      border.width: Config.themeBorderWidth
      border.color: choice.expanded || fieldMouse.containsMouse ? Colors.primary : Colors.outline
      enabled: !writeProc.running
      Accessible.role: Accessible.ComboBox
      Accessible.name: root.label
      Accessible.description: choice.currentLabel
      Accessible.focusable: true

      Text {
        anchors.left: parent.left
        anchors.right: chevron.left
        anchors.leftMargin: Config.spacingMedium
        anchors.verticalCenter: parent.verticalCenter
        text: choice.currentLabel
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeBodyMediumSize
        elide: Text.ElideRight
      }
      IconGlyph {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: Config.spacingSmall
        anchors.verticalCenter: parent.verticalCenter
        iconLabel: choice.expanded ? "expand_less" : "expand_more"
        iconColor: Colors.fgSurfaceVariant
        iconSize: Config.iconSize
      }
      MouseArea {
        id: fieldMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: choice.expanded = !choice.expanded
      }
    }

    Repeater {
      model: choice.expanded ? root.options : []

      delegate: ListItem {
        required property var modelData

        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.preferredHeight: 32
        title: modelData.label
        selected: root.value === modelData.value
        accessibleName: root.label + ": " + modelData.label
        accessibleDescription: selected ? "Selected" : "Select " + modelData.label
        onClicked: {
          choice.expanded = false
          root.commit(modelData.value)
        }
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
