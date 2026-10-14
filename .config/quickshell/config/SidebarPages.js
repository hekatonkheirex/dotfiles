.pragma library

// config/SidebarPages.js: page stepping for the sidebar and its indicators.
function stepPage(current, delta, count) {
  var c = isFinite(current) ? current : 0
  return Math.max(0, Math.min(count - 1, c + delta))
}

function indicatorWidth(selected) { return selected ? 27 : 14 }

// Scrolling up goes to the previous page, down to the next (her scripts).
function wheelPage(current, deltaY, count) {
  if (!deltaY) return current
  return stepPage(current, deltaY > 0 ? -1 : 1, count)
}
