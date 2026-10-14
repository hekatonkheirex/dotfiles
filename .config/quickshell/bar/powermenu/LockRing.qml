import QtQuick
import "../../config"
import "../../config/PowerMenuModel.js" as Model

// Her lock symbol: 47pt glyph in a round 6 S border, 12 S padding. The border
// color follows the last input action (PowerMenuModel.ringBorder); the glyph
// switches to the failed-auth symbol when authentication failed.
Rectangle {
  id: root
  property int inputLength: 0
  property string lastAction: "clear"
  property bool authFailed: false
  readonly property var ring: Model.ringBorder(root.inputLength, root.lastAction)

  width: Math.max(glyph.implicitWidth, glyph.implicitHeight) + 2 * (Config.dp(12) + Config.dp(6))
  height: width
  radius: width / 2
  color: "transparent"
  border.width: Config.dp(6)
  border.color: root.ring.kind === "accent" ? Colors.elenaAccent(root.ring.n)
    : root.ring.kind === "muted" ? Colors.elenaAccent(8)
    : root.ring.kind === "border" ? Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.3)
    : Colors.outlineVariant   // clear: her x0
  Behavior on border.color {
    enabled: !Config.reducedMotion
    ColorAnimation { duration: 300 }
  }

  Text {
    id: glyph
    objectName: "lockGlyph"
    anchors.centerIn: parent
    text: Model.glyph(root.authFailed ? "lockFailed" : "lockOpen")
    color: Colors.fgSurface
    font.family: BottomBarFonts.family
    font.pixelSize: Math.round(47 * 4 / 3 * Config.elenaScale)   // 47pt
  }
}
