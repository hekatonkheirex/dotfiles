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
