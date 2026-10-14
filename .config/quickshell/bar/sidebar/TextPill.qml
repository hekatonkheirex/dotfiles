import QtQuick
import "../../config"

// Her circular-symbol-with-text for title and artist, inside a sideways
// scroll so a long name never widens the page.
Flickable {
  id: scroller
  property string glyph: ""
  property string text: ""
  property bool bold: false
  width: Math.min(contentWidth, Config.dp(300 - 2 * 27))
  height: Config.dp(23)
  clip: true
  contentWidth: pill.width
  contentHeight: height
  flickableDirection: Flickable.HorizontalFlick
  boundsBehavior: Flickable.StopAtBounds
  Rectangle {
    id: pill
    width: pillRow.implicitWidth + Config.dp(7)
    height: Config.dp(23)
    radius: height / 2
    color: Colors.surfaceContainerHighest
    Row {
      id: pillRow
      height: parent.height
      SymbolDisc { glyph: scroller.glyph }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: Config.dp(6)
        text: scroller.text
        color: scroller.bold ? Colors.fgSurface : Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Math.round(9.5 * 4 / 3 * Config.elenaScale)
        font.weight: scroller.bold ? Font.Bold : Font.Normal
      }
    }
  }
}
