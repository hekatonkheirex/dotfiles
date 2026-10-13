// Gate test: node tests/dock/dock-model.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/DockModel.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src + "; return { normalizePinned, pinnedToCsv, dockItems, relevantWindow, nextWindow }")()

const w = (id, appId, o = {}) => ({ id, appId, workspaceId: 1, focused: false, urgent: false, focusTs: id, ...o })

function deepFreeze(v) {
  if (v && typeof v === "object" && !Object.isFrozen(v)) {
    Object.freeze(v)
    for (const k of Object.keys(v)) deepFreeze(v[k])
  }
  return v
}

// normalizePinned
assert.deepEqual(M.normalizePinned("a, b ,,a,c"), ["a", "b", "c"])
assert.deepEqual(M.normalizePinned(["x", " y ", "x", ""]), ["x", "y"])
for (const bad of [undefined, null, 5, {}, ""]) assert.deepEqual(M.normalizePinned(bad), [])
assert.equal(M.pinnedToCsv(["a", "b", "a"]), "a,b")

// dockItems: pinned first in order (even with no window), then others by first-opened window.
const windows = [w(7, "zed"), w(3, "kitty", { focused: true }), w(5, "kitty"), w(9, "mpv", { urgent: true }), w(4, "")]
const items = M.dockItems("brave-origin,kitty", windows)
assert.deepEqual(items.map(i => i.appId), ["brave-origin", "kitty", "zed", "mpv"])
assert.deepEqual(items[0], { appId: "brave-origin", pinned: true, count: 0, windowIds: [], focused: false, urgent: false })
assert.deepEqual(items[1], { appId: "kitty", pinned: true, count: 2, windowIds: [3, 5], focused: true, urgent: false })
assert.equal(items.find(i => i.appId === "mpv").urgent, true)
assert.equal(items.find(i => i.appId === "mpv").pinned, false)
assert.equal(items.some(i => i.appId === ""), false, "windows without an app id are skipped")
assert.deepEqual(M.dockItems([], []), [])
assert.deepEqual(M.dockItems(undefined, undefined), [])

// relevantWindow: urgent > most recently focused > lowest id.
assert.equal(M.relevantWindow([w(3, "k"), w(5, "k", { urgent: true }), w(8, "k")], "k"), 5)
assert.equal(M.relevantWindow([w(3, "k", { focusTs: 10 }), w(5, "k", { focusTs: 30 }), w(8, "k", { focusTs: 20 })], "k"), 5)
assert.equal(M.relevantWindow([w(3, "k", { focusTs: 0 }), w(5, "k", { focusTs: 0 })], "k"), 3)
assert.equal(M.relevantWindow([w(3, "k")], "other"), null)
assert.equal(M.relevantWindow([], "k"), null)

// nextWindow: wraps both ways, single window stays, unfocused app falls back to relevant.
const ks = [w(3, "k"), w(5, "k"), w(8, "k"), w(9, "o")]
assert.equal(M.nextWindow(ks, "k", 3, 1), 5)
assert.equal(M.nextWindow(ks, "k", 8, 1), 3)
assert.equal(M.nextWindow(ks, "k", 3, -1), 8)
assert.equal(M.nextWindow([w(3, "k")], "k", 3, 1), 3)
assert.equal(M.nextWindow(ks, "k", 9, 1), M.relevantWindow(ks, "k"))
assert.equal(M.nextWindow(ks, "k", null, 1), M.relevantWindow(ks, "k"))
assert.equal(M.nextWindow(ks, "none", 3, 1), null)

// No mutation of inputs (frozen inputs throw in strict mode if touched).
const fw = deepFreeze([w(7, "zed"), w(3, "kitty", { focused: true }), w(5, "kitty"), w(9, "mpv", { urgent: true }), w(4, "")])
const fPinned = deepFreeze(["brave-origin", "kitty"])
const fItems = M.dockItems(fPinned, fw)
assert.deepEqual(fItems.map(i => i.appId), ["brave-origin", "kitty", "zed", "mpv"])
assert.deepEqual(fw.map(x => x.id), [7, 3, 5, 9, 4], "dockItems must not reorder its windows input")
assert.equal(M.relevantWindow(fw, "kitty"), 5)
assert.equal(M.nextWindow(fw, "kitty", 3, 1), 5)
assert.deepEqual(fw.map(x => x.id), [7, 3, 5, 9, 4], "nextWindow/relevantWindow must not reorder input")
const fk = deepFreeze([w(8, "k"), w(3, "k"), w(5, "k")])
assert.equal(M.nextWindow(fk, "k", 3, 1), 5)
assert.deepEqual(fk.map(x => x.id), [8, 3, 5], "nextWindow must sort a copy")
assert.deepEqual(M.dockItems(fPinned, deepFreeze([])).map(i => i.appId), ["brave-origin", "kitty"])
assert.deepEqual(M.normalizePinned(deepFreeze(["x", "x", " y "])), ["x", "y"])

// Case-insensitive app ids (niri app_id vs desktop-entry startupClass), frozen inputs.
const cw = deepFreeze([w(2, "google-chrome"), w(4, "Kitty"), w(6, "kitty", { focused: true }), w(8, "Foo"), w(9, "foo")])
const ci = M.dockItems(deepFreeze(["Google-chrome", "KITTY"]), cw)
assert.deepEqual(ci.map(i => i.appId), ["Google-chrome", "KITTY", "Foo"], "pinned spelling wins, unpinned uses first window's")
assert.deepEqual(ci[0], { appId: "Google-chrome", pinned: true, count: 1, windowIds: [2], focused: false, urgent: false })
assert.deepEqual(ci[1], { appId: "KITTY", pinned: true, count: 2, windowIds: [4, 6], focused: true, urgent: false })
assert.deepEqual(ci[2], { appId: "Foo", pinned: false, count: 2, windowIds: [8, 9], focused: false, urgent: false })
assert.deepEqual(M.dockItems(deepFreeze(["Foo", "foo"]), deepFreeze([])).map(i => i.appId), ["Foo"], "pins differing in case collapse")
assert.equal(M.relevantWindow(cw, "KITTY"), 6)
assert.equal(M.relevantWindow(cw, "FOO"), 9, "most recent focusTs across case variants")
assert.equal(M.nextWindow(cw, "kitty", 4, 1), 6)
assert.equal(M.nextWindow(cw, "KITTY", 6, 1), 4)
assert.equal(M.relevantWindow(cw, "nope"), null)

console.log("dock-model: ok")
