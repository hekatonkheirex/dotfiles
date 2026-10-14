pragma Singleton
import QtQml
import Quickshell
import Quickshell.Io
import "SystemMetrics.js" as SystemMetrics

// Home-page tile values. Reads procfs/sysfs once per tick; runs only while a
// consumer sets `active`. -1 means unavailable (the tile dims).
QtObject {
  id: root

  property bool active: false
  property real cpu: -1
  property real ram: -1
  property real swap: -1
  property real disk: -1
  property real temp: -1
  property real netPercent: -1
  property string netLabel: "--"
  property string hostname: ""
  property string uptime: "--"

  property var prevCpu: null
  property var prevNet: null
  property real prevNetAt: 0
  property real netCeilingBytes: 100 * 1000 * 1000     // 100 MB/s = 100 %

  function tick() {
    if (!root.active) return
    statFile.reload(); meminfoFile.reload(); netFile.reload(); uptimeFile.reload()
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
  }
  property FileView meminfoFile: FileView {
    path: root.active ? "/proc/meminfo" : ""
    onLoaded: {
      var m = SystemMetrics.memoryPercent(text())
      var s = SystemMetrics.swapPercent(text())
      root.ram = m === null ? -1 : m
      root.swap = s === null ? -1 : s
    }
  }
  property FileView netFile: FileView {
    path: root.active ? "/proc/net/dev" : ""
    onLoaded: {
      var cur = SystemMetrics.parseNet(text())
      var now = Date.now() / 1000
      var rate = SystemMetrics.netRate(root.prevNet, cur, now - root.prevNetAt)
      if (cur) { root.prevNet = cur; root.prevNetAt = now }
      if (rate === null) return
      var top = Math.max(rate.down, rate.up)
      root.netPercent = Math.max(0, Math.min(100, 100 * top / root.netCeilingBytes))
      root.netLabel = (top / 1000000).toFixed(top >= 10000000 ? 0 : 1)
    }
  }
  property FileView uptimeFile: FileView {
    path: root.active ? "/proc/uptime" : ""
    onLoaded: {
      var v = Number(String(text()).trim().split(/\s+/)[0])
      root.uptime = SystemMetrics.uptimeParts(isFinite(v) ? v : null)
    }
  }
  property FileView hostFile: FileView {
    path: "/etc/hostname"
    onLoaded: root.hostname = String(text()).trim()
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
