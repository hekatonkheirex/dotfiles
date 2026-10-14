import QtQuick
import "../../config"

// One bottom-bar button: accent glyph, optional content to its right, and a
// 3 S bottom border in the accent while hovered.
Item {
  id: root

  property string symbol: ""
  property color accent: Colors.primary
  property bool forceHover: false
  default property alias content: contentRow.data
  readonly property bool hovered: mouse.containsMouse || root.forceHover

  signal clicked()
  signal rightClicked()
  signal middleClicked()
  signal wheel(int delta)

  implicitWidth: Config.bottomBarDp(67)
  implicitHeight: Config.bottomBarHeight

  Row {
    anchors.centerIn: parent
    spacing: Config.bottomBarDp(10)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.symbol
      color: root.accent
      font.family: BottomBarFonts.family
      font.pixelSize: Math.round(12 * 4 / 3 * Config.bottomBarScale)   // 12pt * scale
    }
    Row {
      id: contentRow
      anchors.verticalCenter: parent.verticalCenter
      spacing: Config.bottomBarDp(10)
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Config.bottomBarDp(3)
    color: root.hovered ? root.accent : "transparent"
    Behavior on color {
      enabled: !Config.reducedMotion
      ColorAnimation { duration: 300 }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(m) {
      if (m.button === Qt.RightButton) root.rightClicked()
      else if (m.button === Qt.MiddleButton) root.middleClicked()
      else root.clicked()
    }
    onWheel: function(w) { root.wheel(w.angleDelta.y) }
  }
}
