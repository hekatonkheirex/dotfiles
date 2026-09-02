pragma Singleton
import QtQml
import QtQuick
import Quickshell

QtObject {
  readonly property string wmType: "niri"
  readonly property bool isNiri: wmType === "niri"
  // UI style is separate from Matugen's external desktop palette. Material 3
  // and Neo Brutalism consume its generated roles; classic Nothing and Ghost
  // use authored roles while Nothing Evolution consumes the adaptive cache.
  readonly property bool nothingDesign: Settings.themeStyle === "nothing"
  readonly property bool nothingEvolution: nothingDesign && Settings.nothingVariant === "evolution"
  readonly property bool neoBrutalism: Settings.themeStyle === "neo-brutalism"
  readonly property bool ghostTheme: Settings.themeStyle === "ghost"

  // Compact X390 geometry and shared spacing used by active surfaces.
  // Live-adjustable via the Appearance settings tab's Bar Size slider.
  // Ghost keeps the recovered 34px HUD rail; the shared slider can still make
  // it smaller, while Material, Neo, and Nothing retain the selected size.
  readonly property int barWidth: ghostTheme
    ? Math.min(Settings.barSize, 34)
    : Settings.barSize
  readonly property int widgetSize: ghostTheme
    ? Math.min(Settings.barSize, 34)
    : Settings.barSize
  // Live-adjustable via the Appearance settings tab (single density scale);
  // mirrors Settings the same way reducedMotion below does, so every binding
  // that reads these updates immediately without touching the consuming file.
  property real spacingScale: Settings.spacingScale
  property int spacingCompact: Math.round(4 * spacingScale)
  property int spacingSmall: Math.round(8 * spacingScale)
  property int spacingMedium: Math.round(12 * spacingScale)
  property int spacingLarge: Math.round(16 * spacingScale)
  property int spacingExtraLarge: Math.round(24 * spacingScale)
  property int spacingPage: Math.round(32 * spacingScale)
  // Reserve visual breathing room between tab content and the outer settings
  // scrollbar, which is intentionally overlaid on the Flickable edge.
  readonly property int settingsScrollbarGutter: spacingMedium

  readonly property string fontFamily: nothingEvolution
    ? "Geist"
    : (nothingDesign
      ? "NType 82"
      : ((neoBrutalism || ghostTheme) ? "JetBrains Mono" : "Roboto Flex"))
  readonly property string monoFontFamily: nothingEvolution
    ? "Geist Mono"
    : (nothingDesign
      ? "NType 82 Mono"
      : ((neoBrutalism || ghostTheme) ? "JetBrains Mono" : "Roboto Flex"))
  readonly property string displayFontFamily: nothingEvolution
    ? "Geist"
    : (nothingDesign ? "NType 82 Headline" : fontFamily)
  // Evolution dials dot-matrix typography back to intentional accent areas;
  // compact clocks and numeric readouts use Geist Mono instead.
  readonly property string dotFontFamily: nothingEvolution
    ? "Geist Mono"
    : (nothingDesign ? "Ndot 57" : displayFontFamily)
  // Keep icon geometry coherent with the active visual language. Material 3
  // and Ghost use the calm outlined family, Nothing uses rounded symbols, and
  // Neo uses the sharper family to match its square surfaces.
  readonly property string iconFont: neoBrutalism
    ? "Material Symbols Sharp"
    : (nothingDesign ? "Material Symbols Rounded" : "Material Symbols Outlined")
  // Material Symbols is a variable font. These defaults keep icons crisp and
  // let semantic states opt into fill without scattering font-axis values
  // through individual controls.
  readonly property int iconWeight: neoBrutalism ? 500 : 400
  readonly property int iconGrade: 0
  function iconVariableAxes(fill, pixelSize) {
    var normalizedFill = Math.max(0, Math.min(1, fill))
    var opticalSize = Math.max(20, Math.min(48, pixelSize))
    return {
      "FILL": normalizedFill,
      "GRAD": iconGrade,
      "opsz": opticalSize,
      "wght": iconWeight
    }
  }
  property int iconSize: Settings.iconSize
  property int fontPixelSize: Settings.fontPixelSize

  // Compact Material 3 type roles. The shell is a resizable desktop surface,
  // so these keep the current laptop density while preserving the hierarchy
  // and naming of the M3 type scale. Use weight and line height to express
  // emphasis; do not make every setting row compete with its page heading.
  readonly property int typeLabelSmallSize: Math.max(8, fontPixelSize - 1)
  readonly property int typeLabelMediumSize: fontPixelSize
  readonly property int typeLabelLargeSize: fontPixelSize + 2
  readonly property int typeBodySmallSize: Math.max(10, fontPixelSize - 1)
  readonly property int typeBodyMediumSize: fontPixelSize + 1
  readonly property int typeBodyLargeSize: fontPixelSize + 3
  readonly property int typeTitleSmallSize: fontPixelSize + 2
  readonly property int typeTitleMediumSize: fontPixelSize + 3
  readonly property int typeTitleLargeSize: fontPixelSize + 5
  readonly property int typeHeadlineSmallSize: fontPixelSize + 8
  readonly property int typeHeadlineMediumSize: fontPixelSize + 12
  readonly property int typeHeadlineLargeSize: fontPixelSize + 16
  readonly property int typeDisplaySmallSize: fontPixelSize + 20
  readonly property int typeDisplayMediumSize: fontPixelSize + 28
  readonly property int typeDisplayLargeSize: fontPixelSize + 36

  readonly property int typeLabelSmallLineHeight: 16
  readonly property int typeLabelMediumLineHeight: 18
  readonly property int typeLabelLargeLineHeight: 20
  readonly property int typeBodySmallLineHeight: 16
  readonly property int typeBodyMediumLineHeight: 19
  readonly property int typeBodyLargeLineHeight: 22
  readonly property int typeTitleSmallLineHeight: 18
  readonly property int typeTitleMediumLineHeight: 20
  readonly property int typeTitleLargeLineHeight: 22
  readonly property int typeHeadlineSmallLineHeight: 24
  readonly property int typeHeadlineMediumLineHeight: 28
  readonly property int typeHeadlineLargeLineHeight: 32
  readonly property int typeDisplaySmallLineHeight: 36
  readonly property int typeDisplayMediumLineHeight: 44
  readonly property int typeDisplayLargeLineHeight: 52

  // Qt expresses tracking in pixels. Keep display/headline tracking slightly
  // tight, leave body copy neutral, and give labels only a subtle separation.
  readonly property real typeDisplayTracking: -0.4
  readonly property real typeHeadlineTracking: -0.2
  readonly property real typeTitleTracking: 0
  readonly property real typeBodyTracking: 0
  readonly property real typeLabelTracking: 0.1
  readonly property real typeMonoTracking: 0.8
  readonly property int typeRegularWeight: Font.Normal
  readonly property int typeMediumWeight: Font.Medium
  readonly property int typeStrongWeight: Font.Bold

  // Backward-compatible aliases used by older delegates. New UI should use
  // the named type roles above so hierarchy remains explicit at call sites.
  readonly property int textCaptionSize: typeLabelSmallSize
  readonly property int textBodySize: typeBodyMediumSize
  readonly property int textBodyLargeSize: typeBodyLargeSize
  readonly property int textTitleSize: typeTitleLargeSize
  readonly property int textHeadlineSize: typeHeadlineSmallSize
  readonly property int iconSizeSmall: Math.max(12, iconSize - 2)

  // Bar clock typography is independently adjustable from global UI sizing.
  readonly property int labelSmallSize: typeLabelMediumSize
  readonly property int clockPrimarySize: Settings.clockFontSize
  readonly property int clockSecondarySize: Math.max(8, Settings.clockFontSize - 5)
  // Tight on purpose: the vertical bar stacks HH/MM at the same clockPrimarySize
  // and should read as one digital-clock block, not two separated labels.
  readonly property int clockLineSpacing: 2
  // Sized to the stacked hour/minute content instead of a flat constant, so
  // it keeps breathing room as the clock font size changes. Both lines render
  // at clockPrimarySize in vertical mode (secondary size is horizontal-only).
  readonly property int clockVerticalHeight: Math.round(clockPrimarySize * 1.2) * 2
    + clockLineSpacing
    + spacingMedium * 2

  // Nothing uses a soft, pill-leaning radius scale (Control Center toggles,
  // widget cards). Neo Brutalism keeps its existing hard-edged geometry;
  // Material 3 retains its expressive shapes.
  // Ghost carries the recovered GITS theme's frameRadius: 0 — every surface
  // is a hard, square HUD panel, no rounding at any scale.
  readonly property int shapeCompact: ghostTheme ? 0 : (nothingEvolution ? 10 : (nothingDesign ? 8 : (neoBrutalism ? 4 : 8)))
  readonly property int shapeMedium: ghostTheme ? 0 : (nothingEvolution ? 18 : (nothingDesign ? 14 : (neoBrutalism ? 6 : 12)))
  readonly property int shapeLarge: ghostTheme ? 0 : (nothingEvolution ? 24 : (nothingDesign ? 20 : (neoBrutalism ? 10 : 16)))
  readonly property int borderRadius: shapeLarge
  readonly property int barRadius: nothingEvolution ? shapeMedium : ((nothingDesign || ghostTheme) ? 0 : borderRadius)
  readonly property int themeBorderWidth: neoBrutalism ? 3 : 1
  readonly property int themeFocusBorderWidth: neoBrutalism ? 4 : 2
  readonly property int themeShadowOffset: neoBrutalism ? 6 : 0
  // Keep the Neo full-bar edge aligned with Niri's focused-window edge:
  // the 18px Niri gap minus its 4px focus ring.
  readonly property int neoWindowGap: neoBrutalism ? 18 : 0
  readonly property int neoFullBarInset: neoBrutalism
    ? Math.max(0, neoWindowGap - themeFocusBorderWidth)
    : 0
  // Icon-plus-label Neo controls need room for the thick border and hard shadow.
  readonly property int themeActionButtonMinHeight: neoBrutalism ? 56 : 0
  // Material 3 uses a compact horizontal icon-plus-label action. The other
  // themes retain their taller stacked treatment; compact selector delegates
  // still provide their own height.
  readonly property int themeLabeledActionButtonHeight: (nothingDesign || neoBrutalism || ghostTheme) ? 64 : 48
  // Keep compact settings choices visually distinct in every theme. The
  // button content has its own compact spacing; this value separates adjacent
  // choices so their outlines and labels do not visually merge.
  readonly property int themeOptionGap: neoBrutalism
    ? themeShadowOffset
    : (nothingEvolution ? spacingSmall : spacingCompact)
  readonly property int themeFontWeight: neoBrutalism
    ? Font.DemiBold
    : (nothingEvolution ? Font.Medium : (nothingDesign ? Font.Medium : Font.Normal))

  // Motion is centralized here. reducedMotion mirrors the persisted Settings
  // singleton directly; compatibility consumers continue using animationDuration.
  property bool reducedMotion: Settings.reduceMotion
  readonly property int motionShort: reducedMotion ? 0 : 100
  readonly property int motionMedium: reducedMotion ? 0 : 150
  readonly property int motionLong: reducedMotion ? 0 : 250
  readonly property int motionExtraLong: reducedMotion ? 0 : 450
  readonly property int animationDuration: motionMedium
  // Interactive controls and workspace indicators still use the shared
  // spatial spring model; transient surfaces use the timed entrance below.
  readonly property bool expressiveMotion: !nothingDesign && !neoBrutalism && !ghostTheme
  readonly property real motionSpatialSpring: 2.0
  readonly property real motionSpatialDamping: expressiveMotion ? 0.78 : 1.0
  readonly property real motionSpatialMass: 1.0
  readonly property real motionSpatialEpsilon: 0.01
  // Surface entrances use the same concise, theme-aware easing as before;
  // interactive controls keep their own shorter motion tokens.
  readonly property int themeMotionEasing: (nothingDesign || ghostTheme) ? Easing.OutCubic : Easing.OutBack
  readonly property real evolutionSurfaceAlpha: 0.86
  readonly property real evolutionRaisedAlpha: 0.92
  readonly property real evolutionControlAlpha: 0.74

  readonly property int popupWidth: 340
  readonly property int popupPadding: spacingLarge
  readonly property int settingsMinWidth: 320
  readonly property int settingsMinHeight: 360
  // Shared label column for remote settings rows. Sized for the longest
  // current label while allowing larger type settings to preserve full text.
  readonly property int settingsRowLabelWidth: 200
  // Neo's hard shadows and block controls need a little more room in the
  // Appearance tab; Nothing and Material 3 keep the compact footprint.
  readonly property int settingsMaxWidth: neoBrutalism ? 1200 : 1100
  readonly property int settingsMaxHeight: neoBrutalism ? 900 : 820
  readonly property int settingsDefaultWidth: 900
  readonly property int settingsDefaultHeight: 680
  readonly property int clockIntervalMs: 1000
  readonly property int volumeStep: 5
  readonly property int brightnessStep: 5
}
