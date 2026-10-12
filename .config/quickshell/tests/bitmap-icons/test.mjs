// Gate test: node tests/bitmap-icons/test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/BitmapIcons.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const B = new Function(src + "; return { symbols, glyph }")()

assert.equal(B.glyph("power_settings_new"), "")
assert.equal(B.glyph("no_such_icon"), "")
assert.equal(B.glyph(""), "")
assert.equal(B.glyph("constructor"), "") // own keys only, not Object.prototype
for (const [label, cp] of Object.entries(B.symbols)) {
  assert.ok(cp >= 0xE000 && cp <= 0xE27A, `${label}: U+${cp.toString(16)} outside Siji range`)
  assert.equal(B.glyph(label).codePointAt(0), cp)
}
console.log(`ok: ${Object.keys(B.symbols).length} labels`)
