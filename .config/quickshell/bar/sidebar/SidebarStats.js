.pragma library

function firstNumber(text) {
  var token = String(text).trim().split(/\s+/)[0]
  if (!token) return null
  var value = Number(token)
  return isFinite(value) && value >= 0 ? value : null
}

function memory(text) {
  var total = null
  var available = null
  var lines = String(text).split("\n")
  for (var i = 0; i < lines.length; i++) {
    var match = /^(MemTotal|MemAvailable):\s+(\d+)\s+kB\s*$/.exec(lines[i])
    if (!match) continue
    var value = Number(match[2])
    if (match[1] === "MemTotal") total = value
    else available = value
  }
  if (!isFinite(total) || total === null || total <= 0
      || !isFinite(available) || available === null || available > total) return null
  return { used: total - available, total: total }
}

function uptimeLabel(seconds) {
  if (seconds === null || !isFinite(seconds) || seconds < 0) return "Unavailable"
  var minutes = Math.floor(seconds / 60)
  var days = Math.floor(minutes / 1440)
  var hours = Math.floor(minutes / 60) % 24
  return (days > 0 ? days + "d " : "")
    + (days > 0 || hours > 0 ? hours + "h " : "") + (minutes % 60) + "m"
}

function memoryLabel(value) {
  if (value === null) return "Unavailable"
  return (value.used / 1048576).toFixed(1) + " / "
    + (value.total / 1048576).toFixed(1) + " GiB"
}
