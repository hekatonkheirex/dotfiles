.pragma library

// Layout and list helpers for the full-width wallpaper filmstrip. Sizes are
// fractions of the screen width, measured from the reference capture
// (2560 px wide: card ~735x378, slices ~52x357, lean ~3.8 degrees).
var CARD_W = 0.29
var CARD_RATIO = 1.94        // width / height
var SLICE_W = 0.0203
var SLICE_H = 0.945          // of card height
var LEAN_DEG = 3.8

function geometry(screenW) {
  var w = Math.max(320, screenW)
  var cardW = Math.round(w * CARD_W)
  var cardH = Math.round(cardW / CARD_RATIO)
  return {
    cardW: cardW,
    cardH: cardH,
    sliceW: Math.max(8, Math.round(w * SLICE_W)),
    sliceH: Math.round(cardH * SLICE_H),
    lean: Math.tan(LEAN_DEG * Math.PI / 180)
  }
}

function clampIndex(index, delta, count) {
  if (count <= 0) return 0
  return Math.max(0, Math.min(count - 1, index + delta))
}

function label(filename) {
  var dot = filename.lastIndexOf(".")
  return dot > 0 ? filename.substring(0, dot) : filename
}

function two(n) { return (n < 10 ? "0" : "") + n }

function stamp(epochSeconds) {
  var d = new Date(epochSeconds * 1000)
  return d.getFullYear() + "-" + two(d.getMonth() + 1) + "-" + two(d.getDate())
    + "  " + two(d.getHours()) + ":" + two(d.getMinutes())
}

// Input: "name<TAB>mtime" lines plus an optional "@@current<TAB>/full/path".
// Output: { items: [{name, mtime}] sorted by name, current: index }.
function parse(text) {
  var items = []
  var currentName = ""
  var lines = String(text).split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    if (!line) continue
    var cut = line.indexOf("\t")
    if (cut < 0) continue
    var head = line.substring(0, cut)
    var tail = line.substring(cut + 1)
    if (head === "@@current") {
      currentName = tail.substring(tail.lastIndexOf("/") + 1).trim()
    } else {
      items.push({ name: head, mtime: parseFloat(tail) || 0 })
    }
  }
  items.sort(function(a, b) {
    var x = a.name.toLowerCase(), y = b.name.toLowerCase()
    return x < y ? -1 : (x > y ? 1 : 0)
  })
  var current = 0
  for (var j = 0; j < items.length; j++)
    if (items[j].name === currentName) { current = j; break }
  return { items: items, current: current }
}

function normalize(text) {
  return String(text).toLowerCase().replace(/[._\-\s]+/g, " ").trim()
}

// Type-to-jump: first name starting with the query, else first containing it.
// Returns -1 for an empty query or no match.
function find(names, query) {
  var q = normalize(query)
  if (!q) return -1
  var contains = -1
  for (var i = 0; i < names.length; i++) {
    var n = normalize(names[i])
    if (n.indexOf(q) === 0) return i
    if (contains < 0 && n.indexOf(q) > 0) contains = i
  }
  return contains
}

// Geometry of item `i` while the selection sits at the (possibly fractional)
// position `pos`. x is the left edge relative to the selected card's resting
// left edge. Exactly one card-width of extra size is shared between the two
// items that straddle `pos`, and the gap between neighbours is always `spacing`.
function layout(i, pos, geo, spacing) {
  var step = geo.sliceW + spacing
  var fl = Math.floor(pos)
  var f = pos - fl
  var bump = Math.max(0, 1 - Math.abs(i - pos))
  var g = i <= fl ? 0 : (i === fl + 1 ? 1 - f : 1)
  return {
    x: (i - pos) * step + (geo.cardW - geo.sliceW) * g,
    w: geo.sliceW + (geo.cardW - geo.sliceW) * bump,
    h: geo.sliceH + (geo.cardH - geo.sliceH) * bump,
    bump: bump
  }
}
