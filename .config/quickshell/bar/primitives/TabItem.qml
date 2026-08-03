// Icon + label tab with an underline indicator, hover/press overlay, and a
// focus-ring container. Lifted out of CommandCenter's tab-bar Repeater
// delegate so future tab strips (e.g. a settings sub-nav) don't reinvent it.
import QtQuick
import "../../config"

Item {
  id: root

  property string iconLabel: ""
  property string labelText: ""
  property bool selected: false
  property real iconSize: 28
  property real labelSize: 13
  property real indicatorWidth: 48

  signal clicked()

  Column {
    anchors.centerIn: parent
    spacing: 4

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.iconLabel
      font.family: Config.iconFont
      font.pixelSize: root.iconSize
      color: root.selected ? Colors.primary : Colors.fgSurfaceVariant

      Behavior on color { ColorAnimation { duration: Config.motionMedium } }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.labelText
      font.family: Config.fontFamily
      font.pixelSize: root.labelSize
      font.weight: Font.Medium
      color: root.selected ? Colors.primary : Colors.fgSurfaceVariant

      Behavior on color { ColorAnimation { duration: Config.motionMedium } }
    }
  }

  // Active indicator line below the text
  Rectangle {
    width: root.indicatorWidth
    height: 3
    radius: 1.5
    color: Colors.primary
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    visible: root.selected
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: Config.shapeMedium
    color: tabMouse.pressed ? Colors.pressOverlay
      : (tabMouse.containsMouse ? Colors.hoverOverlay : "transparent")
  }

  MouseArea {
    id: tabMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
