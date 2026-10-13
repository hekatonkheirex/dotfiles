import QtQuick
import "../../config"
import "../primitives"

// Vertical level bar: click or drag the track to set the level; the icon
// underneath is a button (mute toggle for audio, inert for brightness).
Item {
  id: root

  property real value: 0
  property color accent: Colors.primary
  property string iconLabel: ""
  property bool muted: false
  property string accessibleName: ""

  signal moved(real value)
  signal iconClicked()

  implicitWidth: 40
  implicitHeight: 160

  Rectangle {
    id: track
    anchors.top: parent.top
    anchors.bottom: icon.top
    anchors.bottomMargin: Config.spacingSmall
    anchors.horizontalCenter: parent.horizontalCenter
    width: 18
    radius: width / 2
    color: Colors.surfaceContainerHighest

    Rectangle {
      anchors.bottom: parent.bottom
      visible: root.value > 0
      width: parent.width
      height: Math.max(parent.width, parent.height * Math.max(0, Math.min(1, root.value)))
      radius: width / 2
      color: root.muted ? Colors.outline : root.accent
    }

    MouseArea {
      anchors.fill: parent
      anchors.leftMargin: -10
      anchors.rightMargin: -10
      function setFrom(mouse) {
        var p = mapToItem(track, mouse.x, mouse.y)
        var v = Math.max(0, Math.min(1, 1 - p.y / track.height))
        // Skip sub-1% jitter so a drag does not spawn a process per pixel.
        if (Math.abs(v - root.value) >= 0.01) root.moved(v)
      }
      onPressed: function(mouse) { setFrom(mouse) }
      onPositionChanged: function(mouse) { if (pressed) setFrom(mouse) }
    }
  }

  IconButton {
    id: icon
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    size: 32
    iconSize: 18
    iconLabel: root.iconLabel
    accessibleName: root.accessibleName
    tooltipText: root.accessibleName
    onClicked: root.iconClicked()
  }
}
