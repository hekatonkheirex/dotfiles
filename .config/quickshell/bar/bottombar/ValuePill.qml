import QtQuick
import "../../config"

// Circle (or pill) holding a short value: the clock, the date.
Rectangle {
  id: root
  property string text: ""
  property int minWidth: Config.bottomBarDp(30)

  implicitHeight: Config.bottomBarDp(30)
  implicitWidth: Math.max(root.minWidth, label.implicitWidth + Config.bottomBarDp(6))
  radius: height / 2
  color: Colors.surfaceContainerHighest

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text
    color: Colors.fgSurface
    font.family: BottomBarFonts.textFamily
    font.pixelSize: Math.round(11 * 4 / 3 * Config.bottomBarScale)   // 11pt * scale
  }
}
