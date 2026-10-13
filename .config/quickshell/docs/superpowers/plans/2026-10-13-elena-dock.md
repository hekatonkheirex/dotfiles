# elena dock (phase 2c) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Under the elena style, an auto-hiding bottom dock of app icons: visible on an empty workspace, hidden while a window is open, revealed when the pointer reaches the bottom edge; pinned apps from a setting with a Settings editor.

**Architecture:** Pure, node-tested logic (`WindowState.js` event reducer, `DockModel.js` item/selection model) fed by a small singleton (`WindowService`) that reads niri's event stream only under elena. A single always-mapped layer-shell window (`bar/Dock.qml`) shows `DockContent`; its input mask is a 2 px strip while hidden and the dock body while shown. Actions go through `niri msg action`.

**Tech Stack:** Quickshell/QML (`DesktopEntries`, `Quickshell.iconPath`), `.pragma library` JS, node tests, bash + Python PIL render check.

## Global Constraints

- VCS is yadm (no `.git`): `yadm add <paths>`, `yadm commit`. Never `--no-verify`. Never stage `settings.json` or the unrelated modified files (Kvantum, btop, kitty matugen, niri).
- Spec: `docs/superpowers/specs/2026-10-13-elena-dock-design.md`.
- The dock exists only under `Config.elenaTheme`; `WindowService` must not run its event stream otherwise. No behavior change in any other style.
- Visibility rule: `shown = workspaceEmpty || pointerInZone || pointerOnDock || forceShown`; show immediately, hide 400 ms after the pointer leaves; instant under `Config.reducedMotion`.
- Item geometry: tile 50 px, item margin 8 px each side, indicator height 7 px, tile-to-indicator gap 8 px. Tile `Colors.surfaceContainer`, radius `Config.shapeLarge`.
- Indicators: none (no window), dot (running, not focused), wide bar of `tileSize - 2*8` px (focused); color cycles `Colors.primary`, `Colors.secondary`, `Colors.tertiary` by item index; urgent uses `Colors.error` and pulses.
- Left click: launch if pinned with no window, else focus the relevant window (urgent > most recently focused > first); clicking the focused app cycles to its next window. Middle click: close the relevant window. Wheel: cycle focus. No minimize (niri has none).
- Default pinned apps `brave-origin,kitty` (CSV of niri `app_id`s, same storage style as `barWidgetOrder`).
- niri actions are run as `sh -c 'NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg ...'`, the same wrapper `WorkspaceIndicator.qml` uses (the shell environment may lack `NIRI_SOCKET`).
- Hazards (memory `quickshell-elena-theme`, `quickshell-testing-gotchas`): saving files under `~/.config/quickshell` hot-reloads the live shell and can wedge `qs ipc`; subagents run NO `qs ipc`, no restarts, no screenshots of the live desktop, no keystrokes (no wtype). The live check is the controller's, after the user cold-restarts `quickshell.service`. In-memory style switch only; persisted style is `elena`, so restore with `style elena ""` and verify `jq -r .themeStyle settings.json`. Render/golden checks open scratch windows on the compositor briefly (expected).

## File Structure

| File | Responsibility |
|---|---|
| `config/WindowState.js` (new) | pure niri-event reducer + `workspaceEmpty` |
| `config/DockModel.js` (new) | pure `normalizePinned`, `dockItems`, `relevantWindow`, `nextWindow` |
| `tests/dock/window-state.test.mjs`, `tests/dock/dock-model.test.mjs` (new) | gates |
| `config/Settings.qml` (mod) | `dockPinned` setting |
| `config/WindowService.qml`, `config/qmldir` (new/mod) | event-stream singleton |
| `bar/dock/DockItem.qml`, `bar/dock/DockContent.qml` (new) | tile + indicator; row of items |
| `tests/dock/shell.qml`, `scripts/dock-render.sh` (new) | render check |
| `bar/Dock.qml` (new) | layer-shell window, auto-hide, mask |
| `shell.qml` (mod) | instance, actions, IPC `dockState()`/`dockReveal(bool)` |
| `bar/settings/DockSection.qml`, `bar/settings/AppearanceTab.qml`, `bar/SettingsPanel.qml` (new/mod) | pinned-apps editor + search entry |

---

### Task 1: WindowState reducer (gate-tested)

**Files:** Create `config/WindowState.js`, `tests/dock/window-state.test.mjs`

**Interfaces — Produces:**
- `empty() -> state`; `state = { windows: [{id, appId, workspaceId, focused, urgent, focusTs}], focusedWindowId: number|null, focusedWorkspaceId: number|null, clock: number }`
- `applyEvent(state, event) -> state` (same object when nothing the dock shows changed)
- `workspaceEmpty(state) -> bool`

- [ ] **Step 1: Write the failing test** `tests/dock/window-state.test.mjs`

```js
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
```

- [ ] **Step 2: Run, expect FAIL** — `node tests/dock/window-state.test.mjs` → ENOENT `config/WindowState.js`.

- [ ] **Step 3: Create `config/WindowState.js`**

```js
.pragma library

// Folds niri event-stream events into the little the dock needs. Pure: never
// mutates its input, and returns the SAME object when an event changes nothing
// the dock shows (niri emits WindowOpenedOrChanged on every title change).

function empty() {
  return { windows: [], focusedWindowId: null, focusedWorkspaceId: null, clock: 0 }
}

function tsOf(stamp) {
  return stamp && typeof stamp.secs === "number" ? stamp.secs * 1e9 + (stamp.nanos || 0) : 0
}

function compact(w) {
  return {
    id: w.id,
    appId: typeof w.app_id === "string" ? w.app_id : "",
    workspaceId: typeof w.workspace_id === "number" ? w.workspace_id : null,
    focused: !!w.is_focused,
    urgent: !!w.is_urgent,
    focusTs: tsOf(w.focus_timestamp)
  }
}

function sameWindow(a, b) {
  return a.id === b.id && a.appId === b.appId && a.workspaceId === b.workspaceId
    && a.focused === b.focused && a.urgent === b.urgent && a.focusTs === b.focusTs
}

function indexOfId(windows, id) {
  for (var i = 0; i < windows.length; i++) if (windows[i].id === id) return i
  return -1
}

function make(windows, focusedWindowId, focusedWorkspaceId, clock) {
  return { windows: windows, focusedWindowId: focusedWindowId, focusedWorkspaceId: focusedWorkspaceId, clock: clock }
}

function copyWith(w, patch) {
  var out = {}
  for (var k in w) out[k] = w[k]
  for (var p in patch) out[p] = patch[p]
  return out
}

function applyEvent(state, event) {
  if (!event || typeof event !== "object") return state
  var keys = Object.keys(event)
  if (keys.length === 0) return state
  var kind = keys[0]
  var p = event[kind]
  var i, windows

  if (kind === "WindowsChanged") {
    var list = p && Array.isArray(p.windows) ? p.windows : []
    var compacted = []
    var focused = null
    var clock = state.clock
    for (i = 0; i < list.length; i++) {
      if (!list[i] || typeof list[i].id !== "number") continue
      var c = compact(list[i])
      if (c.focused) focused = c.id
      if (c.focusTs > clock) clock = c.focusTs
      compacted.push(c)
    }
    return make(compacted, focused, state.focusedWorkspaceId, clock)
  }

  if (kind === "WindowOpenedOrChanged") {
    if (!p || !p.window || typeof p.window.id !== "number") return state
    var w = compact(p.window)
    var at = indexOfId(state.windows, w.id)
    if (at >= 0 && sameWindow(state.windows[at], w)
        && (!w.focused || state.focusedWindowId === w.id)) return state
    windows = state.windows.slice()
    if (at >= 0) windows[at] = w
    else windows.push(w)
    var focusedId = state.focusedWindowId
    if (w.focused) {
      focusedId = w.id
      for (i = 0; i < windows.length; i++) {
        if (windows[i].id !== w.id && windows[i].focused) windows[i] = copyWith(windows[i], { focused: false })
      }
    } else if (focusedId === w.id) {
      focusedId = null
    }
    return make(windows, focusedId, state.focusedWorkspaceId, Math.max(state.clock, w.focusTs))
  }

  if (kind === "WindowClosed") {
    if (!p || typeof p.id !== "number") return state
    var gone = indexOfId(state.windows, p.id)
    if (gone < 0) return state
    windows = state.windows.slice()
    windows.splice(gone, 1)
    return make(windows, state.focusedWindowId === p.id ? null : state.focusedWindowId,
                state.focusedWorkspaceId, state.clock)
  }

  if (kind === "WindowFocusChanged") {
    var id = p && typeof p.id === "number" ? p.id : null
    if (id === state.focusedWindowId) return state
    var tick = state.clock + 1
    windows = []
    for (i = 0; i < state.windows.length; i++) {
      var cur = state.windows[i]
      if (cur.id === id) windows.push(copyWith(cur, { focused: true, focusTs: tick }))
      else if (cur.focused) windows.push(copyWith(cur, { focused: false }))
      else windows.push(cur)
    }
    return make(windows, id, state.focusedWorkspaceId, id === null ? state.clock : tick)
  }

  if (kind === "WindowUrgencyChanged") {
    if (!p || typeof p.id !== "number") return state
    var u = indexOfId(state.windows, p.id)
    if (u < 0 || state.windows[u].urgent === !!p.urgent) return state
    windows = state.windows.slice()
    windows[u] = copyWith(windows[u], { urgent: !!p.urgent })
    return make(windows, state.focusedWindowId, state.focusedWorkspaceId, state.clock)
  }

  if (kind === "WorkspacesChanged") {
    var rows = p && Array.isArray(p.workspaces) ? p.workspaces : []
    var fw = null
    for (i = 0; i < rows.length; i++) if (rows[i] && rows[i].is_focused) fw = rows[i].id
    if (fw === null || fw === state.focusedWorkspaceId) return state
    return make(state.windows, state.focusedWindowId, fw, state.clock)
  }

  if (kind === "WorkspaceActivated") {
    if (!p || !p.focused || typeof p.id !== "number" || p.id === state.focusedWorkspaceId) return state
    return make(state.windows, state.focusedWindowId, p.id, state.clock)
  }

  return state
}

// True when the focused workspace is known and holds no windows.
function workspaceEmpty(state) {
  if (!state || state.focusedWorkspaceId === null) return false
  for (var i = 0; i < state.windows.length; i++) {
    if (state.windows[i].workspaceId === state.focusedWorkspaceId) return false
  }
  return true
}
```

- [ ] **Step 4: Run, expect PASS** — `node tests/dock/window-state.test.mjs` → `window-state: ok`.
- [ ] **Step 5: Commit**

```bash
yadm add config/WindowState.js tests/dock/window-state.test.mjs
yadm commit -m "dock: pure niri window-state reducer with gate test"
```

---

### Task 2: DockModel (gate-tested)

**Files:** Create `config/DockModel.js`, `tests/dock/dock-model.test.mjs`

**Interfaces — Consumes:** window items shaped by Task 1 (`{id, appId, workspaceId, focused, urgent, focusTs}`). **Produces:**
- `normalizePinned(value) -> string[]` (accepts CSV string or array)
- `pinnedToCsv(list) -> string`
- `dockItems(pinned, windows) -> [{appId, pinned, count, windowIds, focused, urgent}]`
- `relevantWindow(windows, appId) -> number|null`
- `nextWindow(windows, appId, focusedId, direction) -> number|null`

- [ ] **Step 1: Write the failing test** `tests/dock/dock-model.test.mjs`

```js
// Gate test: node tests/dock/dock-model.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/DockModel.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function(src + "; return { normalizePinned, pinnedToCsv, dockItems, relevantWindow, nextWindow }")()

const w = (id, appId, o = {}) => ({ id, appId, workspaceId: 1, focused: false, urgent: false, focusTs: id, ...o })

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
console.log("dock-model: ok")
```

- [ ] **Step 2: Run, expect FAIL** — ENOENT `config/DockModel.js`.

- [ ] **Step 3: Create `config/DockModel.js`**

```js
.pragma library

// Dock item model and window selection. Pure; fed by WindowState windows.

function normalizePinned(value) {
  var parts = Array.isArray(value) ? value : (typeof value === "string" ? value.split(",") : [])
  var seen = {}
  var out = []
  for (var i = 0; i < parts.length; i++) {
    var s = String(parts[i]).trim()
    if (s === "" || seen[s]) continue
    seen[s] = true
    out.push(s)
  }
  return out
}

function pinnedToCsv(list) {
  return normalizePinned(list).join(",")
}

function windowsOf(windows, appId) {
  var out = []
  for (var i = 0; i < (windows || []).length; i++) {
    if (windows[i] && windows[i].appId === appId) out.push(windows[i])
  }
  return out
}

function byId(a, b) { return a.id - b.id }

// Pinned apps first (settings order, shown even with no window), then running
// apps in the order their first window opened (niri ids rise monotonically).
function dockItems(pinned, windows) {
  var pins = normalizePinned(pinned)
  var seen = {}
  var apps = []
  var list = windows || []
  var firstId = {}
  for (var i = 0; i < list.length; i++) {
    var w = list[i]
    if (!w || !w.appId) continue
    if (firstId[w.appId] === undefined || w.id < firstId[w.appId]) firstId[w.appId] = w.id
    if (!seen[w.appId]) { seen[w.appId] = true; apps.push(w.appId) }
  }
  var pinnedSet = {}
  for (var p = 0; p < pins.length; p++) pinnedSet[pins[p]] = true
  var rest = []
  for (var a = 0; a < apps.length; a++) if (!pinnedSet[apps[a]]) rest.push(apps[a])
  rest.sort(function(x, y) { return firstId[x] - firstId[y] })

  var order = pins.concat(rest)
  var items = []
  for (var o = 0; o < order.length; o++) {
    var own = windowsOf(list, order[o]).sort(byId)
    var ids = []
    var focused = false
    var urgent = false
    for (var k = 0; k < own.length; k++) {
      ids.push(own[k].id)
      if (own[k].focused) focused = true
      if (own[k].urgent) urgent = true
    }
    items.push({ appId: order[o], pinned: !!pinnedSet[order[o]], count: own.length,
                 windowIds: ids, focused: focused, urgent: urgent })
  }
  return items
}

// urgent window > most recently focused > lowest id; null when the app has none.
function relevantWindow(windows, appId) {
  var own = windowsOf(windows, appId)
  if (own.length === 0) return null
  var pool = []
  for (var i = 0; i < own.length; i++) if (own[i].urgent) pool.push(own[i])
  if (pool.length === 0) pool = own
  var best = pool[0]
  for (var j = 1; j < pool.length; j++) {
    var c = pool[j]
    if (c.focusTs > best.focusTs || (c.focusTs === best.focusTs && c.id < best.id)) best = c
  }
  return best.id
}

// Next/previous window of the app after `focusedId`, wrapping. Falls back to
// the relevant window when the app is not the focused one.
function nextWindow(windows, appId, focusedId, direction) {
  var own = windowsOf(windows, appId).sort(byId)
  if (own.length === 0) return null
  if (own.length === 1) return own[0].id
  var at = -1
  for (var i = 0; i < own.length; i++) if (own[i].id === focusedId) at = i
  if (at < 0) return relevantWindow(windows, appId)
  var step = direction < 0 ? -1 : 1
  return own[(at + step + own.length) % own.length].id
}
```

- [ ] **Step 4: Run, expect PASS** — `node tests/dock/dock-model.test.mjs` → `dock-model: ok`.
- [ ] **Step 5: Commit**

```bash
yadm add config/DockModel.js tests/dock/dock-model.test.mjs
yadm commit -m "dock: pure dock model and window selection with gate test"
```

---

### Task 3: dockPinned setting

**Files:** Modify `config/Settings.qml` (defaults object near `barWidgetOrder` line ~29; alias ~149; reset ~247; adapter property ~301; load-time normalization near the palette migration ~121-135). Create `tests/dock/settings.test.mjs`.

**Interfaces — Produces:** `Settings.dockPinned: string` (CSV), default `"brave-origin,kitty"`, normalized on load.

- [ ] **Step 1: Failing test** `tests/dock/settings.test.mjs`

```js
// Gate test: node tests/dock/settings.test.mjs  (structural: Settings.qml wiring)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const s = readFileSync(fileURLToPath(new URL("../../config/Settings.qml", import.meta.url)), "utf8")
assert.match(s, /dockPinned: "brave-origin,kitty",/, "default pinned apps")
assert.match(s, /property alias dockPinned: adapter\.dockPinned/, "alias")
assert.match(s, /property string dockPinned: root\.defaults\.dockPinned/, "adapter property")
assert.match(s, /dockPinned = root\.defaults\.dockPinned/, "reset to default")
assert.match(s, /DockModel\.pinnedToCsv\(dockPinned\)/, "normalized on load")
assert.match(s, /import "DockModel\.js" as DockModel/, "imports the model")
console.log("dock settings: ok")
```

- [ ] **Step 2: Run, expect FAIL** (default pinned apps).
- [ ] **Step 3: Implement.** Mirror `barWidgetOrder` at all four places (read each region first): defaults entry `dockPinned: "brave-origin,kitty",`; `property alias dockPinned: adapter.dockPinned`; in the reset function `dockPinned = root.defaults.dockPinned`; in the adapter `property string dockPinned: root.defaults.dockPinned`. Add `import "DockModel.js" as DockModel` after the other `.js` imports. In the load handler, next to the palette migration, add:

```qml
    var normalizedPins = DockModel.pinnedToCsv(dockPinned)
    if (normalizedPins !== dockPinned) {
      dockPinned = normalizedPins
      needsSave = true
    }
```
Do not bump `schemaVersion` unless the file's existing pattern requires it (read the migration block; adding a property with a default needs no version bump).
- [ ] **Step 4: Run, expect PASS** — `node tests/dock/settings.test.mjs && bash scripts/m3-qmllint-gate.sh`.
- [ ] **Step 5: Commit**

```bash
yadm add config/Settings.qml tests/dock/settings.test.mjs
yadm commit -m "dock: dockPinned setting with load-time normalization"
```

---

### Task 4: WindowService (niri event stream, elena only)

**Files:** Create `config/WindowService.qml`; modify `config/qmldir`; create `tests/dock/service.test.mjs`.

**Interfaces — Consumes:** `WindowState.empty/applyEvent/workspaceEmpty` (Task 1). **Produces:** singleton `WindowService { windows: var; focusedWindowId: var; workspaceEmpty: bool; running: bool }`.

- [ ] **Step 1: Failing structural test** `tests/dock/service.test.mjs`

```js
// Gate test: node tests/dock/service.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const qmldir = rd("../../config/qmldir")
assert.match(qmldir, /singleton WindowService 1\.0 WindowService\.qml/, "registered singleton")
const svc = rd("../../config/WindowService.qml")
assert.match(svc, /pragma Singleton/)
assert.match(svc, /import "WindowState\.js" as WindowState/)
assert.match(svc, /niri msg -j event-stream/, "reads the event stream")
assert.match(svc, /NIRI_SOCKET=\$\(ls -t \/run\/user\/\$\(id -u\)\/niri\.\*\.sock/, "socket discovery wrapper")
assert.match(svc, /running: Config\.elenaTheme/, "only runs under elena")
assert.match(svc, /WindowState\.applyEvent\(/, "folds events through the reducer")
assert.match(svc, /JSON\.parse\(/, "parses lines")
assert.match(svc, /try \{[\s\S]*JSON\.parse[\s\S]*\} catch/, "tolerates bad lines")
console.log("window service: ok")
```

- [ ] **Step 2: Run, expect FAIL** (qmldir lacks it).
- [ ] **Step 3: Create `config/WindowService.qml`.** Pattern: read `config/BatteryService.qml` / `config/MediaService.qml` for the singleton header and `Process`/`SplitParser` usage; read `bar/WorkspaceIndicator.qml` ~line 300 for how it consumes `niri msg -j event-stream` and the socket wrapper. Shape:

```qml
pragma Singleton
import QtQml
import Quickshell.Io
import "WindowState.js" as WindowState

QtObject {
  id: root

  // niri event-stream state, only maintained under elena (the dock is the only
  // consumer). Everything derived is a plain property so bindings stay cheap.
  property var state: WindowState.empty()
  readonly property var windows: root.state.windows
  readonly property var focusedWindowId: root.state.focusedWindowId
  readonly property bool workspaceEmpty: WindowState.workspaceEmpty(root.state)
  readonly property bool running: Config.elenaTheme

  property int retryMs: 1000

  function feed(line) {
    var text = line.trim()
    if (text === "") return
    try {
      var next = WindowState.applyEvent(root.state, JSON.parse(text))
      if (next !== root.state) root.state = next
    } catch (e) {
      // ignore one malformed line; the stream keeps going
    }
  }

  property var stream: Process {
    command: ["sh", "-c", "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) exec niri msg -j event-stream"]
    running: Config.elenaTheme
    stdout: SplitParser {
      onRead: function(line) { root.feed(line) }
    }
    onRunningChanged: {
      if (!running && Config.elenaTheme) retry.restart()
      if (!running) root.state = WindowState.empty()
    }
  }

  property var retry: Timer {
    interval: root.retryMs
    repeat: false
    onTriggered: if (Config.elenaTheme) root.stream.running = true
  }
}
```
Fix up to match this repo's singleton conventions (check whether other singleton services declare `pragma Singleton` + `QtObject`, and how they import `Config`; `Config` resolves through the same qmldir). Add `singleton WindowService 1.0 WindowService.qml` to `config/qmldir`. Note: the state resets to empty when the stream stops, so a stale "workspace empty" can never show the dock under another style.
- [ ] **Step 4: Run, expect PASS** — `node tests/dock/service.test.mjs && bash scripts/m3-qmllint-gate.sh`.
- [ ] **Step 5: Commit**

```bash
yadm add config/WindowService.qml config/qmldir tests/dock/service.test.mjs
yadm commit -m "dock: WindowService reads niri events under elena only"
```

---

### Task 5: Dock visuals + render check

**Files:** Create `bar/dock/DockItem.qml`, `bar/dock/DockContent.qml`, `tests/dock/shell.qml`, `scripts/dock-render.sh`.

**Interfaces — Consumes:** `DockModel.dockItems` shape (Task 2). **Produces:**
- `DockItem { appId: string; running: bool; focused: bool; urgent: bool; accent: color; signals activated(), closeRequested(), cycled(int direction); readonly tileSize 50, indicatorHeight 7, itemMargin 8, indicatorGap 8 }`
- `DockContent { items: var; signals itemActivated(string appId), itemClosed(string appId), itemCycled(string appId, int direction) }`

- [ ] **Step 1: Failing render check** `scripts/dock-render.sh` (model on `scripts/sidebar-render.sh`: scratch HOME, settings `{"themeStyle":"elena","colorSource":"fixed","colorPalette":"elenapan","colorVariant":"auto","themePreference":2}`, `SIDEBAR_RENDER_ROOT`-style root override named `DOCK_RENDER_ROOT`, `KEEP_PNG`, the same error-grep pattern and exclusions, `python3 -I` PIL check). `tests/dock/shell.qml` renders `DockContent` in a fixed-size `Item` stage (width 3*66 = 198 + 16, height 50+8+7+16) over `Colors.surface` with a fixed `items` model:

```qml
items: [
  { appId: "brave-origin", pinned: true,  count: 0, windowIds: [],  focused: false, urgent: false },
  { appId: "kitty",        pinned: true,  count: 1, windowIds: [3], focused: false, urgent: false },
  { appId: "zed",          pinned: false, count: 1, windowIds: [7], focused: true,  urgent: false }
]
```
The python check, with column x-ranges computed from the geometry constants (item width = 50 + 2*8 = 66; tile x-offset 8 inside each item; indicator row y from 50+8 to 50+8+7), asserts: (a) tile surface pixels `Colors.surfaceContainer` (elenapan `#232a37`) present in all three tile areas, (b) the indicator band under item 0 has NO accent-colored pixels, (c) item 1's band has between 20 and 80 pixels of `Colors.secondary` (`#f06292`) (a 7 px dot), (d) item 2's band has at least 150 pixels of `Colors.tertiary` (`#5bb8d4`) (a 34x7 bar). Measure the real PNG (`KEEP_PNG`) and adjust the geometry numbers from the measurement, not the other way round; the assertions' meaning must not change.
- [ ] **Step 2: Run, expect FAIL** — `bash scripts/dock-render.sh` (DockContent is not a type).
- [ ] **Step 3: Implement.**

`bar/dock/DockItem.qml`:

```qml
import QtQuick
import Quickshell
import "../../config"

// One dock tile in the reference's style: app icon on a squircle, a dot under
// running apps, a wide bar under the focused one, nothing for pinned-but-closed.
Item {
  id: root

  property string appId: ""
  property bool running: false
  property bool focused: false
  property bool urgent: false
  property color accent: Colors.primary

  readonly property int tileSize: 50
  readonly property int indicatorHeight: 7
  readonly property int itemMargin: 8
  readonly property int indicatorGap: 8

  signal activated()
  signal closeRequested()
  signal cycled(int direction)

  readonly property var entry: DesktopEntries.heuristicLookup(root.appId)
  readonly property string iconSource: root.entry && root.entry.icon !== ""
    ? Quickshell.iconPath(root.entry.icon, true) : ""
  readonly property color indicatorColor: root.urgent ? Colors.error : root.accent

  implicitWidth: root.tileSize + root.itemMargin * 2
  implicitHeight: root.tileSize + root.indicatorGap + root.indicatorHeight

  Rectangle {
    id: tile
    x: root.itemMargin
    width: root.tileSize
    height: root.tileSize
    radius: Config.shapeLarge
    color: Colors.surfaceContainer

    Image {
      id: icon
      anchors.centerIn: parent
      width: 32
      height: 32
      sourceSize: Qt.size(64, 64)
      source: root.iconSource
      visible: status === Image.Ready
    }
    Text {
      anchors.centerIn: parent
      visible: !icon.visible
      text: root.appId.length > 0 ? root.appId.charAt(0).toUpperCase() : "?"
      color: root.accent
      font.family: Config.fontFamily
      font.pixelSize: 22
      font.weight: Font.Medium
    }
  }

  // Indicator row.
  Item {
    x: root.itemMargin
    y: root.tileSize + root.indicatorGap
    width: root.tileSize
    height: root.indicatorHeight

    Rectangle {          // running, not focused: dot
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.indicatorHeight
      height: root.indicatorHeight
      radius: width / 2
      color: root.indicatorColor
      visible: root.running && !root.focused
      opacity: pulse.opacity
    }
    Rectangle {          // focused: wide bar
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.tileSize - root.itemMargin * 2
      height: root.indicatorHeight
      radius: height / 2
      color: root.indicatorColor
      visible: root.focused
      opacity: pulse.opacity
    }
  }

  // Urgent indicators pulse unless motion is reduced.
  QtObject {
    id: pulse
    property real opacity: 1.0
  }
  SequentialAnimation {
    running: root.urgent && !Config.reducedMotion
    loops: Animation.Infinite
    onStopped: pulse.opacity = 1.0
    NumberAnimation { target: pulse; property: "opacity"; to: 0.35; duration: 600 }
    NumberAnimation { target: pulse; property: "opacity"; to: 1.0; duration: 600 }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) root.closeRequested()
      else root.activated()
    }
    onWheel: function(wheel) {
      root.cycled(wheel.angleDelta.y > 0 ? -1 : 1)
    }
  }
}
```

`bar/dock/DockContent.qml`:

```qml
import QtQuick
import "../../config"

// The dock's row of items. No window: Dock.qml hosts it and the render check
// loads it directly.
Row {
  id: root

  property var items: []

  signal itemActivated(string appId)
  signal itemClosed(string appId)
  signal itemCycled(string appId, int direction)

  readonly property var accents: [Colors.primary, Colors.secondary, Colors.tertiary]

  Repeater {
    model: root.items

    DockItem {
      required property var modelData
      required property int index
      appId: modelData.appId
      running: modelData.count > 0
      focused: modelData.focused
      urgent: modelData.urgent
      accent: root.accents[index % root.accents.length]
      onActivated: root.itemActivated(modelData.appId)
      onCloseRequested: root.itemClosed(modelData.appId)
      onCycled: function(direction) { root.itemCycled(modelData.appId, direction) }
    }
  }
}
```
Mind `DesktopEntries` needing `import Quickshell` (already in DockItem). If `DesktopEntries.heuristicLookup("brave-origin")` returns a different/no entry in the scratch HOME the letter fallback tile is drawn; the tile surface assertion is unaffected.
- [ ] **Step 4: Run, expect PASS** — `bash scripts/dock-render.sh && bash scripts/m3-qmllint-gate.sh && qmllint bar/dock/*.qml`.
- [ ] **Step 5: Mutation proof.** In a scratch copy (`DOCK_RENDER_ROOT=<scratch>`; never edit the real tree) set `visible: false` on the focused-bar Rectangle and confirm check (d) FAILS; set the dot's `visible: false` and confirm (c) FAILS. Report both RED outputs.
- [ ] **Step 6: Commit**

```bash
yadm add bar/dock/DockItem.qml bar/dock/DockContent.qml tests/dock/shell.qml scripts/dock-render.sh
yadm commit -m "dock: item and content visuals with render check"
```

---

### Task 6: Dock window, auto-hide, actions, shell wiring

**Files:** Create `bar/Dock.qml`, `tests/dock/window.test.mjs`; modify `shell.qml`, `scripts/m3-qmllint-gate.sh` (add `bar/dock/*.qml`).

**Interfaces — Consumes:** `DockContent` (Task 5), `WindowService` (Task 4), `DockModel` (Task 2), `Settings.dockPinned` (Task 3). **Produces:** `shell.dockActivate(appId)`, `shell.dockClose(appId)`, `shell.dockCycle(appId, direction)`; IPC `dockState(): string` (JSON `{revealed, workspaceEmpty, items}`), `dockReveal(on: bool)`.

- [ ] **Step 1: Failing structural test** `tests/dock/window.test.mjs`

```js
// Gate test: node tests/dock/window.test.mjs (structural)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const dock = rd("../../bar/Dock.qml")
assert.match(dock, /ExclusionMode\.Ignore/, "reserves no space")
assert.match(dock, /WlrLayershell\.layer: WlrLayer\.Top/)
assert.match(dock, /Config\.layerNamespace\("dock"\)/)
assert.match(dock, /anchors\s*\{[\s\S]*bottom: true[\s\S]*left: true[\s\S]*right: true|anchors\s*\{[\s\S]*left: true[\s\S]*right: true[\s\S]*bottom: true/, "full-width bottom anchor")
assert.match(dock, /mask: Region \{ item: /, "input mask follows the visible part")
assert.match(dock, /HoverHandler/, "pointer detection that sees through children")
assert.match(dock, /interval: 400/, "400 ms hide delay")
assert.match(dock, /workspaceEmpty \|\| /, "empty workspace shows the dock")
const shell = rd("../../shell.qml")
assert.match(shell, /function dockActivate\(/)
assert.match(shell, /function dockClose\(/)
assert.match(shell, /function dockCycle\(/)
assert.match(shell, /focus-window --id/)
assert.match(shell, /close-window --id/)
assert.match(shell, /function dockState\(\): string/)
assert.match(shell, /function dockReveal\(on: bool\)/)
assert.match(shell, /Dock \{[\s\S]*visible: Config\.elenaTheme/, "dock only under elena")
console.log("dock window: ok")
```

- [ ] **Step 2: Run, expect FAIL** (no `bar/Dock.qml`).
- [ ] **Step 3: Implement `bar/Dock.qml`.**

```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "dock"

// Elena's bottom dock. One always-mapped, full-width window; its input mask is
// a thin strip at the bottom edge while hidden and the dock body while shown,
// so a hidden dock never steals clicks and the pointer reaching the edge
// reveals it.
PanelWindow {
  id: root

  property var items: []
  property bool workspaceEmpty: false
  property bool forceShown: false          // dev/testing hook (dockReveal)

  readonly property int bodyHeight: 50 + 8 + 7 + 20
  readonly property bool pointerInside: pointer.hovered
  readonly property bool revealed: root.workspaceEmpty || root.forceShown
    || root.pointerInside || holdTimer.running

  signal itemActivated(string appId)
  signal itemClosed(string appId)
  signal itemCycled(string appId, int direction)

  anchors {
    left: true
    right: true
    bottom: true
  }
  implicitHeight: root.bodyHeight
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("dock")
  WlrLayershell.layer: WlrLayer.Top
  mask: Region { item: zone }

  // Linger 400 ms after the pointer leaves before hiding.
  Timer {
    id: holdTimer
    interval: 400
    repeat: false
  }
  onPointerInsideChanged: if (!root.pointerInside) holdTimer.restart()

  // The hit area: 2 px strip when hidden, the whole body when shown.
  Item {
    id: zone
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: root.revealed ? root.bodyHeight : 2

    HoverHandler { id: pointer }
  }

  Item {
    id: body
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    width: content.implicitWidth
    height: content.implicitHeight
    opacity: root.revealed ? 1 : 0
    // Slide up from below the screen edge.
    transform: Translate { y: root.revealed ? 0 : body.height + 24
      Behavior on y { enabled: !Config.reducedMotion; NumberAnimation { duration: Config.motionShort; easing.type: Easing.OutCubic } }
    }
    Behavior on opacity { enabled: !Config.reducedMotion; NumberAnimation { duration: Config.motionShort } }

    DockContent {
      id: content
      items: root.items
      onItemActivated: function(appId) { root.itemActivated(appId) }
      onItemClosed: function(appId) { root.itemClosed(appId) }
      onItemCycled: function(appId, direction) { root.itemCycled(appId, direction) }
    }
  }
}
```
(If `Region { item: ... }` needs `Quickshell` import for `Region`, it is in `import Quickshell`. Adjust the Translate/Behavior syntax if qmllint objects: the intent is slide + fade, instant under reduced motion.)

`shell.qml`: add imports for `"config/DockModel.js" as DockModel` if the file imports other `.js` this way (match the existing style), then near the `Sidebar { }` instance:

```qml
  Dock {
    id: dock
    visible: Config.elenaTheme && bar.visible && !lockScreen.locked
    screen: bar.screen
    items: DockModel.dockItems(DockModel.normalizePinned(Settings.dockPinned), WindowService.windows)
    workspaceEmpty: WindowService.workspaceEmpty
    onItemActivated: function(appId) { shell.dockActivate(appId) }
    onItemClosed: function(appId) { shell.dockClose(appId) }
    onItemCycled: function(appId, direction) { shell.dockCycle(appId, direction) }
  }
```
and the shell-level functions (near `openLauncherWith`):

```qml
  function niriAction(args) {
    Quickshell.execDetached(["sh", "-c",
      "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg action " + args])
  }

  function dockLaunch(appId) {
    var entry = DesktopEntries.heuristicLookup(appId)
    if (entry) entry.execute()
    else Quickshell.execDetached([appId])
  }

  function dockActivate(appId) {
    var windows = WindowService.windows
    var own = DockModel.dockItems([appId], windows)[0]
    if (!own || own.count === 0) { shell.dockLaunch(appId); return }
    var id = own.focused
      ? DockModel.nextWindow(windows, appId, WindowService.focusedWindowId, 1)
      : DockModel.relevantWindow(windows, appId)
    if (id !== null) shell.niriAction("focus-window --id " + Math.floor(id))
  }

  function dockClose(appId) {
    var id = DockModel.relevantWindow(WindowService.windows, appId)
    if (id !== null) shell.niriAction("close-window --id " + Math.floor(id))
  }

  function dockCycle(appId, direction) {
    var id = DockModel.nextWindow(WindowService.windows, appId, WindowService.focusedWindowId, direction)
    if (id !== null) shell.niriAction("focus-window --id " + Math.floor(id))
  }
```
IPC (next to `sidebarSearch`):

```qml
    // Dev/testing: dock state as JSON (items, visibility inputs).
    function dockState(): string {
      return JSON.stringify({
        revealed: dock.revealed,
        workspaceEmpty: WindowService.workspaceEmpty,
        windows: WindowService.windows.length,
        items: dock.items
      })
    }

    // Dev/testing: force the dock shown (true) or back to automatic (false).
    function dockReveal(on: bool): bool {
      dock.forceShown = on
      return dock.revealed
    }
```
Add `bar/dock/*.qml` to `scripts/m3-qmllint-gate.sh`. Batch the `shell.qml` edits into one save.
- [ ] **Step 4: Run, expect PASS** — `node tests/dock/window.test.mjs && bash scripts/m3-qmllint-gate.sh && qmllint bar/Dock.qml bar/dock/*.qml && bash scripts/dock-render.sh`.
- [ ] **Step 5: Commit**

```bash
yadm add bar/Dock.qml tests/dock/window.test.mjs shell.qml scripts/m3-qmllint-gate.sh
yadm commit -m "dock: auto-hiding window, niri actions, IPC hooks"
```

---

### Task 7: Pinned-apps editor in Settings

**Files:** Create `bar/settings/DockSection.qml`, `tests/dock/section.test.mjs`; modify `bar/settings/AppearanceTab.qml`, `bar/SettingsPanel.qml` (search entry).

**Interfaces — Consumes:** `Settings.dockPinned`, `DockModel.normalizePinned/pinnedToCsv`, `DesktopEntries.applications`. 

- [ ] **Step 1: Failing structural test** `tests/dock/section.test.mjs`

```js
// Gate test: node tests/dock/section.test.mjs (structural)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const section = rd("../../bar/settings/DockSection.qml")
assert.match(section, /DockModel\.normalizePinned\(Settings\.dockPinned\)/, "reads the pinned list")
assert.match(section, /Settings\.dockPinned = DockModel\.pinnedToCsv\(/, "writes through the model")
assert.match(section, /Settings\.save\(\)/, "persists")
assert.match(section, /DesktopEntries\.applications/, "add-app source")
assert.match(section, /startupClass/, "app_id guess prefers startupClass")
assert.match(section, /Elena/, "tells the user the dock is Elena-only")
assert.match(rd("../../bar/settings/AppearanceTab.qml"), /DockSection \{/, "wired into Appearance")
assert.match(rd("../../bar/SettingsPanel.qml"), /title: "Dock pinned apps"/, "search entry")
console.log("dock section: ok")
```

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement.** Read `bar/settings/BarOrderRow.qml`, `SettingsCard.qml`, `SettingsSectionLabel.qml` and a short section of `GeneralTab.qml` ("Bar contents", ~lines 320-420) first and follow their idioms. `DockSection.qml` is a `ColumnLayout` containing: a `SettingsSectionLabel { text: "Dock" }`; a note `Text` ("The dock appears under the Elena style: shown on an empty workspace, hidden while windows are open, revealed at the bottom edge."); a `SettingsCard` with a `Repeater` over `DockModel.normalizePinned(Settings.dockPinned)` rendering each pinned app as a row (icon from `DesktopEntries.heuristicLookup(modelData)`, name or the raw id, move-up, move-down and remove `IconButton`s that rebuild the list and write `Settings.dockPinned = DockModel.pinnedToCsv(list); Settings.save()`); and an "Add app" `TextFieldControl` (`leadingIcon: "search"`, placeholder "Add app") with a results list of up to 6 `DesktopEntries.applications` entries whose `name` or `id` contains the query (case-insensitive), skipping `noDisplay` entries and apps already pinned; choosing one appends `entry.startupClass !== "" ? entry.startupClass : entry.id` and clears the field. In `AppearanceTab.qml` add `DockSection { Layout.fillWidth: true }` after the palette/color sections at the end of the main column (read the column's end first). In `SettingsPanel.qml` `searchEntries` add `{ tab: 2, category: "Dock", icon: "dock_to_bottom", title: "Dock pinned apps", anchor: "Dock", subtitle: "Apps the Elena dock always shows" }`. If `AppearanceTab.qml` is saved as part of this task, save it once.
- [ ] **Step 4: Run, expect PASS** — `node tests/dock/section.test.mjs && node tests/settings-tabs/test.mjs && bash scripts/m3-qmllint-gate.sh && qmllint bar/settings/DockSection.qml`.
- [ ] **Step 5: Commit**

```bash
yadm add bar/settings/DockSection.qml bar/settings/AppearanceTab.qml bar/SettingsPanel.qml tests/dock/section.test.mjs
yadm commit -m "dock: pinned-apps editor in Appearance settings"
```

---

### Task 8: Gates, live check, ship (controller)

- [ ] **Step 1: Full gates.** `node tests/dock/window-state.test.mjs && node tests/dock/dock-model.test.mjs && node tests/dock/settings.test.mjs && node tests/dock/service.test.mjs && node tests/dock/window.test.mjs && node tests/dock/section.test.mjs`, the existing node gates (`tests/elena`, `tests/sidebar` x2, `tests/bar-form`, `tests/settings-tabs`), `bash scripts/dock-render.sh`, `scripts/sidebar-render.sh`, `scripts/tag-strip-render.sh`, `scripts/tests/test_niri_shape.sh`, `scripts/m3-qmllint-gate.sh`, `scripts/controls-behavior.sh .`, `scripts/controls-golden-baseline.sh check` (twice).
- [ ] **Step 2: Live check.** The user cold-restarts `quickshell.service`. Then: `dockState` JSON lists pinned apps (`brave-origin`, `kitty`) with counts matching `niri msg -j windows`; with windows open on the focused workspace `revealed` is false; `dockReveal true` returns true and a `grim` screenshot shows the dock at the bottom (read it); `dockReveal false` returns false; switch the in-memory style to `material3` and confirm `dockState` still answers but the window is not visible (`WindowService.running` false: `windows` stays 0) then `style elena ""`; `jq -r .themeStyle settings.json` is `elena`. Do not click or send keystrokes to the dock (actions are covered by the pure tests; one manual click check is left to the user).
- [ ] **Step 3: Docs and memory.** Append the dock section to the spec's Usage (IPC hooks, the settings key, the Settings location), update `quickshell-elena-theme.md` (2c shipped, `WindowService`, `dockPinned`, hot-zone design, what niri actions are used), push with `yadm push origin main`.
- [ ] **Step 4: Report** what to restart (nothing; QML hot-reloads) and the one manual check.

---

## Self-review

- **Spec coverage:** visibility rule and 400 ms delay (T6), single-window hot zone via mask (T6), items/order/grouping (T2), indicators (T5), click/middle/scroll semantics (T2 selection + T6 actions), icons via `DesktopEntries` (T5), `WindowState`/`WindowService` (T1/T4), `dockPinned` (T3), Settings UI + search entry (T7), IPC hooks (T6), render check with mutation proof (T5), live check (T8). Right-click picker, drag reorder, badges, per-output docks stay out of scope.
- **Placeholders:** none; the spots that say "read first" (Settings.qml regions, singleton conventions, `Region` import) name the files and what to match.
- **Types:** `windows` items `{id, appId, workspaceId, focused, urgent, focusTs}` are produced by `WindowState` (T1) and consumed unchanged by `DockModel` (T2) and `shell.dock*` (T6); `dockItems` item shape `{appId, pinned, count, windowIds, focused, urgent}` is what `DockContent` binds (T5) and `dockState` serializes (T6).
- **Risks:** `HoverHandler` on the mask item when the mask region itself is the hit area (an input-transparent window gets no hover outside the mask, by design); `Region { item }` tracking an item whose height changes (verify live); `DesktopEntries.heuristicLookup` misses for apps whose `app_id` differs from their desktop id (letter fallback covers it); the event stream emits `WindowOpenedOrChanged` on every title change (reducer returns the same state, so no QML churn).
