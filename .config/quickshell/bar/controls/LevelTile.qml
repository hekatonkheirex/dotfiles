import QtQuick
import "../../config"
import "../primitives"

// Liquid level tile: squircle that fills from the bottom, white round icon.
Item {
  id: root
  property real value: 0
  property color accent: Colors.primary
  property string iconLabel: ""
  property bool muted: false
  property string accessibleName: ""
  signal moved(real value)
  signal iconClicked()

  implicitWidth: 58
  implicitHeight: 58
  opacity: enabled ? 1 : 0.38

  Rectangle {
    id: tile
    anchors.fill: parent
    radius: Config.shapeLarge
    color: Colors.surfaceContainerHighest
    // clip only cuts to the bounding box, so the fill is a full-height rounded
    // rect inside a box of fill height: the bottom corners follow the radius.
    Item {
      anchors.bottom: parent.bottom
      width: parent.width
      height: parent.height * Math.max(0, Math.min(1, root.value))
      clip: true
      Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: tile.height
        radius: tile.radius
        color: root.muted ? Colors.outline : root.accent
      }
    }
  }
  MouseArea {
    anchors.fill: parent
    enabled: root.enabled
    function setFrom(mouse) {
      var v = Math.max(0, Math.min(1, 1 - mouse.y / height))
      // Skip sub-1% jitter so a drag does not spawn a process per pixel.
      if (Math.abs(v - root.value) >= 0.01) root.moved(v)
    }
    onPressed: function(mouse) { setFrom(mouse) }
    onPositionChanged: function(mouse) { if (pressed) setFrom(mouse) }
  }
  // Real IconButton: focus, Space/Enter, tooltip and accessibility come with
  // it. The white round stays 26px; the hit box is wider and 48px tall,
  // centered on the same point as before (21px above the tile bottom).
  IconButton {
    objectName: "badge"
    visible: root.iconLabel !== ""
    width: root.width
    height: Config.controlHitSize
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 21 - Config.controlHitSize / 2
    size: 26
    iconSize: 16
    variant: "round"
    iconLabel: root.iconLabel
    backgroundColor: "#ffffff"
    iconColor: Colors.surface
    accessibleName: root.accessibleName
    tooltipText: root.accessibleName
    enabled: root.enabled
    onClicked: root.iconClicked()
  }
}
