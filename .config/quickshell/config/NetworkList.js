.pragma library

// Pure nmcli parsers for the networks sidebar page.

// nmcli -e yes escaping: backslash escapes a colon or a backslash.
function parseTerseFields(line) {
  var fields = [], field = "", escaped = false
  for (var i = 0; i < line.length; i++) {
    var c = line[i]
    if (escaped) {
      field += (c === ":" || c === "\\") ? c : "\\" + c
      escaped = false
    } else if (c === "\\") escaped = true
    else if (c === ":") { fields.push(field); field = "" }
    else field += c
  }
  if (escaped) field += "\\"
  fields.push(field)
  return fields
}

function parseWifiList(text) {
  var lines = String(text || "").split(/\r?\n/)
  var list = [], seen = Object.create(null)
  for (var i = 0; i < lines.length; i++) {
    if (lines[i] === "") continue
    var p = parseTerseFields(lines[i])
    if (p.length < 4 || !p[1]) continue
    var active = p[0] === "yes"
    var signal = parseInt(p[2], 10) || 0
    var secure = p[3] !== "" && p[3] !== "--"
    if (seen[p[1]] !== undefined) {
      var row = list[seen[p[1]]]
      if (active) row.active = true
      if (signal > row.signal) { row.signal = signal; row.secure = secure }
      continue
    }
    seen[p[1]] = list.length
    list.push({ name: p[1], signal: signal, secure: secure, active: active })
  }
  list.sort(function (a, b) {
    if (a.active !== b.active) return a.active ? -1 : 1
    return b.signal - a.signal
  })
  return list
}

function parseSaved(text) {
  var lines = String(text || "").split(/\r?\n/), out = []
  for (var i = 0; i < lines.length; i++) {
    if (lines[i] === "") continue
    var p = parseTerseFields(lines[i])
    if (p.length >= 2 && p[0] && (p[1] === "802-11-wireless" || p[1] === "wifi")) out.push(p[0])
  }
  return out
}

function merge(wifi, saved) {
  return wifi.map(function (r) {
    return { name: r.name, signal: r.signal, secure: r.secure, active: r.active,
             saved: saved.indexOf(r.name) !== -1 }
  })
}

function signalBucket(signal) {
  if (signal >= 75) return "excellent"
  if (signal >= 50) return "good"
  if (signal >= 25) return "ok"
  return "bad"
}

function shortName(name) {
  name = String(name || "")
  return name.length > 22 ? name.slice(0, 19) + "..." : name
}

function parsePingLine(line) {
  line = String(line || "")
  var m = /time=([\d.]+)\s*ms/.exec(line)
  if (m) return { kind: "time", ms: Math.round(parseFloat(m[1])) }
  m = /rtt min\/avg\/max\/\w+ = [\d.]+\/([\d.]+)\//.exec(line)
  if (m) return { kind: "avg", ms: Math.round(parseFloat(m[1])) }
  if (/Network is unreachable/i.test(line)) return { kind: "unreachable" }
  return { kind: "none" }
}

// Bytes/s to her bandwidth label (megabits, Mb/s, two decimals); unknown -> "--Mb/s".
function formatRate(bytes) {
  var v = Number(bytes)
  if (!isFinite(v) || v < 0) return "--Mb/s"
  return (v * 8 / 1000000).toFixed(2) + "Mb/s"
}
