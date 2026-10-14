.pragma library

// Pure decisions for the bottom bar. No QML types, no I/O.

function pad2(n) { return (n < 10 ? "0" : "") + n }

function clockText(d) { return pad2(d.getHours()) + pad2(d.getMinutes()) }
function dateText(d) { return pad2(d.getDate()) }

// One battery part: "full" above `half`, "half" above `min` (both strict),
// else "empty". Thresholds are the eww battery-progress-bar-part values.
function part(pct, min, half) {
  if (pct > half) return "full"
  if (pct > min) return "half"
  return "empty"
}

// Top to bottom: the top part has the highest threshold.
function batteryParts(pct) {
  var p = typeof pct === "number" && pct >= 0 ? pct : -1
  if (p < 0) return ["empty", "empty", "empty"]
  return [part(p, 66, 83), part(p, 33, 49), part(p, 0, 16)]
}

function signalParts(signal, connected) {
  var out = []
  for (var i = 1; i <= 4; i++) {
    if (!connected) out.push("disconnected")
    else out.push(signal >= i ? "active" : "inactive")
  }
  return out
}

// nmcli -t -f ACTIVE,SIGNAL dev wifi -> active network and 1..4 bucket.
function parseWifi(text) {
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = lines[i].split(":")
    if (f[0] !== "yes") continue
    var pct = parseInt(f[1], 10)
    var bucket = isNaN(pct) ? 1 : Math.max(1, Math.min(4, Math.ceil(pct / 25)))
    return { connected: true, signal: bucket }
  }
  return { connected: false, signal: 0 }
}

// nmcli -t -f TYPE,STATE con show --active -> any activated vpn/wireguard.
function parseVpn(text) {
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = lines[i].split(":")
    if ((f[0] === "vpn" || f[0] === "wireguard") && f[1] === "activated") return true
  }
  return false
}

// Sidebar page buttons: closed opens at the page, the open page closes it,
// another page switches. `pages` is the number of pages that exist.
function sidebarToggle(openPopup, currentPage, requested, pages) {
  var page = Math.max(0, Math.min(pages - 1, Math.floor(requested)))
  if (openPopup === "sidebar" && currentPage === page) return { page: page, open: false }
  return { page: page, open: true }
}

// Wheel notches: one signed step per full 120 of angleDelta, remainder kept.
// A direction flip drops the old remainder; delta 0 changes nothing. Touchpads
// send many small deltas, so stepping per event would race through values.
function notchSteps(accum, delta) {
  var a = Number(accum) || 0
  var d = Number(delta) || 0
  if (d === 0) return { accum: a, steps: 0 }
  if ((d > 0) !== (a > 0)) a = 0
  a += d
  var steps = Math.trunc(a / 120) || 0   // `|| 0` turns -0 into 0
  return { accum: a - steps * 120, steps: steps }
}
