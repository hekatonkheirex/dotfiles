// Tokens shared by the Nothing, Ghost, and dwm control implementations in this
// folder. Ghost is square HUD chrome; Nothing is rounded; dwm is flat and square. Everything that
// differs between the two lives here so the controls stay one file each.
import QtQuick
import "../../../config"

QtObject {
  readonly property bool ghost: Config.ghostTheme
  // dwm draws flat solid fills: no segments, no rounding.
  readonly property bool flat: Config.dwmTheme
  // Ghost and dwm draw no rounding anywhere; focus rings follow.
  readonly property bool square: ghost || flat
  readonly property int controlRadius: square ? 0 : 16
  readonly property int controlSmallRadius: square ? 0 : 16
  readonly property int borderWidth: 1
  readonly property int focusBorderWidth: 2
  readonly property int shadowOffset: 0
  readonly property int contentVerticalOffset: 0
  readonly property bool evolution: Config.nothingEvolution
  readonly property real surfaceAlpha: evolution ? Config.evolutionSurfaceAlpha : 1.0
  readonly property real raisedAlpha: evolution ? Config.evolutionRaisedAlpha : 1.0
  readonly property real controlAlpha: evolution ? Config.evolutionControlAlpha : 1.0
  readonly property bool translucent: evolution
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
  readonly property color focus: ghost ? Colors.styleAccent : Colors.primary
  readonly property color focusRing: ghost ? Colors.styleAccent : Colors.styleOutlineStrong
  readonly property color signalColor: ghost ? Colors.destructive : Colors.error
  // Slider meter: Ghost is a tight 24-cell scanline, Nothing 18 wider cells.
  readonly property int segmentCount: ghost ? 24 : 18
  readonly property real segmentGap: ghost ? 1 : 2
  readonly property real segmentRadius: ghost ? 0 : 1
  // Ghost marks active buttons with GITS corner-bracket registration ticks.
  readonly property bool registrationTicks: ghost
}
