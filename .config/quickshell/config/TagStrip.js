.pragma library

// Block states for the elena tag strip. Input is the item list
// WorkspaceIndicator.visibleWorkspaces already builds (idx, isFocused,
// isOccupied), so the 5/10/active count rules live in one place.
var ACCENT_COUNT = 3

function tagStates(workspaces) {
  if (!Array.isArray(workspaces)) return []
  var out = []
  for (var i = 0; i < workspaces.length; i++) {
    var w = workspaces[i]
    if (!w || typeof w.idx !== "number") continue
    out.push({
      idx: w.idx,
      state: w.isFocused ? "focused" : (w.isOccupied ? "occupied" : "empty"),
      accent: ((w.idx - 1) % ACCENT_COUNT + ACCENT_COUNT) % ACCENT_COUNT
    })
  }
  return out
}
