import QtQuick
import QtQuick.Controls
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
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  anchors.fill: parent
  visible: root.currentTab === 11
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + shortcutsTab.neoShadowAllowance
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: shortcutsTab }
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
    implicitWidth: keyText.implicitWidth + Config.spacingLarge
    implicitHeight: 22
    radius: Config.shapeMedium
    color: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme
      ? Colors.styleControl
      : Colors.surfaceContainerHighest
    border.color: Colors.styleOutline
    border.width: Config.themeBorderWidth

    Text {
      id: keyText
      anchors.centerIn: parent
      text: parent.keys
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.textCaptionSize
      font.weight: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme ? Config.themeFontWeight : Font.Medium
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
    }

    KeyChip { keys: shortcutRow.keys }
  }

  component GroupCard: StyledSurface {
    id: groupCard
    variant: "filled"
    default property alias rows: rowsList.data
    property string title: ""
    Layout.fillWidth: true
    Layout.preferredHeight: rowsCol.implicitHeight + Config.spacingLarge * 2
    radius: Config.shapeLarge
    surfaceColor: Colors.surfaceContainer
    outlineColor: Colors.styleOutline
    outlineWidth: Config.themeBorderWidth

    ColumnLayout {
      id: rowsCol
      anchors.fill: parent
      anchors.margins: Config.spacingLarge
      spacing: Config.spacingCompact

      Text {
        text: groupCard.title
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.textCaptionSize
        font.weight: Font.Medium
      }

      ColumnLayout {
        id: rowsList
        Layout.fillWidth: true
        spacing: 0
      }
    }
  }

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, shortcutsTab.width - shortcutsTab.neoShadowAllowance - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge + shortcutsTab.neoShadowAllowance

    SettingsPageHeader {
      pageTitle: "Shortcuts"
      subtitle: "Curated common bindings. The source of truth is ~/.config/niri/keybinds.kdl."
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Config.spacingSmall + shortcutsTab.neoShadowAllowance

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: Config.themeLabeledActionButtonHeight
        iconLabel: "open_in_new"
        contentSpacing: Config.spacingMedium
        labelText: "Open Full Config"
        variant: "elevated"
        accessibleName: "Open full keybind configuration"
        onActivated: shortcutsTab.openKeybinds()
      }

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: Config.themeLabeledActionButtonHeight
        iconLabel: "content_copy"
        contentSpacing: Config.spacingMedium
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
      font.pixelSize: Config.typeBodySmallSize
      font.letterSpacing: Config.typeBodyTracking
      lineHeight: Config.typeBodySmallLineHeight
      lineHeightMode: Text.FixedHeight
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
