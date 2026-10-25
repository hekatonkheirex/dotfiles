.pragma library

// 42 cells (six rows) with leading and trailing days of the neighbouring
// months marked `other`. An invalid date gives 42 empty cells.
function buildMonthGrid(date, startsMonday) {
  var cells = []
  if (!date || isNaN(date.getTime())) {
    for (var e = 0; e < 42; e++) cells.push({ day: 0, other: true, key: "" })
    return cells
  }
  var first = new Date(date.getFullYear(), date.getMonth(), 1)
  var lead = first.getDay()
  if (startsMonday) lead = (lead + 6) % 7
  var start = new Date(first.getFullYear(), first.getMonth(), 1 - lead)
  for (var i = 0; i < 42; i++) {
    var d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
    cells.push({ day: d.getDate(), other: d.getMonth() !== date.getMonth(), key: dateKey(d) })
  }
  return cells
}

// "YYYY-MM-DD" in local time; the key ics_events.py puts on each event.
function dateKey(d) {
  var m = d.getMonth() + 1, day = d.getDate()
  return d.getFullYear() + "-" + (m < 10 ? "0" : "") + m + "-" + (day < 10 ? "0" : "") + day
}

function addDays(key, n) {
  var p = key.split("-")
  return dateKey(new Date(+p[0], +p[1] - 1, +p[2] + n))
}

// First key and the key after the last one: the range the grid shows.
function gridRange(cells) {
  if (!cells.length || !cells[0].key) return { start: "", end: "" }
  return { start: cells[0].key, end: addDays(cells[cells.length - 1].key, 1) }
}

function eventsOn(events, key) {
  return (events || []).filter(function(e) { return e.date === key })
}

// { "YYYY-MM-DD": true } for every day with an event.
function daysWithEvents(events) {
  var out = {}
  for (var i = 0; i < (events || []).length; i++) out[events[i].date] = true
  return out
}
