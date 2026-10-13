import QtQuick
import "../../config"
import "../controls"

// Vertical level bar: click or drag the tile to set the level; the round icon
// is a button (mute toggle for audio, inert for brightness).
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

  LevelTile {
    anchors.fill: parent
    value: root.value
    accent: root.accent
    iconLabel: root.iconLabel
    muted: root.muted
    accessibleName: root.accessibleName
    onMoved: function(v) { root.moved(v) }
    onIconClicked: root.iconClicked()
  }
}
