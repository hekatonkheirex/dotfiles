import QtQuick
import "../../config"
import "../../config/PowerMenuModel.js" as Model

// Six 29 S accent circles on a 4 S surface ring, each overlapping the last
// by 15 S, in her order x1, x3, x2, x6, x4, x5.
Row {
  leftPadding: Config.dp(16)
  spacing: -Config.dp(15)
  Repeater {
    model: Model.paletteAccents()
    Rectangle {
      objectName: "palette_" + index
      required property int index
      required property int modelData
      width: Config.dp(29) + 2 * Config.dp(4)
      height: width
      radius: width / 2
      color: Colors.surface
      Rectangle {
        anchors.centerIn: parent
        width: Config.dp(29)
        height: width
        radius: width / 2
        color: Colors.elenaAccent(parent.modelData)
      }
    }
  }
}
