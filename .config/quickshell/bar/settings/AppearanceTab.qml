import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../primitives"
import "../../config"
import "../../config/PaletteCatalog.js" as PaletteCatalog

Flickable {
  id: appearanceTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  readonly property int optionButtonGap: Config.themeOptionGap
  readonly property int segmentedButtonGap: 0
  // Stacked icon + label choices keep breathing room at the global type scale.
  readonly property int optionButtonHeight: Math.max(Config.controlHeight, Config.typeLabelMediumLineHeight + (14))
  anchors.fill: parent
  visible: root.currentTab === 1
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: appearanceTab }

  property string themeStatus: ""
  property bool resetConfirm: false
  property string wmStatusMessage: ""
  property bool paletteSyncPending: false
  property bool paletteSyncQueued: false
  function onWmFieldFailed(message) {
    wmStatusMessage = message
  }

  function themeModeName() {
    return Settings.themePreference === 1 ? "light"
      : (Settings.themePreference === 2 ? "dark" : "auto")
  }

  function normalizeFixedPaletteSelection() {
    if (Settings.colorSource !== "fixed" || Settings.colorPalette !== "material3") return
    Settings.colorPalette = "catppuccin"
    Settings.colorVariant = "auto"
    Settings.save()
  }

  Component.onCompleted: appearanceTab.normalizeFixedPaletteSelection()

  function requestPaletteSync() {
    appearanceTab.paletteSyncPending = true
    appearanceTab.themeStatus = Settings.colorSource === "fixed"
      ? "Rendering fixed palette..."
      : "Reloading colors..."

    if (Settings.colorSource === "fixed") {
      if (!Colors.writeFixedMatugenPalette()) {
        appearanceTab.paletteSyncPending = false
        appearanceTab.themeStatus = "Fixed palette unavailable"
      }
      return
    }

    appearanceTab.startPaletteSync()
  }

  function startPaletteSync() {
    appearanceTab.paletteSyncPending = false
    if (reloadThemeProc.running) {
      // Keep the current generator alive. A variant can be changed while the
      // external theme outputs are rebuilding; queue one follow-up run so the
      // latest cache wins without exposing the cancelled process' exit code.
      appearanceTab.paletteSyncQueued = true
      return
    }
    reloadThemeProc.running = true
  }

  function reloadTheme() {
    appearanceTab.requestPaletteSync()
  }

  Connections {
    target: Colors

    function onFixedPaletteSaved() {
      if (appearanceTab.paletteSyncPending) appearanceTab.startPaletteSync()
    }

    function onFixedPaletteSaveFailed(error) {
      if (!appearanceTab.paletteSyncPending) return
      appearanceTab.paletteSyncPending = false
      appearanceTab.themeStatus = "Fixed palette could not be saved"
    }
  }

  Connections {
    target: Settings
    function onColorSourceChanged() { appearanceTab.normalizeFixedPaletteSelection() }
    function onColorPaletteChanged() { appearanceTab.normalizeFixedPaletteSelection() }
  }

  Process {
    id: reloadThemeProc
    command: [
      Quickshell.env("HOME") + "/.config/quickshell/scripts/sync-active-palette.sh",
      "--source",
      Settings.colorSource,
      "--accent",
      Settings.accentPalette,
      Settings.accentActive,
      appearanceTab.themeModeName()
    ]
    running: false
    onExited: (exitCode) => {
      if (appearanceTab.paletteSyncQueued) {
        appearanceTab.paletteSyncQueued = false
        reloadThemeProc.running = true
        return
      }
      Colors.reloadMatugenPalette()
      appearanceTab.themeStatus = exitCode === 0
        ? "Colors synchronized"
        : (exitCode === 2
          ? "Colors applied; desktop refresh incomplete"
          : "Color synchronization failed")
    }
  }

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, appearanceTab.width - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge

    SettingsPageHeader {
      pageTitle: "Appearance"
      subtitle: "Customize wallpapers, colors, and effects."
    }

    ColumnLayout {
      id: appearanceCardsColumn
      Layout.fillWidth: true
      spacing: Config.spacingLarge

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingCompact

        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingMedium

          Text {
            Layout.fillWidth: true
            text: "General UI"
            color: Colors.primary
            font.family: Config.fontFamily
            font.pixelSize: Config.typeTitleLargeSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeTitleTracking
            lineHeight: Config.typeTitleLargeLineHeight
            lineHeightMode: Text.FixedHeight
          }

          ActionButton {
            id: resetAppearanceButton
            Layout.preferredWidth: appearanceTab.compactLayout ? 40 : 112
            Layout.preferredHeight: Config.themeLabeledActionButtonHeight
            iconLabel: appearanceTab.resetConfirm ? "warning" : "settings_backup_restore"
            iconSize: Config.iconSize - 2
            contentSpacing: Config.spacingSmall
            labelText: appearanceTab.compactLayout
              ? ""
              : (appearanceTab.resetConfirm ? "Confirm" : "Reset")
            variant: appearanceTab.resetConfirm ? "filled" : "outlined"
            accessibleName: appearanceTab.resetConfirm
              ? "Confirm appearance reset"
              : "Reset appearance"
            accessibleDescription: appearanceTab.resetConfirm
              ? "Restore default appearance settings"
              : "Show confirmation before restoring default appearance settings"
            tooltipText: appearanceTab.resetConfirm ? "Confirm reset" : "Reset appearance"
            onActivated: {
              if (appearanceTab.resetConfirm) {
                if (appearanceTab.root) appearanceTab.root.resetAppearance()
                appearanceTab.resetConfirm = false
              } else {
                appearanceTab.resetConfirm = true
              }
            }
          }

          ActionButton {
            Layout.preferredWidth: appearanceTab.compactLayout ? 40 : 88
            Layout.preferredHeight: Config.themeLabeledActionButtonHeight
            iconLabel: "close"
            iconSize: Config.iconSize - 2
            contentSpacing: Config.spacingSmall
            labelText: appearanceTab.compactLayout ? "" : "Cancel"
            variant: "text"
            visible: appearanceTab.resetConfirm
            accessibleName: "Cancel appearance reset"
            accessibleDescription: "Keep the current appearance settings"
            tooltipText: "Cancel reset"
            onActivated: appearanceTab.resetConfirm = false
          }
        }

      }

      // Wallpaper card: the picker itself is the full-width filmstrip.
      SettingsCard {
        variant: "filled"
        Layout.fillWidth: true
        Layout.preferredHeight: wallpaperRow.implicitHeight + Config.spacingExtraLarge * 2
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.outlineVariant
        outlineWidth: Config.themeBorderWidth

        RowLayout {
          id: wallpaperRow
          anchors.fill: parent
          anchors.margins: Config.spacingExtraLarge
          spacing: Config.spacingMedium

          ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: Config.spacingCompact

            Text {
              text: "Wallpaper"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeTitleLargeSize
              font.weight: Config.typeStrongWeight
              font.letterSpacing: Config.typeTitleTracking
              lineHeight: Config.typeTitleLargeLineHeight
              lineHeightMode: Text.FixedHeight
            }

            Text {
              text: "Browse with the filmstrip (also: type @ in the launcher), or apply a random one."
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
            }
          }

          ActionButton {
            Layout.preferredWidth: appearanceTab.compactLayout ? 40 : 112
            Layout.preferredHeight: Config.themeLabeledActionButtonHeight
            iconLabel: "wallpaper"
            iconSize: Config.iconSize - 2
            contentSpacing: Config.spacingSmall
            labelText: appearanceTab.compactLayout ? "" : "Choose"
            variant: "filled"
            accessibleName: "Choose wallpaper"
            accessibleDescription: "Open the wallpaper filmstrip"
            tooltipText: "Choose wallpaper"
            onActivated: Quickshell.execDetached(["qs", "ipc", "call", "shell", "wallpapers"])
          }

          ActionButton {
            Layout.preferredWidth: appearanceTab.compactLayout ? 40 : 112
            Layout.preferredHeight: Config.themeLabeledActionButtonHeight
            iconLabel: "shuffle"
            iconSize: Config.iconSize - 2
            contentSpacing: Config.spacingSmall
            labelText: appearanceTab.compactLayout ? "" : "Random"
            variant: "outlined"
            accessibleName: "Random wallpaper"
            accessibleDescription: "Apply a random wallpaper"
            tooltipText: "Random wallpaper"
            onActivated: Quickshell.execDetached(["qs", "ipc", "call", "shell", "randomWallpaper"])
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingCompact

        Text {
          text: "Color & Theme"
          color: Colors.primary
          font.family: Config.fontFamily
          font.pixelSize: Config.typeTitleLargeSize
          font.weight: Config.typeMediumWeight
          font.letterSpacing: Config.typeTitleTracking
          lineHeight: Config.typeTitleLargeLineHeight
          lineHeightMode: Text.FixedHeight
        }

        Text {
          Layout.fillWidth: true
          text: "Choose the source, palette, and contrast for the shell"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelSmallSize
          font.letterSpacing: Config.typeLabelTracking
          lineHeight: Config.typeLabelSmallLineHeight
          lineHeightMode: Text.FixedHeight
          wrapMode: Text.WordWrap
        }
      }

      // Color scheme card
      SettingsCard {
        id: colorSchemeCard
        variant: "filled"
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(184, colorSchemeColumn.implicitHeight + Config.spacingLarge * 2)
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.outlineVariant
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: colorSchemeColumn
          anchors.fill: parent
          anchors.margins: Config.spacingLarge
          spacing: Config.spacingSmall

          Text {
            text: "Color"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyLargeSize
            font.weight: Config.typeStrongWeight
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyLargeLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.alignment: Qt.AlignHCenter
          }

          Text {
            text: "Color source"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.fillWidth: true
          }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: appearanceTab.optionButtonHeight
            height: appearanceTab.optionButtonHeight

            Row {
              anchors.fill: parent
              spacing: appearanceTab.segmentedButtonGap

              Repeater {
                model: PaletteCatalog.sourceOptions()

                delegate: ActionButton {
                  required property var modelData
                  required property int index
                  width: (parent.width - appearanceTab.segmentedButtonGap) / 2
                  height: parent.height
                  iconLabel: modelData.icon
                  iconSize: 15
                  contentSpacing: Config.spacingSmall
                  horizontalContent: false
                  labelText: modelData.label
                  selected: Settings.colorSource === modelData.value
                  enabled: true
                  checkable: true
                  grouped: true
                  groupPosition: index === 0 ? "first" : "last"
                  accessibleName: modelData.label + " color source"
                  accessibleDescription: modelData.description
                  onActivated: {
                    Settings.colorSource = modelData.value
                    if (modelData.value === "fixed" && Settings.colorPalette === "material3") {
                      Settings.colorPalette = "catppuccin"
                      Settings.colorVariant = "auto"
                    }
                    Settings.save()
                    appearanceTab.requestPaletteSync()
                  }
                }
              }
            }
          }

          Text {
            text: "Color mode"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.fillWidth: true
          }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: appearanceTab.optionButtonHeight
            height: appearanceTab.optionButtonHeight

            Row {
              anchors.fill: parent
              spacing: appearanceTab.segmentedButtonGap

              Repeater {
                model: [
                  { value: 0, icon: "brightness_auto", label: "Auto" },
                  { value: 1, icon: "light_mode", label: "Light" },
                  { value: 2, icon: "dark_mode", label: "Dark" }
                ]

                delegate: ActionButton {
                  required property var modelData
                  required property int index
                  width: (parent.width - appearanceTab.segmentedButtonGap * 2) / 3
                  height: parent.height
                  iconLabel: modelData.icon
                  iconSize: 15
                  contentSpacing: Config.spacingSmall
                  horizontalContent: false
                  labelText: modelData.label
                  selected: Settings.themePreference === modelData.value
                  checkable: true
                  grouped: true
                  groupPosition: index === 0 ? "first" : (index === 2 ? "last" : "middle")
                  accessibleName: modelData.label + " color mode"
                  onActivated: {
                    Settings.themePreference = modelData.value
                    Settings.save()
                  }
                }
              }
            }
          }

          Text {
            text: "Palette family"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            visible: Colors.fixedPaletteActive
            Layout.fillWidth: true
          }

          GridLayout {
            visible: Colors.fixedPaletteActive
            Layout.fillWidth: true
            columns: 2
            columnSpacing: appearanceTab.optionButtonGap
            rowSpacing: appearanceTab.optionButtonGap

            Repeater {
              model: PaletteCatalog.fixedFamilyOptions()

              delegate: ActionButton {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: appearanceTab.optionButtonHeight
                iconLabel: modelData.icon
                iconSize: 15
                contentSpacing: Config.spacingSmall
                horizontalContent: false
                labelText: modelData.label
                selected: Settings.colorPalette === modelData.value
                checkable: true
                grouped: true
                accessibleName: modelData.label + " palette"
                accessibleDescription: selected ? "Selected" : "Use the " + modelData.label + " palette"
                onActivated: {
                  Settings.colorPalette = modelData.value
                  Settings.colorVariant = "auto"
                  Settings.save()
                  appearanceTab.requestPaletteSync()
                }
              }
            }
          }

          Text {
            text: "Palette variant"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            visible: Colors.fixedPaletteActive
            Layout.fillWidth: true
          }

          GridLayout {
            id: paletteVariantGrid
            visible: Colors.fixedPaletteActive
            Layout.fillWidth: true
            columns: 2
            columnSpacing: appearanceTab.optionButtonGap
            rowSpacing: appearanceTab.optionButtonGap

            Repeater {
              id: paletteVariantRepeater
              model: PaletteCatalog.variantOptions(Settings.colorPalette)

              delegate: ActionButton {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: appearanceTab.optionButtonHeight
                iconLabel: modelData.icon
                iconSize: 15
                contentSpacing: Config.spacingSmall
                horizontalContent: false
                labelText: modelData.label
                selected: Settings.colorVariant === modelData.value
                checkable: true
                grouped: true
                accessibleName: modelData.label + " " + PaletteCatalog.familyLabel(Settings.colorPalette) + " variant"
                accessibleDescription: selected ? "Selected" : "Use the " + modelData.label + " variant"
                onActivated: {
                  Settings.colorVariant = modelData.value
                  Settings.save()
                  appearanceTab.requestPaletteSync()
                }
              }
            }
          }

          Text {
            text: "Contrast"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.fillWidth: true
          }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: appearanceTab.optionButtonHeight
            height: appearanceTab.optionButtonHeight

            Row {
              anchors.fill: parent
              spacing: appearanceTab.segmentedButtonGap

              Repeater {
                model: PaletteCatalog.contrastOptions()

                delegate: ActionButton {
                  required property var modelData
                  required property int index
                  width: (parent.width - appearanceTab.segmentedButtonGap * 2) / 3
                  height: parent.height
                  iconLabel: modelData.icon
                  iconSize: 15
                  contentSpacing: Config.spacingSmall
                  horizontalContent: false
                  labelText: modelData.label
                  selected: Settings.colorContrast === modelData.value
                  checkable: true
                  grouped: true
                  groupPosition: index === 0 ? "first" : (index === 2 ? "last" : "middle")
                  accessibleName: modelData.label + " contrast"
                  accessibleDescription: "Use " + modelData.label.toLowerCase() + " color contrast"
                  onActivated: {
                    Settings.colorContrast = modelData.value
                    Settings.save()
                    if (Settings.colorSource === "fixed") appearanceTab.requestPaletteSync()
                  }
                }
              }
            }
          }

          Text {
            text: Colors.paletteSource
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          ActionButton {
            Layout.preferredWidth: 140
            Layout.preferredHeight: Config.themeLabeledActionButtonHeight
            Layout.alignment: Qt.AlignHCenter
            enabled: !reloadThemeProc.running
            radius: height / 2
            iconLabel: "sync"
            iconSize: Config.iconSize - 2
            contentSpacing: Config.spacingMedium
            labelText: "Reload colors"
            variant: "elevated"
            accessibleName: "Reload colors"
            accessibleDescription: "Synchronize GTK, Qt, terminal, and Niri theme outputs"
            onActivated: appearanceTab.reloadTheme()
          }

          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Config.spacingSmall
            visible: appearanceTab.themeStatus !== ""

            LoadingIndicator {
              visible: reloadThemeProc.running
              size: Config.iconSizeSmall
              running: reloadThemeProc.running
              indicatorColor: Colors.primary
              accessibleName: "Reloading colors"
              Layout.preferredWidth: reloadThemeProc.running ? Config.iconSizeSmall : 0
              Layout.preferredHeight: Config.iconSizeSmall
            }

            Text {
              text: appearanceTab.themeStatus
              color: appearanceTab.themeStatus.indexOf("failed") >= 0 ? Colors.error : Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodySmallSize
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodySmallLineHeight
              lineHeightMode: Text.FixedHeight
            }
          }
        }
      }

    }

    ColumnLayout {
      visible: Config.isNiri
      Layout.fillWidth: true
      spacing: Config.spacingCompact

      Text {
        text: "Window Manager"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeTitleLargeSize
        font.weight: Config.typeStrongWeight
        font.letterSpacing: Config.typeTitleTracking
        lineHeight: Config.typeTitleLargeLineHeight
        lineHeightMode: Text.FixedHeight
      }

      Text {
        Layout.fillWidth: true
        text: "Control Niri decorations, effects, and pointer behavior"
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelSmallSize
        font.letterSpacing: Config.typeLabelTracking
        lineHeight: Config.typeLabelSmallLineHeight
        lineHeightMode: Text.FixedHeight
        wrapMode: Text.WordWrap
      }
    }

    SettingsCard {
      visible: Config.isMango
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: mangoWmNoteText.implicitHeight + Config.spacingMedium * 2
      radius: Config.settingsCardRadius
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.outlineVariant
      outlineWidth: Config.themeBorderWidth

      Text {
        id: mangoWmNoteText
        anchors.fill: parent
        anchors.margins: Config.spacingMedium
        text: "Mango decoration and animation settings are managed in ~/.config/mango/*.conf. Mod + Shift + Alt + R reloads the compositor after an edit."
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeBodySmallSize
        font.letterSpacing: Config.typeBodyTracking
        lineHeight: Config.typeBodySmallLineHeight
        lineHeightMode: Text.FixedHeight
        wrapMode: Text.WordWrap
      }
    }

    // Niri window manager (gaps, animations, blur, cursor)
    SettingsCard {
      visible: Config.isNiri
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: wmColumn.implicitHeight + Config.spacingMedium * 2
      radius: Config.settingsCardRadius
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.outlineVariant
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: wmColumn
        anchors.fill: parent
        anchors.margins: Config.spacingMedium
        spacing: Config.spacingSmall

        Text {
          text: "Niri decorations"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodyLargeSize
          font.weight: Config.typeStrongWeight
          font.letterSpacing: Config.typeBodyTracking
          lineHeight: Config.typeBodyLargeLineHeight
          lineHeightMode: Text.FixedHeight
        }

        RemoteSliderRow {
          Layout.fillWidth: true
          live: appearanceTab.visible && appearanceTab.root && appearanceTab.root.visible
          cliFile: "decorations"; cliField: "gaps"
          label: "Gaps"; min: 0; max: 32; unit: "px"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          live: appearanceTab.visible && appearanceTab.root && appearanceTab.root.visible
          cliFile: "decorations"; cliField: "focus-ring-enabled"
          leadingIcon: "crop_free"; title: "Focus ring"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          live: appearanceTab.visible && appearanceTab.root && appearanceTab.root.visible
          cliFile: "decorations"; cliField: "border-enabled"
          leadingIcon: "crop_din"; title: "Window border"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          live: appearanceTab.visible && appearanceTab.root && appearanceTab.root.visible
          cliFile: "decorations"; cliField: "shadow-enabled"
          leadingIcon: "blur_on"; title: "Window shadow"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          live: appearanceTab.visible && appearanceTab.root && appearanceTab.root.visible
          cliFile: "decorations"; cliField: "animations-enabled"
          leadingIcon: "animation"; title: "Animations"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          live: appearanceTab.visible && appearanceTab.root && appearanceTab.root.visible
          cliFile: "decorations"; cliField: "blur-enabled"
          leadingIcon: "lens_blur"; title: "Background blur"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSliderRow {
          Layout.fillWidth: true
          live: appearanceTab.visible && appearanceTab.root && appearanceTab.root.visible
          cliFile: "decorations"; cliField: "blur-passes"
          label: "Blur passes"; min: 1; max: 5
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSliderRow {
          Layout.fillWidth: true
          live: appearanceTab.visible && appearanceTab.root && appearanceTab.root.visible
          cliFile: "decorations"; cliField: "cursor-size"
          label: "Cursor size"; min: 16; max: 48; unit: "px"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }

        Text {
          visible: appearanceTab.wmStatusMessage !== ""
          Layout.fillWidth: true
          text: appearanceTab.wmStatusMessage
          color: Colors.destructive
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodySmallSize
          font.letterSpacing: Config.typeBodyTracking
          lineHeight: Config.typeBodySmallLineHeight
          lineHeightMode: Text.FixedHeight
          wrapMode: Text.WordWrap
        }
      }
    }

    ListItem {
      Layout.fillWidth: true
      leadingIcon: "left_panel_open"
      title: "Open sidebars at the screen edges"
      subtitle: Settings.sidebarEdgeHover ? "Left edge: sidebar, right edge: Settings" : "Use the bar button only"
      toggleControl: edgeHoverSwitch
      SwitchControl {
        id: edgeHoverSwitch
        checked: Settings.sidebarEdgeHover
        activeColor: Colors.primary
        surfaceContainerHigh: Colors.surfaceContainerHigh
        surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.outline
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Open sidebars at the screen edges"
        onToggled: { Settings.sidebarEdgeHover = !Settings.sidebarEdgeHover; Settings.save() }
      }
    }

    ListItem {
      Layout.fillWidth: true
      leadingIcon: "mic"
      title: "Microphone indicator"
      subtitle: Settings.micIndicator ? "Tab at the top center: red while live, dim when muted" : "Hidden"
      toggleControl: micIndicatorSwitch
      SwitchControl {
        id: micIndicatorSwitch
        checked: Settings.micIndicator
        activeColor: Colors.primary
        surfaceContainerHigh: Colors.surfaceContainerHigh
        surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.outline
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Microphone indicator"
        onToggled: { Settings.micIndicator = !Settings.micIndicator; Settings.save() }
      }
    }

    SettingsSectionLabel { text: "Power menu" }

    Text {
      text: "Quote"
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeLabelLargeSize
    }

    TextFieldControl {
      id: powerMenuQuoteField
      Layout.fillWidth: true
      leadingIcon: "format_quote"
      placeholder: "Power menu quote"
      accessibleName: "Power menu quote"
      accessibleDescription: "The quote shown on the power menu"
      Component.onCompleted: input.text = Settings.powerMenuQuote
      Connections {
        target: Settings
        function onPowerMenuQuoteChanged() {
          if (!powerMenuQuoteField.input.activeFocus) powerMenuQuoteField.input.text = Settings.powerMenuQuote
        }
      }
      onAccepted: { Settings.powerMenuQuote = input.text; Settings.save() }
      Connections {
        target: powerMenuQuoteField.input
        function onActiveFocusChanged() {
          if (!powerMenuQuoteField.input.activeFocus && Settings.powerMenuQuote !== powerMenuQuoteField.input.text) {
            Settings.powerMenuQuote = powerMenuQuoteField.input.text
            Settings.save()
          }
        }
      }
    }

    Text {
      text: "Author line"
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeLabelLargeSize
    }

    TextFieldControl {
      id: powerMenuQuoteAuthorField
      Layout.fillWidth: true
      leadingIcon: "person"
      placeholder: "Power menu quote author"
      accessibleName: "Power menu quote author"
      accessibleDescription: "The author line under the power menu quote; leave empty to hide it"
      Component.onCompleted: input.text = Settings.powerMenuQuoteAuthor
      Connections {
        target: Settings
        function onPowerMenuQuoteAuthorChanged() {
          if (!powerMenuQuoteAuthorField.input.activeFocus) powerMenuQuoteAuthorField.input.text = Settings.powerMenuQuoteAuthor
        }
      }
      onAccepted: { Settings.powerMenuQuoteAuthor = input.text; Settings.save() }
      Connections {
        target: powerMenuQuoteAuthorField.input
        function onActiveFocusChanged() {
          if (!powerMenuQuoteAuthorField.input.activeFocus && Settings.powerMenuQuoteAuthor !== powerMenuQuoteAuthorField.input.text) {
            Settings.powerMenuQuoteAuthor = powerMenuQuoteAuthorField.input.text
            Settings.save()
          }
        }
      }
    }

    DockSection { Layout.fillWidth: true }
  }
}
