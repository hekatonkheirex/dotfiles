import QtQuick
import "../../../config"

QtObject {
  readonly property int controlRadius: 12
  readonly property int controlSmallRadius: 8
  readonly property int borderWidth: 1
  readonly property int focusBorderWidth: 2
  readonly property int shadowOffset: 0
  readonly property string fontFamily: "Roboto Flex"
  // Keep the Material 3 role vocabulary available to every concrete control.
  // The older ink/accent names remain as small compatibility aliases.
  readonly property color ink: Colors.fgSurface
  readonly property color mutedInk: Colors.fgSurfaceVariant
  readonly property color surface: Colors.surface
  readonly property color surfaceContainerLowest: Colors.surfaceContainerLowest
  readonly property color surfaceContainerLow: Colors.surfaceContainerLow
  readonly property color surfaceContainer: Colors.surfaceContainer
  readonly property color surfaceContainerHigh: Colors.surfaceContainerHigh
  readonly property color surfaceContainerHighest: Colors.surfaceContainerHighest
  readonly property color surfaceVariant: Colors.surfaceVariant
  readonly property color surfaceRaised: Colors.surfaceContainerHigh
  readonly property color controlSurface: Colors.surfaceContainerHighest
  readonly property color outline: Colors.outline
  readonly property color outlineVariant: Colors.outlineVariant
  readonly property color primary: Colors.primary
  readonly property color primaryContent: Colors.fgPrimary
  readonly property color primaryContainer: Colors.primaryContainer
  readonly property color primaryContainerContent: Colors.fgPrimaryContainer
  readonly property color secondary: Colors.secondary
  readonly property color secondaryContent: Colors.fgSecondary
  readonly property color secondaryContainer: Colors.secondaryContainer
  readonly property color secondaryContainerContent: Colors.fgSecondaryContainer
  readonly property color tertiary: Colors.tertiary
  readonly property color tertiaryContent: Colors.fgTertiary
  readonly property color tertiaryContainer: Colors.tertiaryContainer
  readonly property color tertiaryContainerContent: Colors.fgTertiaryContainer
  readonly property color error: Colors.error
  readonly property color errorContent: Colors.fgError
  readonly property color errorContainer: Colors.errorContainer
  readonly property color errorContainerContent: Colors.fgErrorContainer
  readonly property color inverseSurface: Colors.inverseSurface
  readonly property color inverseOnSurface: Colors.inverseOnSurface
  readonly property color inversePrimary: Colors.inversePrimary
  readonly property color shadowColor: Colors.shadow
  readonly property color scrim: Colors.scrim
  readonly property color accent: Colors.primary
  readonly property color accentText: Colors.fgPrimary
  readonly property color focus: Colors.primary
  readonly property color shadow: Colors.shadow
}
