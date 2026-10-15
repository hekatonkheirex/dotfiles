.pragma library

// 42 cells (six rows) with leading and trailing days of the neighbouring
// months marked `other`. An invalid date gives 42 empty cells.
function buildMonthGrid(date, startsMonday) {
  var cells = []
  if (!date || isNaN(date.getTime())) {
    for (var e = 0; e < 42; e++) cells.push({ day: 0, other: true })
    return cells
  }
  var first = new Date(date.getFullYear(), date.getMonth(), 1)
  var lead = first.getDay()
  if (startsMonday) lead = (lead + 6) % 7
  var start = new Date(first.getFullYear(), first.getMonth(), 1 - lead)
  for (var i = 0; i < 42; i++) {
    var d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
    cells.push({ day: d.getDate(), other: d.getMonth() !== date.getMonth() })
  }
  return cells
}
