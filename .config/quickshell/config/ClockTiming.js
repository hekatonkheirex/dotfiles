.pragma library

function nextInterval(now, showSeconds) {
  return showSeconds
    ? 1000 - now.getMilliseconds()
    : 60000 - now.getSeconds() * 1000 - now.getMilliseconds()
}
