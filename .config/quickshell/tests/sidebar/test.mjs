// Gate test: node tests/sidebar/test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/Weekdays.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const { weekRow } = new Function(src + "; return { weekRow }")()

const letters = row => row.map(d => d.letter).join("")
const todayIdx = row => row.map(d => d.isToday)
  .reduce((acc, t, i) => t ? acc.concat(i) : acc, [])

// Local-time constructors (month is 0-based) keep this timezone independent.
const cases = [
  [new Date(2026, 9, 11, 23, 59), 0, "Sunday"],
  [new Date(2026, 9, 12, 12, 0), 1, "Monday"],
  [new Date(2026, 9, 13, 12, 0), 2, "Tuesday"],
  [new Date(2026, 9, 14, 12, 0), 3, "Wednesday"],
  [new Date(2026, 11, 31, 12, 0), 4, "Thursday, year end"],
  [new Date(2027, 0, 1, 0, 0), 5, "Friday, year start"],
  [new Date(2026, 9, 31, 12, 0), 6, "Saturday, month end"],
  [new Date(2026, 10, 1, 0, 0), 0, "Sunday, month start"],
  [new Date(2026, 2, 8, 2, 30), 0, "Sunday, US DST start"],
]
for (const [date, idx, name] of cases) {
  const row = weekRow(date)
  assert.equal(row.length, 7, name)
  assert.equal(letters(row), "SMTWTFS", name)
  assert.deepEqual(todayIdx(row), [idx], name)
}
// An invalid or missing date marks nothing and still returns 7 letters.
for (const bad of [new Date(NaN), undefined, null, "2026-10-12", 5]) {
  const row = weekRow(bad)
  assert.equal(letters(row), "SMTWTFS")
  assert.deepEqual(todayIdx(row), [])
}
console.log("sidebar: ok")
