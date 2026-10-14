import QtQuick
import "../../config"

// Her circular-symbol-icon: a 23 S foreground-colored disc with the glyph in
// the background color, centered. `family` switches to Material Symbols for
// the weather icon.
Rectangle {
  id: root
  property string glyph: ""
  property string family: BottomBarFonts.family
  property real glyphSize: Math.round(9.5 * 4 / 3 * Config.elenaScale)   // 9.5pt
  property alias glyphOpacity: glyphText.opacity
  implicitWidth: Config.dp(23)
  implicitHeight: implicitWidth
  width: implicitWidth
  height: width
  radius: width / 2
  color: Colors.fgSurface

  Text {
    id: glyphText
    anchors.centerIn: parent
    text: root.glyph
    color: Colors.surface
    font.family: root.family
    font.pixelSize: root.glyphSize
  }
}
