// Gate test: node tests/bar-form/test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/BarForm.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const B = new Function(src + "; return { FORMS, fromLegacy, normalize, metrics, resolve, shoulderPath, outlinePath, wavePath }")()
const o = { barWidth: 42, spacingSmall: 8, spacingLarge: 16 }

assert.deepEqual(B.FORMS, ["full", "fit", "dock", "notch", "pill"])
for (const bad of [undefined, null, "", "pills", "FULL"]) assert.equal(B.normalize(bad), "full")
for (const f of B.FORMS) assert.equal(B.normalize(f), f)

assert.equal(B.fromLegacy(false), "pill")
for (const v of [true, undefined, null, "false"]) assert.equal(B.fromLegacy(v), "full")

assert.deepEqual(B.metrics("full", o), { edgeGap: 0, sideInset: 0, shoulder: 0, roundNear: false, flat: true, pills: false })
assert.deepEqual(B.metrics("fit", o), { edgeGap: 8, sideInset: 8, shoulder: 0, roundNear: true, flat: false, pills: false })
assert.deepEqual(B.metrics("dock", o), { edgeGap: 0, sideInset: 42, shoulder: 0, roundNear: false, flat: false, pills: false })
assert.deepEqual(B.metrics("notch", o), { edgeGap: 0, sideInset: 42, shoulder: 20, roundNear: false, flat: false, pills: false })
assert.deepEqual(B.metrics("pill", o), { edgeGap: 0, sideInset: 0, shoulder: 0, roundNear: false, flat: false, pills: true })
assert.deepEqual(B.metrics("junk", o), B.metrics("full", o))

// Elena forces the workspace strip's full form; saved forms remain reusable.
for (const f of B.FORMS) assert.equal(B.resolve(f, true), "full")
for (const f of B.FORMS) assert.equal(B.resolve(f, false), f)
assert.equal(B.resolve("junk", false), "full")
assert.equal(B.resolve(undefined, true), "full")

assert.equal(B.shoulderPath(0, { edge: "top", x: 0, y: 0, w: 100, h: 42 }), "")

// Top bar, body x=42..158 (window 200 wide): left shoulder spans x 26..42.
const top = B.shoulderPath(16, { edge: "top", x: 42, y: 0, w: 116, h: 42 })
assert.equal(top,
  "M 26 0 L 42 0 L 42 16 A 16 16 0 0 0 26 0 Z " +
  "M 174 0 L 158 0 L 158 16 A 16 16 0 0 1 174 0 Z")

// Every shoulder point stays within s of the corner on both axes.
function parse(p) { return p.split(" Z").filter(Boolean).map(s => s.trim().split(/\s+/)) }
for (const edge of ["top", "bottom", "left", "right"]) {
  const g = { edge, x: 20, y: 30, w: edge === "top" || edge === "bottom" ? 100 : 42,
    h: edge === "top" || edge === "bottom" ? 42 : 100 }
  const paths = parse(B.shoulderPath(16, g))
  assert.equal(paths.length, 2, edge)
  for (const t of paths) {
    const nums = t.filter(x => !isNaN(x)).map(Number)
    // M x y L x y L x y A rx ry rot large sweep x y
    const pts = [[nums[0], nums[1]], [nums[2], nums[3]], [nums[4], nums[5]], [nums[11], nums[12]]]
    const c = pts[1]
    for (const p of pts) assert.ok(Math.abs(p[0] - c[0]) <= 16 && Math.abs(p[1] - c[1]) <= 16, edge)
    // Corner sits on the screen-edge line of the body.
    const onEdge = { top: c[1] === g.y, bottom: c[1] === g.y + g.h, left: c[0] === g.x, right: c[0] === g.x + g.w }[edge]
    assert.ok(onEdge, edge)
    // Far end is on the screen-edge line, third point is toward the bar interior.
    assert.ok(pts[0][0] === pts[3][0] && pts[0][1] === pts[3][1], edge)
  }
}
// Outline: top frame exact, other edges are mirrors/rotations with the same shape.
assert.equal(B.outlinePath(0, 10, { edge: "top", x: 0, y: 0, w: 100, h: 42 }), "")
assert.equal(B.outlinePath(16, 10, { edge: "top", x: 42, y: 0, w: 116, h: 42 }),
  "M 26 0 A 16 16 0 0 1 42 16 L 42 32 A 10 10 0 0 0 52 42 L 148 42 A 10 10 0 0 0 158 32 L 158 16 A 16 16 0 0 1 174 0")
assert.equal(B.outlinePath(16, 10, { edge: "bottom", x: 42, y: 0, w: 116, h: 42 }),
  "M 26 42 A 16 16 0 0 0 42 26 L 42 10 A 10 10 0 0 1 52 0 L 148 0 A 10 10 0 0 1 158 10 L 158 26 A 16 16 0 0 0 174 42")
assert.equal(B.outlinePath(16, 10, { edge: "left", x: 0, y: 42, w: 42, h: 116 }),
  "M 0 26 A 16 16 0 0 0 16 42 L 32 42 A 10 10 0 0 1 42 52 L 42 148 A 10 10 0 0 1 32 158 L 16 158 A 16 16 0 0 0 0 174")
assert.equal(B.outlinePath(16, 10, { edge: "right", x: 0, y: 42, w: 42, h: 116 }),
  "M 42 26 A 16 16 0 0 1 26 42 L 10 42 A 10 10 0 0 0 0 52 L 0 148 A 10 10 0 0 0 10 158 L 26 158 A 16 16 0 0 1 42 174")
// Radius is clamped so a thin bar never folds the outline back on itself.
assert.ok(B.outlinePath(20, 50, { edge: "top", x: 0, y: 0, w: 100, h: 29 }).includes("A 9 9"))
assert.equal(B.wavePath(40, 2, 4, 10),
  "M 0 10 Q 10 2 20 10 T 40 10 T 60 10 T 80 10")
assert.equal(B.wavePath(40, 1, 4, 10).split(" T ").length, 2)
console.log("PASS bar-form")

