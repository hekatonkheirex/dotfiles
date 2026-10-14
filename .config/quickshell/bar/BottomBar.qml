import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "../config/BottomBarModel.js" as BottomBarModel
import "bottombar"

// Elena's bottom bar: a full-width, screen-fixed layer-shell window
// that reserves its height. Data comes from the existing services; actions
// leave through signals that shell.qml wires.
PanelWindow {
  id: root

  property var items: []
  property alias content: content

  // Focus a running pavucontrol, else start one. The shell service may not
  // export NIRI_SOCKET, so pick the newest socket like shell.niriAction.
  readonly property string pavucontrolCommand:
    "export NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1); "
    + "id=$(niri msg -j windows | jq -r '[.[] | select(.app_id==\"org.pulseaudio.pavucontrol\" or .app_id==\"pavucontrol\")][0].id // empty'); "
    + "if [ -n \"$id\" ]; then niri msg action focus-window --id \"$id\"; else exec pavucontrol; fi"

  signal sidebarPageRequested(int page)
  signal launcherRequested()
  signal networkRequested()
  signal alarmsRequested()
  signal logoutRequested()
  signal itemActivated(string appId)
  signal itemClosed(string appId)
  signal itemCycled(string appId, int direction)

  anchors {
    left: true
    right: true
    bottom: true
  }
  implicitHeight: Config.bottomBarHeight
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: root.implicitHeight
  WlrLayershell.namespace: Config.layerNamespace("bottombar")
  WlrLayershell.layer: WlrLayer.Top

  // Own writer flags: the bar is the only consumer of these services' slow
  // paths while it is visible.
  Binding { target: AudioService; property: "barActive"; value: root.visible }
  Binding { target: NetworkStatusService; property: "active"; value: root.visible }

  SystemClock { id: clock; precision: SystemClock.Minutes; enabled: root.visible }

  // Touchpads send many small deltas: one volume step per full 120 notch
  // (BottomBarModel.notchSteps, shared with DockGlyph's window cycling).
  property real wheelAccum: 0

  BottomBarContent {
    id: content
    anchors.fill: parent
    items: root.items
    clockText: BottomBarModel.clockText(clock.date)
    dateText: BottomBarModel.dateText(clock.date)
    volume: Math.round(AudioService.volume * 100)
    muted: AudioService.muted
    batteryPct: BatteryService.pct
    charging: BatteryService.charging
    signal: NetworkStatusService.signal
    connected: NetworkStatusService.connected
    vpn: NetworkStatusService.vpn
    alarmCount: AlarmService.count

    onGlanceClicked: root.sidebarPageRequested(0)
    onGlanceRightClicked: root.launcherRequested()
    onTasksClicked: root.sidebarPageRequested(1)
    onMediaClicked: root.sidebarPageRequested(2)
    // Same step as the top-bar AudioIndicator wheel (Config.volumeStep %).
    onMediaScrolled: function(delta) {
      const r = BottomBarModel.notchSteps(root.wheelAccum, delta)
      root.wheelAccum = r.accum
      if (r.steps !== 0) AudioService.setVolume(AudioService.volume + r.steps * Config.volumeStep / 100)
    }
    onMediaMiddleClicked: AudioService.toggleMute()
    onMediaRightClicked: Quickshell.execDetached(["sh", "-c", root.pavucontrolCommand])
    onNetworkClicked: root.networkRequested()
    onAlarmsClicked: root.alarmsRequested()
    onLogoutClicked: root.logoutRequested()
    onItemActivated: function(appId) { root.itemActivated(appId) }
    onItemClosed: function(appId) { root.itemClosed(appId) }
    onItemCycled: function(appId, direction) { root.itemCycled(appId, direction) }
  }
}
