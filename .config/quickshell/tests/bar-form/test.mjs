// Gate test: node tests/bar-form/test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/BarForm.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const B = new Function(src + "; return { FORMS, fromLegacy, normalize, metrics, shoulderPath, wavePath }")()
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
assert.equal(B.wavePath(40, 2, 4, 10),
  "M 0 10 Q 10 2 20 10 T 40 10 T 60 10 T 80 10")
assert.equal(B.wavePath(40, 1, 4, 10).split(" T ").length, 2)
console.log("PASS bar-form")

// Source guards for fixed regressions.
const read = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
assert.ok(!/Spring\.stop\(\)/.test(read("../../bar/primitives/ColorSpring.qml")), "ColorSpring must not stop() Behavior animations")
assert.ok(/fillColor: barBg\.color/.test(read("../../bar/Bar.qml")), "notch shoulders must follow the body fill")
assert.ok(/BarForm\.fromLegacy/.test(read("../../config/Settings.qml")), "Settings must migrate fullBar")
console.log("PASS source-guards")

const bar = read("../../bar/Bar.qml")
assert.equal((bar.match(/running: root\.ambientMotion/g) || []).length, 2, "both SignalWaves must be gated on ambientMotion")
assert.ok(/ambientMotion: !UPower\.onBattery && !root\.sessionLocked/.test(bar.replace(/readonly property bool /, "")), "ambientMotion gates on battery and lock")
console.log("PASS wave-gating")

const toast = read("../../bar/NotificationToast.qml")
assert.ok(/visualSize[\s\S]{0,300}IconButton \{\s*anchors\.centerIn: parent/.test(toast), "toast close button must sit in a fixed-size wrapper")
console.log("PASS toast-close")
