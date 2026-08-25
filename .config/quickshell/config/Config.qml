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
  readonly property string iconFont: nothingDesign
    ? "Material Symbols Rounded"
    : "Material Symbols Outlined"
  property int iconSize: Settings.iconSize
  property int fontPixelSize: Settings.fontPixelSize
  readonly property int textCaptionSize: Math.max(8, fontPixelSize - 1)
  readonly property int textBodySize: fontPixelSize + 1
  readonly property int textBodyLargeSize: fontPixelSize + 3
  readonly property int textTitleSize: fontPixelSize + 5
  readonly property int textHeadlineSize: fontPixelSize + 8
  readonly property int iconSizeSmall: Math.max(12, iconSize - 2)

  // Bar clock typography is independently adjustable from global UI sizing.
  readonly property int labelSmallSize: fontPixelSize
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
  readonly property int themeOptionGap: neoBrutalism
    ? themeShadowOffset
    : (nothingEvolution ? spacingSmall : (nothingDesign ? spacingCompact : 0))
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
  // Nothing uses precise ease-out motion; Material 3 and Neo retain their
  // expressive overshoot for entrances and state changes.
  readonly property int themeMotionEasing: (nothingDesign || ghostTheme) ? Easing.OutCubic : Easing.OutBack
  readonly property real evolutionSurfaceAlpha: 0.86
  readonly property real evolutionRaisedAlpha: 0.92
  readonly property real evolutionControlAlpha: 0.74

  readonly property int popupWidth: 340
  readonly property int popupPadding: spacingLarge
  readonly property int settingsMinWidth: 320
  readonly property int settingsMinHeight: 360
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
