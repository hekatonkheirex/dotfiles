import QtQuick
import "../../config"

// Her bandwidth row: down arrow x1 and up arrow x2, each half centered,
// MB/s text in monospace 14pt.
Row {
  id: root
  property string downText: ""
  property string upText: ""

  Repeater {
    model: 2
    Item {
      id: half
      required property int index
      readonly property bool up: half.index === 1
      width: root.width / 2
      height: pair.implicitHeight
      Row {
        id: pair
        anchors.centerIn: parent
        spacing: Config.dp(3)
        Text {
          objectName: half.up ? "bandUpSymbol" : "bandDownSymbol"
          anchors.verticalCenter: parent.verticalCenter
          text: half.up ? "" : ""
          color: Colors.elenaAccent(half.up ? 2 : 1)
          font.family: BottomBarFonts.materialFamily
          font.pixelSize: Math.round(17 * 4 / 3 * Config.elenaScale)   // 17pt
        }
        Text {
          objectName: half.up ? "bandUpText" : "bandDownText"
          anchors.verticalCenter: parent.verticalCenter
          text: half.up ? root.upText : root.downText
          color: Colors.fgSurface
          font.family: "monospace"
          font.pixelSize: Math.round(14 * 4 / 3 * Config.elenaScale)   // 14pt
        }
      }
    }
  }
}
