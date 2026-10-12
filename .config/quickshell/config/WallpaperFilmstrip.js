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
