import QtQuick
import Quickshell
import Quickshell.Wayland
import "../config"

// Top-edge strip of workspace color blocks (elena style). The Bar sits
// below it: with a top bar, the Bar's top margin reserves the strip's space
// (deterministic stacking); otherwise the strip reserves it itself.
PanelWindow {
  id: root

  property var workspaces: []
  // False when a top-docked horizontal bar already includes the strip in its
  // own margin; true for bottom and vertical bars.
  property bool reserveZone: false

  signal activated(int idx)

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: Config.tagStripHeight
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: root.reserveZone ? Config.tagStripHeight : 0
  WlrLayershell.namespace: Config.layerNamespace("tagstrip")
  WlrLayershell.layer: WlrLayer.Top

  TagStripBlocks {
    anchors.fill: parent
    workspaces: root.workspaces
    onActivated: function(idx) { root.activated(idx) }
  }
}
