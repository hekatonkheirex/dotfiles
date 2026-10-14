import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "networks"
import "../config"
import "../config/NetworkList.js" as NetworkList

// Her networks window (popup route "networks"): right and bottom anchored
// overlay above the bottom bar, no reserved space. Dismiss paths: Esc and
// middle click (NetworksContent), click outside (shell.qml's PopupShield),
// focus moving to another window (FocusDismiss), the bar button again.
// The services run only while it is shown.
PanelWindow {
  id: root

  signal dismissed()

  // IPC forgetPrompt sets this before opening; the hide reset clears it.
  property alias forgetFor: content.forgetFor

  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("networks")
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  anchors.right: true
  anchors.bottom: true
  margins.right: 0
  margins.bottom: Config.bottomBarHeight + Config.dp(10)
  implicitWidth: Config.dp(300)
  implicitHeight: content.implicitHeight

  Binding { target: NetworkListService; property: "active"; value: root.visible }
  Binding { target: SystemMetricsService; property: "networksActive"; value: root.visible }

  onVisibleChanged: {
    if (visible) { content.forceActiveFocus(); return }
    // A reopen starts clean; hiding the passphrase row also clears its text.
    content.passphraseFor = ""
    content.forgetFor = ""
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
      // Square right corners (the window touches the screen edge).
      topLeftRadius: Config.dp(20)
      bottomLeftRadius: Config.dp(20)
      topRightRadius: 0
      bottomRightRadius: 0

      NetworksContent {
        id: content
        anchors.fill: parent
        networksModel: NetworkListService.networks
        scanning: NetworkListService.scanning
        pingText: NetworkListService.pingText
        vpnOn: NetworkStatusService.vpn
        downText: NetworkList.formatRate(SystemMetricsService.netDown)
        upText: NetworkList.formatRate(SystemMetricsService.netUp)
        onConnectRequested: function(name, password) { NetworkListService.connect(name, password) }
        onDisconnectRequested: NetworkListService.disconnect()
        onForgetConfirmed: function(name) { NetworkListService.forget(name) }
        onScanRequested: NetworkListService.scan()
        onSpeedtestRequested: NetworkListService.speedtest()
        onPingRequested: NetworkListService.ping()
        onVpnRequested: NetworkListService.openVpnEditor()
        onDismissRequested: root.dismissed()
      }
    }
  }
}
