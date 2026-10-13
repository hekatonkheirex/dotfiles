# elena sidebar search field (phase 2b) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A search field at the foot of the elena sidebar; Enter closes the sidebar and opens the existing launcher with the typed text already in its search box.

**Architecture:** The launcher keeps owning all search logic. `LauncherPopup` gets an `initialQuery` hook applied after its existing reset on show (the same path the voice-search result uses). `shell.qml` gets one helper, `openLauncherWith(query)`, shared by the sidebar field and a dev IPC function. The field is a thin wrapper around the existing `TextFieldControl`.

**Tech Stack:** Quickshell/QML, node (structural gate test), bash + Python PIL (render check).

## Global Constraints

- VCS is yadm (no `.git`): `yadm add <paths>`, `yadm commit`. Never `--no-verify`. Never stage `settings.json` or the unrelated modified Kvantum files.
- Spec: `docs/superpowers/specs/2026-10-12-elena-sidebar-search-design.md`.
- Only the elena style is affected: the sidebar exists only under `Config.elenaTheme`; `sidebarSearch` returns false elsewhere; the launcher's behavior is unchanged when `initialQuery` is empty.
- No inline results, no Down-arrow handling, no voice input from the sidebar (spec "Out of scope").
- Hazards (memory `quickshell-elena-theme`, `quickshell-testing-gotchas`): saving files under `~/.config/quickshell` hot-reloads the live shell and can wedge `qs ipc`; subagents run NO `qs ipc`, no restarts, no screenshots of the live desktop, no keystrokes. The live check is the controller's, after the user cold-restarts `quickshell.service`. In-memory style switch only (`qs ipc call shell style elena ""`); the persisted style is `elena` now, so restore to `elena`, not `material3`, and verify with `jq -r .themeStyle settings.json`.

## File Structure

| File | Responsibility |
|---|---|
| `bar/LauncherPopup.qml` (mod) | `initialQuery` hook applied after the reset on show |
| `shell.qml` (mod) | `anchorLauncher()`, `openLauncherWith(query)`, `sidebarSearch`/`launcherQuery` IPC, Sidebar handler |
| `tests/sidebar/search.test.mjs` (new) | Structural gate: hook exists, applied after the reset, consumed, helper sets it before opening |
| `bar/sidebar/SearchField.qml` (new) | `TextFieldControl` wrapper: `submitted(text)`, `escaped()`, `focusField()`, `clear()` |
| `bar/sidebar/SidebarContent.qml` (mod) | Field below the level bars; focus on open, clear on close; forwards signals |
| `bar/Sidebar.qml` (mod) | `searchSubmitted(text)` signal; Esc closes |
| `tests/sidebar/shell.qml`, `scripts/sidebar-render.sh` (mod) | Taller stage; assert the field border is drawn |

---

### Task 1: Launcher hook, shell helper, IPC, structural gate

**Files:**
- Modify: `bar/LauncherPopup.qml` (`property string searchText` ~line 191; `onVisibleChanged` ~line 759-775), `shell.qml` (IPC `launcher()` ~line 291, `launcherMode()` ~line 384, `Sidebar {}` ~line 571, shell-level functions near `popupBarInset()` ~line 231)
- Create: `tests/sidebar/search.test.mjs`

**Interfaces:**
- Produces: `LauncherPopup.initialQuery: string`; `shell.openLauncherWith(query: string)`; IPC `sidebarSearch(text: string): bool`, `launcherQuery(): string`; the `Sidebar` instance connects `onSearchSubmitted` (signal added in Task 2).

- [ ] **Step 1: Write the failing test** `tests/sidebar/search.test.mjs`

```js
// Gate test: node tests/sidebar/search.test.mjs
// Structural: the launcher hook exists and is applied after the reset on show,
// and the shell helper sets it before the launcher opens.
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const read = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const launcher = read("../../bar/LauncherPopup.qml")
const shell = read("../../shell.qml")

assert.match(launcher, /property string initialQuery: ""/, "initialQuery property")

const start = launcher.indexOf("onVisibleChanged: {")
assert.ok(start > 0, "launcher onVisibleChanged")
const body = launcher.slice(start, start + 4000)
const reset = body.indexOf("filteredModel.clear()")
const apply = body.indexOf("root.initialQuery")
const done = body.indexOf("root.voiceRecording = false")
assert.ok(reset > 0 && apply > reset, "initialQuery is applied after the reset")
assert.ok(done > apply, "initialQuery is applied before the visible branch ends")
assert.match(body, /root\.initialQuery = ""/, "initialQuery is consumed")
assert.match(body, /searchInputControl\.text = q/, "text goes through the input")
assert.match(body, /root\.filterApps\(\)/, "results are filtered")

const helper = shell.slice(shell.indexOf("function openLauncherWith"))
const set = helper.indexOf("launcherPopup.initialQuery = query")
const open = helper.indexOf('bar.openPopup = "launcher"')
assert.ok(set > 0 && open > set, "helper sets initialQuery before opening the launcher")
assert.match(shell, /function sidebarSearch\(text: string\): bool/, "sidebarSearch IPC")
assert.match(shell, /function launcherQuery\(\): string/, "launcherQuery IPC")
assert.match(shell, /onSearchSubmitted: function\(text\) \{ shell\.openLauncherWith\(text\) \}/, "sidebar hand-off")
console.log("sidebar search: ok")
```

- [ ] **Step 2: Run, expect FAIL**

Run: `node tests/sidebar/search.test.mjs`
Expected: AssertionError on `initialQuery property`.

- [ ] **Step 3: Launcher hook.** In `bar/LauncherPopup.qml`, next to `property string searchText: ""` add:

```qml
  // Set by the sidebar search field (shell.qml) before the launcher opens; applied
  // once after the on-show reset below, then cleared.
  property string initialQuery: ""
```

In `onVisibleChanged`, inside the `if (visible) {` branch, immediately after the `if (appModel.count > 0) { for ... appendFilteredResult(...) }` block and before the `if (Config.reducedMotion || root.dmenu) {` animation block, add:

```qml
      if (root.initialQuery !== "") {
        var q = root.initialQuery
        root.initialQuery = ""
        searchInputControl.text = q
        root.searchText = q
        root.selectedIndex = 0
        root.filterApps()
        searchInputControl.input.cursorPosition = q.length
      }
```

(Read the real lines first; match the file's indentation. The brief's placement rule is: after the reset and the app list refill, before the entry animation.)

- [ ] **Step 4: Shell helper and IPC.** In `shell.qml`, next to `popupBarInset()` add:

```qml
  // Anchors the launcher exactly as the launcher() IPC call does.
  function anchorLauncher() {
    if (bar.horizontal) {
      bar.popupAnchorX = bar.getLauncherX()
    } else {
      bar.popupAnchorY = 0
    }
  }

  // Opens the launcher with `query` already typed. Shared by the sidebar search
  // field and the sidebarSearch IPC hook. Re-opening while the launcher is
  // already visible must re-run its on-show reset, so close it first.
  function openLauncherWith(query) {
    anchorLauncher()
    if (bar.openPopup === "launcher") bar.openPopup = ""
    launcherPopup.initialQuery = query
    bar.openPopup = "launcher"
  }
```

Change the IPC `launcher()` body to use the shared anchoring:

```qml
    function launcher() {
      shell.anchorLauncher()
      bar.openPopup = bar.openPopup === "launcher" ? "" : "launcher"
    }
```

Next to `launcherMode()` add:

```qml
    // Dev/testing: submit the sidebar search with `text` (same path as Enter).
    // False outside the elena style.
    function sidebarSearch(text: string): bool {
      if (!Config.elenaTheme) return false
      shell.openLauncherWith(text)
      return true
    }

    // Dev/testing: the launcher's current search text.
    function launcherQuery(): string {
      return launcherPopup.searchText
    }
```

On the `Sidebar { ... }` instance add:

```qml
    onSearchSubmitted: function(text) { shell.openLauncherWith(text) }
```
(the signal itself is added in Task 2; until then the handler line is harmless to qmllint only if the signal exists, so add this line in Task 2 Step 4 instead and keep the gate assertion for it there; see below.)

**Order note:** to keep every commit lint-clean, in this task omit the `onSearchSubmitted` line and in Step 1's test comment out the `onSearchSubmitted` assertion; Task 2 Step 5 re-enables it. Concretely: remove the last `assert.match(shell, /onSearchSubmitted ...` line from the test now and add it back in Task 2.

- [ ] **Step 5: Run, expect PASS**

Run: `node tests/sidebar/search.test.mjs && bash scripts/m3-qmllint-gate.sh`
Expected: `sidebar search: ok`, lint exit 0.

- [ ] **Step 6: Commit**

```bash
yadm add bar/LauncherPopup.qml shell.qml tests/sidebar/search.test.mjs
yadm commit -m "launcher: initialQuery hook; shell: openLauncherWith and sidebar search IPC"
```

---

### Task 2: Search field in the sidebar + render check

**Files:**
- Create: `bar/sidebar/SearchField.qml`
- Modify: `bar/sidebar/SidebarContent.qml`, `bar/Sidebar.qml`, `shell.qml` (Sidebar instance), `tests/sidebar/shell.qml`, `scripts/sidebar-render.sh`, `tests/sidebar/search.test.mjs`

**Interfaces:**
- Consumes: `TextFieldControl` (`bar/primitives`: `text`, `input`, `placeholder`, `leadingIcon`, `accessibleName`, signals `accepted()`, `escapePressed()`), `shell.openLauncherWith` (Task 1).
- Produces: `SearchField { signal submitted(string text); signal escaped(); function focusField(); function clear() }`; `SidebarContent { signal searchSubmitted(string text); signal escaped() }`; `Sidebar { signal searchSubmitted(string text) }`.

- [ ] **Step 1: Failing render assertion.** In `tests/sidebar/shell.qml` change the stage and window height from 640 to 720 (`implicitHeight: 720`, `height: 720`). In `scripts/sidebar-render.sh` change the size assertion to `(w, h) == (320, 720)` and add, before the final `print("sidebar render: ok")`:

```python
# Search field: a bordered row under the level bars. Its border is Colors.outline
# (unfocused) or Colors.primary (focused); the level bars card ends above y=655.
outline = (0x5b, 0x65, 0x78)    # elenapam outline
primary = (0xc7, 0x7d, 0xc8)
FIELD_Y0 = 655
n_border = sum(near(p, outline) or near(p, primary) for p in px[w * FIELD_Y0:])
print(f"search field border px (y>={FIELD_Y0}) {n_border}")
assert n_border >= 300, "search field missing"
```
Also in `tests/sidebar/search.test.mjs` re-add the last assertion from Task 1: `assert.match(shell, /onSearchSubmitted: function\(text\) \{ shell\.openLauncherWith\(text\) \}/, "sidebar hand-off")`.

- [ ] **Step 2: Run, expect FAIL**

Run: `bash scripts/sidebar-render.sh` (opens a window on the compositor briefly; expected) and `node tests/sidebar/search.test.mjs`
Expected: render prints `search field border px ... 0` and FAILs with "search field missing"; the node test fails on "sidebar hand-off".

- [ ] **Step 3: Create `bar/sidebar/SearchField.qml`**

```qml
import QtQuick
import "../../config"
import "../primitives"

// Sidebar search box. Submitting hands the text to the launcher (shell.qml);
// results are never shown here.
TextFieldControl {
  id: root

  signal submitted(string text)
  signal escaped()

  placeholder: "Search"
  leadingIcon: "search"
  accessibleName: "Search apps and actions"

  function focusField() { root.input.forceActiveFocus() }
  function clear() { root.text = "" }

  onAccepted: root.submitted(root.text)
  onEscapePressed: root.escaped()
}
```

- [ ] **Step 4: Wire the content, the window and the shell.**

`bar/sidebar/SidebarContent.qml`: add signals after `property bool active: true`:

```qml
  signal searchSubmitted(string text)
  signal escaped()
```
and append inside the ColumnLayout after `LevelBars { ... }`:

```qml
  SearchField {
    id: search
    Layout.fillWidth: true
    onSubmitted: function(text) { root.searchSubmitted(text) }
    onEscaped: root.escaped()
  }

  // Focus the field when the sidebar opens (after the window has focus) and
  // clear it when it closes.
  Timer {
    id: focusTimer
    interval: 50
    onTriggered: search.focusField()
  }
  onActiveChanged: {
    if (root.active) focusTimer.restart()
    else search.clear()
  }
```

`bar/Sidebar.qml`: add `signal searchSubmitted(string text)` after `surfaceWidth: 320`, and on the `SidebarContent` instance:

```qml
    onSearchSubmitted: function(text) { root.searchSubmitted(text) }
    onEscaped: root.dismissed()
```

`shell.qml`: on the `Sidebar { ... }` instance add the line from Task 1: `onSearchSubmitted: function(text) { shell.openLauncherWith(text) }`.

- [ ] **Step 5: Run, expect PASS**

Run: `node tests/sidebar/search.test.mjs && bash scripts/sidebar-render.sh && node tests/sidebar/test.mjs && bash scripts/m3-qmllint-gate.sh && qmllint bar/Sidebar.qml bar/sidebar/*.qml`
Expected: `sidebar search: ok`, render ok with `search field border px N` (N >= 300) and the 2a assertions unchanged (card px, secondary px in clock card), lint clean.

- [ ] **Step 6: Mutation proof.** The new assertion must fail without the field. Copy the repo to a scratch dir, delete the `SearchField { ... }` block (and its Timer) from the scratch `bar/sidebar/SidebarContent.qml`, run `SIDEBAR_RENDER_ROOT=<scratch> bash scripts/sidebar-render.sh`, and confirm "search field missing". Do not edit files under `~/.config/quickshell` for this.

- [ ] **Step 7: Commit**

```bash
yadm add bar/sidebar/SearchField.qml bar/sidebar/SidebarContent.qml bar/Sidebar.qml shell.qml tests/sidebar/shell.qml scripts/sidebar-render.sh tests/sidebar/search.test.mjs
yadm commit -m "elena sidebar: search field hands off to the launcher"
```

---

### Task 3: Live check, gates, ship (controller)

- [ ] **Step 1: Full gates.** `node tests/sidebar/test.mjs && node tests/sidebar/search.test.mjs && node tests/elena/test.mjs && node tests/bar-form/test.mjs && node tests/settings-tabs/test.mjs`, `bash scripts/sidebar-render.sh`, `bash scripts/tag-strip-render.sh`, `bash scripts/tests/test_niri_shape.sh`, `bash scripts/m3-qmllint-gate.sh`, `scripts/controls-behavior.sh .`, `scripts/controls-golden-baseline.sh check` (twice).
- [ ] **Step 2: Live check.** The user cold-restarts `quickshell.service`. Then (in-memory style only; the persisted style is already `elena`, so `style elena ""` is a no-op restore): `popup sidebar` (true) → `currentPopup` is `sidebar` → `sidebarSearch "term"` (true) → `currentPopup` is `launcher`, `launcherQuery` is `term` → `sidebarSearch ">"` then `launcherQuery` is `>` → `dismissPopups`. Then `style material3 ""`; `sidebarSearch "x"` returns false; `style elena ""`; `jq -r .themeStyle settings.json` is `elena`. Screenshot the sidebar open (field visible at the foot) with `grim -o eDP-1`.
- [ ] **Step 3: Docs and memory.** Append a "Phase 2b shipped" line to the memory note `quickshell-elena-theme.md` (field wired through `LauncherPopup.initialQuery` and `shell.openLauncherWith`; IPC `sidebarSearch`/`launcherQuery`). Push with `yadm push origin main` (user rule: commit and push after a task).
- [ ] **Step 4: Report** what to restart (nothing; QML hot-reloads).

---

## Self-review

- **Spec coverage:** field (T2), focus on open/clear on close (T2 Step 4), Enter hands off, Esc closes (T2), launcher hook (T1), shared anchoring helper (T1), IPC hooks (T1), render assertion with mutation proof (T2), live check (T3). Empty submit opens the launcher empty: `initialQuery === ""` skips the hook, launcher opens at its normal reset.
- **Placeholders:** none; Task 1 Step 3's placement rule names the exact anchors in the file.
- **Types:** `searchSubmitted(string text)` flows `SearchField.submitted -> SidebarContent.searchSubmitted -> Sidebar.searchSubmitted -> shell.openLauncherWith(text)`; `initialQuery` is a `string` set before `openPopup = "launcher"`.
- **Risks:** `forceActiveFocus` timing in a layer-shell window (the launcher uses the same pattern with a Timer); render stage height 720 vs real panel height (~1040) so the level bars have room in production; `openLauncherWith` while the launcher is already open (closed first so `onVisibleChanged` re-runs).
