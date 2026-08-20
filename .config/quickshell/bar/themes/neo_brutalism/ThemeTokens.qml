import QtQuick
import "../../../config"

QtObject {
  readonly property int controlRadius: 4
  readonly property int controlSmallRadius: 3
  readonly property int borderWidth: 3
  readonly property int focusBorderWidth: 4
  readonly property int shadowOffset: 6
  // Small optical correction without pushing either edge into the border.
  readonly property int contentVerticalOffset: -1
  readonly property string fontFamily: "JetBrains Mono"
  readonly property color ink: Colors.fgSurface
  readonly property color mutedInk: Colors.fgSurfaceVariant
  readonly property color surface: Colors.surfaceContainerLow
  readonly property color surfaceRaised: Colors.surfaceContainer
  readonly property color controlSurface: Colors.surfaceContainerHighest
  readonly property color outline: Colors.fgSurface
  readonly property color accent: Colors.darkMode ? Colors.primary : Colors.primaryContainer
  readonly property color accentText: Colors.darkMode ? Colors.fgPrimary : Colors.fgPrimaryContainer
  readonly property color focus: Colors.darkMode ? Colors.primary : Colors.primaryContainer
  readonly property color shadow: Colors.darkMode ? Colors.fgSurface : Colors.shadow
}
