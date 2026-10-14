// Gate test: node tests/r6/launcher-layout.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const src = readFileSync(fileURLToPath(new URL("../../config/LauncherLayout.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const L = new Function('"use strict";\n' + src + "; return { LINES, MIN_WIDTH_DP, windowWidth, listHeight, centered, clampSelection }")()

assert.equal(L.LINES, 8)
assert.equal(L.windowWidth(1920, 560, 16), 960)
assert.equal(L.windowWidth(2560, 560, 16), 1280)
assert.equal(L.windowWidth(1366, 560, 16), 683)
assert.equal(L.windowWidth(1000, 560, 16), 560, "minimum wins when 50 percent is narrower")
assert.equal(L.windowWidth(500, 560, 16), 468, "never wider than the screen less the gaps")
assert.equal(L.windowWidth(20, 560, 16), 0)
assert.equal(L.listHeight(60, 3), 8 * 60 + 7 * 3)
assert.equal(L.centered(1080, 740), 170)
assert.equal(L.centered(600, 900), 0, "taller than the screen pins to the edge")
assert.equal(L.clampSelection(-3, 5), 0)
assert.equal(L.clampSelection(9, 5), 4)
assert.equal(L.clampSelection(2, 5), 2)
assert.equal(L.clampSelection(4, 0), 0)
console.log("launcher-layout: ok")
