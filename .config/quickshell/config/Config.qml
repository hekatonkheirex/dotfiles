pragma Singleton
import QtQml
import QtQuick
import Quickshell

QtObject {
  readonly property string wmType: "niri"
  readonly property bool isNiri: wmType === "niri"

  // Compact X390 geometry and shared spacing.
  readonly property int barWidth: 36
  readonly property int widgetSize: 36
  readonly property int padding: 6
  readonly property int spacingExtraSmall: 4
  readonly property int spacingSmall: 8
  readonly property int spacingMedium: 12
  readonly property int spacingLarge: 16
  readonly property int spacingExtraLarge: 24

  // M3 type roles. Existing aliases below remain for migrated components.
  readonly property int displayLargeSize: 36
  readonly property int headlineLargeSize: 28
  readonly property int headlineMediumSize: 24
  readonly property int titleLargeSize: 22
  readonly property int titleMediumSize: 16
  readonly property int bodyLargeSize: 16
  readonly property int bodyMediumSize: 14
  readonly property int bodySmallSize: 12
  readonly property int labelLargeSize: 14
  readonly property int labelMediumSize: 12
  readonly property int labelSmallSize: 9
  readonly property int lineHeightBody: 20
  readonly property int lineHeightLabel: 16

  readonly property string fontFamily: "Roboto Flex"
  readonly property string iconFont: "Material Symbols Outlined"
  readonly property int iconSize: 16
  readonly property int iconSizeSmall: 16
  readonly property int iconSizeLarge: 28
  readonly property int fontPixelSize: 9

  // Small shape scale for compact controls and expressive containers.
  readonly property int shapeCompact: 8
  readonly property int shapeMedium: 12
  readonly property int shapeLarge: 16
  readonly property int shapeFull: 999
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
  readonly property int commandCenterMaxWidth: 800
  readonly property int commandCenterMaxHeight: 606
  readonly property int commandCenterMinWidth: 640
  readonly property int commandCenterMinHeight: 480
  readonly property int clockIntervalMs: 1000
  readonly property int volumeStep: 5
  readonly property int brightnessStep: 5
  readonly property int notificationToastDurationMs: 5000
}
