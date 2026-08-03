// Compact icon-only action button: circular hover/press overlay around a
// single icon glyph. For close/refresh/nav/media-style controls scattered
// across popups as duplicated Rectangle + Text + MouseArea blocks.
import QtQuick
import "../../config"

Item {
  id: root

  property string iconLabel: ""
  property int size: 32
  property int iconSize: 18
  property color iconColor: Colors.fgSurface
  property color hoverColor: Qt.tint("transparent", Colors.hoverOverlay)
  property color pressColor: Qt.tint("transparent", Colors.pressOverlay)
  property bool enabled: true

  signal clicked(var mouse)

  implicitWidth: size
  implicitHeight: size

  Rectangle {
    anchors.fill: parent
    radius: root.size / 2
    color: !root.enabled ? "transparent"
      : (mouseArea.pressed ? root.pressColor : (mouseArea.containsMouse ? root.hoverColor : "transparent"))

    Behavior on color {
      ColorAnimation { duration: Config.animationDuration }
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.iconLabel
    color: root.iconColor
    opacity: root.enabled ? 1.0 : 0.38
    font.family: Config.iconFont
    font.pixelSize: root.iconSize
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) { root.clicked(mouse) }
  }
}
