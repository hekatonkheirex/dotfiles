# Elena powermenu and lock look (R3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Her powermenu overlay replaces the QuickMenu and doubles as the lock surface look, with PAM and `WlSessionLock` untouched.

**Architecture:** A pure `config/PowerMenuModel.js` carries button order, accent slots, ring colors and keyboard stepping. A window-less `bar/powermenu/PowerMenuContent.qml` (render-checkable, `locked` true/false) is hosted by `bar/PowerMenu.qml` (Overlay layer) and by the lock surfaces in `bar/LockScreen.qml`. The popup route name stays `"quickmenu"` so Bar widgets and IPC keep working.

**Tech Stack:** Quickshell QML (Qt 6.12), plain JS pure modules, node gate tests, scratch-HOME render scripts.

Spec: `docs/superpowers/specs/2026-10-14-elena-powermenu-lock-r3-design.md`. Reference: github.com/elenapan/dotfiles `config/eww/windows/powermenu.{yuck,scss}` (shallow clone also at `/tmp/claude-1000/-home-mura--config-quickshell/8cd8fea9-cfb2-4e19-9657-170b9c0b16ef/scratchpad/elenapan-ref/dotfiles`; re-clone if missing).

## Global Constraints
- VCS is yadm only (no `.git` here). Commit with `yadm add <paths>`, `yadm commit`, `yadm push`; for plain git use `GIT_DIR=$HOME/.local/share/yadm/repo.git GIT_WORK_TREE=$HOME`. Never stage `settings.json`, Kvantum, kitty, niri, btop or starship files; never edit niri files.
- Sizes go through `Config.dp(N)` (scale `Config.elenaScale` = 1.5); accents through `Colors.elenaAccent(n)` (x1 error, x2 secondary, x3 tertiary, x4 primary, x5 inversePrimary, x6 fgTertiaryContainer, x8 outline).
- Power buttons order and accents: poweroff x1, reboot x2, exit x4, hibernate x6, suspend x3, lock x5. Palette row order x1, x3, x2, x6, x4, x5.
- Quote defaults: `powerMenuQuote` "Take a breath.", `powerMenuQuoteAuthor` "" (empty hides the author).
- poweroff, reboot, exit confirm through the existing `PowerConfirmation`; hibernate, suspend, lock run immediately. Exit uses `scripts/safe-logout.sh`.
- PAM and `WlSessionLock` code in `bar/LockScreen.qml` (`PamContext`, `sessionLock`, `updateReloadWatchState`, `tryLockAuth`, `unlockSession`) must not change behavior.
- QML saves hot-reload the live shell: keep every saved state valid; new types go in their own files (inline `component` breaks hot reload).
- No em dashes, no new dependency, no `rm -rf`, no `--no-verify`.
- Every task ships tests in the same commit; render checks are mutation-proven.

---

### Task 1: PowerMenuModel, settings keys, gate tests

**Files:**
- Create: `config/PowerMenuModel.js`, `tests/power-menu/model.test.mjs`
- Modify: `config/Settings.qml` (add `powerMenuQuote`, `powerMenuQuoteAuthor`), `bar/settings/AppearanceTab.qml` (two text rows + search anchors), `tests/elena/config-dump.allow.json` (new keys)
- Test: `tests/power-menu/model.test.mjs`

**Interfaces:**
- Produces (`config/PowerMenuModel.js`, `.pragma library`):
  - `buttons()` -> array of `{id, label, accent, confirm}` in order `poweroff, reboot, exit, hibernate, suspend, lock`; `confirm` true for the first three.
  - `paletteAccents()` -> `[1,3,2,6,4,5]`.
  - `ringBorder(len, action)` -> `{kind, n}`; `action` is `"clear" | "insert" | "delete"`. `clear` -> `{kind:"clear", n:0}`; `insert` -> `{kind:"accent", n: paletteAccents()[(len-1) % 6]}` (len >= 1); `delete` -> style = `((len-1)%6)+1` (len >= 1): odd style -> `{kind:"muted", n:8}`, even style -> `{kind:"border", n:0}`; delete with len 0 -> `{kind:"clear", n:0}`.
  - `maskInput(len)` -> `"*".repeat(len)` (len < 0 treated as 0).
  - `step(index, key, count)` -> next index: `"left"`/`"right"` move -1/+1 wrapping over `count`; `"up"`/`"down"` move -3/+3 wrapping over `count`; unknown key returns `index`.
  - `terminalText(selectedId)` -> `"$ " + selectedId` (empty id gives `"$ "`).

- [ ] **Step 1: Write the failing test** `tests/power-menu/model.test.mjs`

```js
// Gate test: node tests/power-menu/model.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/PowerMenuModel.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src +
  "; return { buttons, paletteAccents, ringBorder, maskInput, step, terminalText }")()

const b = M.buttons()
assert.deepEqual(b.map(x => x.id), ["poweroff", "reboot", "exit", "hibernate", "suspend", "lock"])
assert.deepEqual(b.map(x => x.accent), [1, 2, 4, 6, 3, 5])
assert.deepEqual(b.map(x => x.confirm), [true, true, true, false, false, false])
assert.deepEqual(M.paletteAccents(), [1, 3, 2, 6, 4, 5])

assert.deepEqual(M.ringBorder(0, "clear"), { kind: "clear", n: 0 })
assert.deepEqual(M.ringBorder(1, "insert"), { kind: "accent", n: 1 })
assert.deepEqual(M.ringBorder(2, "insert"), { kind: "accent", n: 3 })
assert.deepEqual(M.ringBorder(6, "insert"), { kind: "accent", n: 5 })
assert.deepEqual(M.ringBorder(7, "insert"), { kind: "accent", n: 1 })   // cycle wraps
assert.deepEqual(M.ringBorder(1, "delete"), { kind: "muted", n: 8 })    // style 1 odd
assert.deepEqual(M.ringBorder(2, "delete"), { kind: "border", n: 0 })   // style 2 even
assert.deepEqual(M.ringBorder(7, "delete"), { kind: "muted", n: 8 })    // style 1 again
assert.deepEqual(M.ringBorder(0, "delete"), { kind: "clear", n: 0 })

assert.equal(M.maskInput(0), "")
assert.equal(M.maskInput(4), "****")
assert.equal(M.maskInput(-3), "")

assert.equal(M.step(0, "right", 6), 1)
assert.equal(M.step(5, "right", 6), 0)
assert.equal(M.step(0, "left", 6), 5)
assert.equal(M.step(1, "down", 6), 4)
assert.equal(M.step(4, "down", 6), 1)
assert.equal(M.step(1, "up", 6), 4)
assert.equal(M.step(2, "other", 6), 2)

assert.equal(M.terminalText("reboot"), "$ reboot")
assert.equal(M.terminalText(""), "$ ")
console.log("power-menu model ok")
```

- [ ] **Step 2:** Run `node tests/power-menu/model.test.mjs`; expected FAIL (file missing).
- [ ] **Step 3:** Write `config/PowerMenuModel.js` exactly to the interface above, with a `.pragma library` first line (same style as `config/SidebarPages.js`).
- [ ] **Step 4:** Add `powerMenuQuote: "Take a breath."` and `powerMenuQuoteAuthor: ""` to the defaults and property list in `config/Settings.qml`, following how a neighbouring string setting is declared, saved and reset (read how `sidebarEdgeHover` was added in commit 2 of R2 for the pattern). Add two text rows in `bar/settings/AppearanceTab.qml` ("Power menu quote", "Power menu quote author") with search anchors in `SettingsPanel.qml` like the other rows. Add the two keys to `tests/elena/config-dump.allow.json`.
- [ ] **Step 5:** Run `node tests/power-menu/model.test.mjs`, `bash scripts/config-dump.sh check`, `bash scripts/m3-qmllint-gate.sh`; all pass. Append wiring asserts to a new `tests/power-menu/wiring.test.mjs` for the two settings keys and rows.
- [ ] **Step 6:** Commit and push: `yadm add config/PowerMenuModel.js config/Settings.qml bar/settings tests/power-menu tests/elena/config-dump.allow.json` then `yadm commit -m "power menu R3: model, quote settings"`, `yadm push`.

---

### Task 2: PowerMenuContent and pieces with a render check

**Files:**
- Create: `bar/powermenu/PowerMenuContent.qml`, `bar/powermenu/{PowerButton,BunnyBlock,PaletteRow,TerminalLine,LockRing}.qml`, `tests/power-menu/shell.qml` (render stage), `scripts/powermenu-render.sh`
- Modify: `config/qmldir` / `bar/powermenu/qmldir` if the repo uses qmldir for sibling folders (follow `bar/sidebar` and `bar/bottombar`)
- Test: `scripts/powermenu-render.sh` (pixel checks), `tests/power-menu/wiring.test.mjs`

**Interfaces:**
- Consumes: `PowerMenuModel.js` (Task 1), `Config.dp`, `Colors.elenaAccent`, `BottomBarFonts` (family `ElenaIcons1`, text `Kyok`), `Settings.powerMenuQuote`, `Settings.powerMenuQuoteAuthor`.
- Produces: `PowerMenuContent` (an Item) with properties `locked: bool`, `revealed: bool` (true plays the staggered color fade; render stage sets it true and `Config.reducedMotion`-style instant mode if present), `selected: string` (hovered/selected button id, "" none), `inputLength: int`, `lastAction: string` (`"clear"|"insert"|"delete"`), `authFailed: bool`; signals `activated(string id)`, `dismissRequested()`, `hovered(string id)` (empty on hover end).

- [ ] **Step 1:** Write failing render checks in `scripts/powermenu-render.sh`, modelled on `scripts/sidebar-render.sh` (scratch HOME, `tests/power-menu/shell.qml` stage emitting GEOM lines, `GOLDEN_OUT` png, fail on QML errors). Checks: (a) with `revealed` true each of the six button glyph centers has the pixel color of its accent slot; (b) with `selected: "reboot"` the other five glyphs are dimmed (alpha 0.3 against `surface` background) and reboot is not; (c) the six palette circles match the palette order; (d) the terminal text area has non-background pixels and shows `$ reboot`; (e) `locked: true`: buttons are absent, the ring border pixel equals `ringBorder(len, lastAction)` color for `(0,clear)`, `(1,insert)`, `(2,insert)`, `(1,delete)`, `(2,delete)`; (f) masked input shows `inputLength` characters (compare text width at 3 vs 6). Run it; expected FAIL (stage missing).
- [ ] **Step 2:** Implement the pieces to the spec section "Overlay" and "Lock state": left side (greeting BattleAndy 80pt S with heart glyph x1, subtitle "(again)", quote block, palette row), right side (bunny block with hover head `( ^ ^)`, 3x2 button grid 54 S buttons with 30pt S glyphs, terminal line "/ A P H E L I O N /" then `$ <selected>_` blinking 1 s steps(2); locked mode hides buttons and bunny terminal and shows the ring with `[ L O C K D O W N ]` and `> ` plus masked input, terminal colour x1). Glyph codepoints: extract the private-use characters from the reference `powermenu.yuck` (`:symbol` attributes for poweroff, reboot, exit, hibernate, suspend, lock, the lock-container symbols for normal and failed auth, the little-heart) with a short Python script (`python3 -I`), put them in `config/DockSymbols.js`-style constants inside `PowerMenuModel.js` as `glyph(id)`, and prove each resolves from the icon fonts with `scripts/bar-font-check.sh` (extend its table). Button colors: muted `outline` at 0.6 until `revealed`, then the accent slot; staggered `ColorAnimation` 0.5 s with 0.1 s steps in button order; `Config.reducedMotion` (use the existing flag name found by grep) snaps. Selection uses the model's `step`.
- [ ] **Step 3:** Run `bash scripts/powermenu-render.sh`; all checks pass.
- [ ] **Step 4:** Mutation-prove: swap two accent slots in `PowerMenuModel.buttons()`, drop the dim opacity, break the ring mapping; each makes the render check fail; restore.
- [ ] **Step 5:** `bash scripts/m3-qmllint-gate.sh`, `scripts/bar-font-check.sh`, `scripts/style-refs.sh --elena`; commit and push `power menu R3: overlay content and render check`.

---

### Task 3: PowerMenu window and shell wiring, QuickMenu removed

**Files:**
- Create: `bar/PowerMenu.qml`
- Modify: `shell.qml`, `README.md`, `tests/elena/test.mjs` (drop the QuickMenu grid assertions, assert the model's `step` instead), `scripts/popup-ipc-check.sh` (if it names the quick menu), `docs` links as needed
- Delete: `bar/QuickMenu.qml`, QuickMenu-only checks and settings rows that reference it (found by `rg -n "QuickMenu|quickMenu" -g '*.qml' -g '*.mjs' -g '*.sh'`)
- Test: `tests/power-menu/wiring.test.mjs`, `scripts/popup-ipc-check.sh`

**Interfaces:**
- Consumes: `PowerMenuContent` (Task 2), `PowerMenuModel.buttons()`.
- Produces: `PowerMenu` window with `property int pendingIndex` (index into `PowerMenuModel.buttons()`, -1 none), `signal dismissed()`, `signal lockRequested()`; `function confirmPending()`, `function cancelPending()`. The popup route stays `"quickmenu"`.

- [ ] **Step 1:** Add failing wiring assertions in `tests/power-menu/wiring.test.mjs`: `shell.qml` instantiates `PowerMenu`, not `QuickMenu`; `visible: bar.openPopup === "quickmenu" && !lockScreen.locked`; `onLogoutRequested` toggles `"quickmenu"` with no "until R3" comment; `bar/QuickMenu.qml` does not exist; the confirmation window reads its label from the PowerMenu pending button; `scripts/safe-logout.sh` is referenced for exit; hibernate/suspend use `systemctl`.
- [ ] **Step 2:** Implement `bar/PowerMenu.qml`: layer Overlay, anchors all edges, `exclusionMode: Ignore`, `WlrLayershell.keyboardFocus: visible ? Exclusive : None`, namespace `Config.layerNamespace("powermenu")`, content `PowerMenuContent` with `locked: false`; click outside buttons and middle click and Esc emit `dismissed()`; arrows use `step`, Enter activates. Activation: confirm-flagged ids set `pendingIndex` and emit `dismissed()` (as QuickMenu did, so one surface owns focus); others run immediately (`systemctl hibernate`, `systemctl suspend`, lock via `lockRequested()`). `confirmPending()` runs the command (`["sh", HOME/.config/quickshell/scripts/safe-logout.sh]` for exit, `["systemctl","poweroff"]`, `["systemctl","reboot"]`). Keep a descriptive label and description table in `PowerMenu.qml` for the confirmation dialog (same texts as QuickMenu had) and the glyph from `glyph(id)`.
- [ ] **Step 3:** Rewire `shell.qml`: replace the `QuickMenu` instance and the confirmation window bindings with `PowerMenu` (`id: powerMenu`), keep `powerConfirmationWindow` but bind label/description/icon to `powerMenu`. Keep `ipc.quickmenu()` and the `qsquickmenu-trigger` mapping (they toggle `"quickmenu"` and no longer need `getMenuIndicatorX/Y`; keep the anchor writes only if the Bar still needs them). Remove `onSettingsRequested` use for the menu. Delete `bar/QuickMenu.qml` last, after the instance is gone, so no saved state is invalid.
- [ ] **Step 4:** Update README (menu description rows at lines mentioning Quick Menu, the Mod+Escape row, project tree) and `tests/elena/test.mjs`.
- [ ] **Step 5:** Run `node tests/power-menu/*.test.mjs`, `node tests/elena/test.mjs`, `bash scripts/m3-qmllint-gate.sh`, `bash scripts/powermenu-render.sh`, `bash scripts/config-dump.sh check`, `bash scripts/style-refs.sh --elena`, `bash scripts/popup-ipc-check.sh` (live, hot-reloaded shell; report that it ran against the live shell); commit and push `power menu R3: overlay window, QuickMenu removed`.

---

### Task 4: Lock surface in her look, lock settings removed

**Files:**
- Create: `bar/powermenu/LockSurfaceContent.qml` (backdrop + `PowerMenuContent` in locked mode + keyboard input forwarding)
- Modify: `bar/LockScreen.qml` (both the session-lock surface at the `WlSessionLockSurface` and the fallback layer-shell surface), `config/Settings.qml` (remove `lockShowSeconds`, `lockFontSize`, `lockClockSize`, `lockShowMedia`, `lockUseWallpaper`), `bar/settings/LockMediaTab.qml` (delete the tab or rows that only served these; follow how tabs are registered), `bar/settings/AppearanceTab.qml`, `bar/settings/GeneralTab.qml`, `tests/elena/config-dump.legacy.json` (add the removed keys as legacy), `tests/elena/config-dump.allow.json`
- Test: `tests/power-menu/lock-wiring.test.mjs`, `scripts/powermenu-render.sh` (locked cases), existing lock tests

**Interfaces:**
- Consumes: `PowerMenuContent` (`locked`, `inputLength`, `lastAction`, `authFailed`), `PowerMenuModel.ringBorder`, `maskInput`.
- Produces: `LockSurfaceContent` with `property string password`, `property bool authFailed`, signals `submitted()` and `edited(string action)`; `LockScreen.lockPassword`/`lockInputText`/`tryLockAuth()` stay the source of truth.

- [ ] **Step 1:** Write failing `tests/power-menu/lock-wiring.test.mjs`: the PAM and session-lock code lines named in Global Constraints are present exactly as at base (pin them with `assert.match` on the original strings: `PamContext`, `WlSessionLock {`, `function tryLockAuth`, `function unlockSession`, `updateReloadWatchState`, `if (Config.isNiri) root.locked = sessionLock.locked`); `LockScreen.qml` no longer contains `Settings.lockShowMedia`, `Settings.lockClockSize`, `Settings.lockUseWallpaper`, `lockMprisProcess`, `MultiEffect`, `profile.jpg`, `requestPowerAction`; both surfaces instantiate `LockSurfaceContent`; the settings keys are gone from `Settings.qml` and listed in `config-dump.legacy.json`. Run, expect FAIL.
- [ ] **Step 2:** Implement `LockSurfaceContent` and replace the two lock surfaces' bodies. Keep `WlSessionLockSurface` the surface, an input `TextInput` (invisible, `echoMode: TextInput.Password`, forced focus) feeding `root.lockInputText`/`lockPassword` exactly as the old field did (copy its `Keys.onPressed` handling and Enter -> `tryLockAuth()`), `edited("insert"|"delete"|"clear")` set on key actions, `authFailed` bound to `root.lockError !== ""`. Locked background: `Colors.surface` opaque with the `diagonal-fade` reveal replaced by a 1.2 s opacity fade (instant under reduced motion). Remove from LockScreen.qml: wallpaper loader and MultiEffects, profile image, clock, date, MPRIS process and fields, the three power buttons and the nested `PowerConfirmation` instances (both), `pendingPowerLabel`/`pendingPowerCommand` and the three helper functions if nothing else uses them (verify with rg). Do not alter PAM, `sessionLock`, reload guard.
- [ ] **Step 3:** Remove the five settings and their rows; add the legacy keys; run `bash scripts/config-dump.sh check` (allow list updated deliberately), and the settings tab tests under `tests/settings-tabs`.
- [ ] **Step 4:** Extend `scripts/powermenu-render.sh` with a full-surface locked case driving `LockSurfaceContent` with a fake password length sequence; run all gates; mutation-prove (ring colour mapping, mask length, deleted PAM line in a scratch copy makes `lock-wiring` fail).
- [ ] **Step 5:** Commit and push `power menu R3: lock surface in her look, lock media/wallpaper settings removed`.

---

### Task 5: Docs, live verification, final review

**Files:**
- Modify: `README.md` (power menu and lock sections, settings list, IPC rows, project tree), memory note `quickshell-elena-theme.md`
- Test: live checks (user cold restart) and the final whole-branch review

- [ ] **Step 1:** README: replace the Quick Menu description with the power menu overlay and lock look; remove the removed lock settings from the settings docs; keep the `quickmenu` IPC/trigger documented as the power menu toggle.
- [ ] **Step 2:** After the user's cold restart: `bash scripts/popup-ipc-check.sh`; open via `qs ipc call shell quickmenu`, confirm `niri msg layers` shows the powermenu on Overlay while open and none when closed; journal has no QML errors; RSS sample. Lock check by the user: lock, type a wrong then right password; report unverified items honestly (pointer and password entry are the user's).
- [ ] **Step 3:** Final opus whole-branch review of the R3 range; one fix wave.
- [ ] **Step 4:** Update the memory note and index; commit and push.
