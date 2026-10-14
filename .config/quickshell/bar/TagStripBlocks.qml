import QtQuick
import "../config"
import "../config/TagStrip.js" as TagStrip

// Her workspaces row on niri: one equal-width block per existing workspace in
// her color order. Focused is solid, occupied 0.3, the empty trailing
// workspace is invisible (0.2 on hover), a non-focused block is 0.6 on hover.
// Click focuses, right click moves the focused window there, the wheel steps
// to the previous or next workspace. Pure view: the owner supplies the model
// and performs the actions.
Item {
  id: root

  property var workspaces: []
  property int forceHoverIdx: -1   // render checks
  readonly property var blocks: TagStrip.tagStates(root.workspaces)
  property real wheelAccum: 0

  signal activated(int idx)
  signal moveRequested(int idx)
  // -1 previous (wheel up), +1 next
  signal stepped(int direction)

  Row {
    anchors.fill: parent

    Repeater {
      model: root.blocks.length

      delegate: Item {
        id: slot
        required property int index
        // Stable delegates (integer model) so the Behaviors animate.
        readonly property var block: index < root.blocks.length ? root.blocks[index] : null
        readonly property bool hovered: mouse.containsMouse || (block !== null && root.forceHoverIdx === block.idx)
        width: root.blocks.length > 0 ? root.width / root.blocks.length : 0
        height: parent.height

        Rectangle {
          objectName: "block"
          anchors.fill: parent
          color: slot.block ? Colors.elenaAccent(slot.block.slot) : "transparent"
          opacity: slot.block ? TagStrip.opacityFor(slot.block.state, slot.hovered) : 0
          bottomLeftRadius: slot.block && slot.block.roundLeft ? height : 0
          bottomRightRadius: slot.block && slot.block.roundRight ? height : 0
          Behavior on opacity {
            enabled: !Config.reducedMotion
            NumberAnimation { duration: 200 }
          }
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(m) {
            if (!slot.block) return
            if (m.button === Qt.RightButton) root.moveRequested(slot.block.idx)
            else root.activated(slot.block.idx)
          }
          onWheel: function(w) {
            var r = TagStrip.wheelStep(root.wheelAccum, w.angleDelta.y)
            root.wheelAccum = r.accum
            if (r.step !== 0) root.stepped(r.step)
          }
        }
      }
    }
  }
}
