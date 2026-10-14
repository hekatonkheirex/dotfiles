.pragma library

// config/MediaMath.js: position and seek arithmetic for the Media page.
function fraction(positionSec, lengthSec) {
  if (!(lengthSec > 0) || !isFinite(positionSec)) return 0
  return Math.max(0, Math.min(1, positionSec / lengthSec))
}

function seekTarget(positionSec, deltaSec, lengthSec) {
  var t = positionSec + deltaSec
  // Unknown length: cannot seek forward past the current position.
  t = Math.min(t, lengthSec > 0 ? lengthSec : positionSec)
  return Math.max(0, t)
}

function timeText(sec) {
  if (!isFinite(sec) || sec < 0) sec = 0
  var s = Math.floor(sec)
  return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60)
}

function lineIndex(fraction, lines) {
  var f = Math.max(0, Math.min(1, fraction))
  return Math.min(lines - 1, Math.floor(f * lines))
}

function fractionOfLine(index, lines) { return (index + 1) / lines }
