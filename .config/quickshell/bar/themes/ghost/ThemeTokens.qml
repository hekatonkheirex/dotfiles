import QtQuick
import "../../../config"

QtObject {
  readonly property int controlRadius: 0
  readonly property int controlSmallRadius: 0
  readonly property int borderWidth: 1
  readonly property int focusBorderWidth: 2
  readonly property int shadowOffset: 0
  readonly property int contentVerticalOffset: 0
  readonly property string fontFamily: Config.fontFamily
  readonly property string monoFontFamily: Config.monoFontFamily
  readonly property color ink: Colors.styleInk
  readonly property color mutedInk: Colors.fgSurfaceVariant
  readonly property color surface: Colors.styleSurface
  readonly property color surfaceRaised: Colors.styleSurfaceRaised
  readonly property color controlSurface: Colors.styleControl
  readonly property color outline: Colors.styleOutlineStrong
  readonly property color accent: Colors.styleAccent
  readonly property color accentText: Colors.styleAccentText
  readonly property color focus: Colors.styleAccent
  readonly property color signalColor: Colors.destructive
}
