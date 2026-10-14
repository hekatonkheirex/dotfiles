.pragma library

// Pure alarm logic for her alarms window (R5). Times are epoch milliseconds,
// input state is {field, hours, minutes, label} with string inputs as her
// input-sink-alarms.sh kept them.

var DAY_MINUTES = 1440
var DEFAULT_LABEL = "beep beep"
var LIMITS = { hours: 2, minutes: 2, label: 16 }
var MAX = { hours: 23, minutes: 59 }
var NEXT_FIELD = { hours: "minutes", minutes: "label", label: "hours" }
var PREVIOUS_FIELD = { hours: "label", minutes: "hours", label: "minutes" }

function pad2(n) { return (n < 10 ? "0" : "") + n }

function emptyState() { return { field: "hours", hours: "", minutes: "", label: "" } }

function toInt(s) {
  var n = parseInt(s, 10)
  return isNaN(n) ? 0 : n
}

function totalMinutes(state) { return toInt(state.hours) * 60 + toInt(state.minutes) }

// Her alarm-set-minutes.sh: total wraps in a day, both directions.
function addMinutes(total, delta) {
  return (((total + delta) % DAY_MINUTES) + DAY_MINUTES) % DAY_MINUTES
}

function stepMinutes(state, delta) {
  var t = addMinutes(totalMinutes(state), delta)
  return { field: state.field, hours: String(Math.floor(t / 60)), minutes: String(t % 60), label: state.label }
}

// Her input-sink-alarms.sh. Unknown keys and rejected characters change nothing.
function applyKey(state, key) {
  var s = { field: state.field, hours: state.hours, minutes: state.minutes, label: state.label }
  var f = s.field
  if (key === "tab") { s.field = NEXT_FIELD[f]; return s }
  if (key === "s-tab") { s.field = PREVIOUS_FIELD[f]; return s }
  if (key === "backspace") { s[f] = s[f].slice(0, -1); return s }
  if (key === "c-backspace") { s[f] = ""; return s }
  if (typeof key !== "string" || key.length !== 1) return s
  if (s[f].length >= LIMITS[f]) return s
  if (f === "label") {
    if (key < " ") return s
    s.label = s.label + key
    return s
  }
  if (key < "0" || key > "9") return s
  var next = s[f] + key
  s[f] = toInt(next) > MAX[f] ? String(MAX[f]) : next
  return s
}

function previewHours(state) { return pad2(toInt(state.hours)) }
function previewMinutes(state) { return pad2(toInt(state.minutes)) }

// "ring at": next occurrence of hh:mm, tomorrow when it is not in the future.
function nextOccurrence(nowMs, hh, mm) {
  var d = new Date(nowMs)
  d.setHours(hh, mm, 0, 0)
  if (d.getTime() <= nowMs) d.setDate(d.getDate() + 1)
  return d.getTime()
}

function inMinutes(nowMs, n) { return nowMs + n * 60000 }

// Confirm: mode "quick" | "standard". null when nothing may be scheduled.
function fromInput(mode, state, nowMs) {
  var label = state.label === "" ? DEFAULT_LABEL : state.label
  if (mode === "quick") {
    var t = totalMinutes(state)
    if (t === 0) return null
    return { at: inMinutes(nowMs, t), label: label }
  }
  if (mode === "standard") {
    return { at: nextOccurrence(nowMs, toInt(state.hours), toInt(state.minutes)), label: label }
  }
  return null
}

function sortAlarms(list) {
  return list.slice().sort(function(a, b) { return a.at !== b.at ? a.at - b.at : a.id - b.id })
}

function due(list, nowMs) {
  return sortAlarms(list.filter(function(a) { return a.at <= nowMs }))
}

function nextId(list) {
  var max = 0
  for (var i = 0; i < list.length; i++) if (list[i].id > max) max = list[i].id
  return max + 1
}

function formatHM(at) {
  var d = new Date(at)
  return pad2(d.getHours()) + ":" + pad2(d.getMinutes())
}

// A corrupt or foreign file is an empty list; bad entries are dropped.
function parse(text) {
  var data
  try { data = JSON.parse(text) } catch (e) { return [] }
  if (!Array.isArray(data)) return []
  var out = [], seen = {}
  for (var i = 0; i < data.length; i++) {
    var a = data[i]
    if (!a || typeof a.at !== "number" || !isFinite(a.at)) continue
    var id = typeof a.id === "number" && a.id > 0 && !seen[a.id] ? a.id : 0
    out.push({ id: id, at: a.at, label: typeof a.label === "string" ? a.label : DEFAULT_LABEL })
    if (id) seen[id] = true
  }
  for (var j = 0; j < out.length; j++) if (!out[j].id) out[j].id = nextId(out)
  return sortAlarms(out)
}

function serialize(list) { return JSON.stringify(sortAlarms(list)) + "\n" }

// How late a ring may be before the notification says it was missed.
var MISSED_AFTER_MS = 90000

// Re-arm interval: exact deadline, never above 30 s (suspend drift), never 0.
function nextDelay(list, nowMs) {
  if (list.length === 0) return 0
  var earliest = sortAlarms(list)[0].at
  return Math.max(250, Math.min(30000, earliest - nowMs))
}
