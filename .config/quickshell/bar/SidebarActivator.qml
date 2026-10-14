import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"

// 1 px strip at a side screen edge (left by default): hovering it for 120 ms
// opens the sidebar on that side.
PanelWindow {
  id: root

  // false while locked (shell.qml). niri 26.04 reports no fullscreen flag on
  // its windows, so there is no fullscreen gate.
  property bool enabledByState: true
  property bool rightEdge: false
  signal activated()

  anchors { left: !root.rightEdge; right: root.rightEdge; top: true; bottom: true }
  // Clear the top strip and the bottom bar so their x=0 pixels stay clickable.
  margins.top: Config.barWidth
  margins.bottom: Config.bottomBarHeight
  implicitWidth: 1
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace(root.rightEdge ? "settings-activator" : "sidebar-activator")
  WlrLayershell.layer: WlrLayer.Top
  visible: Settings.sidebarEdgeHover && root.enabledByState

  Timer {
    id: dwell
    interval: 120
    onTriggered: {
      root.activated()
    }
  }
  HoverHandler {
    onHoveredChanged: hovered ? dwell.restart() : dwell.stop()
  }
}
