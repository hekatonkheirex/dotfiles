.pragma library

var LETTERS = ["M", "T", "W", "T", "F", "S", "S"]

// Monday-first week row for the sidebar clock. `date` marks today; anything
// that is not a valid Date marks nothing.
function weekRow(date) {
  var today = (date instanceof Date && !isNaN(date.getTime()))
    ? (date.getDay() + 6) % 7
    : -1
  return LETTERS.map(function(letter, i) {
    return { letter: letter, isToday: i === today }
  })
}
