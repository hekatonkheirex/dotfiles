// Gate test: node tests/wallpaper-filmstrip/test.mjs
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"

const read = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const F = new Function(read("../../config/WallpaperFilmstrip.js").replace(/^\.pragma library$/m, "")
  + "; return { geometry, clampIndex, label, stamp, parse }")()

// Geometry follows the reference capture (2560 px: card ~735x378, slices ~52x357).
const g = F.geometry(2560)
assert.ok(Math.abs(g.cardW - 742) <= 8 && Math.abs(g.cardH - 382) <= 8, "card size: " + JSON.stringify(g))
assert.ok(Math.abs(g.sliceW - 52) <= 2 && Math.abs(g.sliceH - 361) <= 8, "slice size: " + JSON.stringify(g))
assert.ok(Math.abs(Math.atan(g.lean) * 180 / Math.PI - 3.8) < 0.01, "lean is 3.8 degrees")
assert.ok(F.geometry(1920).cardW < g.cardW, "geometry scales with the screen")
assert.ok(F.geometry(0).sliceW >= 8, "degenerate screens stay usable")

// Selection never leaves the list.
assert.equal(F.clampIndex(0, -1, 5), 0)
assert.equal(F.clampIndex(4, 1, 5), 4)
assert.equal(F.clampIndex(2, 1, 5), 3)
assert.equal(F.clampIndex(2, -99, 5), 0)
assert.equal(F.clampIndex(2, 99, 5), 4)
assert.equal(F.clampIndex(3, 1, 0), 0, "empty list")

assert.equal(F.label("Last Horizon.jpeg"), "Last Horizon")
assert.equal(F.label("a.b.png"), "a.b")
assert.equal(F.label(".hidden"), ".hidden")
assert.match(F.stamp(0), /^\d{4}-\d{2}-\d{2}  \d{2}:\d{2}$/)

// Listing: case-insensitive sort, and the current wallpaper's index follows the sort.
const p = F.parse("b.png\t10.5\nA.jpg\t20\nc.webp\t30\n@@current\t/home/x/Pictures/Walls/b.png\n")
assert.deepEqual(p.items.map(i => i.name), ["A.jpg", "b.png", "c.webp"])
assert.equal(p.current, 1)
assert.equal(F.parse("a.png\t1\n@@current\t\n").current, 0, "unknown current falls back to the first")
assert.deepEqual(F.parse("").items, [])
assert.equal(F.parse("a b.png\t5\n@@current\t/p/a b.png").current, 0, "names with spaces survive")
console.log("PASS filmstrip-logic")

// Wiring guards.
const qml = read("../../bar/WallpaperFilmstrip.qml")
assert.ok(/apply-wallpaper\.sh/.test(qml), "applies through the shared script")
assert.ok(/Qt\.Key_Escape\) root\.dismissed\(\)/.test(qml), "Escape closes")
assert.ok(/Qt\.Key_Return/.test(qml) && /Qt\.Key_Left/.test(qml) && /Qt\.Key_Right/.test(qml), "keyboard navigation")
assert.ok(/ListView \{/.test(qml), "virtualized list, not 700+ live delegates")
assert.ok(/layerNamespace\("popup"\)/.test(qml), "uses a namespace the compositor does not blur")
assert.ok(/source: slot\.current \? /.test(qml), "full image only for the selected card")
const shell = read("../../shell.qml")
assert.ok(/function wallpapers\(\)/.test(shell), "IPC entry exists")
assert.ok(/WallpaperFilmstrip \{/.test(shell), "window instantiated")
assert.ok(/shell\.wallpaperFilmstripOpen = false/.test(shell.slice(shell.indexOf("function dismissPopups"))), "dismissPopups closes it")
console.log("PASS filmstrip-wiring")
