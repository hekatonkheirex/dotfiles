.pragma library

// cava ascii frame ("12;40;7;...", 0..100 per bar) to wave levels in 0..1.
// Stereo output is mirrored (bass at both ends, treble in the middle), so the
// two channels fold into one low-to-high spectrum before splitting in two.
var GAIN = 2.5       // cava autosens leaves mean band energy near 0.2-0.4
var ATTACK = 0.6     // fraction of the gap closed per frame while rising
var RELEASE = 0.15   // and while falling, so peaks snap and decay softly

function parse(line) {
  var parts = String(line).trim().split(";")
  var vals = []
  for (var i = 0; i < parts.length; i++) {
    var n = parseInt(parts[i])
    if (!isNaN(n)) vals.push(n)
  }
  return vals
}

function mean(vals, from, to) {
  var s = 0
  for (var i = from; i < to; i++) s += vals[i]
  return to > from ? s / (to - from) : 0
}

function level(vals, from, to) {
  var v = Math.min(1, Math.max(0, mean(vals, from, to) / 100 * GAIN))
  return Math.sqrt(v)   // lifts quiet passages so they still move the line
}

function bands(vals) {
  var half = Math.floor(vals.length / 2)
  if (half < 2) return { low: 0, high: 0 }
  var folded = []
  for (var i = 0; i < half; i++)
    folded.push((vals[i] + vals[vals.length - 1 - i]) / 2)
  var mid = Math.floor(half / 2)
  return { low: level(folded, 0, mid), high: level(folded, mid, half) }
}

function follow(prev, next) {
  var k = next > prev ? ATTACK : RELEASE
  var v = prev + (next - prev) * k
  return v < 0.01 ? 0 : v
}
