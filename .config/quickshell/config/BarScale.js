.pragma library

// One scale factor drives bar thickness, text, clock, icons and spacing together.
// Baselines are the Settings defaults, so 1.0 is the stock look. Results are
// clamped to the individual sliders' ranges.
var MIN = 0.7
var MAX = 1.3
var STEP = 0.05

function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

function snap(scale) {
  return clamp(Math.round(scale / STEP) * STEP, MIN, MAX)
}

function values(scale) {
  var s = snap(scale)
  return {
    barSize: clamp(Math.round(42 * s), 28, 56),
    fontPixelSize: clamp(Math.round(12 * s), 7, 16),
    clockFontSize: clamp(Math.round(14 * s), 8, 24),
    iconSize: clamp(Math.round(20 * s), 12, 28),
    spacingScale: clamp(Math.round(s * 20) / 20, 0.75, 1.5)
  }
}

// Step on the slider grid whose values() lie closest to the current settings.
// exact is false when any individual slider was tuned away from the step, so
// the UI can say "Custom" instead of claiming a percentage.
function match(o) {
  var best = MIN, bestCost = Infinity
  for (var s = MIN; s <= MAX + 1e-9; s += STEP) {
    var v = values(s)
    var cost = Math.abs(o.barSize - v.barSize) + Math.abs(o.fontPixelSize - v.fontPixelSize)
      + Math.abs(o.clockFontSize - v.clockFontSize) + Math.abs(o.iconSize - v.iconSize)
      + Math.abs(o.spacingScale - v.spacingScale) * 20
    if (cost < bestCost - 1e-9) { bestCost = cost; best = s }
  }
  return { scale: snap(best), exact: bestCost < 1e-6 }
}
