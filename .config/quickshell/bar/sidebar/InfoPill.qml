import QtQuick
import "../../config"

// Her circular-symbol-with-text: disc, left text, then a 6 S x8 dot and the
// right text when present; 7 S right padding on an x0 pill.
Rectangle {
  id: pill
  property string glyph: ""
  property string glyphFamily: BottomBarFonts.family
  property string leftText: ""
  property string rightText: ""
  width: pillRow.implicitWidth + Config.dp(7)
  height: Config.dp(23)
  radius: height / 2
  color: Colors.surfaceContainerHighest
  Row {
    id: pillRow
    height: parent.height
    SymbolDisc { glyph: pill.glyph; family: pill.glyphFamily }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      leftPadding: Config.dp(6)
      visible: pill.leftText !== ""
      text: pill.leftText
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Math.round(9.5 * 4 / 3 * Config.elenaScale)
      font.weight: Font.Bold
    }
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      visible: pill.rightText !== "" && pill.leftText !== ""
      width: Config.dp(6) + 2 * Config.dp(6)
      height: Config.dp(6)
      color: "transparent"
      Rectangle { anchors.centerIn: parent; width: Config.dp(6); height: width; radius: width / 2; color: Colors.outline }
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: pill.rightText !== ""
      leftPadding: pill.leftText === "" ? Config.dp(6) : 0
      text: pill.rightText
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Math.round(9.5 * 4 / 3 * Config.elenaScale)
    }
  }
}
