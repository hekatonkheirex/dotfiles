// Square toggle-style action tile: filled when selected, tonal container
// otherwise, with hover overlay, keyboard activation (Space/Enter), and a
// focus ring. Lifted out of QuickMenu's four near-identical layout/wallpaper/
// idle/theme toggle tiles.
import QtQuick
import "../../config"

Rectangle {
  id: root

  property string iconLabel: ""
  property bool selected: false
  property real iconSize: Config.iconSize + 4
  property color iconColor: root.selected ? Colors.fgPrimary : Colors.fgSurfaceVariant

  signal activated()

  radius: 20
  activeFocusOnTab: true
  color: {
    var overlay = mouseArea.containsMouse ? Colors.hoverOverlay : Qt.rgba(0, 0, 0, 0)
    return Qt.tint(root.selected ? Colors.primary : Colors.surfaceContainer, overlay)
  }
  border.color: root.selected ? "transparent" : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
  border.width: 1

  Behavior on color {
    ColorAnimation { duration: Config.animationDuration }
  }

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.activated()
      event.accepted = true
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.iconLabel
    color: root.iconColor
    font.family: Config.iconFont
    font.pixelSize: root.iconSize
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.forceActiveFocus()
      root.activated()
    }
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: root.radius + 4
    color: "transparent"
    border.width: root.activeFocus ? 2 : 0
    border.color: Colors.primary
    visible: root.activeFocus
  }
}
