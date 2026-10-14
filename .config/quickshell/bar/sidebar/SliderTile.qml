import QtQuick
import Quickshell.Widgets
import "../../config"

// Her slider tile: 64 S square, fill rising from the bottom, a round label
// glyph at the bottom-right that shows the value on hover. The trough is a
// ClippingRectangle because Item.clip ignores the rounded corners.
Item {
  id: root

  property real value: 0            // 0..100, -1 = unavailable
  property color accent: Colors.primary
  property string glyph: ""
  property string valueText: ""
  property bool interactive: false
  property bool muted: false

  signal moved(real value)

  readonly property real level: root.value < 0 ? 0 : Math.max(0, Math.min(100, root.value))
  implicitWidth: Config.dp(64) + Config.dp(12)
  implicitHeight: Config.dp(64) + Config.dp(12)
  opacity: root.value < 0 ? 0.45 : 1

  ClippingRectangle {
    id: trough
    anchors.centerIn: parent
    width: Config.dp(64)
    height: Config.dp(64)
    radius: Config.dp(23)
    color: Colors.surfaceContainerHighest

    Rectangle {
      objectName: "tileFill"
      anchors.bottom: parent.bottom
      width: parent.width
      height: parent.height * root.level / 100
      color: root.muted ? Colors.elenaAccent(8) : root.accent
      // Square top corners under 70 %, rounded (her no-round class) above.
      radius: root.level >= 70 ? Config.dp(3) : 0
      Behavior on height {
        enabled: !Config.reducedMotion
        NumberAnimation { duration: 300 }
      }
    }
  }

  MouseArea {
    anchors.fill: trough
    enabled: root.interactive && root.value >= 0
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    function setFrom(mouse) {
      root.moved(Math.max(0, Math.min(100, 100 * (1 - mouse.y / height))))
    }
    onPressed: function(m) { setFrom(m) }
    onPositionChanged: function(m) { if (pressed) setFrom(m) }
  }

  // Her slider-with-label: the round label sits 9 S in from the trough's
  // bottom-right corner; hovering the tile grows it (150 ms) to 64 - 18 S and
  // swaps the glyph for the value at 11pt.
  HoverHandler { id: hover }
  SymbolDisc {
    id: label
    objectName: "tileLabel"
    x: trough.x + trough.width - width - Config.dp(9)
    y: trough.y + trough.height - height - Config.dp(9)
    width: hover.hovered ? Config.dp(64 - 18) : Config.dp(23)
    glyph: root.glyph
    glyphOpacity: hover.hovered ? 0 : 1
    Behavior on width { enabled: !Config.reducedMotion; NumberAnimation { duration: 150 } }
    Text {
      anchors.centerIn: parent
      opacity: hover.hovered ? 1 : 0
      text: root.valueText
      color: Colors.surface
      font.family: Config.fontFamily
      font.pixelSize: Math.round(11 * 4 / 3 * Config.elenaScale)   // 11pt
    }
  }
}
