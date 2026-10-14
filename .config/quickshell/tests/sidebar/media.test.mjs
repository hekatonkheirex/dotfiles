// Gate test: node tests/sidebar/media.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/MediaMath.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src +
  "; return { fraction, seekTarget, timeText, lineIndex, fractionOfLine }")()

assert.equal(M.fraction(30, 120), 0.25)
assert.equal(M.fraction(200, 120), 1)
assert.equal(M.fraction(-5, 120), 0)
assert.equal(M.fraction(10, 0), 0)          // unknown length
assert.equal(M.fraction(NaN, 100), 0)

assert.equal(M.seekTarget(50, 10, 120), 60)
assert.equal(M.seekTarget(115, 10, 120), 120)
assert.equal(M.seekTarget(4, -10, 120), 0)
assert.equal(M.seekTarget(10, 10, 0), 10)   // unknown length: no upper clamp beyond position

assert.equal(M.timeText(0), "0:00")
assert.equal(M.timeText(65), "1:05")
assert.equal(M.timeText(3600 + 61), "61:01")
assert.equal(M.timeText(-3), "0:00")
assert.equal(M.timeText(NaN), "0:00")

// 20 seek lines
assert.equal(M.lineIndex(0, 20), 0)
assert.equal(M.lineIndex(0.049, 20), 0)
assert.equal(M.lineIndex(0.05, 20), 1)
assert.equal(M.lineIndex(1, 20), 19)
assert.equal(M.lineIndex(-1, 20), 0)
assert.equal(M.fractionOfLine(0, 20), 0.05)
assert.equal(M.fractionOfLine(19, 20), 1)
console.log("sidebar media: ok")
