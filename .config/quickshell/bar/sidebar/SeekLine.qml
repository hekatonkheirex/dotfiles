import QtQuick
import "../../config"
import "../../config/MediaMath.js" as MediaMath

// 20 vertical lines; line i is colored while fractionOfLine(i) <= fraction,
// and clicking it seeks to fractionOfLine(i) = (i + 1) / lines. That never
// reaches 0, so a click in the left 40 % of line 0 seeks to the start.
Row {
  id: root
  property real fraction: 0
  property int lines: 20
  signal seekRequested(real fraction)
  spacing: Config.dp(5)

  Repeater {
    model: root.lines
    Item {
      required property int index
      objectName: "seekCell" + index
      width: Config.dp(7)
      height: Config.dp(26)
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Config.dp(3)
        height: parent.height * (0.45 + 0.55 * Math.abs(Math.sin(index * 0.9)))
        radius: width / 2
        color: MediaMath.fractionOfLine(index, root.lines) <= root.fraction + 1e-9
          ? Colors.elenaAccent(5) : Colors.surfaceContainerHighest
      }
      MouseArea {
        anchors.fill: parent
        anchors.leftMargin: -Config.dp(2)
        anchors.rightMargin: -Config.dp(2)
        cursorShape: Qt.PointingHandCursor
        onClicked: function(m) {
          var f = (index === 0 && m.x < 0.4 * width) ? 0 : MediaMath.fractionOfLine(index, root.lines)
          root.seekRequested(f)
        }
      }
    }
  }
}
