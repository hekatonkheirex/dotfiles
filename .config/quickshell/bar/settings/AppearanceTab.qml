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
  readonly property bool material3Theme: Config.material3Theme
  readonly property int optionButtonGap: Config.themeOptionGap
  readonly property int segmentedButtonGap: appearanceTab.material3Theme ? 0 : appearanceTab.optionButtonGap
  // Stacked icon + label choices need a 48px hit area to keep both glyphs
  // comfortably inside the button outline at the global font scale.
  readonly property int optionButtonHeight: 48
  readonly property int uiStyleColumns: width < 260 ? 1 : (width < 740 ? 2 : 5)
  readonly property int uiStyleRows: Math.ceil(5 / uiStyleColumns)
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

  property string previousStyle: ""
  property string previousNothingVariant: ""

  function selectStyle(style, variant) {
    if (Settings.themeStyle === style
        && (style !== "nothing" || Settings.nothingVariant === variant)) return
    previousStyle = Settings.themeStyle
    previousNothingVariant = Settings.nothingVariant
    Settings.themeStyle = style
    if (style === "nothing") Settings.nothingVariant = variant
    Settings.save()
  }

  function revertStyle() {
    if (previousStyle === "") return
    var style = previousStyle
    var variant = previousNothingVariant
    previousStyle = ""
    Settings.themeStyle = style
    Settings.nothingVariant = variant
    Settings.save()
  }
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

    if (Settings.colorSource === "fixed" && Colors.paletteSourceSelectable) {
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
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeTitleLargeSize
            font.weight: Config.typeStrongWeight
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

      // UI Style card
      StyledSurface {
        variant: "filled"
        Layout.fillWidth: true
        Layout.preferredHeight: uiStyleColumn.implicitHeight + Config.spacingExtraLarge * 2
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: uiStyleColumn
          anchors.fill: parent
          anchors.margins: Config.spacingExtraLarge
          spacing: Config.spacingMedium

          Text {
            text: "UI Style"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeTitleLargeSize
            font.weight: Config.typeStrongWeight
            font.letterSpacing: Config.typeTitleTracking
            lineHeight: Config.typeTitleLargeLineHeight
            lineHeightMode: Text.FixedHeight
          }

          Text {
            text: "Choose a shell style. Changes apply and save automatically."
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }

          Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft
            Layout.preferredWidth: 0
            Layout.minimumWidth: 0
            Layout.maximumWidth: parent.width
            Layout.preferredHeight: (appearanceTab.optionButtonHeight + 112) * appearanceTab.uiStyleRows
              + appearanceTab.optionButtonGap * (appearanceTab.uiStyleRows - 1)
            height: Layout.preferredHeight

            GridLayout {
              id: styleGrid
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              anchors.leftMargin: Config.spacingCompact
              anchors.rightMargin: Config.spacingCompact
              clip: true
              columns: appearanceTab.uiStyleColumns
              rows: appearanceTab.uiStyleRows
              columnSpacing: appearanceTab.optionButtonGap
              rowSpacing: appearanceTab.optionButtonGap

              Repeater {
                model: [
                  { value: "material3", variant: "", icon: "auto_awesome", label: "Material", surface: "#f3eff8", panel: "#e5e0ed", ink: "#25232a", accent: "#6259a5", onAccent: "#ffffff", font: "Roboto Flex" },
                  { value: "nothing", variant: "classic", icon: "grid_3x3", label: "Classic", surface: "#f0f0ee", panel: "#ffffff", ink: "#1a1a1a", accent: "#d71920", onAccent: "#ffffff", font: "NType 82" },
                  { value: "nothing", variant: "evolution", icon: "layers", label: "Evolution", surface: "#dcdce1", panel: "#f1f1f4", ink: "#1d1d1f", accent: "#557bae", onAccent: "#ffffff", font: "Geist" },
                  { value: "ghost", variant: "", icon: "network_intelligence", label: "Ghost", surface: "#0d1418", panel: "#152328", ink: "#cdeeea", accent: "#57d9cc", onAccent: "#0d1418", font: "JetBrains Mono" },
                  { value: "liquid-glass", variant: "", icon: "blur_on", label: "Liquid", surface: "#d9dce5", panel: "#f0f1f5", ink: "#1d1d1f", accent: "#818bb8", onAccent: "#ffffff", font: "Roboto Flex" }
                ]

                delegate: Item {
                  id: styleTile
                  required property var modelData
                  required property int index
                  readonly property bool centerLast: appearanceTab.uiStyleColumns === 2 && index === 4
                  readonly property bool classic: modelData.value === "nothing" && modelData.variant === "classic"
                  readonly property bool evolution: modelData.variant === "evolution"
                  readonly property bool ghost: modelData.value === "ghost"
                  readonly property bool glass: modelData.value === "liquid-glass"
                  readonly property bool selectedStyle: Settings.themeStyle === modelData.value
                    && (modelData.value !== "nothing" || Settings.nothingVariant === modelData.variant)
                  readonly property real corner: ghost ? 0 : (classic ? 4 : (glass ? 16 : 12))
                  Layout.fillWidth: !centerLast
                  Layout.fillHeight: true
                  Layout.columnSpan: centerLast ? 2 : 1
                  Layout.preferredWidth: centerLast ? (styleGrid.width - styleGrid.columnSpacing) / 2 : -1
                  Layout.alignment: centerLast ? Qt.AlignHCenter : Qt.AlignLeft
                  Layout.minimumWidth: 0

                  Rectangle {
                    anchors.fill: parent
                    radius: styleTile.ghost ? 0 : Config.shapeMedium
                    color: styleTile.selectedStyle
                      ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.10)
                      : "transparent"
                    border.width: styleTile.selectedStyle ? 2 : 0
                    border.color: Colors.primary
                  }

                  // Previews show the system's hierarchy, not just its accent.
                  Rectangle {
                    id: miniature
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Config.spacingCompact
                    height: 96
                    radius: corner
                    color: modelData.surface
                    border.color: ghost || classic ? modelData.accent : modelData.ink
                    border.width: ghost || classic ? 1 : 0
                    clip: true

                    Rectangle {
                      id: miniatureBar
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.top: parent.top
                      anchors.margins: 8
                      height: 16
                      radius: ghost || classic ? 0 : 8
                      color: ghost ? modelData.panel : (glass ? "#eeeef4" : modelData.panel)

                      Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: ghost ? "S9 • 09:41" : "09:41"
                        font.family: modelData.font
                        font.pixelSize: 9
                        color: modelData.ink
                      }

                      Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        width: ghost ? 24 : 28
                        height: ghost ? 4 : 8
                        radius: ghost || classic ? 0 : 5
                        color: modelData.accent
                      }
                    }

                    Rectangle {
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.bottom: parent.bottom
                      anchors.margins: 8
                      height: 58
                      radius: ghost ? 0 : (classic ? 4 : (glass ? 12 : (evolution ? 10 : 14)))
                      color: modelData.panel
                      border.color: ghost ? modelData.accent : (classic ? modelData.ink : "transparent")
                      border.width: ghost || classic ? 1 : 0
                      opacity: glass ? 0.86 : 1

                      Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        text: ghost ? "SETTINGS_01" : "Settings"
                        font.family: modelData.font
                        font.pixelSize: ghost ? 9 : 11
                        font.weight: ghost || classic ? Font.Medium : Font.DemiBold
                        color: modelData.ink
                      }

                      Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 11
                        width: ghost ? 52 : (classic ? 46 : 64)
                        height: ghost ? 2 : 4
                        radius: ghost || classic ? 0 : 2
                        color: ghost ? modelData.accent : modelData.ink
                        opacity: ghost ? 1 : 0.45
                      }

                      Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        width: 48
                        height: 20
                        radius: ghost ? 0 : (classic ? 10 : 12)
                        color: modelData.accent

                        Text {
                          anchors.centerIn: parent
                          text: ghost ? "RUN" : "Apply"
                          font.family: modelData.font
                          font.pixelSize: 9
                          color: modelData.onAccent
                        }
                      }
                    }
                  }
                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: appearanceTab.selectStyle(styleTile.modelData.value, styleTile.modelData.variant)
                  }

                  ActionButton {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Config.spacingCompact
                    height: appearanceTab.optionButtonHeight
                    iconLabel: modelData.icon
                    iconSize: 15
                    contentSpacing: Config.spacingSmall
                    horizontalContent: true
                    labelText: modelData.label
                    selected: styleTile.selectedStyle
                    checkable: true
                    variant: "text"
                    accessibleName: (modelData.value === "nothing" ? "Nothing " : "") + modelData.label + " UI style"
                    accessibleDescription: selected ? "Selected" : "Use the " + modelData.label + " UI style; revert is available below"
                    onActivated: appearanceTab.selectStyle(modelData.value, modelData.variant)
                  }
                }
              }
            }
          }

          GridLayout {
            Layout.fillWidth: true
            columns: appearanceTab.uiStyleColumns === 5 ? 2 : 1
            columnSpacing: Config.spacingMedium
            rowSpacing: Config.spacingSmall

            Text {
              text: Settings.themeStyle === "nothing" && Settings.nothingVariant === "evolution"
                ? "Geist type, adaptive wallpaper colour, and translucent layers"
                : (Settings.themeStyle === "nothing"
                  ? "Neutral surfaces, rounded controls, and signal accents"
                  : (Settings.themeStyle === "ghost"
                    ? "Void panels, cyan hairlines, and a Section 9 HUD"
                    : (Settings.themeStyle === "liquid-glass"
                      ? "Translucent functional surfaces, clear controls, and adaptive contrast"
                      : "Rounded surfaces, tonal elevation, and expressive motion")))
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              font.letterSpacing: Config.typeBodyTracking
              lineHeight: Config.typeBodyMediumLineHeight
              lineHeightMode: Text.FixedHeight
              wrapMode: Text.WordWrap
              Layout.fillWidth: true
              Layout.minimumWidth: 0
            }

            ActionButton {
              Layout.alignment: appearanceTab.uiStyleColumns === 5 ? Qt.AlignRight : Qt.AlignLeft
              Layout.preferredWidth: Math.min(160, uiStyleColumn.width)
              Layout.preferredHeight: 40
              visible: appearanceTab.previousStyle !== ""
              labelText: "Revert style"
              variant: "outlined"
              accessibleName: "Revert to previous UI style"
              onActivated: appearanceTab.revertStyle()
            }
          }
        }
      }

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
      StyledSurface {
        id: colorSchemeCard
        variant: "filled"
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(184, colorSchemeColumn.implicitHeight + Config.spacingLarge * 2)
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
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
                  enabled: Colors.paletteSourceSelectable
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
            text: !Colors.paletteSourceSelectable
              ? "The selected UI style owns its palette"
              : Colors.paletteSource
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

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingCompact

      Text {
        text: "Bar"
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
      StyledSurface {
        variant: "filled"
        Layout.column: appearanceTab.compactLayout ? 0 : 1
        Layout.row: 0
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: barPlacementColumn.implicitHeight + Config.spacingPage
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
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

      // Full bar toggle
      StyledSurface {
        variant: "filled"
        Layout.column: 0
        Layout.row: appearanceTab.compactLayout ? 1 : 0
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: barPlacementColumn.implicitHeight + Config.spacingPage
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
        outlineWidth: Config.themeBorderWidth

          Row {
            anchors.fill: parent
            anchors.margins: Config.spacingMedium
            spacing: 0

            Item {
              width: parent.width / 3
              height: parent.height

              Rectangle {
                anchors.centerIn: parent
                width: 24
                height: 24
                radius: Config.shapeCompact
                color: Colors.styleAccent

                IconGlyph {
                  anchors.centerIn: parent
                  iconLabel: "dock_to_bottom"
                  iconColor: Colors.styleAccentText
                  iconSize: Config.iconSize
                }
              }
            }

            Item {
              width: parent.width / 3
              height: parent.height

              ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                height: implicitHeight
                spacing: 1

                Text {
                  Layout.fillWidth: true
                  text: root.fullBar ? "Full bar" : "Pills bar"
                  color: Colors.fgSurface
                  font.family: Config.fontFamily
                  font.pixelSize: Config.typeBodyLargeSize
                  font.weight: Config.typeStrongWeight
                  font.letterSpacing: Config.typeBodyTracking
                  lineHeight: Config.typeBodyLargeLineHeight
                  lineHeightMode: Text.FixedHeight
                  horizontalAlignment: Text.AlignHCenter
                }

                Text {
                  Layout.fillWidth: true
                  text: root.fullBar ? "One continuous surface" : "Floating pill per widget"
                  color: Colors.fgSurfaceVariant
                  font.family: Config.fontFamily
                  font.pixelSize: Config.typeLabelMediumSize
                  font.letterSpacing: Config.typeLabelTracking
                  lineHeight: Config.typeLabelMediumLineHeight
                  lineHeightMode: Text.FixedHeight
                  horizontalAlignment: Text.AlignHCenter
                  wrapMode: Text.WordWrap
                  maximumLineCount: 2
                  elide: Text.ElideRight
                }
              }
            }

            Item {
              width: parent.width / 3
              height: parent.height

              SwitchControl {
                anchors.centerIn: parent
                checked: root.fullBar
                activeColor: Colors.primary
                surfaceContainerHigh: Colors.surfaceContainerHigh
                surfaceContainerHighest: Colors.surfaceContainerHighest
                outline: Colors.styleOutlineStrong
                motionDuration: Config.motionMedium
                reducedMotion: Config.reducedMotion
                accessibleName: "Bar display style"
                accessibleDescription: root.fullBar
                  ? "All widgets share one continuous bar"
                  : "Each widget is shown as a separate floating pill"
                onToggled: root.toggleFullBar()
              }
            }
          }
      }

      // Workspace marker and range controls
      StyledSurface {
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
        outlineColor: Colors.styleOutline
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
              spacing: appearanceTab.material3Theme ? 0 : appearanceTab.optionButtonGap

              Repeater {
                model: appearanceTab.workspaceCountOptions

                delegate: ActionButton {
                  required property var modelData
                  required property int index
                  width: (parent.width - (appearanceTab.material3Theme ? 0 : appearanceTab.optionButtonGap * 2)) / 3
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

      StyledSurface {
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: sizingColumn.implicitHeight + Config.spacingMedium * 2
      implicitHeight: sizingColumn.implicitHeight + Config.spacingMedium * 2
      radius: Config.settingsCardRadius
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
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
            Layout.preferredWidth: appearanceTab.compactLayout ? 64 : 90
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
            outline: Colors.styleOutlineStrong
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
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: 34
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
            Layout.preferredWidth: appearanceTab.compactLayout ? 64 : 90
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.clockFontSize - 12) / 12
            stepSize: 1 / 12
            accessibleMinimumValue: 12
            accessibleMaximumValue: 24
            accessibleUnit: "px"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Clock font size"
            accessibleDescription: "Adjust the bar clock font size"
            onChanged: function(val) {
              Settings.clockFontSize = Math.round(12 + val * 12)
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: Settings.clockFontSize + "px"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: 34
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
            Layout.preferredWidth: appearanceTab.compactLayout ? 64 : 90
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
            outline: Colors.styleOutlineStrong
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
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: 34
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
            Layout.preferredWidth: appearanceTab.compactLayout ? 64 : 90
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
            outline: Colors.styleOutlineStrong
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
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: 34
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
            Layout.preferredWidth: appearanceTab.compactLayout ? 64 : 90
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
            outline: Colors.styleOutlineStrong
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
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeLabelTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: 34
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

    StyledSurface {
      visible: Config.isMango
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: mangoWmNoteText.implicitHeight + Config.spacingMedium * 2
      radius: Config.settingsCardRadius
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
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
    StyledSurface {
      visible: Config.isNiri
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: wmColumn.implicitHeight + Config.spacingMedium * 2
      radius: Config.settingsCardRadius
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
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

  }
}
