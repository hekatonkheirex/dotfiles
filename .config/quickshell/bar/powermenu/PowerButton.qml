import QtQuick
import "../../config"
import "../../config/PowerMenuModel.js" as Model

// One power button: a 54 S square with her 30pt icon glyph. Muted outline at
// 0.6 until `revealed`, then the accent slot fades in after a stagger of
// 0.1 s per position; `dimmed` drops it to 0.3 while another one is selected.
Item {
  id: root
  property string buttonId: ""
  property int accent: 4
  property int order: 0
  property bool revealed: false
  property bool dimmed: false

  signal entered()
  signal exited()
  signal clicked()

  implicitWidth: Config.dp(54)
  implicitHeight: Config.dp(54)
  opacity: root.dimmed ? 0.3 : 1
  Behavior on opacity {
    enabled: !Config.reducedMotion
    NumberAnimation { duration: 400 }
  }

  Text {
    anchors.centerIn: parent
    text: Model.glyph(root.buttonId)
    font.family: BottomBarFonts.family
    font.pixelSize: Math.round(30 * 4 / 3 * Config.elenaScale)   // 30pt
    color: root.revealed ? Colors.elenaAccent(root.accent)
      : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.6)
    Behavior on color {
      enabled: !Config.reducedMotion
      SequentialAnimation {
        PauseAnimation { duration: 100 * (root.order + 1) }
        ColorAnimation { duration: 500 }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: root.entered()
    onExited: root.exited()
    onClicked: root.clicked()
  }
}
