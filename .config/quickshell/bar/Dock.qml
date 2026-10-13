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
  mask: Region { item: zone }

  // Linger 400 ms after the pointer leaves before hiding.
  Timer {
    id: holdTimer
    interval: 400
    repeat: false
  }
  onPointerInsideChanged: if (!root.pointerInside) holdTimer.restart()

  // The hit area: 2 px strip when hidden, the whole body when shown.
  Item {
    id: zone
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: root.revealed ? root.bodyHeight : 2

    HoverHandler { id: pointer }
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
      onItemActivated: function(appId) { root.itemActivated(appId) }
      onItemClosed: function(appId) { root.itemClosed(appId) }
      onItemCycled: function(appId, direction) { root.itemCycled(appId, direction) }
    }
  }
}
