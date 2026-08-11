import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../primitives"
import "../../config"

// Curated subset of ~/.config/niri/keybinds.kdl: the shell-integration and
// most-used binds. Not exhaustive — press Mod+Shift+Slash for niri's own
// full hotkey overlay.
Flickable {
  id: shortcutsTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 10
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  property string actionStatus: ""

  function openKeybinds() {
    Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/.config/niri/keybinds.kdl"])
    shortcutsTab.actionStatus = "Opened the full Niri keybind configuration"
  }

  function copyKeybinds() {
    Quickshell.execDetached(["sh", "-c",
      "if command -v wl-copy >/dev/null 2>&1 && [ -r \"$HOME/.config/niri/keybinds.kdl\" ]; then cat \"$HOME/.config/niri/keybinds.kdl\" | wl-copy; fi"])
    shortcutsTab.actionStatus = "Copied the full Niri keybind configuration"
  }

  component KeyChip: Rectangle {
    property string keys: ""
    implicitWidth: keyText.implicitWidth + 16
    implicitHeight: 22
    radius: Config.shapeMedium
    color: Colors.surfaceContainerHighest
    border.color: Colors.outlineVariant
    border.width: 1

    Text {
      id: keyText
      anchors.centerIn: parent
      text: parent.keys
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.textCaptionSize
      font.weight: Font.Medium
    }
  }

  component ShortcutRow: RowLayout {
    id: shortcutRow
    property string action: ""
    property string keys: ""
    Layout.fillWidth: true
    Layout.preferredHeight: 30
    spacing: Config.spacingSmall

    Text {
      text: shortcutRow.action
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.textBodyLargeSize
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
      anchors.margins: Config.spacingSmall
      spacing: 0

      Text {
        text: groupCard.title
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.textCaptionSize
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
    spacing: Config.spacingLarge

    Text {
      Layout.fillWidth: true
      text: "Curated common bindings. The source of truth is ~/.config/niri/keybinds.kdl."
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.fontPixelSize
      wrapMode: Text.WordWrap
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Config.spacingSmall

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        iconLabel: "open_in_new"
        labelText: "Open Full Config"
        accessibleName: "Open full keybind configuration"
        onActivated: shortcutsTab.openKeybinds()
      }

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        iconLabel: "content_copy"
        labelText: "Copy Keybinds"
        variant: "outlined"
        accessibleName: "Copy full keybind configuration"
        onActivated: shortcutsTab.copyKeybinds()
      }
    }

    Text {
      Layout.fillWidth: true
      text: shortcutsTab.actionStatus
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Math.max(8, Config.fontPixelSize - 1)
      visible: shortcutsTab.actionStatus !== ""
    }

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
