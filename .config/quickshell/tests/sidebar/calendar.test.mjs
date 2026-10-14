// Gate test: node tests/sidebar/calendar.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../bar/CalendarLogic.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src + "; return { buildMonthGrid }")()

const days = g => g.map(c => c.day).join(",")
// October 2026: starts on Thursday (4), 31 days.
const oct = M.buildMonthGrid(new Date(2026, 9, 15), false)
assert.equal(oct.length, 42)
assert.equal(days(oct.slice(0, 5)), "27,28,29,30,1")     // Sunday-first: Sep 27..30 then Oct 1
assert.deepEqual(oct.slice(0, 4).map(c => c.other), [true, true, true, true])
assert.equal(oct[4].other, false)
assert.equal(oct[4 + 30].day, 31)
assert.equal(oct[4 + 31].day, 1)                          // Nov 1
assert.equal(oct[4 + 31].other, true)
// Monday-first: Thursday is index 3.
const octM = M.buildMonthGrid(new Date(2026, 9, 15), true)
assert.equal(days(octM.slice(0, 4)), "28,29,30,1")
// February 2028 (leap): 29 days, starts Tuesday.
const feb = M.buildMonthGrid(new Date(2028, 1, 10), false)
assert.equal(feb.filter(c => !c.other).length, 29)
assert.equal(feb[2].day, 1)
// December 2026: starts Tuesday; leading Nov 29, 30; trailing Jan 1..9.
const dec = M.buildMonthGrid(new Date(2026, 11, 1), false)
assert.equal(dec.filter(c => !c.other).length, 31)
assert.equal(days(dec.slice(0, 3)), "29,30,1")
assert.deepEqual(dec.slice(0, 2).map(c => c.other), [true, true])
assert.equal(days(dec.slice(33)), "1,2,3,4,5,6,7,8,9")
assert.equal(dec.slice(33).every(c => c.other), true)
// January 2027: starts Friday; leading Dec 27..31; trailing Feb 1..6.
const jan = M.buildMonthGrid(new Date(2027, 0, 1), false)
assert.equal(days(jan.slice(0, 6)), "27,28,29,30,31,1")
assert.deepEqual(jan.slice(0, 5).map(c => c.other), [true, true, true, true, true])
assert.equal(jan.filter(c => !c.other).length, 31)
assert.equal(days(jan.slice(36)), "1,2,3,4,5,6")
// Invalid date gives 42 empty cells.
assert.equal(M.buildMonthGrid(new Date(NaN), false).length, 42)
console.log("sidebar calendar: ok")
