import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "dock"

// Elena's bottom dock. One always-mapped, full-width window; its input mask is
// a thin strip at the bottom edge while hidden and the dock body while shown,
// so a hidden dock never steals clicks and the pointer reaching the edge
// reveals it.
PanelWindow {
  id: root

  property var items: []
  property bool workspaceEmpty: false
  property bool forceShown: false          // dev/testing hook (dockReveal)

  readonly property int edgeGap: 12
  readonly property int bodyHeight: content.implicitHeight + root.edgeGap
  readonly property bool pointerInside: pointer.hovered
  readonly property bool revealed: root.workspaceEmpty || root.forceShown
    || root.pointerInside || holdTimer.running

  signal itemActivated(string appId)
  signal itemClosed(string appId)
  signal itemCycled(string appId, int direction)

  anchors {
    left: true
    right: true
    bottom: true
  }
  implicitHeight: root.bodyHeight
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("dock")
  WlrLayershell.layer: WlrLayer.Top
  // Union of a permanent 2 px full-width strip (the pointer reaching the
  // bottom edge anywhere reveals the dock) and, while shown, a body-sized hit
  // area. Region children combine (union) by default; Combine is explicit.
  // Everything else passes clicks through to the windows underneath.
  mask: Region {
    item: strip
    Region { item: bodyHit; intersection: Intersection.Combine }
  }

  // Linger 400 ms after the pointer leaves before hiding.
  Timer {
    id: holdTimer
    interval: 400
    repeat: false
  }
  onPointerInsideChanged: if (!root.pointerInside) holdTimer.restart()

  // Spans the window so the handler sees the pointer on the strip or the
  // body; input only arrives inside the mask anyway.
  Item {
    id: hoverArea
    anchors.fill: parent
    HoverHandler { id: pointer }
  }

  // Always-on reveal strip. Keep it full width: shrinking it to the body
  // would flicker the dock hide/show at the edge.
  Item {
    id: strip
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 2
  }

  // Body-sized input area, empty while hidden.
  Item {
    id: bodyHit
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    width: root.revealed ? body.width : 0
    height: root.revealed ? root.bodyHeight : 0
  }

  Item {
    id: body
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: root.edgeGap
    width: content.implicitWidth
    height: content.implicitHeight
    opacity: root.revealed ? 1 : 0
    // Slide up from below the screen edge.
    transform: Translate {
      y: root.revealed ? 0 : body.height + root.edgeGap
      Behavior on y {
        enabled: !Config.reducedMotion
        NumberAnimation { duration: Config.motionLong; easing.type: Easing.OutCubic }
      }
    }
    Behavior on opacity {
      enabled: !Config.reducedMotion
      NumberAnimation { duration: Config.motionMedium }
    }

    DockContent {
      id: content
      items: root.items
      active: root.revealed
      onItemActivated: function(appId) { root.itemActivated(appId) }
      onItemClosed: function(appId) { root.itemClosed(appId) }
      onItemCycled: function(appId, direction) { root.itemCycled(appId, direction) }
    }
  }
}
