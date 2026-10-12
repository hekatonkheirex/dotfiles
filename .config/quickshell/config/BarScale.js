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

// Scale implied by the current bar thickness, snapped to the slider grid.
function fromBarSize(barSize) {
  return snap(barSize / 42)
}
