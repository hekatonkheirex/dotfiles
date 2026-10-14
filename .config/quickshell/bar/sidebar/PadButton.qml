import QtQuick
import "../../config"

// One arm of the cross or a round side button: left and right click
// signals; the glyph sits `glyphDx/Dy` off center (her symbol margins).
Rectangle {
  id: pad
  property string glyph: ""
  property color glyphColor: Colors.elenaAccent(5)
  property real glyphDx: 0
  property real glyphDy: 0
  signal leftClicked()
  signal rightClicked()
  color: Colors.surfaceContainerHighest
  Text {
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: pad.glyphDx
    anchors.verticalCenterOffset: pad.glyphDy
    text: pad.glyph
    color: pad.glyphColor
    font.family: BottomBarFonts.family
    font.pixelSize: Math.round(10 * 4 / 3 * Config.elenaScale)
  }
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(m) { if (m.button === Qt.RightButton) pad.rightClicked(); else pad.leftClicked() }
  }
}
