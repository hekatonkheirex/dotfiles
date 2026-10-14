import QtQuick
import "../../config"

// One alarms-window button (her .button): a tinted round tile holding either
// a symbol-font glyph or a short text. `dim` shows it disabled (x8) without
// blocking clicks, as hers; `enabled: false` blocks them.
Rectangle {
  id: root
  property string glyph: ""
  property string text: ""
  property int accent: 6
  property bool dim: false
  property color fill: Colors.surfaceContainer
  property int glyphPt: 10
  property int textPt: 8
  readonly property alias label: label
  signal clicked()

  color: root.fill
  radius: Math.min(width, height) / 2

  Text {
    id: label
    objectName: "symbol"
    anchors.centerIn: parent
    text: root.glyph !== "" ? root.glyph : root.text
    color: Colors.elenaAccent(root.dim ? 8 : root.accent)
    font.family: root.glyph !== "" ? BottomBarFonts.family : Config.fontFamily
    font.pixelSize: Math.round((root.glyph !== "" ? root.glyphPt : root.textPt) * 4 / 3 * Config.elenaScale)
    font.weight: root.glyph !== "" ? Font.Normal : Font.Bold
    Behavior on color {
      enabled: !Config.reducedMotion
      ColorAnimation { duration: 300 }
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
