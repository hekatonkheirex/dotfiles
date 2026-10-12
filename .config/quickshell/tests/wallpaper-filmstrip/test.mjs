// Gate test: node tests/wallpaper-filmstrip/test.mjs
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"

const read = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const F = new Function(read("../../config/WallpaperFilmstrip.js").replace(/^\.pragma library$/m, "")
  + "; return { geometry, clampIndex, label, stamp, parse, find, normalize, layout }")()

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
// Type-to-jump.
const names = ["Last Horizon.jpeg", "jessica-helgesson-rain-sky-01.jpg", "sky_blue.png", "Skyline.webp"]
assert.equal(F.find(names, ""), -1, "empty query matches nothing")
assert.equal(F.find(names, "last"), 0)
assert.equal(F.find(names, "SKY"), 2, "prefix match wins over contains, case-insensitive")
assert.equal(F.find(names, "rain sky"), 1, "separators normalize to spaces")
assert.equal(F.find(names, "rain-sky"), 1)
assert.equal(F.find(names, "zzz"), -1)
assert.equal(F.find([], "a"), -1)
// Layout: resting positions, constant gaps and continuity while sliding.
{
  const geo = F.geometry(1920), sp = 2, step = geo.sliceW + sp
  const at = (i, pos) => F.layout(i, pos, geo, sp)
  assert.equal(at(5, 5).x, 0, "selected card rests at x = 0")
  assert.equal(at(5, 5).w, geo.cardW)
  assert.equal(at(5, 5).h, geo.cardH)
  assert.equal(at(4, 5).x, -step, "left neighbour is one slice step away")
  assert.equal(at(4, 5).w, geo.sliceW)
  assert.equal(at(6, 5).x, step + geo.cardW - geo.sliceW, "right neighbour clears the card")
  for (const pos of [5, 5.25, 5.5, 5.9, 6, 7.3, 0, 0.4]) {
    let widths = 0
    for (let i = Math.floor(pos) - 3; i <= Math.floor(pos) + 4; i++) {
      const a = at(i, pos), b = at(i + 1, pos)
      assert.ok(Math.abs(b.x - (a.x + a.w + sp)) < 1e-6, `gap at pos ${pos}, item ${i}`)
      if (i >= Math.floor(pos) - 1 && i <= Math.floor(pos) + 2) widths += a.w - geo.sliceW
    }
    assert.ok(Math.abs(widths - (geo.cardW - geo.sliceW)) < 1e-6, "one card of extra width in total at pos " + pos)
  }
  // Continuous: a tiny move in pos moves every item by a tiny amount.
  for (let i = 2; i <= 9; i++) {
    const a = at(i, 5.999), b = at(i, 6.001)
    assert.ok(Math.abs(a.x - b.x) < 2 && Math.abs(a.w - b.w) < 2, "continuous across integer pos, item " + i)
  }
}
console.log("PASS filmstrip-logic")

// Wiring guards.
const qml = read("../../bar/WallpaperFilmstrip.qml")
assert.ok(/apply-wallpaper\.sh/.test(qml), "applies through the shared script")
assert.ok(/Qt\.Key_Escape/.test(qml), "Escape is handled")
assert.ok(/Qt\.Key_Return/.test(qml) && /Qt\.Key_Left/.test(qml) && /Qt\.Key_Right/.test(qml), "keyboard navigation")
assert.ok(/% slot\.span\) \+ slot\.span\) % slot\.span/.test(qml), "delegates keep their item as the window advances")
assert.ok(!/ListView/.test(qml), "no ListView: its origin drifts as delegates load")
assert.ok(/Repeater \{\s+model: 2 \* strip\.reach \+ 3/.test(qml), "windowed delegates, not 700+ live ones")
assert.ok(/layerNamespace\("popup"\)/.test(qml), "uses a namespace the compositor does not blur")
assert.ok(/source: slot\.current && slot\.valid && strip\.rested \?/.test(qml), "full image only for the selected card, once it has rested")
const shell = read("../../shell.qml")
assert.ok(/function wallpapers\(\)/.test(shell), "IPC entry exists")
assert.ok(/WallpaperFilmstrip \{/.test(shell), "window instantiated")
assert.ok(/shell\.wallpaperFilmstripOpen = false/.test(shell.slice(shell.indexOf("function dismissPopups"))), "dismissPopups closes it")
const launcher = read("../../bar/LauncherPopup.qml")
assert.ok(/signal wallpapersRequested\(string query\)/.test(launcher), "launcher exposes the hand-off")
assert.ok(/if \(!root\.wallpaperMode\) return\s+root\.wallpapersRequested\(root\.searchText\.trim\(\)\.substring\(1\)\.trim\(\)\)\s+root\.dismissed\(\)/.test(launcher), "@ opens the filmstrip and closes the launcher")
assert.ok(/onWallpapersRequested: function\(query\)[\s\S]{0,120}wallpaperFilmstripOpen = true/.test(shell), "shell opens the filmstrip on request")
assert.ok(/initialQuery: shell\.wallpaperFilmstripQuery/.test(shell), "query reaches the filmstrip")
assert.ok(/if \(root\.query !== ""\) root\.query = ""\s+else root\.dismissed\(\)/.test(qml), "Escape clears typed text before closing")
console.log("PASS filmstrip-wiring")
