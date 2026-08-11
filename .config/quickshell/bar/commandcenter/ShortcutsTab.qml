import QtQuick
import QtQuick.Layouts
import "../"
import "../../config"

// Curated subset of ~/.config/niri/keybinds.kdl: the shell-integration and
// most-used binds. Not exhaustive — press Mod+Shift+Slash for niri's own
// full hotkey overlay.
Flickable {
  id: shortcutsTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 7
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  component KeyChip: Rectangle {
    property string keys: ""
    implicitWidth: keyText.implicitWidth + 16
    implicitHeight: 22
    radius: 8
    color: Colors.surfaceContainerHighest
    border.color: Colors.outlineVariant
    border.width: 1

    Text {
      id: keyText
      anchors.centerIn: parent
      text: parent.keys
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: 11
      font.weight: Font.Medium
    }
  }

  component ShortcutRow: RowLayout {
    id: shortcutRow
    property string action: ""
    property string keys: ""
    Layout.fillWidth: true
    Layout.preferredHeight: 30
    spacing: 8

    Text {
      text: shortcutRow.action
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: 13
      Layout.fillWidth: true
      Layout.leftMargin: 8
    }

    KeyChip { keys: shortcutRow.keys; Layout.rightMargin: 8 }
  }

  component GroupCard: Rectangle {
    id: groupCard
    default property alias rows: rowsCol.data
    property string title: ""
    Layout.fillWidth: true
    Layout.preferredHeight: rowsCol.implicitHeight + 16
    radius: Config.shapeLarge
    color: Colors.surfaceContainer
    border.color: Colors.outlineVariant
    border.width: 1

    ColumnLayout {
      id: rowsCol
      anchors.fill: parent
      anchors.margins: 8
      spacing: 0

      Text {
        text: groupCard.title
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
        Layout.leftMargin: 8
        Layout.topMargin: 4
        Layout.bottomMargin: 4
      }
    }
  }

  ColumnLayout {
    id: mainColumn
    width: shortcutsTab.width
    spacing: 16

    GroupCard {
      title: "Apps"
      ShortcutRow { action: "Terminal"; keys: "Mod + Return" }
      ShortcutRow { action: "Launcher"; keys: "Mod + D" }
      ShortcutRow { action: "Lock Screen"; keys: "Mod + Alt + L" }
      ShortcutRow { action: "Browser"; keys: "Mod + B" }
      ShortcutRow { action: "File Manager"; keys: "Mod + T" }
      ShortcutRow { action: "Quick Settings"; keys: "Mod + Escape" }
    }

    GroupCard {
      title: "Windows"
      ShortcutRow { action: "Close window"; keys: "Mod + W" }
      ShortcutRow { action: "Fullscreen"; keys: "Mod + Shift + F" }
      ShortcutRow { action: "Toggle floating"; keys: "Mod + V" }
      ShortcutRow { action: "Focus left / down / up / right"; keys: "Mod + H J K L" }
      ShortcutRow { action: "Move column"; keys: "Mod + Ctrl + H J K L" }
    }

    GroupCard {
      title: "Workspaces"
      ShortcutRow { action: "Switch workspace"; keys: "Mod + 1-9" }
      ShortcutRow { action: "Workspace up / down"; keys: "Mod + Page Up/Down" }
      ShortcutRow { action: "Move column to workspace"; keys: "Mod + Shift + 1-9" }
    }

    GroupCard {
      title: "System"
      ShortcutRow { action: "Show all niri shortcuts"; keys: "Mod + Shift + /" }
      ShortcutRow { action: "Screenshot"; keys: "Print" }
      ShortcutRow { action: "Power off monitors"; keys: "Mod + Shift + P" }
      ShortcutRow { action: "Quit niri"; keys: "Mod + Shift + E" }
    }
  }
}
