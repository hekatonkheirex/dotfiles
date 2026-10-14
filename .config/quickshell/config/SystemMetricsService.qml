pragma Singleton
import QtQml
import Quickshell
import Quickshell.Io
import "SystemMetrics.js" as SystemMetrics

// Home-page tile values and the networks window's bandwidth. Reads
// procfs/sysfs once per tick; runs while either consumer wants it (the sidebar
// Home page or the networks window), so closing one leaves the other running.
// -1 means unavailable (the tile dims).
QtObject {
  id: root

  property bool sidebarActive: false
  property bool networksActive: false
  readonly property bool active: root.sidebarActive || root.networksActive
  property real cpu: -1
  property real ram: -1
  property real swap: -1
  property real disk: -1
  property real temp: -1
  property real netPercent: -1
  property string netLabel: "--"
  property real netDown: -1   // bytes/s, all interfaces (networks window)
  property real netUp: -1
  property string hostname: ""
  property string uptime: "--"

  property var prevCpu: null
  property var prevNet: null
  property real prevNetAt: 0
  property real netCeilingBytes: 100 * 1000 * 1000     // 100 MB/s = 100 %

  // Drop baselines and values when the page closes so the next open starts
  // from a fresh 2 s delta instead of a stale one.
  onActiveChanged: {
    if (root.active) return
    root.prevCpu = null; root.prevNet = null; root.prevNetAt = 0
    root.cpu = -1; root.ram = -1; root.swap = -1; root.disk = -1
    root.temp = -1; root.netPercent = -1; root.netLabel = "--"; root.uptime = "--"
    root.netDown = -1; root.netUp = -1
    root.firstTick = true
  }

  property bool firstTick: true

  function tick() {
    if (!root.active) return
    // Setting `path` already loads the file on activation; that first read is
    // the baseline, so skip the explicit reload to avoid a zero-length delta.
    if (root.firstTick) root.firstTick = false
    else { statFile.reload(); meminfoFile.reload(); netFile.reload(); uptimeFile.reload() }
    if (!dfProc.running) dfProc.running = true
    if (!thermalProc.running) thermalProc.running = true
  }

  property FileView statFile: FileView {
    path: root.active ? "/proc/stat" : ""
    onLoaded: {
      var cur = SystemMetrics.parseCpu(text())
      var pct = SystemMetrics.cpuPercent(root.prevCpu, cur)
      if (cur) root.prevCpu = cur
      root.cpu = pct === null ? root.cpu : pct
    }
    onLoadFailed: root.cpu = -1
  }
  property FileView meminfoFile: FileView {
    path: root.active ? "/proc/meminfo" : ""
    onLoaded: {
      var m = SystemMetrics.memoryPercent(text())
      var s = SystemMetrics.swapPercent(text())
      root.ram = m === null ? -1 : m
      root.swap = s === null ? -1 : s
    }
    onLoadFailed: { root.ram = -1; root.swap = -1 }
  }
  property FileView netFile: FileView {
    path: root.active ? "/proc/net/dev" : ""
    onLoaded: {
      var cur = SystemMetrics.parseNet(text())
      var now = Date.now() / 1000
      var rate = SystemMetrics.netRate(root.prevNet, cur, now - root.prevNetAt)
      if (cur) { root.prevNet = cur; root.prevNetAt = now }
      if (rate === null) return
      root.netDown = rate.down
      root.netUp = rate.up
      var top = Math.max(rate.down, rate.up)
      root.netPercent = Math.max(0, Math.min(100, 100 * top / root.netCeilingBytes))
      root.netLabel = (top / 1000000).toFixed(top >= 10000000 ? 0 : 1)
    }
    onLoadFailed: { root.netPercent = -1; root.netLabel = "--"; root.netDown = -1; root.netUp = -1 }
  }
  property FileView uptimeFile: FileView {
    path: root.active ? "/proc/uptime" : ""
    onLoaded: {
      var v = Number(String(text()).trim().split(/\s+/)[0])
      root.uptime = SystemMetrics.uptimeParts(isFinite(v) ? v : null)
    }
    onLoadFailed: root.uptime = "--"
  }
  property FileView hostFile: FileView {
    path: root.active ? "/etc/hostname" : ""
    onLoaded: root.hostname = String(text()).trim()
    onLoadFailed: root.hostname = ""
  }

  property Process dfProc: Process {
    command: ["df", "-P", "/"]
    stdout: StdioCollector {
      onStreamFinished: {
        var d = SystemMetrics.diskPercent(text)
        root.disk = d === null ? -1 : d
      }
    }
  }
  property Process thermalProc: Process {
    command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        var t = SystemMetrics.tempC(String(text).split("\n"))
        root.temp = t === null ? -1 : t
      }
    }
  }

  property Timer timer: Timer {
    interval: 2000
    repeat: true
    running: root.active
    triggeredOnStart: true
    onTriggered: root.tick()
  }
}
