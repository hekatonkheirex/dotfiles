import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "powermenu"
import "../config"
import "../config/PowerMenuModel.js" as Model

// Her powermenu as a full-screen overlay (popup route "quickmenu").
// poweroff, reboot, exit set `pendingIndex` and close, so the confirmation
// window owns keyboard focus alone; hibernate, suspend and lock run at once.
PanelWindow {
  id: root

  property int pendingIndex: -1

  signal dismissed()
  signal lockRequested()

  readonly property var buttons: Model.buttons()
  readonly property string home: Quickshell.env("HOME")
  readonly property var commands: ({
    poweroff: ["systemctl", "poweroff"],
    reboot: ["systemctl", "reboot"],
    exit: ["sh", root.home + "/.config/quickshell/scripts/safe-logout.sh"],
    hibernate: ["systemctl", "hibernate"],
    suspend: ["systemctl", "suspend"]
  })
  // Confirmation dialog texts (same as the QuickMenu had). The dialog draws
  // Material Symbols, so its icons are Material names, not her remix glyphs.
  readonly property var labels: ({ poweroff: "Shut Down", reboot: "Restart", exit: "Log Out" })
  readonly property var descriptions: ({
    poweroff: "The computer will power off.",
    reboot: "The computer will restart.",
    exit: "Your current session will end."
  })
  readonly property var icons: ({ poweroff: "power_settings_new", reboot: "restart_alt", exit: "logout" })
  readonly property string pendingId: root.pendingIndex >= 0 && root.pendingIndex < root.buttons.length
    ? root.buttons[root.pendingIndex].id : ""

  function activate(id) {
    var i = content.indexOf(id)
    if (i < 0) return
    if (root.buttons[i].confirm) {
      root.pendingIndex = i
    } else if (id === "lock") {
      root.lockRequested()
    } else {
      runner.command = root.commands[id]
      runner.running = true
    }
    root.dismissed()
  }

  function confirmPending() {
    var cmd = root.commands[root.pendingId]
    root.pendingIndex = -1
    if (cmd) Quickshell.execDetached(cmd)
  }

  function cancelPending() { root.pendingIndex = -1 }

  // hibernate/suspend: a failure (e.g. no swap for hibernate) is logged, not silent.
  Process {
    id: runner
    onExited: function(code) {
      if (code !== 0) console.warn("powermenu: " + runner.command.join(" ") + " exited " + code)
    }
  }

  visible: false
  color: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.7)
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("powermenu")
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true

  onVisibleChanged: {
    if (!visible) return
    // activate() sets the index before dismissed(), so the handoff to the
    // confirmation survives the close; a fresh open drops any stale one.
    root.pendingIndex = -1
    content.selected = ""
    content.forceActiveFocus()
  }

  // The backdrop: content only covers its own box, so clicks around it land here.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: root.dismissed()
  }

  PowerMenuContent {
    id: content
    anchors.centerIn: parent
    width: implicitWidth
    height: implicitHeight
    focus: true
    locked: false
    revealed: root.visible
    onActivated: function(id) { root.activate(id) }
    onDismissRequested: root.dismissed()
  }
}
