// Gate test: node tests/power-menu/model.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/PowerMenuModel.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src +
  "; return { buttons, paletteAccents, ringBorder, maskInput, step, glyph }")()

const b = M.buttons()
assert.deepEqual(b.map(x => x.id), ["poweroff", "reboot", "exit", "hibernate", "suspend", "lock"])
assert.deepEqual(b.map(x => x.accent), [1, 2, 4, 6, 3, 5])
assert.deepEqual(b.map(x => x.confirm), [true, true, true, false, false, false])
assert.deepEqual(M.paletteAccents(), [1, 3, 2, 6, 4, 5])

assert.deepEqual(M.ringBorder(0, "clear"), { kind: "clear", n: 0 })
assert.deepEqual(M.ringBorder(1, "insert"), { kind: "accent", n: 1 })
assert.deepEqual(M.ringBorder(2, "insert"), { kind: "accent", n: 3 })
assert.deepEqual(M.ringBorder(6, "insert"), { kind: "accent", n: 5 })
assert.deepEqual(M.ringBorder(7, "insert"), { kind: "accent", n: 1 })   // cycle wraps
assert.deepEqual(M.ringBorder(1, "delete"), { kind: "muted", n: 8 })    // style 1 odd
assert.deepEqual(M.ringBorder(2, "delete"), { kind: "border", n: 0 })   // style 2 even
assert.deepEqual(M.ringBorder(7, "delete"), { kind: "muted", n: 8 })    // style 1 again
assert.deepEqual(M.ringBorder(0, "delete"), { kind: "clear", n: 0 })

assert.equal(M.maskInput(0), "")
assert.equal(M.maskInput(4), "****")
assert.equal(M.maskInput(-3), "")

assert.equal(M.step(0, "right", 6), 1)
assert.equal(M.step(5, "right", 6), 0)
assert.equal(M.step(0, "left", 6), 5)
assert.equal(M.step(1, "down", 6), 4)
assert.equal(M.step(4, "down", 6), 1)
assert.equal(M.step(1, "up", 6), 4)
assert.equal(M.step(2, "other", 6), 2)

// Codepoints from her powermenu.yuck.
assert.deepEqual(["poweroff", "reboot", "exit", "hibernate", "suspend", "lock", "lockOpen", "lockFailed"]
  .map(id => M.glyph(id).codePointAt(0).toString(16)),
  ["ee10", "eb92", "ec9d", "ee0e", "ed60", "ec53", "eac8", "ea45"])
assert.equal(M.glyph("heart"), "favorite")   // Material Symbols ligature
assert.equal(M.glyph("nope"), "")
console.log("power-menu model ok")
