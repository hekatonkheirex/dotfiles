pragma Singleton
import QtQml
import QtQuick
import Quickshell

QtObject {
  readonly property string wmType: "niri"
  readonly property bool isNiri: wmType === "niri"

  // Compact X390 geometry and shared spacing used by active surfaces.
  // Live-adjustable via the Appearance settings tab's Bar Size slider.
  readonly property int barWidth: Settings.barSize
  readonly property int widgetSize: Settings.barSize
  // Live-adjustable via the Appearance settings tab (single density scale);
  // mirrors Settings the same way reducedMotion below does, so every binding
  // that reads these updates immediately without touching the consuming file.
  property real spacingScale: Settings.spacingScale
  property int spacingCompact: Math.round(4 * spacingScale)
  property int spacingSmall: Math.round(8 * spacingScale)
  property int spacingMedium: Math.round(12 * spacingScale)
  property int spacingLarge: Math.round(16 * spacingScale)
  property int spacingExtraLarge: Math.round(24 * spacingScale)

  // UI style is separate from Matugen's external desktop palette. Material 3
  // and Neo Brutalism consume its generated roles; Nothing uses Colors.qml's
  // fixed neutral/red light and dark roles.
  readonly property bool nothingDesign: Settings.themeStyle === "nothing"
  readonly property bool neoBrutalism: Settings.themeStyle === "neo-brutalism"
  readonly property string fontFamily: nothingDesign
    ? "NType 82"
    : (neoBrutalism ? "JetBrains Mono" : "Roboto Flex")
  readonly property string monoFontFamily: nothingDesign
    ? "NType 82 Mono"
    : (neoBrutalism ? "JetBrains Mono" : "Roboto Flex")
  readonly property string displayFontFamily: nothingDesign
    ? "NType 82 Headline"
    : fontFamily
  // Ndot is Nothing's dot-matrix numeral font, reserved for the clock digits
  // the way the brand doc reserves it for product names/logotypes.
  readonly property string dotFontFamily: nothingDesign
    ? "Ndot 57"
    : displayFontFamily
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
  readonly property int shapeCompact: nothingDesign ? 8 : (neoBrutalism ? 4 : 8)
  readonly property int shapeMedium: nothingDesign ? 14 : (neoBrutalism ? 6 : 12)
  readonly property int shapeLarge: nothingDesign ? 20 : (neoBrutalism ? 10 : 16)
  readonly property int borderRadius: shapeLarge
  readonly property int barRadius: nothingDesign ? 0 : borderRadius
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
  readonly property int themeOptionGap: neoBrutalism ? themeShadowOffset : (nothingDesign ? spacingCompact : 0)
  readonly property int themeFontWeight: neoBrutalism
    ? Font.DemiBold
    : (nothingDesign ? Font.Medium : Font.Normal)

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
  readonly property int themeMotionEasing: nothingDesign ? Easing.OutCubic : Easing.OutBack

  readonly property int popupWidth: 340
  readonly property int popupPadding: spacingLarge
  readonly property int commandCenterMinWidth: 320
  readonly property int commandCenterMinHeight: 360
  // Neo's hard shadows and block controls need a little more room in the
  // Appearance tab; Nothing and Material 3 keep the compact footprint.
  readonly property int commandCenterMaxWidth: neoBrutalism ? 864 : 800
  readonly property int commandCenterMaxHeight: neoBrutalism ? 700 : 606
  readonly property int clockIntervalMs: 1000
  readonly property int volumeStep: 5
  readonly property int brightnessStep: 5
}
