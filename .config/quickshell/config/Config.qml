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

  readonly property string fontFamily: "Roboto Flex"
  readonly property string iconFont: "Material Symbols Outlined"
  property int iconSize: Settings.iconSize
  property int fontPixelSize: Settings.fontPixelSize
  readonly property int textCaptionSize: Math.max(8, fontPixelSize - 1)
  readonly property int textBodySize: fontPixelSize + 1
  readonly property int textBodyLargeSize: fontPixelSize + 3
  readonly property int textTitleSize: fontPixelSize + 5
  readonly property int textHeadlineSize: fontPixelSize + 8
  readonly property int iconSizeSmall: Math.max(12, iconSize - 2)

  // M3 type role currently consumed by the focused-window metadata.
  readonly property int labelSmallSize: fontPixelSize
  readonly property int clockPrimarySize: fontPixelSize + 6
  readonly property int clockSecondarySize: fontPixelSize + 1
  readonly property int clockLineSpacing: spacingCompact
  readonly property int clockVerticalHeight: 42

  // Small shape scale for compact controls and expressive containers.
  readonly property int shapeCompact: 8
  readonly property int shapeMedium: 12
  readonly property int shapeLarge: 16
  readonly property int borderRadius: shapeLarge

  // Motion is centralized here. reducedMotion mirrors the persisted Settings
  // singleton directly; compatibility consumers continue using animationDuration.
  property bool reducedMotion: Settings.reduceMotion
  readonly property int motionShort: reducedMotion ? 0 : 100
  readonly property int motionMedium: reducedMotion ? 0 : 150
  readonly property int motionLong: reducedMotion ? 0 : 250
  readonly property int motionExtraLong: reducedMotion ? 0 : 450
  readonly property int animationDuration: motionMedium

  readonly property int popupWidth: 340
  readonly property int popupPadding: spacingLarge
  readonly property int commandCenterMinWidth: 320
  readonly property int commandCenterMinHeight: 360
  readonly property int commandCenterMaxWidth: 800
  readonly property int commandCenterMaxHeight: 606
  readonly property int clockIntervalMs: 1000
  readonly property int volumeStep: 5
  readonly property int brightnessStep: 5
}
