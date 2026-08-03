import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"

Item {
  id: root


  property bool active: false
  property bool horizontal: false
  property string iconLabel: "settings"

  signal clicked(var mouse)

  Layout.preferredWidth: Config.widgetSize
  Layout.preferredHeight: Config.widgetSize

  Rectangle {
    id: bgOverlay
    anchors {
      fill: parent
      leftMargin: root.horizontal ? 0 : 6
      rightMargin: root.horizontal ? 0 : 6
      topMargin: root.horizontal ? 6 : 0
      bottomMargin: root.horizontal ? 6 : 0
    }
    radius: root.horizontal ? height / 2 : width / 2
    clip: true
    color: {
      var overlay = mouseArea.pressed ? Colors.pressOverlay : (mouseArea.containsMouse ? Colors.hoverOverlay : Qt.rgba(0, 0, 0, 0))
      return Qt.tint(root.active ? Colors.primary : Colors.surfaceContainerHigh, overlay)
    }
    border.color: {
      if (root.active) return "transparent"
      return Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
    }
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: Config.animationDuration}
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.iconLabel
    color: {
      if (root.active) return Colors.fgPrimary
      return Colors.primary
    }
    font.family: Config.iconFont
    font.pixelSize: Config.iconSize
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.clicked(mouse)
    }
  }
}
