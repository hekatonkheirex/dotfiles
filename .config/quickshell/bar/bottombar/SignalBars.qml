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

  spacing: 4
  readonly property var parts: BottomBarModel.signalParts(root.signal, root.connected)
  // Heights: 23-16, 23-10.5, 23-5.5, 23 (scaled); disconnected: 23-17.
  readonly property var heights: [Config.dp(7), Config.dp(12.5), Config.dp(17.5), Config.dp(23)]

  Repeater {
    model: root.parts
    Item {
      required property string modelData
      required property int index
      width: Config.dp(5)
      height: Config.dp(23)
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: modelData === "disconnected" ? Config.dp(6) : root.heights[index]
        radius: width / 2
        color: modelData === "active" ? root.activeColor
          : (modelData === "disconnected" ? Colors.elenaAccent(8) : Colors.surfaceContainerHighest)
      }
    }
  }
}
