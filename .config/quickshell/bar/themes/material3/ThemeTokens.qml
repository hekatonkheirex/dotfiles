import QtQuick
import "../../../config"

QtObject {
  readonly property int controlRadius: 12
  readonly property int controlSmallRadius: 8
  readonly property int borderWidth: 1
  readonly property int focusBorderWidth: 2
  readonly property int shadowOffset: 0
  readonly property string fontFamily: "Roboto Flex"
  readonly property color ink: Colors.fgSurface
  readonly property color mutedInk: Colors.fgSurfaceVariant
  readonly property color surface: Colors.surfaceContainer
  readonly property color surfaceRaised: Colors.surfaceContainerHigh
  readonly property color controlSurface: Colors.surfaceContainerHighest
  readonly property color outline: Colors.outline
  readonly property color accent: Colors.primary
  readonly property color accentText: Colors.fgPrimary
  readonly property color focus: Colors.primary
  readonly property color shadow: "transparent"
}
