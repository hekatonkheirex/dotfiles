.pragma library

// Dock item model and window selection. Pure; fed by WindowState windows.

function normalizePinned(value) {
  var parts = Array.isArray(value) ? value : (typeof value === "string" ? value.split(",") : [])
  var seen = {}
  var out = []
  for (var i = 0; i < parts.length; i++) {
    var s = String(parts[i]).trim()
    if (s === "" || seen[s]) continue
    seen[s] = true
    out.push(s)
  }
  return out
}

function pinnedToCsv(list) {
  return normalizePinned(list).join(",")
}

// niri app_id is case-sensitive and often differs in case from the desktop
// entry's StartupWMClass, so every match goes through this key.
function key(appId) { return String(appId).toLowerCase() }

function windowsOf(windows, appId) {
  var k = key(appId)
  var out = []
  for (var i = 0; i < (windows || []).length; i++) {
    if (windows[i] && windows[i].appId && key(windows[i].appId) === k) out.push(windows[i])
  }
  return out
}

function byId(a, b) { return a.id - b.id }

// Pinned apps first (settings order, shown even with no window), then running
// apps in the order their first window opened (niri ids rise monotonically).
// Pins and windows merge by lowercased key; the item shows the pinned spelling
// when pinned, else the spelling of the app's first window.
function dockItems(pinned, windows) {
  var pins = normalizePinned(pinned)
  var list = windows || []
  var firstId = {}
  var spelling = {}
  var apps = []
  for (var i = 0; i < list.length; i++) {
    var w = list[i]
    if (!w || !w.appId) continue
    var k = key(w.appId)
    if (firstId[k] === undefined) apps.push(k)
    if (firstId[k] === undefined || w.id < firstId[k]) { firstId[k] = w.id; spelling[k] = w.appId }
  }
  var order = []
  var pinnedSet = {}
  for (var p = 0; p < pins.length; p++) {
    var pk = key(pins[p])
    if (pinnedSet[pk]) continue
    pinnedSet[pk] = true
    order.push({ key: pk, appId: pins[p] })
  }
  var rest = []
  for (var a = 0; a < apps.length; a++) if (!pinnedSet[apps[a]]) rest.push(apps[a])
  rest.sort(function(x, y) { return firstId[x] - firstId[y] })
  for (var r = 0; r < rest.length; r++) order.push({ key: rest[r], appId: spelling[rest[r]] })

  var items = []
  for (var o = 0; o < order.length; o++) {
    var own = windowsOf(list, order[o].key).sort(byId)
    var ids = []
    var focused = false
    var urgent = false
    for (var j = 0; j < own.length; j++) {
      ids.push(own[j].id)
      if (own[j].focused) focused = true
      if (own[j].urgent) urgent = true
    }
    items.push({ appId: order[o].appId, pinned: !!pinnedSet[order[o].key], count: own.length,
                 windowIds: ids, focused: focused, urgent: urgent })
  }
  return items
}

// urgent window > most recently focused > lowest id; null when the app has none.
function relevantWindow(windows, appId) {
  var own = windowsOf(windows, appId)
  if (own.length === 0) return null
  var pool = []
  for (var i = 0; i < own.length; i++) if (own[i].urgent) pool.push(own[i])
  if (pool.length === 0) pool = own
  var best = pool[0]
  for (var j = 1; j < pool.length; j++) {
    var c = pool[j]
    if (c.focusTs > best.focusTs || (c.focusTs === best.focusTs && c.id < best.id)) best = c
  }
  return best.id
}

// Next/previous window of the app after `focusedId`, wrapping. Falls back to
// the relevant window when the app is not the focused one.
function nextWindow(windows, appId, focusedId, direction) {
  var own = windowsOf(windows, appId).sort(byId)
  if (own.length === 0) return null
  if (own.length === 1) return own[0].id
  var at = -1
  for (var i = 0; i < own.length; i++) if (own[i].id === focusedId) at = i
  if (at < 0) return relevantWindow(windows, appId)
  var step = direction < 0 ? -1 : 1
  return own[(at + step + own.length) % own.length].id
}
