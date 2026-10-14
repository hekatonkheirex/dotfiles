// Gate test: node tests/sidebar/pages.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/SidebarPages.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src + "; return { stepPage, indicatorWidth, wheelPage }")()

assert.equal(M.stepPage(0, 1, 3), 1)
assert.equal(M.stepPage(2, 1, 3), 2)      // clamped, no wrap
assert.equal(M.stepPage(0, -1, 3), 0)
assert.equal(M.stepPage(1, -1, 3), 0)
assert.equal(M.stepPage(1, 5, 3), 2)
assert.equal(M.stepPage(NaN, 1, 3), 1)    // NaN treated as page 0
assert.equal(M.indicatorWidth(true), 27)
assert.equal(M.indicatorWidth(false), 14)
// wheel: positive deltaY (scroll up) goes to the previous page
assert.equal(M.wheelPage(1, 120, 3), 0)
assert.equal(M.wheelPage(1, -120, 3), 2)
assert.equal(M.wheelPage(0, 120, 3), 0)
assert.equal(M.wheelPage(1, 0, 3), 1)
console.log("sidebar pages: ok")
