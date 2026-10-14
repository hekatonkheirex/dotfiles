import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "alarms"
import "../config"
import "../config/Alarms.js" as Alarms

// Her alarms window (popup route "alarms"): right and bottom anchored
// overlay above the bottom bar, no reserved space. Same dismiss paths as the
// networks window: Esc (a time entry first), middle click, click outside
// (shell.qml's PopupShield), focus moving away (FocusDismiss), the bar button.
PanelWindow {
  id: root

  signal dismissed()

  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  // Matches the existing popup no-blur rule, including the transparent corners.
  WlrLayershell.namespace: Config.layerNamespace("popup-alarms")
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  anchors.right: true
  anchors.bottom: true
  margins.right: 0
  margins.bottom: Config.bottomBarHeight + Config.dp(10)
  implicitWidth: Config.dp(300)
  implicitHeight: content.implicitHeight

  onVisibleChanged: {
    if (visible) { content.forceActiveFocus(); return }
    // A reopen starts at the browse state with an empty entry.
    content.reset()
  }

  FocusScope {
    anchors.fill: parent
    focus: true

    FocusDismiss {
      target: root
      onDismissed: root.dismissed()
    }

    Rectangle {
      anchors.fill: parent
      color: Colors.surface
      topLeftRadius: Config.dp(20)
      bottomLeftRadius: Config.dp(20)
      topRightRadius: 0
      bottomRightRadius: 0

      AlarmsContent {
        id: content
        anchors.fill: parent
        alarmsModel: AlarmService.alarms
        onConfirmed: function(mode, input) {
          var a = Alarms.fromInput(mode, input, AlarmService.nowFn())
          if (a) AlarmService.add(a.at, a.label)
        }
        onDeleteRequested: function(index) { AlarmService.removeAt(index) }
        onDismissRequested: root.dismissed()
      }
    }
  }
}
