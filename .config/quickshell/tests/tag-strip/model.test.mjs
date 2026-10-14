// Gate test: node tests/tag-strip/model.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const src = readFileSync(fileURLToPath(new URL("../../config/TagStrip.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const T = new Function('"use strict";\n' + src + "; return { ACCENT_ORDER, accentSlot, opacityFor, tagStates, wheelStep }")()

// her color order x1 x3 x2 x6 x4 x5 then the first four again
assert.deepEqual([1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(T.accentSlot), [1, 3, 2, 6, 4, 5, 1, 3, 2, 6])
assert.equal(T.accentSlot(11), 1, "cycle continues past ten")
assert.equal(T.accentSlot(20), 6)
assert.equal(T.accentSlot(0), 6, "guards idx 0")

// opacity table: focused 1, occupied .3, empty 0; hover .6 / .2, focused stays 1
assert.equal(T.opacityFor("focused", false), 1)
assert.equal(T.opacityFor("occupied", false), 0.3)
assert.equal(T.opacityFor("empty", false), 0)
assert.equal(T.opacityFor("occupied", true), 0.6)
assert.equal(T.opacityFor("empty", true), 0.2)
assert.equal(T.opacityFor("focused", true), 1)
assert.equal(T.opacityFor("bogus", true), 0)

// states and rounding, her rule against empty neighbors only
const ws = [
  { idx: 1, isFocused: false, isOccupied: true },
  { idx: 2, isFocused: true, isOccupied: true },
  { idx: 3, isFocused: false, isOccupied: false },
]
let b = T.tagStates(ws)
assert.deepEqual(b.map(x => x.state), ["occupied", "focused", "empty"])
assert.deepEqual(b.map(x => x.slot), [1, 3, 2])
assert.deepEqual(b.map(x => x.roundLeft), [false, false, false])
assert.deepEqual(b.map(x => x.roundRight), [false, true, false], "focused before the empty one rounds on the right")
b = T.tagStates([
  { idx: 1, isFocused: false, isOccupied: false },
  { idx: 2, isFocused: true, isOccupied: true },
  { idx: 3, isFocused: false, isOccupied: false },
])
assert.deepEqual(b.map(x => [x.roundLeft, x.roundRight]), [[false, false], [true, true], [false, false]], "isolated block rounds both sides")
// a run of three rounds only at its ends
b = T.tagStates([
  { idx: 1, isFocused: false, isOccupied: false },
  { idx: 2, isFocused: false, isOccupied: true },
  { idx: 3, isFocused: true, isOccupied: true },
  { idx: 4, isFocused: false, isOccupied: true },
  { idx: 5, isFocused: false, isOccupied: false },
])
assert.deepEqual(b.map(x => [x.roundLeft, x.roundRight]),
  [[false, false], [true, false], [false, false], [false, true], [false, false]])
// the row's own ends never round
b = T.tagStates([{ idx: 1, isFocused: true, isOccupied: true }])
assert.deepEqual([b[0].roundLeft, b[0].roundRight], [false, false])
// junk input
assert.deepEqual(T.tagStates(null), [])
assert.deepEqual(T.tagStates([null, { idx: "x" }, { idx: 2, isFocused: true }]).map(x => x.idx), [2])

// wheel: 120 per notch, up is previous (-1), remainder kept, sign flip resets by sum
assert.deepEqual(T.wheelStep(0, 120), { step: -1, accum: 0 })
assert.deepEqual(T.wheelStep(0, -120), { step: 1, accum: 0 })
assert.deepEqual(T.wheelStep(0, 30), { step: 0, accum: 30 })
assert.deepEqual(T.wheelStep(90, 30), { step: -1, accum: 0 })
assert.deepEqual(T.wheelStep(-100, -20), { step: 1, accum: 0 })
assert.deepEqual(T.wheelStep(60, -30), { step: 0, accum: 30 })
console.log("tag-strip model: ok")
