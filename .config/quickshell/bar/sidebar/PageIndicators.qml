import QtQuick
import "../../config"
import "../../config/SidebarPages.js" as SidebarPages

// Her page dots under a separator: x1, x2, x5 pills, the selected one wider.
// Click selects a page; the wheel anywhere over the section steps pages.
Item {
  id: root
  property int currentPage: 0
  property int count: 3
  signal pageSelected(int page)
  signal pageScrolled(int deltaY)
  implicitHeight: column.implicitHeight

  MouseArea {   // wheel anywhere over the section (under the dots' clicks)
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    onWheel: function(w) { root.pageScrolled(w.angleDelta.y) }
  }

  Column {
    id: column
    width: parent.width
    spacing: Config.dp(20)

    Rectangle {   // separator
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width - 2 * Config.dp(34)
      height: Config.dp(8)
      radius: height / 2
      color: Colors.surfaceContainerHighest
    }
    Row {
      id: dots
      objectName: "pageDots"
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.dp(12)
      Repeater {
        model: root.count
        Rectangle {
          required property int index
          readonly property bool selected: index === root.currentPage
          width: Config.dp(SidebarPages.indicatorWidth(selected))
          height: Config.dp(14)
          radius: height / 2
          color: Colors.elenaAccent(index === 0 ? 1 : (index === 1 ? 2 : 5))
          opacity: selected ? 1 : 0.3
          Behavior on width { enabled: !Config.reducedMotion; NumberAnimation { duration: 150 } }
          MouseArea {
            anchors.fill: parent
            anchors.margins: -Config.dp(6)
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pageSelected(index)
          }
        }
      }
    }
  }
}
