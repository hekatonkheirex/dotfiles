import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../primitives"
import "../../config"
import "../../config/PaletteCatalog.js" as PaletteCatalog
import "../../config/AccentPalette.js" as AccentPalette
import "../../config/BarScale.js" as BarScale

Flickable {
  id: appearanceTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  property bool fineTuneOpen: false
  readonly property var fineTuneTitles: ["ui font size", "clock size", "icon size", "spacing", "bar size"]
  // Settings search calls this before locating a target; true means the
  // layout changed and the caller should retry on the next tick.
  function expandForSearch(title) {
    var t = String(title).toLowerCase()
    var hit = fineTuneTitles.indexOf(t) >= 0
    if (!hit || fineTuneOpen) return false
    fineTuneOpen = true
    return true
  }
  readonly property int optionButtonGap: Config.themeOptionGap
  readonly property int segmentedButtonGap: 0
  // Stacked icon + label choices keep breathing room at the global type scale.
  readonly property int optionButtonHeight: Math.max(Config.controlHitSize, Config.typeLabelMediumLineHeight + (24))
  // Keep the selector model independent of palette roles: a new JS array
  // recreates every button, including the one handling the style change.
  readonly property var workspaceCountOptions: [
    { value: "active", icon: "dynamic_feed", label: "Active", description: "Show the workspaces currently known to Niri" },
    { value: "5", icon: "looks_5", label: "1–5", description: "Show workspaces one through five" },
    { value: "10", icon: "filter_9_plus", label: "1–10", description: "Show workspaces one through ten" }
  ]
  readonly property var workspaceStyleOptions: [
    { value: "expressive", icon: "auto_awesome", label: "Expressive", description: "Keep the current expressive workspace treatment" },
    { value: "pill", icon: "horizontal_rule", label: "Pill", description: "Use capsule-shaped workspace buttons" },
    { value: "rounded", icon: "rounded_corner", label: "Rounded", description: "Use rounded rectangle workspace buttons" },
    { value: "circle", icon: "circle", label: "Circle", description: "Use circular workspace buttons" },
    { value: "dots", icon: "radio_button_checked", label: "Dots", description: "Use a calm dot and halo marker" },
    { value: "numbers", icon: "123", label: "Numbers", description: "Show each workspace number" },
    { value: "magic", icon: "auto_awesome", label: "Glyph", description: "Use sparkle glyphs for workspace state" },
    { value: "kanji", icon: "language", label: "Kanji", description: "Use compact Japanese numerals" },
    { value: "rings", icon: "crop_free", label: "Frame", description: "Frame the focused workspace" },
    { value: "aurora", icon: "linear_scale", label: "Aurora", description: "Use a flat streak marker" },
    { value: "pacman", icon: "sports_esports", label: "Pacman", description: "Use a Pacman marker and pellets" }
  ]
  anchors.fill: parent
  visible: root.currentTab === 2
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
      subtitle: "Customize the shell’s visual style, colors, layout, and effects."
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

      // UI Style card

      Loader {
        id: sizingCardLoader
        Layout.fillWidth: true
        Layout.preferredHeight: item ? item.implicitHeight : 0
        sourceComponent: sizingCardComponent
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
            columns: appearanceTab.compactLayout
              ? 2
              : Math.min(3, PaletteCatalog.fixedFamilyOptions().length)
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
            columns: Math.min(3, paletteVariantRepeater.count)
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

      // Accent colors: shortlist of Matugen roles plus the active accent.
      SettingsCard {
        id: accentCard
        readonly property var picked: AccentPalette.normalize(Settings.accentPalette)
        readonly property string active: AccentPalette.resolve(Settings.accentPalette, Settings.accentActive)
        readonly property bool full: picked.length >= AccentPalette.MAX
        variant: "filled"
        Layout.fillWidth: true
        Layout.preferredHeight: accentColumn.implicitHeight + Config.spacingLarge * 2
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.outlineVariant
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: accentColumn
          anchors.fill: parent
          anchors.margins: Config.spacingLarge
          spacing: Config.spacingSmall

          Text {
            text: "Accent colors"
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
            text: "Shortlist up to " + AccentPalette.MAX + " colors from the palette ("
              + accentCard.picked.length + " of " + AccentPalette.MAX + " chosen)"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.fillWidth: true
          }

          Flow {
            Layout.fillWidth: true
            spacing: Config.spacingMedium

            Repeater {
              model: AccentPalette.ROLES

              delegate: AccentSwatch {
                required property var modelData
                readonly property bool member: accentCard.picked.indexOf(modelData.key) >= 0
                swatchColor: Colors.accentRoleColor(modelData.key)
                mark: member
                enabled: member || !accentCard.full
                label: modelData.label
                description: member ? "In shortlist. Activate to remove" : "Activate to add to shortlist"
                onActivated: {
                  Settings.accentPalette = AccentPalette.toggle(Settings.accentPalette, modelData.key)
                  var dropsActive = Settings.accentActive === modelData.key && member
                  if (dropsActive) Settings.accentActive = ""
                  Settings.save()
                  if (dropsActive) appearanceTab.requestPaletteSync()
                }
              }
            }
          }

          Text {
            text: "Active accent"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.fillWidth: true
          }

          Flow {
            Layout.fillWidth: true
            spacing: Config.spacingMedium

            AccentSwatch {
              swatchColor: Colors.accentRoleColor("primary")
              ring: accentCard.active === ""
              label: "Default accent"
              description: "Use the style's own primary color"
              onActivated: {
                Settings.accentActive = ""
                Settings.save()
                appearanceTab.requestPaletteSync()
              }
            }

            Repeater {
              model: accentCard.picked

              delegate: AccentSwatch {
                required property string modelData
                swatchColor: Colors.accentRoleColor(modelData)
                ring: accentCard.active === modelData
                label: AccentPalette.find(modelData).label + " accent"
                description: "Use this color as the active accent"
                onActivated: {
                  Settings.accentActive = modelData
                  Settings.save()
                  appearanceTab.requestPaletteSync()
                }
              }
            }
          }

          Text {
            text: accentCard.active === ""
              ? "Default is the first swatch; pick one of your shortlist to recolor the shell, GTK, Qt, Kvantum, Niri and terminals"
              : "The shell and desktop use " + AccentPalette.find(accentCard.active).label.toLowerCase()
                + (appearanceTab.themeStatus !== "" ? " · " + appearanceTab.themeStatus : "")
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingCompact

      Text {
        text: "Bar"
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
          text: "Configure the bar's surface and position"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelSmallSize
          font.letterSpacing: Config.typeLabelTracking
          lineHeight: Config.typeLabelSmallLineHeight
          lineHeightMode: Text.FixedHeight
          wrapMode: Text.WordWrap
        }
      }

      GridLayout {
        id: barOptionsGrid
        Layout.fillWidth: true
        columns: appearanceTab.compactLayout ? 1 : 2
        columnSpacing: Config.spacingLarge
        rowSpacing: Config.spacingLarge

      // Bar Placement card
      SettingsCard {
        variant: "filled"
        Layout.column: appearanceTab.compactLayout ? 0 : 1
        Layout.row: 0
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: barPlacementColumn.implicitHeight + Config.spacingPage
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.outlineVariant
        outlineWidth: Config.themeBorderWidth

          ColumnLayout {
            id: barPlacementColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Config.spacingLarge
            anchors.leftMargin: Config.spacingLarge
            anchors.rightMargin: Config.spacingLarge
            spacing: Config.spacingSmall

            Text {
              text: "Bar Placement"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyLargeSize
              font.weight: Config.typeStrongWeight
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodyLargeLineHeight
              lineHeightMode: Text.FixedHeight
              Layout.alignment: Qt.AlignHCenter
            }

            Item {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredHeight: appearanceTab.optionButtonHeight
              height: appearanceTab.optionButtonHeight

              Row {
                anchors.fill: parent
                spacing: appearanceTab.segmentedButtonGap

                Repeater {
                  model: [
                    { value: "top", icon: "vertical_align_top", label: "Top" },
                    { value: "bottom", icon: "vertical_align_bottom", label: "Bottom" },
                    { value: "left", icon: "dock_to_left", label: "Left" },
                    { value: "right", icon: "dock_to_right", label: "Right" }
                  ]

                  delegate: ActionButton {
                    required property var modelData
                    required property int index
                    width: (parent.width - appearanceTab.segmentedButtonGap * 3) / 4
                    height: parent.height
                    iconLabel: modelData.icon
                    iconSize: 15
                    contentSpacing: Config.spacingSmall
                    horizontalContent: false
                    labelText: modelData.label
                    selected: root.barPosition === modelData.value
                    checkable: true
                    grouped: true
                    groupPosition: index === 0 ? "first" : (index === 3 ? "last" : "middle")
                    accessibleName: modelData.label + " bar"
                    accessibleDescription: selected ? "Selected" : "Switch bar to " + modelData.label.toLowerCase()
                    onActivated: root.setBarPosition(modelData.value)
                  }
                }
              }
            }
          }
      }

      // Bar form chooser
      SettingsCard {
        variant: "filled"
        Layout.column: 0
        Layout.row: appearanceTab.compactLayout ? 1 : 0
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: barFormColumn.implicitHeight + Config.spacingPage
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.outlineVariant
        outlineWidth: Config.themeBorderWidth

          ColumnLayout {
            id: barFormColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Config.spacingLarge
            anchors.leftMargin: Config.spacingLarge
            anchors.rightMargin: Config.spacingLarge
            spacing: Config.spacingSmall

            Text {
              text: "Bar Form"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyLargeSize
              font.weight: Config.typeStrongWeight
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodyLargeLineHeight
              lineHeightMode: Text.FixedHeight
              Layout.alignment: Qt.AlignHCenter
            }

            Item {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredHeight: appearanceTab.optionButtonHeight
              height: appearanceTab.optionButtonHeight
              enabled: true
              opacity: 1

              Row {
                anchors.fill: parent
                spacing: appearanceTab.segmentedButtonGap

                Repeater {
                  model: [
                    { value: "full", icon: "dock_to_bottom", label: "Full", description: "Edge to edge" },
                    { value: "fit", icon: "web_asset", label: "Fit", description: "Inset rounded frame" },
                    { value: "dock", icon: "bottom_app_bar", label: "Dock", description: "Open desktop edge" },
                    { value: "notch", icon: "flip_to_front", label: "Notch", description: "Flowing shoulders" },
                    { value: "pill", icon: "pill", label: "Pill", description: "Grouped pills and signal line" }
                  ]

                  delegate: ActionButton {
                    required property var modelData
                    required property int index
                    width: (parent.width - appearanceTab.segmentedButtonGap * 4) / 5
                    height: parent.height
                    iconLabel: modelData.icon
                    iconSize: 15
                    contentSpacing: Config.spacingSmall
                    horizontalContent: false
                    labelText: modelData.label
                    selected: Settings.barForm === modelData.value
                    checkable: true
                    grouped: true
                    groupPosition: index === 0 ? "first" : (index === 4 ? "last" : "middle")
                    accessibleName: modelData.label + " bar form"
                    accessibleDescription: modelData.description
                    onActivated: root.setBarForm(modelData.value)
                  }
                }
              }
            }

            Text {
              Layout.fillWidth: true
              text: {

                var forms = { full: "Edge to edge", fit: "Inset rounded frame",
                  dock: "Open desktop edge", notch: "Flowing shoulders",
                  pill: "Grouped pills and signal line" }
                return forms[Settings.barForm] || forms.full
              }
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelMediumSize
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: Config.typeLabelMediumLineHeight
              lineHeightMode: Text.FixedHeight
              horizontalAlignment: Text.AlignHCenter
            }
          }
      }

      // Workspace marker and range controls
      SettingsCard {
        id: workspaceShapeCard
        variant: "filled"
        Layout.column: 0
        Layout.row: appearanceTab.compactLayout ? 2 : 1
        Layout.columnSpan: appearanceTab.compactLayout ? 1 : 2
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: workspaceShapeColumn.implicitHeight + Config.spacingLarge * 2
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.outlineVariant
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: workspaceShapeColumn
          anchors.fill: parent
          anchors.margins: Config.spacingLarge
          spacing: Config.spacingSmall

          Text {
            text: "Workspace buttons"
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
            text: "Choose how many workspaces are shown and how their markers look"
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

          Text {
            text: "Visible workspaces"
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
              spacing: 0

              Repeater {
                model: appearanceTab.workspaceCountOptions

                delegate: ActionButton {
                  required property var modelData
                  required property int index
                  width: (parent.width - (0)) / 3
                  height: parent.height
                  iconLabel: modelData.icon
                  iconSize: 15
                  contentSpacing: Config.spacingSmall
                  horizontalContent: false
                  labelText: modelData.label
                  selected: Settings.workspaceCount === modelData.value
                  checkable: true
                  grouped: true
                  groupPosition: index === 0 ? "first" : (index === 2 ? "last" : "middle")
                  accessibleName: modelData.label + " workspace count"
                  accessibleDescription: selected ? "Selected. " + modelData.description : modelData.description
                  onActivated: {
                    Settings.workspaceCount = modelData.value
                    Settings.save()
                  }
                }
              }
            }
          }

          Text {
            text: "Marker style"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.fillWidth: true
          }

          GridLayout {
            Layout.fillWidth: true
            columns: appearanceTab.compactLayout ? 2 : 4
            columnSpacing: appearanceTab.optionButtonGap
            rowSpacing: appearanceTab.optionButtonGap
            enabled: true
            opacity: 1

            Repeater {
              model: appearanceTab.workspaceStyleOptions

              delegate: ActionButton {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: appearanceTab.optionButtonHeight
                iconLabel: modelData.icon
                iconSize: 15
                contentSpacing: Config.spacingSmall
                horizontalContent: false
                labelText: modelData.label
                selected: Settings.workspaceShape === modelData.value
                checkable: true
                grouped: true
                accessibleName: modelData.label + " workspace marker"
                accessibleDescription: selected ? "Selected. " + modelData.description : modelData.description
                onActivated: {
                  Settings.workspaceShape = modelData.value
                  Settings.save()
                }
              }
            }
          }

        }
      }

      }
    }

    // Font / Icon / Spacing sliders
    Component {
      id: sizingCardComponent

      SettingsCard {
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: sizingColumn.implicitHeight + Config.spacingMedium * 2
      implicitHeight: sizingColumn.implicitHeight + Config.spacingMedium * 2
      radius: Config.settingsCardRadius
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.outlineVariant
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: sizingColumn
        anchors.fill: parent
        anchors.margins: Config.spacingMedium
        spacing: Config.spacingSmall

        Text {
          text: "Sizing"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodyLargeSize
          font.weight: Config.typeStrongWeight
          font.letterSpacing: Config.typeBodyTracking
          lineHeight: Config.typeBodyLargeLineHeight
          lineHeightMode: Text.FixedHeight
        }


        // Bar scale: drives bar size, font, icon and spacing together
        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingMedium
          readonly property var scaleMatch: BarScale.match({
            barSize: Settings.barSize, fontPixelSize: Settings.fontPixelSize,
            clockFontSize: Settings.clockFontSize, iconSize: Settings.iconSize,
            spacingScale: Settings.spacingScale
          })
          readonly property real barScale: scaleMatch.scale

          Text {
            text: "Bar Scale"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: (appearanceTab.compactLayout ? 64 : 90)
          }

          SliderControl {
            Layout.fillWidth: true
            value: (parent.barScale - BarScale.MIN) / (BarScale.MAX - BarScale.MIN)
            stepSize: BarScale.STEP / (BarScale.MAX - BarScale.MIN)
            accessibleMinimumValue: Math.round(BarScale.MIN * 100)
            accessibleMaximumValue: Math.round(BarScale.MAX * 100)
            accessibleUnit: "%"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Bar scale"
            accessibleDescription: "Scale the bar thickness, text, clock, icons and spacing together"
            onChanged: function(val) {
              var v = BarScale.values(BarScale.MIN + val * (BarScale.MAX - BarScale.MIN))
              Settings.barSize = v.barSize
              Settings.fontPixelSize = v.fontPixelSize
              Settings.clockFontSize = v.clockFontSize
              Settings.iconSize = v.iconSize
              Settings.spacingScale = v.spacingScale
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: parent.scaleMatch.exact ? Math.round(parent.barScale * 100) + "%" : "Custom"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelMediumSize
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: 56
          }
        }


        // Individual sizes live under Bar Scale; collapsed by default.
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: Math.max(Config.controlHitSize, fineTuneLabel.implicitHeight + Config.spacingMedium)
          radius: Config.shapeCompact
          color: fineTuneArea.containsMouse ? Colors.surfaceContainerHigh : "transparent"
          activeFocusOnTab: true
          Accessible.role: Accessible.Button
          Accessible.name: "Individual sizes"
          Keys.onSpacePressed: appearanceTab.fineTuneOpen = !appearanceTab.fineTuneOpen
          Keys.onReturnPressed: appearanceTab.fineTuneOpen = !appearanceTab.fineTuneOpen

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Config.spacingSmall
            anchors.rightMargin: Config.spacingSmall
            spacing: Config.spacingSmall

            IconGlyph {
              iconLabel: appearanceTab.fineTuneOpen ? "expand_more" : "chevron_right"
              iconColor: Colors.fgSurfaceVariant
              iconSize: Config.iconSize
            }
            Text {
              id: fineTuneLabel
              Layout.fillWidth: true
              text: "Individual sizes"
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodyMediumLineHeight
              lineHeightMode: Text.FixedHeight
            }
          }

          MouseArea {
            id: fineTuneArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: appearanceTab.fineTuneOpen = !appearanceTab.fineTuneOpen
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          visible: appearanceTab.fineTuneOpen
          spacing: Config.spacingSmall

          // UI font size
          RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingMedium

            Text {
              text: "UI Font Size"
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodyMediumLineHeight
              lineHeightMode: Text.FixedHeight

              Layout.preferredWidth: Math.max(90, implicitWidth)
            }

            SliderControl {
              Layout.fillWidth: true
              value: (Settings.fontPixelSize - 7) / 9
              stepSize: 1 / 9
              accessibleMinimumValue: 7
              accessibleMaximumValue: 16
              accessibleUnit: "px"
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              focusColor: Colors.primary
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "UI font size"
              accessibleDescription: "Adjust global UI font size"
              onChanged: function(val) {
                Settings.fontPixelSize = Math.round(7 + val * 9)
              }
              onInteractionFinished: Settings.save()
            }

            Text {
              text: Settings.fontPixelSize + "px"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelMediumSize
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: Config.typeLabelMediumLineHeight
              lineHeightMode: Text.FixedHeight
              Layout.preferredWidth: 44
            }
          }

          // Clock font size
          RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingMedium

            Text {
              text: "Clock Size"
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodyMediumLineHeight
              lineHeightMode: Text.FixedHeight

              Layout.preferredWidth: Math.max(90, implicitWidth)
            }

            SliderControl {
              Layout.fillWidth: true
              value: (Settings.clockFontSize - 8) / 16
              stepSize: 1 / 16
              accessibleMinimumValue: 8
              accessibleMaximumValue: 24
              accessibleUnit: "px"
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              focusColor: Colors.primary
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Clock font size"
              accessibleDescription: "Adjust the bar clock font size"
              onChanged: function(val) {
                Settings.clockFontSize = Math.round(8 + val * 16)
              }
              onInteractionFinished: Settings.save()
            }

            Text {
              text: Settings.clockFontSize + "px"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelMediumSize
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: Config.typeLabelMediumLineHeight
              lineHeightMode: Text.FixedHeight
              Layout.preferredWidth: 44
            }
          }

          // Icon size
          RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingMedium

            Text {
              text: "Icon Size"
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodyMediumLineHeight
              lineHeightMode: Text.FixedHeight

              Layout.preferredWidth: Math.max(90, implicitWidth)
            }

            SliderControl {
              Layout.fillWidth: true
              value: (Settings.iconSize - 12) / 16
              stepSize: 1 / 16
              accessibleMinimumValue: 12
              accessibleMaximumValue: 28
              accessibleUnit: "px"
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              focusColor: Colors.primary
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Icon size"
              accessibleDescription: "Adjust global icon size"
              onChanged: function(val) {
                Settings.iconSize = Math.round(12 + val * 16)
              }
              onInteractionFinished: Settings.save()
            }

            Text {
              text: Settings.iconSize + "px"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelMediumSize
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: Config.typeLabelMediumLineHeight
              lineHeightMode: Text.FixedHeight
              Layout.preferredWidth: 44
            }
          }

          // Spacing
          RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingMedium

            Text {
              text: "Spacing"
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodyMediumLineHeight
              lineHeightMode: Text.FixedHeight

              Layout.preferredWidth: (appearanceTab.compactLayout ? 64 : 90)
            }

            SliderControl {
              Layout.fillWidth: true
              value: (Settings.spacingScale - 0.75) / 0.75
              stepSize: 0.05 / 0.75
              accessibleMinimumValue: 75
              accessibleMaximumValue: 150
              accessibleUnit: "%"
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              focusColor: Colors.primary
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Spacing"
              accessibleDescription: "Adjust global layout spacing"
              onChanged: function(val) {
                Settings.spacingScale = Math.round((0.75 + val * 0.75) * 20) / 20
              }
              onInteractionFinished: Settings.save()
            }

            Text {
              text: Math.round(Settings.spacingScale * 100) + "%"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelMediumSize
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: Config.typeLabelMediumLineHeight
              lineHeightMode: Text.FixedHeight
              Layout.preferredWidth: 44
            }
          }

          // Bar size
          RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingMedium

            Text {
              text: "Bar Size"
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodyMediumLineHeight
              lineHeightMode: Text.FixedHeight

              Layout.preferredWidth: (appearanceTab.compactLayout ? 64 : 90)
            }

            SliderControl {
              Layout.fillWidth: true
              value: (Settings.barSize - 28) / 28
              stepSize: 2 / 28
              accessibleMinimumValue: 28
              accessibleMaximumValue: 56
              accessibleUnit: "px"
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              focusColor: Colors.primary
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Bar size"
              accessibleDescription: "Adjust the bar's thickness and widget size"
              onChanged: function(val) {
                Settings.barSize = Math.round(28 + val * 28)
              }
              onInteractionFinished: Settings.save()
            }

            Text {
              text: Settings.barSize + "px"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelMediumSize
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: Config.typeLabelMediumLineHeight
              lineHeightMode: Text.FixedHeight
              Layout.preferredWidth: 44
            }
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
      title: "Open sidebar at the left screen edge"
      subtitle: Settings.sidebarEdgeHover ? "Hover the left edge to open" : "Use the bar button only"
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
        accessibleName: "Open sidebar at the left screen edge"
        onToggled: { Settings.sidebarEdgeHover = !Settings.sidebarEdgeHover; Settings.save() }
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
