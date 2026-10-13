// Gate test: node tests/dock/window-state.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/WindowState.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const { empty, applyEvent, workspaceEmpty } = new Function(src + "; return { empty, applyEvent, workspaceEmpty }")()

const win = (id, app, ws, extra = {}) => ({
  id, title: "t" + id, app_id: app, pid: 100 + id, workspace_id: ws,
  is_focused: false, is_floating: false, is_urgent: false,
  layout: {}, focus_timestamp: { secs: id, nanos: 0 }, ...extra,
})
const wsEv = (list) => ({ WorkspacesChanged: { workspaces: list } })
const wsRow = (id, focused) => ({ id, idx: id, name: null, output: "eDP-1", is_urgent: false, is_active: focused, is_focused: focused, active_window_id: null })

// WindowsChanged seeds everything.
let s = applyEvent(empty(), { WindowsChanged: { windows: [win(2, "brave-origin", 1), win(3, "kitty", 2, { is_focused: true })] } })
assert.deepEqual(s.windows.map(w => [w.id, w.appId, w.workspaceId, w.focused]), [[2, "brave-origin", 1, false], [3, "kitty", 2, true]])
assert.equal(s.focusedWindowId, 3)

// Workspaces: focused workspace id and emptiness.
s = applyEvent(s, wsEv([wsRow(1, false), wsRow(2, true), wsRow(3, false)]))
assert.equal(s.focusedWorkspaceId, 2)
assert.equal(workspaceEmpty(s), false)
s = applyEvent(s, { WorkspaceActivated: { id: 3, focused: true } })
assert.equal(s.focusedWorkspaceId, 3)
assert.equal(workspaceEmpty(s), true)
s = applyEvent(s, { WorkspaceActivated: { id: 1, focused: false } })     // not focused: ignored
assert.equal(s.focusedWorkspaceId, 3)
assert.equal(workspaceEmpty(empty()), false, "unknown workspace is not 'empty'")

// Title-only change returns the SAME object (no dock churn).
const same = applyEvent(s, { WindowOpenedOrChanged: { window: win(2, "brave-origin", 1) } })
assert.equal(same, s)

// Open a new window; app change is a change.
s = applyEvent(s, { WindowOpenedOrChanged: { window: win(4, "firefox", 3) } })
assert.equal(s.windows.length, 3)
assert.equal(workspaceEmpty(s), false)
const changed = applyEvent(s, { WindowOpenedOrChanged: { window: win(4, "librewolf", 3) } })
assert.notEqual(changed, s)
assert.equal(changed.windows.find(w => w.id === 4).appId, "librewolf")

// Focus moves; focused flags are exclusive and the focus clock advances.
const before = s.clock
s = applyEvent(s, { WindowFocusChanged: { id: 2 } })
assert.equal(s.focusedWindowId, 2)
assert.deepEqual(s.windows.filter(w => w.focused).map(w => w.id), [2])
assert.ok(s.windows.find(w => w.id === 2).focusTs > before)
assert.equal(applyEvent(s, { WindowFocusChanged: { id: 2 } }), s)
s = applyEvent(s, { WindowFocusChanged: { id: null } })
assert.equal(s.focusedWindowId, null)
assert.deepEqual(s.windows.filter(w => w.focused), [])

// Urgency.
s = applyEvent(s, { WindowUrgencyChanged: { id: 4, urgent: true } })
assert.equal(s.windows.find(w => w.id === 4).urgent, true)
assert.equal(applyEvent(s, { WindowUrgencyChanged: { id: 4, urgent: true } }), s)
assert.equal(applyEvent(s, { WindowUrgencyChanged: { id: 999, urgent: true } }), s)

// Close, including the focused window and an unknown id.
s = applyEvent(s, { WindowFocusChanged: { id: 3 } })
s = applyEvent(s, { WindowClosed: { id: 3 } })
assert.equal(s.focusedWindowId, null)
assert.equal(s.windows.some(w => w.id === 3), false)
assert.equal(applyEvent(s, { WindowClosed: { id: 12345 } }), s)

// Immutability and junk.
const frozen = Object.freeze({ ...s, windows: Object.freeze(s.windows.map(w => Object.freeze({ ...w }))) })
applyEvent(frozen, { WindowFocusChanged: { id: 2 } })
applyEvent(frozen, { WindowClosed: { id: 2 } })
for (const junk of [null, undefined, 5, "x", {}, { Nope: {} }, { WindowClosed: null }, { WindowsChanged: null }]) {
  assert.doesNotThrow(() => applyEvent(s, junk))
}
assert.equal(applyEvent(s, { Nope: {} }), s)
console.log("window-state: ok")
