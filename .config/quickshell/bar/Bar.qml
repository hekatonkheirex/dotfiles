import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "primitives"

// The top strip (elena): an 8 px row of workspace blocks. The window also owns
// the popup routing (`openPopup`, anchors, `togglePopupByName`), the niri
// workspace data (WorkspaceIndicator, invisible) and the system tray watcher.
PanelWindow {
  id: root

  // PanelWindow's Wayland surface is not safe to reuse across a reload when
  // the theme-dependent namespace may have changed. The shell enables this
  // after one event-loop turn so a reloaded instance drops the old surface
  // before creating the new one.
  property bool surfaceReady: false
  // Set by shell.qml: the lock screen covers the bar.
  property bool sessionLocked: false

  anchors {
    left: true
    right: true
    top: true
  }

  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: Config.barWidth
  WlrLayershell.namespace: Config.layerNamespace("panel")
  WlrLayershell.layer: WlrLayer.Top

  implicitHeight: Config.barWidth

  mask: Region { item: barBg }

  Timer {
    interval: 0
    running: true
    repeat: false
    onTriggered: root.surfaceReady = true
  }

  property string openPopup: ""

  function togglePopup(name) {
    openPopup = openPopup === name ? "" : name
  }

  // IPC entry point: open (or toggle closed) a popup by name. Returns false
  // for unknown names.
  function togglePopupByName(name) {
    if (["sidebar", "settings", "networks", "tray", "quickmenu", "launcher"].indexOf(name) < 0) return false
    togglePopup(name)
    return true
  }

  Item {
    anchors.fill: parent

    Rectangle {
      id: barBg
      width: parent.width
      height: Config.barWidth
      color: "transparent"

      MouseArea {
        id: barMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.openPopup = ""
        enabled: !root.openPopup
      }

      // The whole bar is the workspace block row. The mask above is barBg, so
      // clicks reach only these blocks.
      TagStripBlocks {
        anchors.fill: parent
        z: 10
        // The workspaces niri has; the retired workspaceCount padding is ignored.
        workspaces: wsIndicator.workspaces
        onActivated: function(idx) { wsIndicator.focusWorkspace(idx) }
        onMoveRequested: function(idx) { wsIndicator.moveFocusedWindowTo(idx) }
        onStepped: function(direction) { wsIndicator.stepWorkspace(direction) }
      }
    }

    // Niri workspace and focused-window state (its refreshers are gated on
    // `visible`, so it stays visible with no size).
    WorkspaceIndicator {
      id: wsIndicator
      width: 0
      height: 0
    }
  }
}
