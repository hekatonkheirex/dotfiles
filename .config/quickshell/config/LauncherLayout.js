.pragma library

// Pure geometry for her rofi launcher layout (R6c).

var LINES = 8          // her listview `lines: 8`, fixed height
var MIN_WIDTH_DP = 560

// 50 percent of the screen, never narrower than `minPx`, never wider than the
// screen less `gapPx` on each side.
function windowWidth(screenW, minPx, gapPx) {
  var w = Math.round(screenW * 0.5)
  if (w < minPx) w = minPx
  var cap = screenW - 2 * gapPx
  return Math.max(0, Math.min(w, cap))
}

function listHeight(rowPx, spacingPx) {
  return LINES * rowPx + (LINES - 1) * spacingPx
}

// Centered position along one axis.
function centered(screenPx, sizePx) {
  return Math.max(0, Math.round((screenPx - sizePx) / 2))
}

function clampSelection(index, count) {
  if (count <= 0) return 0
  return Math.max(0, Math.min(count - 1, index))
}
