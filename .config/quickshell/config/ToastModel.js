.pragma library

// Pure toast rules from her dunstrc (R6b). Urgency numbers are the
// freedesktop ones: 0 low, 1 normal, 2 critical.

var LIMIT = 5
var LOW_MS = 3000

// Accent slot for text and glyphs: low x6, normal x2, critical x1.
function urgencySlot(urgency) {
  return urgency === 2 ? 1 : urgency === 0 ? 6 : 2
}

// Milliseconds until the card goes; 0 means it stays until closed.
// `expireMs`: the app's own timeout as Quickshell reports it, in milliseconds
// (0 never, negative unset; verified live: notify-send -t 1500 reads 1500).
function timeoutMs(urgency, expireMs, normalMs) {
  if (expireMs === 0) return 0
  if (expireMs > 0) return Math.round(expireMs)
  if (urgency === 2) return 0
  return urgency === 0 ? LOW_MS : normalMs
}

// Cards with the same app, summary and body stack into one with a count.
function keyFor(appName, summary, body) {
  return String(appName) + "\u0000" + String(summary) + "\u0000" + String(body)
}

// keys: the visible cards' keys, oldest first. Either bump the card with this
// key or append a new one, dropping the oldest cards beyond the limit.
function plan(keys, key, limit) {
  var at = keys.indexOf(key)
  if (at >= 0) return { action: "bump", index: at, drop: 0 }
  return { action: "append", index: keys.length, drop: Math.max(0, keys.length + 1 - limit) }
}

function title(summary, count) {
  return count > 1 ? summary + " (" + count + ")" : summary
}
