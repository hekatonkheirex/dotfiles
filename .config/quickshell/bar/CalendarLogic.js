.pragma library

var sundayFirstWeekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
var mondayFirstWeekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
var monthNames = ["January", "February", "March", "April", "May", "June", "July",
  "August", "September", "October", "November", "December"]

function daysInMonth(d) {
  return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
}

function monthStartDay(d) {
  return new Date(d.getFullYear(), d.getMonth(), 1).getDay()
}

function weekDays(startsMonday) {
  return startsMonday ? mondayFirstWeekDays : sundayFirstWeekDays
}

function isToday(dayNum, displayMonth, currentDate) {
  return dayNum === currentDate.getDate()
    && displayMonth.getMonth() === currentDate.getMonth()
    && displayMonth.getFullYear() === currentDate.getFullYear()
}

function buildDayModel(date, startsMonday) {
  if (!date || isNaN(date.getTime())) return []
  var list = []
  var startDay = monthStartDay(date)
  if (startsMonday) startDay = (startDay + 6) % 7
  var days = daysInMonth(date)
  for (var i = 0; i < startDay; i++) list.push(-1)
  for (var d = 1; d <= days; d++) list.push(d)
  while (list.length % 7 !== 0) list.push(-1)
  return list
}

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
