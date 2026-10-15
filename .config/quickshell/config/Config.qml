pragma Singleton
import QtQml
import QtQuick
import Quickshell

QtObject {
  // Keep Niri as the compatibility default, but detect Mango when the shell
  // is started from the Mango session or its user service environment.
  readonly property string wmType: {
    var desktop = String(Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()
    var sessionDesktop = String(Quickshell.env("XDG_SESSION_DESKTOP") || "").toLowerCase()
    return desktop.indexOf("mango") === 0 || sessionDesktop.indexOf("mango") === 0
      ? "mango"
      : "niri"
  }
  readonly property bool isNiri: wmType === "niri"
  readonly property bool isMango: wmType === "mango"
  // elena is the only UI style. The bar is the top-edge row of workspace
  // blocks (barWidth = tagStripHeight, form full, top).
  readonly property bool spatialMotion: true
  readonly property bool expressiveMotion: true
  readonly property int tagStripHeight: 8
  // Reference scale for the sidebar, networks window and power menu.
  readonly property real elenaScale: 1.5
  function dp(n) { return Math.round(n * elenaScale) }
  // Laptop-sized bottom bar; its content has an independent scale.
  readonly property int bottomBarHeight: 48
  readonly property real bottomBarScale: bottomBarHeight / 43
  function bottomBarDp(n) { return Math.round(n * bottomBarScale) }

  function layerNamespace(kind) {
    return "quickshell-" + kind
  }

  readonly property int barWidth: tagStripHeight
  // Density scale; set in settings.json (no UI).
  property real spacingScale: Settings.spacingScale
  property int spacingCompact: Math.round(4 * spacingScale)
  property int spacingSmall: Math.round(8 * spacingScale)
  property int spacingMedium: Math.round(12 * spacingScale)
  property int spacingLarge: Math.round(16 * spacingScale)
  property int spacingExtraLarge: Math.round(24 * spacingScale)
  property int spacingPage: Math.round(32 * spacingScale)
  readonly property int controlHitSize: 48
  // Visual height of buttons, rows and text fields; the 48 px input target above stays for icon buttons and switches.
  readonly property int controlHeight: 36
  readonly property int materialRowPadding: spacingMedium
  // Reserve visual breathing room between tab content and the outer settings
  // scrollbar, which is intentionally overlaid on the Flickable edge.
  readonly property int settingsScrollbarGutter: spacingMedium

  readonly property string fontFamily: "Roboto Flex"
  readonly property string monoFontFamily: "Roboto Flex"
  readonly property string displayFontFamily: fontFamily
  readonly property string iconFont: "Material Symbols Outlined"
  readonly property int iconWeight: 400
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

  // The type scale follows the font-size preference (Settings.fontPixelSize).
  readonly property real materialTypeScale: Math.max(0.85, fontPixelSize / 12)
  readonly property int typeLabelSmallSize: Math.round(11 * materialTypeScale)
  readonly property int typeLabelMediumSize: Math.round(12 * materialTypeScale)
  readonly property int typeLabelLargeSize: Math.round(14 * materialTypeScale)
  readonly property int typeBodySmallSize: Math.round(12 * materialTypeScale)
  readonly property int typeBodyMediumSize: Math.round(14 * materialTypeScale)
  readonly property int typeBodyLargeSize: Math.round(16 * materialTypeScale)
  readonly property int typeTitleSmallSize: Math.round(14 * materialTypeScale)
  readonly property int typeTitleMediumSize: Math.round(16 * materialTypeScale)
  readonly property int typeTitleLargeSize: Math.round(22 * materialTypeScale)
  readonly property int typeHeadlineSmallSize: Math.round(24 * materialTypeScale)
  readonly property int typeHeadlineLargeSize: Math.round(32 * materialTypeScale)

  readonly property int typeLabelSmallLineHeight: Math.round(16 * materialTypeScale)
  readonly property int typeLabelMediumLineHeight: Math.round(16 * materialTypeScale)
  readonly property int typeBodySmallLineHeight: Math.round(16 * materialTypeScale)
  readonly property int typeBodyMediumLineHeight: Math.round(20 * materialTypeScale)
  readonly property int typeBodyLargeLineHeight: Math.round(24 * materialTypeScale)
  readonly property int typeTitleSmallLineHeight: Math.round(20 * materialTypeScale)
  readonly property int typeTitleLargeLineHeight: Math.round(28 * materialTypeScale)
  readonly property int typeHeadlineLargeLineHeight: Math.round(40 * materialTypeScale)

  // Qt expresses tracking in pixels. Keep display/headline tracking slightly
  // tight, leave body copy neutral, and give labels only a subtle separation.
  readonly property real typeHeadlineTracking: -0.2
  readonly property real typeTitleTracking: 0
  readonly property real typeBodyTracking: 0
  readonly property real typeLabelTracking: 0.1
  readonly property real typeMonoTracking: 0.8
  readonly property int typeMediumWeight: Font.Medium
  readonly property int typeStrongWeight: Font.Bold

  // Backward-compatible aliases used by older delegates. New UI should use
  // the named type roles above so hierarchy remains explicit at call sites.
  readonly property int textCaptionSize: typeLabelSmallSize
  readonly property int textBodySize: typeBodyMediumSize
  readonly property int textBodyLargeSize: typeBodyLargeSize
  readonly property int textTitleSize: typeTitleLargeSize
  readonly property int iconSizeSmall: Math.max(12, iconSize - 2)

  readonly property int shapeCompact: 8
  readonly property int shapeMedium: 12
  readonly property int shapeLarge: 20
  readonly property int settingsCardRadius: shapeLarge
  readonly property int borderRadius: shapeLarge
  readonly property int popupRadius: borderRadius
  readonly property int themeBorderWidth: 1
  readonly property int themeFocusBorderWidth: 2
  readonly property int themeLabeledActionButtonHeight: 48
  readonly property int themeOptionGap: spacingCompact
  readonly property int themeFontWeight: Font.Normal

  // Motion is centralized here. reducedMotion mirrors the persisted Settings
  // singleton directly; compatibility consumers continue using animationDuration.
  property bool reducedMotion: Settings.reduceMotion
  readonly property int motionShort: reducedMotion ? 0 : 60
  readonly property int motionMedium: reducedMotion ? 0 : 90
  readonly property int motionExtraLong: reducedMotion ? 0 : 220
  readonly property int animationDuration: motionMedium
  // Workspace geometry responds to selection with a little spring.
  readonly property real motionSpatialSpring: 8.0
  readonly property real motionSpatialDamping: 0.82
  readonly property real motionSpatialMass: 1.0
  readonly property real motionSpatialEpsilon: 0.01
  readonly property real motionEffectsSpring: 12.0
  // One entrance grammar shared by Settings, launcher and menus.
  readonly property real surfaceEntryScale: 0.985
  readonly property real surfaceEntryOffset: -6
  readonly property int controlMotionDuration: reducedMotion ? 0 : 150
  readonly property int transientFadeDuration: reducedMotion ? 0 : 300

  readonly property int popupWidth: 340
  // Shared label column for remote settings rows. Sized for the longest
  // current label while allowing larger type settings to preserve full text.
  readonly property int settingsRowLabelWidth: 120
  readonly property int volumeStep: 5
}
