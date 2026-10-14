.pragma library

// Block states for the elena tag strip (her workspaces row, adapted to niri).
// Niri workspaces are dynamic, so the row holds the workspaces that exist
// (WorkspaceIndicator.visibleWorkspaces: idx, isFocused, isOccupied) and not
// her fixed ten slots. The look is hers: her accent order, focused opacity 1,
// occupied 0.3, empty 0 (0.2 on hover), non-focused hover 0.6, and rounded
// bottom corners where a block's neighbor is empty.

// Her slot colors in order (x1 x3 x2 x6 x4 x5, repeating the first four).
var ACCENT_ORDER = [1, 3, 2, 6, 4, 5, 1, 3, 2, 6]

var OPACITY = { focused: 1.0, occupied: 0.3, empty: 0.0 }
var HOVER_OPACITY = { focused: 1.0, occupied: 0.6, empty: 0.2 }

function accentSlot(idx) {
  var n = ACCENT_ORDER.length
  return ACCENT_ORDER[(((idx - 1) % n) + n) % n]
}

function stateOf(w) {
  return w.isFocused ? "focused" : (w.isOccupied ? "occupied" : "empty")
}

function opacityFor(state, hovered) {
  var table = hovered ? HOVER_OPACITY : OPACITY
  return table[state] !== undefined ? table[state] : 0
}

function tagStates(workspaces) {
  if (!Array.isArray(workspaces)) return []
  var items = []
  for (var i = 0; i < workspaces.length; i++) {
    var w = workspaces[i]
    if (!w || !Number.isInteger(w.idx)) continue
    items.push({ idx: w.idx, state: stateOf(w) })
  }
  for (var j = 0; j < items.length; j++) {
    items[j].slot = accentSlot(items[j].idx)
    // Her round-left/round-right: only against an empty neighbor, never at
    // the row's own ends.
    items[j].roundLeft = j > 0 && items[j - 1].state === "empty"
    items[j].roundRight = j < items.length - 1 && items[j + 1].state === "empty"
  }
  return items
}

// Wheel accumulation: 120 units per notch. Up (positive) is the previous
// workspace as hers; returns the step to take now and the remainder.
function wheelStep(accum, delta) {
  var total = accum + delta
  if (total >= 120) return { step: -1, accum: 0 }
  if (total <= -120) return { step: 1, accum: 0 }
  return { step: 0, accum: total }
}
