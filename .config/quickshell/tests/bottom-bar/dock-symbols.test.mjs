// Gate test: node tests/bottom-bar/dock-symbols.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/DockSymbols.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src + "; return { symbolFor, table }")()

// Ported entries resolve to their glyphs.
assert.equal(M.symbolFor("kitty").symbol, "\ueef5")
assert.equal(M.symbolFor("firefox").symbol, "\ueb84")
assert.equal(M.symbolFor("org.telegram.desktop").symbol, "\ued28")
// Case-insensitive, like DockModel.
assert.equal(M.symbolFor("Kitty").symbol, "\ueef5")
assert.equal(M.symbolFor("GIMP").symbol, M.symbolFor("Gimp").symbol)
// Color index 1..10 maps onto slots 1..6 (7 to 10 wrap onto 1 to 4).
assert.equal(M.symbolFor("kitty").slot, 5)      // her color "5"
assert.equal(M.symbolFor("lutris").slot, 6)     // her color "6"
assert.equal(M.symbolFor("unknown-app").slot, 4) // default color "10" wraps to 4
// Unknown and empty ids give the default (Material Symbols fallback glyph).
for (const id of ["unknown-app", "", undefined, null]) {
  const s = M.symbolFor(id)
  assert.equal(s.font, "material")
  assert.equal(s.symbol, "web_asset")
}
// Every ported key resolves to a non-empty symbol and a slot in 1..6.
let n = 0
for (const k of Object.keys(M.table)) {
  const s = M.symbolFor(k)
  assert.ok(s.symbol.length > 0, k)
  assert.ok(s.slot >= 1 && s.slot <= 6, k)
  n++
}
assert.equal(n, 35, "34 ported apps + default")
// Prototype names miss the table and get the default glyph.
const def = M.symbolFor("___default___")
for (const id of ["constructor", "__proto__", "toString", "hasOwnProperty"])
  assert.deepEqual(M.symbolFor(id), def, id)
console.log("dock symbols: ok")
