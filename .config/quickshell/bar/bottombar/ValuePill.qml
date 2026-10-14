import QtQuick
import "../../config"

// Circle (or pill) holding a short value: the clock, the date, the alarm count.
Rectangle {
  id: root
  property string text: ""
  property int minWidth: Config.bottomBarDp(23)

  implicitHeight: Config.bottomBarDp(23)
  implicitWidth: Math.max(root.minWidth, label.implicitWidth + Config.bottomBarDp(8))
  radius: height / 2
  color: Colors.surfaceContainerHighest

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text
    color: Colors.fgSurface
    font.family: BottomBarFonts.textFamily
    font.pixelSize: Math.round(8 * 4 / 3 * Config.bottomBarScale)   // 8pt * scale
  }
}
