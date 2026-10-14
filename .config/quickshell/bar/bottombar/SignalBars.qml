import QtQuick
import "../../config"
import "../../config/BottomBarModel.js" as BottomBarModel

// Four vertical bars growing left to right; all four collapse to short muted
// bars when there is no active Wi-Fi network.
Row {
  id: root
  property int signal: 0
  property bool connected: false
  property color activeColor: Colors.elenaAccent(4)

  spacing: Config.bottomBarDp(8 / 3)
  readonly property var parts: BottomBarModel.signalParts(root.signal, root.connected)
  // Heights: 23-16, 23-10.5, 23-5.5, 23 (scaled); disconnected: 23-17.
  readonly property var heights: [Config.bottomBarDp(7), Config.bottomBarDp(12.5), Config.bottomBarDp(17.5), Config.bottomBarDp(23)]

  Repeater {
    model: root.parts
    Item {
      required property string modelData
      required property int index
      width: Config.bottomBarDp(5)
      height: Config.bottomBarDp(23)
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: modelData === "disconnected" ? Config.bottomBarDp(6) : root.heights[index]
        radius: width / 2
        color: modelData === "active" ? root.activeColor
          : (modelData === "disconnected" ? Colors.elenaAccent(8) : Colors.surfaceContainerHighest)
      }
    }
  }
}
