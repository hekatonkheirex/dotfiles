.pragma library

// Niri's window JSON has no fullscreen flag. A tiled window can never cover
// the whole output because the bar reserves space, so a focused window whose
// size reaches the output's logical size is fullscreen.
// size: [w, h] from layout.window_size; screenW/H: output logical size.
function fillsScreen(size, screenW, screenH) {
  if (!Array.isArray(size) || !(screenW > 0) || !(screenH > 0)) return false
  return size[0] >= screenW && size[1] >= screenH
}

// Pull window_size out of a Niri window object, or null.
function windowSize(win) {
  var s = win && win.layout && win.layout.window_size
  return Array.isArray(s) && s.length === 2 ? [Number(s[0]), Number(s[1])] : null
}
