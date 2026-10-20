.pragma library

// Launch history. store = { id: { n: decayedCount, t: lastUsedMs } }.
// Counts decay with a 14 day half life so last year's habit does not outrank
// this week's.

var HALF_LIFE_MS = 14 * 24 * 3600 * 1000
var MAX_ENTRIES = 500
var MAX_BOOST = 300

function decayed(entry, now) {
  return entry.n * Math.pow(0.5, Math.max(0, now - entry.t) / HALF_LIFE_MS)
}

function record(store, id, now) {
  var next = {}
  for (var k in store) next[k] = store[k]
  var old = next[id]
  next[id] = { n: (old ? decayed(old, now) : 0) + 1, t: now }
  return prune(next, now)
}

function prune(store, now) {
  var ids = Object.keys(store)
  if (ids.length <= MAX_ENTRIES) return store
  ids.sort(function(a, b) { return decayed(store[b], now) - decayed(store[a], now) })
  var kept = {}
  for (var i = 0; i < MAX_ENTRIES; i++) kept[ids[i]] = store[ids[i]]
  return kept
}

// id -> boost in [0, MAX_BOOST]
function boosts(store, now) {
  var out = {}
  for (var id in store) {
    var v = decayed(store[id], now)
    out[id] = Math.min(MAX_BOOST, 60 * Math.log(1 + v) / Math.LN2)
  }
  return out
}

// Defensive parse for a file the user may have edited or truncated.
function parse(text) {
  try {
    var raw = JSON.parse(text)
    var out = {}
    for (var id in raw) {
      var e = raw[id]
      if (e && typeof e.n === "number" && typeof e.t === "number" && isFinite(e.n) && isFinite(e.t) && e.n > 0) out[id] = { n: e.n, t: e.t }
    }
    return out
  } catch (err) {
    return {}
  }
}
