.pragma library

// config/SidebarPages.js: page stepping for the sidebar and its indicators.
function stepPage(current, delta, count) {
  var c = isFinite(current) ? current : 0
  return Math.max(0, Math.min(count - 1, c + delta))
}

function indicatorWidth(selected) { return selected ? 27 : 14 }
