pragma Singleton
import QtQml
import Quickshell.Io
import "BottomBarModel.js" as BottomBarModel

// Wi-Fi signal bucket and VPN state for the bottom bar. nmcli monitor wakes a
// refresh on any NetworkManager change; a 10 s timer is the fallback. Nothing
// runs while no consumer sets `active`. `--rescan no` reads NetworkManager's
// cached scan: the default (auto) would trigger a Wi-Fi rescan every ~30 s.
QtObject {
  id: root

  property bool active: false
  property bool connected: false
  property int signal: 0
  property bool vpn: false
  // NetworkListService refreshes on these instead of polling.
  signal nmChanged()
  readonly property bool monitorRunning: monitor.running

  function refresh() {
    if (!root.active) return
    if (!wifiQuery.running) wifiQuery.running = true
    if (!vpnQuery.running) vpnQuery.running = true
  }

  property Process wifiQuery: Process {
    command: ["sh", "-c", "nmcli -t -f ACTIVE,SIGNAL dev wifi list --rescan no"]
    stdout: StdioCollector {
      onStreamFinished: {
        var r = BottomBarModel.parseWifi(text)
        root.connected = r.connected
        root.signal = r.signal
      }
    }
  }

  property Process vpnQuery: Process {
    command: ["sh", "-c", "nmcli -t -f TYPE,STATE con show --active"]
    stdout: StdioCollector {
      onStreamFinished: root.vpn = BottomBarModel.parseVpn(text)
    }
  }

  property Process monitor: Process {
    running: root.active
    command: ["nmcli", "monitor"]
    stdout: SplitParser {
      onRead: {
        root.restartDelay = 2000   // the monitor works again: next failure retries fast
        root.refresh()
        root.nmChanged()
      }
    }
    onRunningChanged: {
      if (running || !root.active) return
      restart.interval = root.restartDelay
      restart.start()
      root.restartDelay = Math.min(60000, root.restartDelay * 2)
    }
  }

  // Restart back-off: 2 s doubling to 60 s while nmcli monitor keeps dying.
  property int restartDelay: 2000

  property Timer restart: Timer {
    // Re-bind, not `= true`: a plain assignment would drop the active gate.
    onTriggered: root.monitor.running = Qt.binding(function() { return root.active })
  }

  property Timer fallback: Timer {
    interval: 10000
    repeat: true
    running: root.active
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
