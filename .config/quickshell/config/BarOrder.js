.pragma library

var defaultOrder = [
  "launcher", "workspaces", "layout", "focused", "gap", "center",
  "audio", "display", "media", "weather", "battery", "tray",
  "notifications", "clock"
]

function normalize(value) {
  if (typeof value !== "string") return defaultOrder.slice()
  var items = value.split(",")
  var previousOrder = items.length === defaultOrder.length - 1
    && items.indexOf("center") === -1
  if (!previousOrder && items.length !== defaultOrder.length) return defaultOrder.slice()
  var seen = {}
  for (var i = 0; i < items.length; i++) {
    if (defaultOrder.indexOf(items[i]) === -1 || seen[items[i]]) return defaultOrder.slice()
    seen[items[i]] = true
  }
  if (previousOrder) {
    if (items.indexOf("gap") === -1) return defaultOrder.slice()
    items.splice(items.indexOf("gap") + 1, 0, "center")
  }
  return items
}

// The dividers mark the start and end of the middle group. The clock normally
// uses its theme position; moving it opts into the ordered regions.
function move(value, id, direction, clockInFlow) {
  var items = normalize(value)
  if (id === "gap" || id === "center" || (direction !== -1 && direction !== 1)) return items.join(",")
  var from = items.indexOf(id)
  if (from < 0) return items.join(",")
  var to = from + direction
  if (id !== "clock" && !clockInFlow && items[to] === "clock") to += direction
  if (to < 0 || to >= items.length) return items.join(",")
  var neighbor = items[to]
  items[to] = id
  items[from] = neighbor
  return items.join(",")
}

// Material and vertical bars center an untouched clock; horizontal Ghost
// keeps it at the end. The first arrow starts from that visible position.
function moveClock(value, direction, themeZone) {
  var items = normalize(value)
  items.splice(items.indexOf("clock"), 1)
  items.splice(themeZone === "middle" ? items.indexOf("gap") + 1 : items.length,
    0, "clock")
  return move(items.join(","), "clock", direction, true)
}

function zone(value, id) {
  var items = normalize(value)
  var at = items.indexOf(id)
  if (at < 0 || id === "gap" || id === "center") return ""
  if (at < items.indexOf("gap")) return "start"
  return at < items.indexOf("center") ? "middle" : "end"
}

function group(value, name, themeZone, clockInFlow) {
  var items = normalize(value)
  var first = items.indexOf("gap")
  var second = items.indexOf("center")
  var from = name === "start" ? 0 : (name === "middle" ? first + 1 : second + 1)
  var to = name === "start" ? first : (name === "middle" ? second : items.length)
  var result = items.slice(from, to)
  if (!clockInFlow) {
    var clock = result.indexOf("clock")
    if (clock !== -1) result.splice(clock, 1)
    if (name === themeZone) {
      if (name === "middle") result.unshift("clock")
      else result.push("clock")
    }
  }
  return result
}

function moveToZone(value, id, target) {
  var items = normalize(value)
  if (id === "gap" || id === "center"
      || (target !== "start" && target !== "middle" && target !== "end")
      || zone(value, id) === target) return items.join(",")
  var from = items.indexOf(id)
  if (from < 0) return items.join(",")
  items.splice(from, 1)
  var to = target === "start" ? items.indexOf("gap")
    : (target === "middle" ? items.indexOf("center") : items.length)
  items.splice(to, 0, id)
  return items.join(",")
}

function edgeOrder(value, enabled) {
  var items = normalize(value)
  var gap = items.indexOf("gap")
  var center = items.indexOf("center")
  return items.filter(function(id, index) {
    return id !== "center" && (index <= gap || index > center)
      && (id === "gap" || enabled[id] !== false)
  })
}

function middleOrder(value, enabled) {
  var items = normalize(value)
  return items.slice(items.indexOf("gap") + 1, items.indexOf("center"))
    .filter(function(id) { return enabled[id] !== false })
}
