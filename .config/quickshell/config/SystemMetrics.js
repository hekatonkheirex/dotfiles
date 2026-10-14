.pragma library

// Pure parsers for the Home page tiles. No QML types, no I/O.

function num(text) {
  var v = Number(String(text).trim())
  return isFinite(v) ? v : null
}

function parseCpu(text) {
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    if (!/^cpu\s/.test(lines[i])) continue
    var f = lines[i].trim().split(/\s+/).slice(1).map(Number)
    if (f.length < 5 || f.some(function(v) { return !isFinite(v) })) return null
    var total = 0
    for (var j = 0; j < f.length; j++) total += f[j]
    return { idle: f[3] + f[4], total: total }
  }
  return null
}

function cpuPercent(prev, cur) {
  if (!prev || !cur) return null
  var dt = cur.total - prev.total
  var di = cur.idle - prev.idle
  if (dt <= 0 || di < 0 || di > dt) return null
  return Math.round(100 * (dt - di) / dt)
}

function meminfo(text) {
  var out = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var m = /^(MemTotal|MemAvailable|SwapTotal|SwapFree):\s+(\d+)\s+kB/.exec(lines[i])
    if (m) out[m[1]] = Number(m[2])
  }
  return out
}

function memoryPercent(text) {
  var m = meminfo(text)
  if (!(m.MemTotal > 0) || m.MemAvailable === undefined || m.MemAvailable > m.MemTotal) return null
  return Math.round(100 * (m.MemTotal - m.MemAvailable) / m.MemTotal)
}

function swapPercent(text) {
  var m = meminfo(text)
  if (!(m.SwapTotal > 0) || m.SwapFree === undefined || m.SwapFree > m.SwapTotal) return null
  return Math.round(100 * (m.SwapTotal - m.SwapFree) / m.SwapTotal)
}

// thermal zone files hold millidegrees Celsius.
function tempC(texts) {
  var best = null
  for (var i = 0; i < (texts || []).length; i++) {
    var s = String(texts[i]).trim()
    if (s === "") continue
    var v = Number(s)
    if (!isFinite(v)) continue
    var c = v / 1000
    if (best === null || c > best) best = c
  }
  return best
}

function diskPercent(text) {
  var lines = String(text || "").trim().split("\n")
  if (lines.length < 2) return null
  var f = lines[1].trim().split(/\s+/)
  var m = /^(\d+)%$/.exec(f[4] || "")
  return m ? Number(m[1]) : null
}

function parseNet(text) {
  var rx = 0, tx = 0, seen = false
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var m = /^\s*([^:\s]+):\s*(.*)$/.exec(lines[i])
    if (!m || m[1] === "lo") continue
    var f = m[2].trim().split(/\s+/).map(Number)
    if (f.length < 9 || !isFinite(f[0]) || !isFinite(f[8])) continue
    rx += f[0]
    tx += f[8]
    seen = true
  }
  return seen ? { rx: rx, tx: tx } : null
}

function netRate(prev, cur, dtSec) {
  if (!prev || !cur || !(dtSec > 0)) return null
  var down = cur.rx - prev.rx
  var up = cur.tx - prev.tx
  return { down: down > 0 ? down / dtSec : 0, up: up > 0 ? up / dtSec : 0 }
}

function uptimeParts(seconds) {
  if (seconds === null || seconds === undefined || !isFinite(seconds) || seconds < 0) return "--"
  var s = Math.floor(seconds)
  if (s < 60) return s + "s"
  var minutes = Math.floor(s / 60)
  var units = [
    ["w", Math.floor(minutes / (7 * 1440))],
    ["d", Math.floor(minutes / 1440) % 7],
    ["h", Math.floor(minutes / 60) % 24],
    ["m", minutes % 60]
  ]
  var out = []
  for (var i = 0; i < units.length && out.length < 2; i++) {
    if (units[i][1] > 0) out.push(units[i][1] + units[i][0])
  }
  return out.join(" ")
}
