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
  // UI style is separate from the desktop palette. Material 3 and Liquid
  // Glass consume Matugen roles; Nothing Classic and Ghost use authored
  // palettes, while Nothing Evolution uses the adaptive cache.
  readonly property bool nothingDesign: Settings.themeStyle === "nothing"
  readonly property bool nothingEvolution: nothingDesign && Settings.nothingVariant === "evolution"
  readonly property bool ghostTheme: Settings.themeStyle === "ghost"
  readonly property bool liquidGlassTheme: Settings.themeStyle === "liquid-glass"
  readonly property bool material3Theme: !nothingDesign && !ghostTheme && !liquidGlassTheme

  // Liquid Glass transient surfaces retain compositor glass blur, except
  // the full-screen click-outside shield, which Niri excludes explicitly.
  // The persistent bar stays on the standard panel namespace. The lock
  // surface owns its own full-screen wallpaper blur.
  function layerNamespace(kind) {
    return liquidGlassTheme && kind !== "panel"
      ? "quickshell-liquid-glass-" + kind
      : "quickshell-" + kind
  }

  // Compact X390 geometry and shared spacing used by active surfaces.
  // Live-adjustable via the Appearance settings tab's Bar Size slider.
  // Ghost uses the same selected thickness as other styles; its geometry
  // stays square rather than capping the rail at 34px.
  readonly property int barWidth: Settings.barSize
  readonly property int widgetSize: barWidth
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

  // Classic keeps its NType display and mono labels, but uses a readable
  // sans for dense settings copy instead of setting paragraphs in display type.
  readonly property string fontFamily: nothingEvolution
    ? "Geist"
    : (nothingDesign ? "Noto Sans" : (ghostTheme ? "JetBrains Mono" : "Roboto Flex"))
  readonly property string monoFontFamily: nothingEvolution
    ? "Geist Mono"
    : (nothingDesign ? "NType 82 Mono" : (ghostTheme ? "JetBrains Mono" : "Roboto Flex"))
  readonly property string displayFontFamily: nothingEvolution
    ? "Geist"
    : (nothingDesign ? "NType 82 Headline" : fontFamily)
  // Evolution dials dot-matrix typography back to intentional accent areas;
  // compact clocks and numeric readouts use Geist Mono instead.
  readonly property string dotFontFamily: nothingEvolution
    ? "Geist Mono"
    : (nothingDesign ? "Ndot 57" : displayFontFamily)
  // Material 3 and Ghost use outlined icons; Nothing uses rounded symbols.
  // Liquid Glass uses SF glyphs from the locally installed SF Pro Text font.
  readonly property string iconFont: nothingDesign ? "Material Symbols Rounded" : "Material Symbols Outlined"
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

  readonly property string sfSymbolsFont: "SF Pro Text"

  property int iconSize: Settings.iconSize
  property int fontPixelSize: Settings.fontPixelSize

  // Compact Material 3 type roles. The shell is a resizable desktop surface,
  // so these keep the current laptop density while preserving the hierarchy
  // and naming of the M3 type scale. Use weight and line height to express
  // emphasis; do not make every setting row compete with its page heading.
  readonly property int typeLabelSmallSize: nothingDesign && !nothingEvolution
    ? Math.max(12, fontPixelSize) : Math.max(8, fontPixelSize - 1)
  readonly property int typeLabelMediumSize: fontPixelSize + (ghostTheme ? 1 : 0)
  readonly property int typeLabelLargeSize: fontPixelSize + 2
  readonly property int typeBodySmallSize: nothingDesign && !nothingEvolution
    ? Math.max(12, fontPixelSize) : Math.max(10, fontPixelSize - 1)
  readonly property int typeBodyMediumSize: fontPixelSize + (ghostTheme ? 2 : 1)
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

  // Nothing uses soft corners; Liquid Glass uses restrained macOS-like
  // geometry. Ghost keeps its square HUD panels.
  readonly property int shapeCompact: ghostTheme ? 0 : (liquidGlassTheme ? 6 : (nothingEvolution ? 10 : (nothingDesign ? 8 : 8)))
  readonly property int shapeMedium: ghostTheme ? 0 : (liquidGlassTheme ? 10 : (nothingEvolution ? 18 : (nothingDesign ? 14 : 12)))
  readonly property int shapeLarge: ghostTheme ? 0 : (liquidGlassTheme ? 16 : (nothingEvolution ? 24 : (nothingDesign ? 20 : 16)))
  // Keep Settings cards nested within the Evolution window's larger corners.
  readonly property int settingsCardRadius: nothingEvolution ? shapeMedium : shapeLarge
  readonly property int borderRadius: shapeLarge
  readonly property int popupRadius: liquidGlassTheme ? 10 : borderRadius
  readonly property int barRadius: liquidGlassTheme
    ? shapeLarge
    : (nothingEvolution ? shapeMedium : ((nothingDesign || ghostTheme) ? 0 : borderRadius))
  readonly property int themeBorderWidth: 1
  readonly property int themeFocusBorderWidth: 2
  readonly property int themeLabeledActionButtonHeight: (nothingDesign || ghostTheme) ? 64 : 48
  readonly property int themeOptionGap: nothingEvolution || liquidGlassTheme ? spacingSmall : spacingCompact
  readonly property int themeFontWeight: nothingEvolution || liquidGlassTheme
    ? Font.Medium : (nothingDesign ? Font.Medium : Font.Normal)

  // Motion is centralized here. reducedMotion mirrors the persisted Settings
  // singleton directly; compatibility consumers continue using animationDuration.
  property bool reducedMotion: Settings.reduceMotion
  readonly property int motionShort: reducedMotion ? 0 : 60
  readonly property int motionMedium: reducedMotion ? 0 : 90
  readonly property int motionLong: reducedMotion ? 0 : 140
  readonly property int motionExtraLong: reducedMotion ? 0 : 220
  readonly property int animationDuration: motionMedium
  // Workspace geometry responds to selection. Material can settle with a
  // little spring, while Nothing and Ghost stop sharply and glass stays soft.
  readonly property bool spatialMotion: !nothingDesign && !ghostTheme
  readonly property bool expressiveMotion: spatialMotion && !liquidGlassTheme
  readonly property real motionSpatialSpring: ghostTheme ? 24.0
    : (nothingDesign ? 18.0 : (liquidGlassTheme ? 11.0 : 8.0))
  readonly property real motionSpatialDamping: material3Theme ? 0.82 : 1.0
  readonly property real motionSpatialMass: 1.0
  readonly property real motionSpatialEpsilon: 0.01
  // One entrance grammar per style, shared by Settings, launcher and menus.
  readonly property real surfaceEntryScale: ghostTheme || (nothingDesign && !nothingEvolution)
    ? 1.0 : (nothingEvolution ? 0.98 : (liquidGlassTheme ? 0.97 : 0.90))
  readonly property real surfaceEntryOffset: ghostTheme ? -8
    : (nothingDesign ? -12 : (liquidGlassTheme ? -10 : -20))
  readonly property int surfaceEntryDuration: reducedMotion ? 0
    : (ghostTheme ? 90 : (nothingDesign ? (nothingEvolution ? 120 : 100)
      : (liquidGlassTheme ? 160 : 190)))
  readonly property int surfaceOpacityDuration: reducedMotion ? 0
    : (ghostTheme ? 80 : (nothingDesign ? 95 : (liquidGlassTheme ? 110 : 140)))
  readonly property real toastEntryScale: ghostTheme || (nothingDesign && !nothingEvolution)
    ? 1.0 : (nothingEvolution ? 0.98 : (liquidGlassTheme ? 0.98 : 0.92))
  readonly property real toastEntryOffset: ghostTheme ? 14
    : (nothingDesign ? 22 : (liquidGlassTheme ? 18 : 32))
  readonly property int toastEntryDuration: reducedMotion ? 0
    : (ghostTheme ? 100 : (nothingDesign ? 120 : (liquidGlassTheme ? 160 : 190)))
  // Reduced motion keeps a short opacity-only acknowledgement for Liquid
  // Glass, while removing spatial movement, scale, and decorative morphs.
  readonly property int reducedMotionFadeDuration: liquidGlassTheme && reducedMotion ? 80 : 0
  readonly property int controlMotionDuration: liquidGlassTheme
    ? (reducedMotion ? 0 : 120)
    : (reducedMotion ? 0 : 150)
  readonly property int transientFadeDuration: liquidGlassTheme
    ? (reducedMotion ? reducedMotionFadeDuration : 160)
    : (reducedMotion ? 0 : 300)
  // Surface entrances use concise, theme-aware easing; interactive controls
  // keep their own shorter motion tokens.
  readonly property int themeMotionEasing: (nothingDesign || ghostTheme || liquidGlassTheme)
    ? Easing.OutCubic
    : Easing.OutBack
  readonly property real evolutionSurfaceAlpha: 0.86
  readonly property real evolutionRaisedAlpha: 0.92
  readonly property real evolutionControlAlpha: 0.86

  readonly property int popupWidth: 340
  readonly property int launcherWidth: 460
  readonly property int popupPadding: spacingLarge
  readonly property int settingsMinWidth: 560
  readonly property int settingsMinHeight: 360
  // Shared label column for remote settings rows. Sized for the longest
  // current label while allowing larger type settings to preserve full text.
  readonly property int settingsRowLabelWidth: 200
  readonly property int settingsMaxWidth: 1100
  readonly property int settingsDefaultWidth: 1100
  readonly property int settingsDefaultHeight: 900
  readonly property int volumeStep: 5
  readonly property int brightnessStep: 5
}
