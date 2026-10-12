// Gate test: node tests/bar-form/scale.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/BarScale.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const S = new Function(src + "; return { values, fromBarSize, snap }")()

assert.deepEqual(S.values(1), { barSize: 42, fontPixelSize: 12, clockFontSize: 14, iconSize: 20, spacingScale: 1 })
assert.deepEqual(S.values(0.8), { barSize: 34, fontPixelSize: 10, clockFontSize: 12, iconSize: 16, spacingScale: 0.8 })
assert.deepEqual(S.values(0.7), { barSize: 29, fontPixelSize: 8, clockFontSize: 12, iconSize: 14, spacingScale: 0.75 })
assert.deepEqual(S.values(1.3), { barSize: 55, fontPixelSize: 16, clockFontSize: 18, iconSize: 26, spacingScale: 1.3 })
assert.deepEqual(S.values(5), S.values(1.3))
assert.deepEqual(S.values(-1), S.values(0.7))
assert.equal(S.fromBarSize(42), 1)
assert.equal(S.fromBarSize(34), 0.8)
assert.equal(S.fromBarSize(28), 0.7)
assert.equal(S.fromBarSize(56), 1.3)
for (let s = 0.7; s <= 1.3001; s += 0.05) {
  const v = S.values(s)
  assert.ok(v.barSize >= 28 && v.barSize <= 56)
  assert.ok(v.fontPixelSize >= 7 && v.fontPixelSize <= 16)
  assert.ok(v.clockFontSize >= 12 && v.clockFontSize <= 24)
  assert.ok(v.iconSize >= 12 && v.iconSize <= 28)
  assert.ok(v.spacingScale >= 0.75 && v.spacingScale <= 1.5)
}
console.log("PASS bar-scale")
