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
    clip: true
    Rectangle {
      anchors.bottom: parent.bottom
      width: parent.width
      height: parent.height * Math.max(0, Math.min(1, root.value))
      color: root.muted ? Colors.outline : root.accent
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
  Rectangle {
    id: badge
    visible: root.iconLabel !== ""
    width: 26; height: 26; radius: 13
    color: "#ffffff"
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 8
    IconGlyph {
      anchors.centerIn: parent
      iconLabel: root.iconLabel
      iconColor: Colors.surface
      iconSize: 16
    }
    MouseArea { anchors.fill: parent; enabled: root.enabled; onClicked: root.iconClicked() }
    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName
  }
}
