import QtQuick
import "../../config"

// Her calendar-controls: month arrows left of the month/year block, year
// arrows right of it; the up arrow is next (later), the down arrow previous.
Column {
  id: arrows
  property int months: 1
  signal stepped(int months)
  anchors.verticalCenter: parent.verticalCenter
  spacing: Config.dp(4)
  Repeater {
    model: [[1, "\ue923"], [-1, "\ue920"]]   // up = later, down = earlier
    Text {
      required property int index
      required property var modelData
      objectName: (arrows.months === 1 ? "month" : "year") + (index === 0 ? "Up" : "Down")
      text: modelData[1]
      color: arrow.containsMouse ? Colors.elenaAccent(2) : Colors.fgSurfaceVariant
      font.family: BottomBarFonts.family
      font.pixelSize: Config.dp(12)
      MouseArea {
        id: arrow
        anchors.fill: parent
        anchors.margins: -Config.dp(3)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: arrows.stepped(parent.modelData[0] * arrows.months)
      }
    }
  }
}
