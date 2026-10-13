// Gate test: node tests/dock/window-state.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

// Strict mode: a reducer that writes to a frozen input throws here instead of
// silently ignoring the write (sloppy mode would hide the mutation).
const body = readFileSync(fileURLToPath(new URL("../../config/WindowState.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const { empty, applyEvent, workspaceEmpty } = new Function('"use strict";\n' + body + "; return { empty, applyEvent, workspaceEmpty }")()

const win = (id, app, ws, extra = {}) => ({
  id, title: "t" + id, app_id: app, pid: 100 + id, workspace_id: ws,
  is_focused: false, is_floating: false, is_urgent: false,
  layout: {}, focus_timestamp: { secs: id, nanos: 0 }, ...extra,
})
const wsEv = (list) => ({ WorkspacesChanged: { workspaces: list } })
const wsRow = (id, focused) => ({ id, idx: id, name: null, output: "eDP-1", is_urgent: false, is_active: focused, is_focused: focused, active_window_id: null })
const niriSecs = (secs) => ({ secs, nanos: 0 })

// WindowsChanged seeds everything.
let s = applyEvent(empty(), { WindowsChanged: { windows: [win(2, "brave-origin", 1), win(3, "kitty", 2, { is_focused: true })] } })
assert.deepEqual(s.windows.map(w => [w.id, w.appId, w.workspaceId, w.focused]), [[2, "brave-origin", 1, false], [3, "kitty", 2, true]])
assert.equal(s.focusedWindowId, 3)

// Replaying an identical WindowsChanged returns the same object; a real change does not.
const seedEv = { WindowsChanged: { windows: [win(2, "brave-origin", 1), win(3, "kitty", 2, { is_focused: true })] } }
const seeded = applyEvent(empty(), seedEv)
assert.equal(applyEvent(seeded, seedEv), seeded, "identical WindowsChanged keeps the same object")
assert.notEqual(applyEvent(seeded, { WindowsChanged: { windows: [win(2, "brave-origin", 1), win(3, "foot", 2, { is_focused: true })] } }), seeded)
assert.notEqual(applyEvent(seeded, { WindowsChanged: { windows: [win(2, "brave-origin", 1)] } }), seeded)

// WindowsChanged replaces the list and drops unknown shapes.
s = applyEvent(seeded, { WindowsChanged: { windows: [win(7, "foot", 1, { is_focused: true }), null, { app_id: "no-id" }, "junk", { id: "8" }] } })
assert.deepEqual(s.windows.map(w => w.id), [7])
assert.equal(s.focusedWindowId, 7)

// Workspaces: focused workspace id and emptiness.
s = applyEvent(seeded, wsEv([wsRow(1, false), wsRow(2, true), wsRow(3, false)]))
assert.equal(s.focusedWorkspaceId, 2)
assert.equal(workspaceEmpty(s), false)
s = applyEvent(s, { WorkspaceActivated: { id: 3, focused: true } })
assert.equal(s.focusedWorkspaceId, 3)
assert.equal(workspaceEmpty(s), true)
s = applyEvent(s, { WorkspaceActivated: { id: 1, focused: false } })     // not focused: ignored
assert.equal(s.focusedWorkspaceId, 3)
assert.equal(workspaceEmpty(empty()), false, "unknown workspace is not 'empty'")

// Title-only change returns the SAME object (no dock churn).
s = applyEvent(seeded, wsEv([wsRow(1, false), wsRow(2, true), wsRow(3, false)]))
s = applyEvent(s, { WorkspaceActivated: { id: 3, focused: true } })
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

// Focus ordering: the dock ranks windows by focusTs, most recently focused highest.
// Niri-scale stamps (secs ~1e6), so local focus ticks must stay comparable with them.
const T = 1e6
const A = 10, B = 11
const ts = (st, id) => st.windows.find(w => w.id === id).focusTs
let o = applyEvent(empty(), { WindowsChanged: { windows: [
  win(A, "A", 1, { is_focused: true, focus_timestamp: niriSecs(T) }),
  win(B, "B", 1, { focus_timestamp: niriSecs(T - 5) }),
] } })
assert.ok(ts(o, A) > ts(o, B), "seed: focused A ranks above B")
o = applyEvent(o, { WindowFocusChanged: { id: B } })
assert.ok(ts(o, B) > ts(o, A), "focusing B ranks B above A")
o = applyEvent(o, { WindowFocusChanged: { id: A } })
assert.ok(ts(o, A) > ts(o, B), "focusing A ranks A above B")
// Title-only re-report of B with its original niri stamp must not lift B above A.
o = applyEvent(o, { WindowOpenedOrChanged: { window: win(B, "B", 1, { focus_timestamp: niriSecs(T - 5) }) } })
assert.ok(ts(o, A) > ts(o, B), "stale re-report does not lift B above A")

// Events the dock does not show return the same object.
const quiet = applyEvent(empty(), { WindowsChanged: { windows: [win(2, "brave-origin", 1), win(3, "kitty", 2, { is_focused: true })] } })
for (const ev of [
  { WorkspaceActiveWindowChanged: { workspace_id: 1, active_window_id: 2 } },
  { WindowLayoutsChanged: { changes: [] } },
  { KeyboardLayoutsChanged: { keyboard_layouts: { names: ["us"], current_idx: 0 } } },
  { OverviewOpenedOrChanged: { is_open: true } },
  { ConfigLoaded: { failed: false } },
  { CastsChanged: { casts: [] } },
]) {
  assert.equal(applyEvent(quiet, ev), quiet, "unrelated event " + Object.keys(ev)[0])
}

// Immutability: frozen input must not throw (strict mode turns any write into a TypeError)
// and must not change, as seen by a JSON snapshot taken before each call.
const deepFreeze = (st) => Object.freeze({ ...st, windows: Object.freeze(st.windows.map(w => Object.freeze({ ...w }))) })
const frozen = deepFreeze(applyEvent(empty(), { WindowsChanged: { windows: [win(2, "brave-origin", 1, { is_focused: true }), win(4, "firefox", 2)] } }))
const frozenEvents = [
  { WindowsChanged: { windows: [win(2, "brave-origin", 1, { is_focused: true }), win(4, "firefox", 2)] } },
  { WindowOpenedOrChanged: { window: win(4, "librewolf", 2) } },
  { WindowOpenedOrChanged: { window: win(5, "foot", 2, { is_focused: true }) } },
  { WindowFocusChanged: { id: 4 } },
  { WindowFocusChanged: { id: null } },
  { WindowUrgencyChanged: { id: 4, urgent: true } },
  { WindowClosed: { id: 2 } },
  wsEv([wsRow(1, false), wsRow(2, true)]),
  { WorkspaceActivated: { id: 1, focused: true } },
]
for (const ev of frozenEvents) {
  const snap = JSON.stringify(frozen)
  assert.doesNotThrow(() => applyEvent(frozen, ev), "frozen input, event " + Object.keys(ev)[0])
  assert.equal(JSON.stringify(frozen), snap, "input unchanged after " + Object.keys(ev)[0])
}

// Junk never throws.
for (const junk of [null, undefined, 5, "x", {}, { Nope: {} }, { WindowClosed: null }, { WindowsChanged: null }]) {
  assert.doesNotThrow(() => applyEvent(s, junk))
}
assert.equal(applyEvent(s, { Nope: {} }), s)
console.log("window-state: ok")
