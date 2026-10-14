import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"

// 1 px strip at the left screen edge: hovering it for 120 ms opens the sidebar.
PanelWindow {
  id: root

  // false while locked (shell.qml). niri 26.04 reports no fullscreen flag on
  // its windows, so there is no fullscreen gate.
  property bool enabledByState: true
  signal activated()

  anchors { left: true; top: true; bottom: true }
  implicitWidth: 1
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("sidebar-activator")
  WlrLayershell.layer: WlrLayer.Top
  visible: Settings.sidebarEdgeHover && root.enabledByState

  Timer {
    id: dwell
    interval: 120
    onTriggered: {
      console.info("sidebar-activator: hover")
      root.activated()
    }
  }
  HoverHandler {
    onHoveredChanged: hovered ? dwell.restart() : dwell.stop()
  }
}
