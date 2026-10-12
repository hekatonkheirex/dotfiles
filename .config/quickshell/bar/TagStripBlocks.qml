import QtQuick
import "../config"
import "../config/TagStrip.js" as TagStrip

// One equal-width block per workspace. Pure view: the model and the focus
// action come from the owner.
Item {
  id: root

  property var workspaces: []
  readonly property var blocks: TagStrip.tagStates(root.workspaces)
  readonly property var accents: [Colors.primary, Colors.secondary, Colors.tertiary]

  signal activated(int idx)

  function fill(block) {
    var a = root.accents[block.accent]
    if (block.state === "focused") return a
    return Qt.rgba(a.r, a.g, a.b, block.state === "occupied" ? 0.35 : 0.08)
  }

  Row {
    anchors.fill: parent

    Repeater {
      model: root.blocks.length

      delegate: Rectangle {
        required property int index
        // Stable delegates (integer model) so Behavior on color animates.
        readonly property var block: index < root.blocks.length ? root.blocks[index] : null
        width: root.blocks.length > 0 ? root.width / root.blocks.length : 0
        height: parent.height
        color: block ? root.fill(block) : "transparent"
        Behavior on color { ColorAnimation { duration: Config.motionShort } }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: if (block) root.activated(block.idx)
        }
      }
    }
  }
}
