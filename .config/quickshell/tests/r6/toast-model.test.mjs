// Gate test: node tests/r6/toast-model.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const src = readFileSync(fileURLToPath(new URL("../../config/ToastModel.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const T = new Function('"use strict";\n' + src + "; return { LIMIT, urgencySlot, timeoutMs, keyFor, plan, title }")()

// urgency to accent slot: low x6, normal x2, critical x1; unknown is normal
assert.equal(T.urgencySlot(0), 6)
assert.equal(T.urgencySlot(1), 2)
assert.equal(T.urgencySlot(2), 1)
assert.equal(T.urgencySlot(undefined), 2)

// timeouts: app timeout wins (ms), 0 never, unset follows urgency
assert.equal(T.timeoutMs(1, -1, 8000), 8000)
assert.equal(T.timeoutMs(0, -1, 8000), 3000)
assert.equal(T.timeoutMs(2, -1, 8000), 0, "critical is sticky")
assert.equal(T.timeoutMs(1, 0, 8000), 0, "app asked for never")
assert.equal(T.timeoutMs(2, 1500, 8000), 1500, "app timeout beats critical default")
assert.equal(T.timeoutMs(0, 12000, 8000), 12000)
assert.equal(T.timeoutMs(1, 1500.4, 8000), 1500)
assert.equal(T.timeoutMs(1, -1, 5000), 5000, "normal follows the setting")

// duplicate key
assert.equal(T.keyFor("a", "b", "c"), T.keyFor("a", "b", "c"))
assert.notEqual(T.keyFor("a", "b", "c"), T.keyFor("a", "b", "d"))
assert.notEqual(T.keyFor("ab", "c", ""), T.keyFor("a", "bc", ""), "separator prevents joins")

// stack plan
assert.deepEqual(T.plan([], "k", 5), { action: "append", index: 0, drop: 0 })
assert.deepEqual(T.plan(["a", "b"], "b", 5), { action: "bump", index: 1, drop: 0 })
assert.deepEqual(T.plan(["a", "b", "c", "d"], "e", 5), { action: "append", index: 4, drop: 0 })
assert.deepEqual(T.plan(["a", "b", "c", "d", "e"], "f", 5), { action: "append", index: 5, drop: 1 })
assert.equal(T.LIMIT, 5)

// title
assert.equal(T.title("Hi", 1), "Hi")
assert.equal(T.title("Hi", 3), "Hi (3)")
console.log("toast-model: ok")
