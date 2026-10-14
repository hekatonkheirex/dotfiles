pragma Singleton
import QtQml
import Quickshell
import Quickshell.Io
import "NetworkList.js" as NetworkList

// Wi-Fi list, scan, ping and connect/disconnect/forget for the networks
// window. Every process takes its argv from `commandFor(kind, args)`, so the
// render stage swaps in fixture commands; the defaults are the working nmcli
// commands from the old Settings Wi-Fi panel, byte for byte. Nothing polls
// while `active` is false. NM changes arrive through NetworkStatusService's
// `nmcli monitor`; a 10 s timer covers the time it is not running.
QtObject {
  id: root

  property bool active: false
  property var networks: []
  property bool scanning: false
  property string pingText: "ping"
  property bool pinging: false
  property string lastError: ""
  property string device: ""
  // Test knob: the render stage shortens the 1 s scan poll.
  property int scanPollInterval: 1000
  readonly property bool pollRunning: pollTimer.running || scanTimer.running

  property var wifiRows: []
  property var savedNames: []
  property int scanPolls: 0
  // Names for the failure notices; set only when the process really started.
  property string pendingConnectName: ""
  property string pendingForgetName: ""

  function quote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

  property var commandFor: function(kind, args) {
    switch (kind) {
    // `rescan: "no"` reads NM's cache (event and poll refreshes); without it
    // nmcli's default (auto) may rescan, as on open and during a scan.
    case "list": return ["nmcli", "-t", "-e", "yes", "-f", "active,ssid,signal,security", "dev", "wifi", "list"]
      .concat(args.rescan === "no" ? ["--rescan", "no"] : [])
    case "saved": return ["nmcli", "-t", "-e", "yes", "-f", "NAME,TYPE,AUTOCONNECT,DEVICE", "connection", "show"]
    case "device": return ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
    case "rescan": return ["nmcli", "dev", "wifi", "rescan"]
    case "connect": return ["sh", "-c", args.password
      ? "nmcli dev wifi connect " + root.quote(args.name) + " password " + root.quote(args.password) + " 2>&1"
      : "nmcli dev wifi connect " + root.quote(args.name) + " 2>&1"]
    case "disconnect": return ["nmcli", "device", "disconnect", args.device]
    case "forget": return ["nmcli", "connection", "delete", args.name]
    case "ping": return ["sh", "-c", "stdbuf -oL ping -c 10 -w 30 1.1.1.1 2>&1"]
    case "notify": return ["notify-send", "-u", "low", "Networks", args.message]
    case "vpn": return ["nm-connection-editor"]
    case "speedtest": return ["xdg-open", "https://www.speedtest.net"]
    }
    return ["true"]
  }

  function run(proc, kind, args) {
    if (proc.running) return false
    proc.command = root.commandFor(kind, args || {})
    proc.running = true
    return true
  }

  function fail(message) {
    root.lastError = message
    Quickshell.execDetached(root.commandFor("notify", { message: message }))
  }

  // fresh: let nmcli rescan (open, scan polls); else read the cache.
  function refresh(fresh) {
    if (!root.active) return
    root.run(listProc, "list", fresh ? {} : { rescan: "no" })
    root.run(savedProc, "saved")
    root.run(deviceProc, "device")
  }

  function scan() {
    if (!root.active || root.scanning) return
    root.scanning = true
    root.scanPolls = 0
    root.run(rescanProc, "rescan")
    scanTimer.start()
  }

  function connect(name, password) {
    if (!name || connectProc.running) return
    if (root.run(connectProc, "connect", { name: name, password: password || "" })) root.pendingConnectName = name
  }

  function disconnect() {
    if (!root.device) {
      root.fail("Could not determine the Wi-Fi device")
      root.run(deviceProc, "device")
      return
    }
    root.run(disconnectProc, "disconnect", { device: root.device })
  }

  function forget(name) {
    if (!name) return
    if (root.run(forgetProc, "forget", { name: name })) root.pendingForgetName = name
  }

  function ping() {
    if (root.pinging) return
    root.pinging = true
    root.pingText = "ping"
    root.run(pingProc, "ping")
  }

  function openVpnEditor() { Quickshell.execDetached(root.commandFor("vpn", {})) }
  function speedtest() { Quickshell.execDetached(root.commandFor("speedtest", {})) }

  onActiveChanged: {
    if (root.active) { root.refresh(true); return }
    scanTimer.stop()
    root.scanning = false
    root.scanPolls = 0
  }

  property Process listProc: Process {
    stdout: StdioCollector {
      onStreamFinished: {
        root.wifiRows = NetworkList.parseWifiList(text)
        root.networks = NetworkList.merge(root.wifiRows, root.savedNames)
      }
    }
  }
  property Process savedProc: Process {
    stdout: StdioCollector {
      onStreamFinished: {
        root.savedNames = NetworkList.parseSaved(text)
        root.networks = NetworkList.merge(root.wifiRows, root.savedNames)
      }
    }
  }
  // The Wi-Fi device the way the old Settings Wi-Fi panel found it: first wifi row whose state
  // starts with "connected".
  property Process deviceProc: Process {
    stdout: StdioCollector {
      onStreamFinished: {
        var dev = ""
        var lines = String(text).split(/\r?\n/)
        for (var i = 0; i < lines.length && !dev; i++) {
          var p = NetworkList.parseTerseFields(lines[i])
          if (p.length >= 3 && p[1] === "wifi" && p[2].indexOf("connected") === 0) dev = p[0]
        }
        root.device = dev
      }
    }
  }
  property Process rescanProc: Process {}
  property Process connectProc: Process {
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.indexOf("successfully activated") >= 0) root.lastError = ""
        else root.fail("Could not connect to " + root.pendingConnectName)
        root.refresh()
      }
    }
  }
  property Process disconnectProc: Process {
    onExited: function(code) {
      if (code !== 0) root.fail("Could not disconnect")
      else root.lastError = ""
      root.refresh()
    }
  }
  property Process forgetProc: Process {
    onExited: function(code) {
      if (code !== 0) root.fail("Could not forget " + root.pendingForgetName)
      else root.lastError = ""
      root.refresh()
    }
  }
  property Process pingProc: Process {
    stdout: SplitParser {
      onRead: function(line) {
        var r = NetworkList.parsePingLine(line)
        if (r.kind === "time" || r.kind === "avg") root.pingText = r.ms + "ms"
        else if (r.kind === "unreachable") root.pingText = "dc"
      }
    }
    onExited: root.pinging = false
  }

  property Connections nmEvents: Connections {
    target: NetworkStatusService
    function onNmChanged() { root.refresh() }
  }

  property Timer pollTimer: Timer {
    interval: 10000
    repeat: true
    running: root.active && !NetworkStatusService.monitorRunning
    onTriggered: root.refresh()
  }

  // Scan: one rescan, then five list polls one interval apart.
  property Timer scanTimer: Timer {
    interval: root.scanPollInterval
    repeat: true
    onTriggered: {
      root.refresh(true)
      root.scanPolls++
      if (root.scanPolls >= 5) { stop(); root.scanning = false }
    }
  }
}
