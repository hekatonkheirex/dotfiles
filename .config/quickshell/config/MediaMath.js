.pragma library

// config/MediaMath.js: position and seek arithmetic for the Media page.
function fraction(positionSec, lengthSec) {
  if (!(lengthSec > 0) || !isFinite(positionSec)) return 0
  return Math.max(0, Math.min(1, positionSec / lengthSec))
}

function timeText(sec) {
  if (!isFinite(sec) || sec < 0) sec = 0
  var s = Math.floor(sec)
  return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60)
}

function fractionOfLine(index, lines) { return (index + 1) / lines }
