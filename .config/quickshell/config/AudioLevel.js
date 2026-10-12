.pragma library

// cava ascii frame ("12;40;7;...", 0..100 per bar) helpers. The bar's signal
// wave only needs to know whether there is sound; its motion is scripted.
var FLOOR = 3   // cava reads exactly 0 in silence; 3 ignores dither

function parse(line) {
  var parts = String(line).trim().split(";")
  var vals = []
  for (var i = 0; i < parts.length; i++) {
    var n = parseInt(parts[i])
    if (!isNaN(n)) vals.push(n)
  }
  return vals
}

function hasSound(vals) {
  for (var i = 0; i < vals.length; i++) if (vals[i] >= FLOOR) return true
  return false
}
