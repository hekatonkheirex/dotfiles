import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "primitives"

// The top strip (elena): an 8 px row of workspace blocks. The window also owns
// the popup routing (`openPopup`, anchors, `togglePopupByName`), the niri
// workspace data (WorkspaceIndicator, invisible) and the system tray watcher.
// The old bar indicator widgets and the form/order machinery are gone.
PanelWindow {
  id: root

  property string barPosition: "top"
  // PanelWindow's Wayland surface is not safe to reuse across a reload when
  // the theme-dependent namespace may have changed. The shell enables this
  // after one event-loop turn so a reloaded instance drops the old surface
  // before creating the new one.
  property bool surfaceReady: false
  // Set by shell.qml: the lock screen covers the bar.
  property bool sessionLocked: false

  readonly property bool horizontal: barPosition === "top" || barPosition === "bottom"
  readonly property bool dockedTop: barPosition === "top"
  readonly property bool dockedBottom: barPosition === "bottom"
  readonly property bool dockedLeft: barPosition === "left"
  readonly property bool dockedRight: barPosition === "right"

  // Geometry (see config/BarForm.js); elena resolves to the full form.
  readonly property int edgeGap: Config.barFormMetrics.edgeGap
  readonly property int verticalPillPanelWidth: Config.barWidth
  readonly property int normalPanelExtent: Config.barWidth

  anchors {
    left: root.horizontal || root.dockedLeft
    right: root.horizontal || root.dockedRight
    top: root.horizontal ? root.dockedTop : true
    bottom: root.horizontal ? root.dockedBottom : true
  }

  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: (root.horizontal ? Config.barWidth : root.verticalPillPanelWidth) + root.edgeGap
  WlrLayershell.namespace: Config.layerNamespace("panel")
  WlrLayershell.layer: WlrLayer.Top

  implicitHeight: root.normalPanelExtent
  implicitWidth: root.normalPanelExtent

  mask: Region { item: barBg }

  Timer {
    interval: 0
    running: true
    repeat: false
    onTriggered: root.surfaceReady = true
  }

  property string openPopup: ""
  property int popupAnchorX: 0
  property int popupAnchorY: 0

  // The launcher and power menu have no widget to hang from; they open at a
  // fixed spot under the strip.
  function defaultAnchorX() {
    return root.screen ? Math.round(root.screen.width * 0.75) : 0
  }
  function getLauncherX() { return root.horizontal ? Math.round((root.screen ? root.screen.width : 0) / 2) : 0 }
  function getSettingsX() { return root.horizontal ? root.defaultAnchorX() : 0 }
  function getSettingsY() { return root.height }

  function togglePopup(name) {
    if (openPopup === name) {
      openPopup = ""
      return
    }
    if (root.horizontal) {
      popupAnchorX = root.defaultAnchorX()
      popupAnchorY = root.height + Config.spacingLarge
    }
    openPopup = name
  }

  // IPC entry point: open (or toggle closed) a popup by name. Returns false
  // for unknown names.
  function togglePopupByName(name) {
    // The sidebar, networks and tray windows have no anchor.
    if (name === "sidebar" || name === "networks" || name === "tray") {
      openPopup = openPopup === name ? "" : name
      return true
    }
    if (name !== "quickmenu" && name !== "launcher") return false
    togglePopup(name)
    return true
  }

  Item {
    anchors.fill: parent

    Rectangle {
      id: barBg
      x: root.horizontal
        ? 0
        : (root.dockedRight ? parent.width - root.verticalPillPanelWidth : 0)
      y: 0
      width: root.horizontal ? parent.width : root.verticalPillPanelWidth
      height: root.horizontal ? Config.barWidth : parent.height
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
