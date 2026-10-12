# elena theme (phase 1: palette + tag strip) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `themeStyle: "elena"` style that applies the elenapam palette and draws a colored workspace-block strip on the top screen edge.

**Architecture:** `elena` rides the Material 3 control path (`Config.material3Theme` stays true) and adds one flag, `Config.elenaTheme`. The palette is a new fixed family in `PaletteCatalog.js`. The strip is a second `PanelWindow` (`bar/TagStrip.qml`) that renders `bar/TagStripBlocks.qml` from the model `WorkspaceIndicator.visibleWorkspaces` already holds; state mapping is a pure function in `config/TagStrip.js`.

**Tech Stack:** Quickshell/QML, `.pragma library` JS, node (`tests/*/test.mjs`), bash, Python PIL (pixel check).

## Global Constraints

- VCS is yadm (no `.git` here): `yadm add <paths>` then `yadm commit`. Never `--no-verify`. Never stage `settings.json` (already modified, unrelated).
- QML edits go live on save. In-memory style switch: `qs ipc call shell style elena ""`; restore with `qs ipc call shell style material3 ""` and `qs ipc call shell dismissPopups`, then check `jq .themeStyle ~/.config/quickshell/settings.json`. Send no keystrokes (`wtype`) during tests.
- Strip height is 8 px, one token: `Config.tagStripHeight`.
- Accent cycle is `Colors.primary`, `Colors.secondary`, `Colors.tertiary` (purple, pink, cyan in the elenapam palette), indexed by workspace `idx`, so a workspace keeps its color when the list shifts.
- elenapam palette is dark only; `palette("elenapam", v, darkMode)` ignores `darkMode`.
- Block fill: focused = accent, occupied = accent at alpha 0.35, empty = accent at alpha 0.08, over a transparent strip.
- Fonts, shape tokens and controls are unchanged (Material).

## File Structure

| File | Responsibility |
|---|---|
| `config/TagStrip.js` (new) | `tagStates(workspaces)`: pure mapping from workspace items to `{idx, state, accent}` |
| `config/PaletteCatalog.js` (mod) | `elenapam` family, variant list, `elenapamPalette()` |
| `config/Config.qml` (mod) | `elenaTheme`, `tagStripHeight`, `tagStripOffset` |
| `bar/TagStripBlocks.qml` (new) | Renders blocks, emits `activated(idx)`. No window, testable alone |
| `bar/TagStrip.qml` (new) | Top-edge `PanelWindow` wrapping `TagStripBlocks` |
| `bar/Bar.qml` (mod) | Top margin under elena, popup anchor offset, hide in-bar workspaces, expose model + focus |
| `bar/PopupBase.qml` (mod) | Offset top floor by `Config.tagStripOffset` |
| `shell.qml` (mod) | Instantiate `TagStrip` next to `Bar` |
| `bar/settings/AppearanceTab.qml` (mod) | Tile, 7-choice grid math, palette default on select, revert |
| `scripts/sync-active-palette.sh` (mod) | Add `elena` to the two Matugen-terminal whitelists |
| `scripts/tests/test_niri_shape.sh` (new) | Locks: elena leaves Niri corners rounded |
| `tests/elena/test.mjs` (new) | Gate: `tagStates`, elenapam palette, catalog wiring |
| `tests/tag-strip/shell.qml`, `scripts/tag-strip-render.sh` (new) | Pixel check of block states |
| `scripts/controls-behavior.sh`, `scripts/controls-golden.sh` (mod) | Add `elena:classic` |
| `docs/superpowers/specs/2026-10-12-elena-theme-design.md` (mod) | Record three deltas found while planning |

---

### Task 1: Pure logic + palette (gate-tested)

**Files:**
- Create: `config/TagStrip.js`, `tests/elena/test.mjs`
- Modify: `config/PaletteCatalog.js` (familyList line 7, variantLists line 14, `resolveVariant` line 86, `fixedFamilyOptions` line 62, `palette` line 327)
- Modify: `docs/superpowers/specs/2026-10-12-elena-theme-design.md`

**Interfaces:**
- Produces: `TagStrip.tagStates(workspaces) -> [{idx:int, state:"focused"|"occupied"|"empty", accent:0|1|2}]`; `PaletteCatalog.palette("elenapam", variant, darkMode) -> role map`.

- [ ] **Step 1: Write the failing test** `tests/elena/test.mjs`

```js
// Gate test: node tests/elena/test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const load = (rel, exports) => {
  const src = readFileSync(fileURLToPath(new URL(rel, import.meta.url)), "utf8")
    .replace(/^\.pragma library$/m, "")
  return new Function(src + `; return { ${exports} }`)()
}
const T = load("../../config/TagStrip.js", "tagStates, ACCENT_COUNT")
const P = load("../../config/PaletteCatalog.js",
  "palette, resolveVariant, fixedFamilyOptions, familyLabel, variantLabel, variantOptions, semanticPalette")

// tagStates
assert.equal(T.ACCENT_COUNT, 3)
assert.deepEqual(T.tagStates([]), [])
for (const bad of [undefined, null, "x", 5]) assert.deepEqual(T.tagStates(bad), [])
assert.deepEqual(
  T.tagStates([
    { idx: 1, isFocused: false, isOccupied: true },
    { idx: 2, isFocused: true, isOccupied: true },
    { idx: 3, isFocused: false, isOccupied: false },
    { idx: 4, isFocused: false, isOccupied: false },
  ]),
  [
    { idx: 1, state: "occupied", accent: 0 },
    { idx: 2, state: "focused", accent: 1 },
    { idx: 3, state: "empty", accent: 2 },
    { idx: 4, state: "empty", accent: 0 },
  ])
// focused beats occupied; accent follows idx, not list position
assert.deepEqual(T.tagStates([{ idx: 7, isFocused: true, isOccupied: false }]),
  [{ idx: 7, state: "focused", accent: 0 }])
// idx 0 / negative entries must not give negative accents; non-numeric idx is skipped
assert.deepEqual(T.tagStates([{ idx: 0 }, { idx: -1 }, null, {}]),
  [{ idx: 0, state: "empty", accent: 2 }, { idx: -1, state: "empty", accent: 1 }])

// palette
const light = P.palette("elenapam", "auto", false)
const dark = P.palette("elenapam", "auto", true)
assert.ok(light && dark)
assert.deepEqual(light, dark)
assert.equal(dark.primary, "#c77dc8")
assert.equal(dark.secondary, "#f06292")
assert.equal(dark.tertiary, "#5bb8d4")
assert.equal(dark.surface, "#1a1f2b")
const roles = Object.keys(P.palette("tokyonight", "night", true))
for (const k of roles) assert.ok(dark[k], `elenapam missing role ${k}`)
for (const v of ["auto", "dark", "light", "junk", undefined]) assert.equal(P.resolveVariant("elenapam", v, true), "dark")
assert.ok(P.fixedFamilyOptions().some(f => f.value === "elenapam"))
assert.equal(P.familyLabel("elenapam"), "Elenapam")
assert.equal(P.variantLabel("elenapam", "dark"), "Dark")
// existing families untouched
assert.equal(P.palette("material3", "auto", true), null)
assert.equal(P.palette("tokyonight", "night", true).primary, "#7aa2f7")
console.log("elena: ok")
```

- [ ] **Step 2: Run, expect FAIL**

Run: `node tests/elena/test.mjs`
Expected: throws, `config/TagStrip.js` not found (ENOENT).

- [ ] **Step 3: Create `config/TagStrip.js`**

```js
.pragma library

// Block states for the elena tag strip. Input is the item list
// WorkspaceIndicator.visibleWorkspaces already builds (idx, isFocused,
// isOccupied), so the 5/10/active count rules live in one place.
var ACCENT_COUNT = 3

function tagStates(workspaces) {
  if (!Array.isArray(workspaces)) return []
  var out = []
  for (var i = 0; i < workspaces.length; i++) {
    var w = workspaces[i]
    if (!w || typeof w.idx !== "number") continue
    out.push({
      idx: w.idx,
      state: w.isFocused ? "focused" : (w.isOccupied ? "occupied" : "empty"),
      accent: ((w.idx - 1) % ACCENT_COUNT + ACCENT_COUNT) % ACCENT_COUNT
    })
  }
  return out
}
```

- [ ] **Step 4: Add the palette to `config/PaletteCatalog.js`**

Append to `familyList` (after tokyonight):
```js
  { value: "tokyonight", label: "TokyoNight", icon: "nights_stay" },
  { value: "elenapam", label: "Elenapam", icon: "palette" }
```
Append to `variantLists`:
```js
  tokyonight: [ /* unchanged */ ],
  elenapam: [
    { value: "dark", label: "Dark", icon: "dark_mode" }
  ]
```
In `resolveVariant`, before `return "expressive"`:
```js
  if (family === "elenapam") return "dark"
```
`fixedFamilyOptions`:
```js
  return [familyList[1], familyList[2], familyList[3], familyList[4]]
```
Before `palette()`:
```js
// elenapam: navy cards with pink, purple and cyan accents (the AwesomeWM rice
// by elenapam). Dark only; light mode reuses it.
function elenapamPalette() {
  var s = {
    base: "#1a1f2b", dim: "#151922", bright: "#2a3140", lowest: "#131720",
    low: "#1e2430", container: "#232a37", high: "#2a3140", highest: "#343c4d",
    variant: "#2a3140", text: "#f2f4f8", subtext: "#a3acbd",
    outline: "#5b6578", outlineVariant: "#3a4254"
  }
  var a = {
    primary: "#c77dc8", onPrimary: "#1a1f2b", primaryContainer: "#4a2f4d", onPrimaryContainer: "#f3d4f4",
    secondary: "#f06292", onSecondary: "#1a1f2b", secondaryContainer: "#522a39", onSecondaryContainer: "#ffd6e3",
    tertiary: "#5bb8d4", onTertiary: "#1a1f2b", tertiaryContainer: "#1f4452", onTertiaryContainer: "#cfeefa",
    error: "#ff6b6b", onError: "#1a1f2b", errorContainer: "#5a2a2a", onErrorContainer: "#ffd9d9",
    inversePrimary: "#8e4f90"
  }
  return semanticPalette(s, a)
}
```
In `palette()` add `if (family === "elenapam") return elenapamPalette()` before the final `return null`.

- [ ] **Step 5: Run, expect PASS**

Run: `node tests/elena/test.mjs`
Expected: `elena: ok`. Also run `node tests/bar-form/test.mjs` to confirm nothing else moved.

- [ ] **Step 6: Amend the spec** (three deltas found while reading the code)

In `docs/superpowers/specs/2026-10-12-elena-theme-design.md`:
- Theme id: replace "Excluded from `Config.material3Theme`." with "Stays inside `Config.material3Theme` (the facades in `bar/SliderControl.qml`, `bar/primitives/ActionButton.qml` pick Material controls from it). `Config.elenaTheme` is an extra flag only."
- Tag strip: replace "Each block has a fixed accent, cycling purple, pink, cyan, mint, green." with "Each block takes its accent from `primary`, `secondary`, `tertiary` by workspace `idx` modulo 3 (purple, pink, cyan in elenapam)." and replace the `tagStates(workspaces, count)` sentence with "`tagStates(workspaces)` maps the items `WorkspaceIndicator.visibleWorkspaces` already builds, so count rules (active/5/10, focused outside range) stay in one place."
- Verification: replace the gate-test bullet with "Gate test `tests/elena/test.mjs`: `tagStates` states, accent by idx, junk input; elenapam palette roles and catalog wiring."

- [ ] **Step 7: Commit**

```bash
yadm add config/TagStrip.js config/PaletteCatalog.js tests/elena/test.mjs docs/superpowers/specs/2026-10-12-elena-theme-design.md docs/superpowers/plans/2026-10-12-elena-theme.md
yadm commit -m "elena: tag state mapping and elenapam palette family"
```

---

### Task 2: Style wiring (flag, tile, scripts)

**Files:**
- Modify: `config/Config.qml:25-27`, `bar/settings/AppearanceTab.qml:35,38-45,89-107,486,514,~495-505`, `scripts/sync-active-palette.sh:283,562`, `scripts/controls-behavior.sh:7`, `scripts/controls-golden.sh:6`
- Create: `scripts/tests/test_niri_shape.sh`

**Interfaces:**
- Produces: `Config.elenaTheme: bool`, `Config.tagStripHeight: int` (8), `Config.tagStripOffset: int` (8 under elena, else 0).

- [ ] **Step 1: Write the Niri shape lock test** `scripts/tests/test_niri_shape.sh`

```bash
#!/usr/bin/env bash
# Gate test: elena keeps Niri window corners rounded; only dwm squares them.
set -euo pipefail
repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
for style in elena material3 ghost; do
  NIRI_CONFIG_DIR="$tmp/$style" bash "$repo/scripts/sync-niri-shape.sh" "$style"
  if grep -q geometry-corner-radius "$tmp/$style/style.kdl"; then
    echo "FAIL $style: style.kdl squares corners" >&2; exit 1
  fi
done
NIRI_CONFIG_DIR="$tmp/dwm" bash "$repo/scripts/sync-niri-shape.sh" dwm
grep -q 'geometry-corner-radius 0' "$tmp/dwm/style.kdl" || { echo "FAIL dwm: corners not squared" >&2; exit 1; }
echo "niri shape: ok"
```

- [ ] **Step 2: Run** `bash scripts/tests/test_niri_shape.sh`
Expected: `niri shape: ok` (this locks existing fall-through behavior; there is no red phase).

- [ ] **Step 3: Config flags** in `config/Config.qml`, after the `dwmTheme` line:

```qml
  // elena rides the Material control path (material3Theme stays true); this
  // flag only gates its palette default and the top-edge tag strip.
  readonly property bool elenaTheme: Settings.themeStyle === "elena"
  readonly property int tagStripHeight: 8
  readonly property int tagStripOffset: elenaTheme ? tagStripHeight : 0
```
Do not edit `material3Theme`.

- [ ] **Step 4: AppearanceTab edits** (`bar/settings/AppearanceTab.qml`)

1. `uiStyleColumns`: `width < 720 ? 2 : 6` becomes `width < 720 ? 2 : 7`; `uiStyleRows`: `Math.ceil(6 / ...)` becomes `Math.ceil(7 / ...)`.
2. Lines 486 and 514: `uiStyleColumns === 6` becomes `uiStyleColumns === 7`.
3. Append to `styleChoices` after the dwm entry: `{ value: "elena", variant: "", icon: "palette", label: "Elena" }`.
4. In the description ternary, insert before the final `"Rounded surfaces, tonal elevation, and expressive motion"`:
```qml
                        : (Settings.themeStyle === "elena"
                          ? "Navy cards, pink, purple and cyan accents, and a colour-block workspace strip"
                          : "Rounded surfaces, tonal elevation, and expressive motion")))))
```
   (adds one closing paren to the existing chain).
5. Replace `selectStyle` and `revertStyle` (lines 89-107) with:

```qml
  property string previousColorSource: ""
  property string previousColorPalette: ""
  property string previousColorVariant: ""

  function selectStyle(style, variant) {
    if (Settings.themeStyle === style
        && (style !== "nothing" || Settings.nothingVariant === variant)) return
    previousStyle = Settings.themeStyle
    previousNothingVariant = Settings.nothingVariant
    previousColorSource = Settings.colorSource
    previousColorPalette = Settings.colorPalette
    previousColorVariant = Settings.colorVariant
    Settings.themeStyle = style
    if (style === "nothing") Settings.nothingVariant = variant
    // elena ships its own fixed palette. The palette controls can still
    // switch it to Live (wallpaper) afterwards.
    var paletteChanged = style === "elena" && Settings.colorPalette !== "elenapam"
    if (paletteChanged) {
      Settings.colorSource = "fixed"
      Settings.colorPalette = "elenapam"
      Settings.colorVariant = "auto"
    }
    Settings.save()
    if (paletteChanged) appearanceTab.requestPaletteSync()
  }

  function revertStyle() {
    if (previousStyle === "") return
    var style = previousStyle
    var variant = previousNothingVariant
    var restorePalette = Settings.themeStyle === "elena" && previousColorPalette !== ""
    previousStyle = ""
    Settings.themeStyle = style
    Settings.nothingVariant = variant
    if (restorePalette) {
      Settings.colorSource = previousColorSource
      Settings.colorPalette = previousColorPalette
      Settings.colorVariant = previousColorVariant
    }
    Settings.save()
    if (restorePalette) appearanceTab.requestPaletteSync()
  }
```

- [ ] **Step 5: Script whitelists**

`scripts/sync-active-palette.sh:283`: `material3|liquid-glass|dwm) ;;` becomes `material3|liquid-glass|dwm|elena) ;;`.
`scripts/sync-active-palette.sh:562`: add `|| "$ui_style" == "elena"` to the condition.
`scripts/controls-behavior.sh:7` and `scripts/controls-golden.sh:6`: add `elena:classic` to the style list. In `controls-golden.sh` the list is an array, add `"elena:classic"`.

- [ ] **Step 6: Verify**

```bash
bash scripts/tests/test_niri_shape.sh
bash scripts/tests/test_accent_override.sh
bash scripts/m3-qmllint-gate.sh
scripts/controls-behavior.sh .
```
Expected: all `ok`; `ok   elena-classic: N checks`. In `controls-behavior.sh` the settings fixture forces `colorPalette: material3`, so elena runs the Material path there; that is the intended coverage (controls unchanged under elena).

- [ ] **Step 7: Commit**

```bash
yadm add config/Config.qml bar/settings/AppearanceTab.qml scripts/sync-active-palette.sh scripts/controls-behavior.sh scripts/controls-golden.sh scripts/tests/test_niri_shape.sh
yadm commit -m "elena: style flag, settings tile, palette default, script whitelists"
```

---

### Task 3: Strip rendering with a pixel check

> **Revision 2026-10-12:** `bar/TagStrip.qml` (the second PanelWindow) was dropped: niri orders layer surfaces by map order, so it landed under the bar. Under elena the Bar itself renders `TagStripBlocks`. Ignore TagStrip.qml and `tagStripOffset` below.

**Files:**
- Create: `bar/TagStripBlocks.qml`, `bar/TagStrip.qml`, `tests/tag-strip/shell.qml`, `scripts/tag-strip-render.sh`

**Interfaces:**
- Consumes: `TagStrip.tagStates` (Task 1), `Config.tagStripHeight`, `Config.elenaTheme` (Task 2).
- Produces: `TagStripBlocks { workspaces: var; signal activated(int idx) }`; `TagStrip { screen; workspaces: var; reserveZone: bool; signal activated(int idx) }` (a `PanelWindow`).

- [ ] **Step 1: Write the failing render check** `scripts/tag-strip-render.sh`

```bash
#!/usr/bin/env bash
# Usage: tag-strip-render.sh [quickshell-root]
# Renders TagStripBlocks with a fixed model under the elenapam palette and
# checks the block colors. Exits non-zero on mismatch.
set -euo pipefail
root=$(realpath "${1:-$(dirname "$0")/..}")
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$root/resources" "$home/cfg/"
cp "$root/tests/tag-strip/shell.qml" "$home/cfg/shell.qml"
printf '{"themeStyle":"elena","colorSource":"fixed","colorPalette":"elenapam","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" GOLDEN_OUT="$home/strip.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/strip.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
python3 -I - "$home/strip.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
w, h = im.size
assert (w, h) == (450, 8), f"size {w}x{h}"
surface = (0x1a, 0x1f, 0x2b)
accents = [(0xc7, 0x7d, 0xc8), (0xf0, 0x62, 0x92), (0x5b, 0xb8, 0xd4)]
def blend(a, alpha):
    return tuple(round(alpha * a[i] + (1 - alpha) * surface[i]) for i in range(3))
# model: idx1 occupied, idx2 focused, idx3 empty, idx4 occupied, idx5 empty, idx6 focused
want = [blend(accents[0], .35), accents[1], blend(accents[2], .08),
        blend(accents[0], .35), blend(accents[1], .08), accents[2]]
bad = 0
for i, exp in enumerate(want):
    got = im.getpixel((i * 75 + 37, 4))
    ok = all(abs(got[c] - exp[c]) <= 3 for c in range(3))
    bad += not ok
    print(("ok   " if ok else "FAIL ") + f"block {i + 1}: got {got} want {exp}")
sys.exit(1 if bad else 0)
PY
```

`tests/tag-strip/shell.qml`:

```qml
// Copied to the root of a config copy by scripts/tag-strip-render.sh.
// Renders TagStripBlocks over the palette surface and saves $GOLDEN_OUT.
import QtQuick
import Quickshell
import "config"
import "bar"

ShellRoot {
  FloatingWindow {
    implicitWidth: 450
    implicitHeight: 8
    color: Colors.surface

    Item {
      id: stage
      anchors.fill: parent
      Rectangle { anchors.fill: parent; color: Colors.surface }
      TagStripBlocks {
        anchors.fill: parent
        workspaces: [
          { idx: 1, isFocused: false, isOccupied: true },
          { idx: 2, isFocused: true, isOccupied: true },
          { idx: 3, isFocused: false, isOccupied: false },
          { idx: 4, isFocused: false, isOccupied: true },
          { idx: 5, isFocused: false, isOccupied: false },
          { idx: 6, isFocused: true, isOccupied: false }
        ]
      }
    }

    Timer {
      interval: 2000
      running: true
      onTriggered: stage.grabToImage(function(r) {
        r.saveToFile(Quickshell.env("GOLDEN_OUT"))
        Qt.quit()
      })
    }
  }
}
```

- [ ] **Step 2: Run, expect FAIL**

Run: `bash scripts/tag-strip-render.sh`
Expected: `FAIL: no render` (TagStripBlocks undefined, qs log shows the missing type).

- [ ] **Step 3: Create `bar/TagStripBlocks.qml`**

```qml
import QtQuick
import "../config"
import "../config/TagStrip.js" as TagStrip

// One equal-width block per workspace. Pure view: the model and the focus
// action come from the owner.
Item {
  id: root

  property var workspaces: []
  readonly property var blocks: TagStrip.tagStates(root.workspaces)
  readonly property var accents: [Colors.primary, Colors.secondary, Colors.tertiary]

  signal activated(int idx)

  function fill(block) {
    var a = root.accents[block.accent]
    if (block.state === "focused") return a
    return Qt.rgba(a.r, a.g, a.b, block.state === "occupied" ? 0.35 : 0.08)
  }

  Row {
    anchors.fill: parent

    Repeater {
      model: root.blocks

      delegate: Rectangle {
        required property var modelData
        width: root.blocks.length > 0 ? root.width / root.blocks.length : 0
        height: parent.height
        color: root.fill(modelData)
        Behavior on color { ColorAnimation { duration: Config.motionShort } }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.activated(modelData.idx)
        }
      }
    }
  }
}
```

- [ ] **Step 4: Create `bar/TagStrip.qml`**

```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../config"

// Top-edge strip of workspace color blocks (elena style). The Bar sits
// below it: with a top bar, the Bar's top margin reserves the strip's space
// (deterministic stacking); otherwise the strip reserves it itself.
PanelWindow {
  id: root

  property var workspaces: []
  // False when a top-docked horizontal bar already includes the strip in its
  // own margin; true for bottom and vertical bars.
  property bool reserveZone: false

  signal activated(int idx)

  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: Config.tagStripHeight
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: root.reserveZone ? Config.tagStripHeight : 0
  WlrLayershell.namespace: Config.layerNamespace("tagstrip")
  WlrLayershell.layer: WlrLayer.Top

  TagStripBlocks {
    anchors.fill: parent
    workspaces: root.workspaces
    onActivated: function(idx) { root.activated(idx) }
  }
}
```

- [ ] **Step 5: Run, expect PASS**

Run: `bash scripts/tag-strip-render.sh`
Expected: six `ok   block N` lines, exit 0. If a block is off by more than 3, print the PNG path (`cp "$home/strip.png" /tmp/tag-strip.png` inside the script when debugging) and look at it before changing tolerances.

- [ ] **Step 6: Lint + commit**

```bash
bash scripts/m3-qmllint-gate.sh
yadm add bar/TagStripBlocks.qml bar/TagStrip.qml tests/tag-strip/shell.qml scripts/tag-strip-render.sh
yadm commit -m "elena: tag strip blocks, panel window, pixel check"
```

---

### Task 4: Bar + shell integration, live verification

> **Revision 2026-10-12:** superseded. Bar.qml shows `TagStripBlocks` in `barBg` under elena, hides the other content with opacity/enabled, `Config.barWidth` = 8, form full, position forced top in shell.qml. No TagStrip window, no margins.top, no popup offsets. Steps 1-4 below are historical.

**Files:**
- Modify: `bar/Bar.qml` (near line 120 `exclusionMode`; lines 227/229 `popupAnchorY`; lines 602-623 `WorkspaceIndicator`), `bar/PopupBase.qml` (top-margin floor, line ~49), `shell.qml` (after the `Bar { }` block, line ~516)

**Interfaces:**
- Consumes: `TagStrip` (Task 3), `Config.tagStripOffset` (Task 2).
- Produces: `Bar.tagWorkspaces: var`, `Bar.focusTagWorkspace(idx)`.

- [ ] **Step 1: Bar top margin and exposure** in `bar/Bar.qml`, directly after `exclusiveZone: root.niriExclusiveZone`:

```qml
  // elena: the tag strip owns the top 8 px of the screen; shifting the whole
  // bar surface keeps the strip and the bar from fighting over exclusive-zone
  // order. Layer-shell counts the edge margin in the exclusive zone.
  margins.top: Config.tagStripOffset

  // Read by shell.qml for the elena tag strip.
  readonly property var tagWorkspaces: wsIndicator.visibleWorkspaces
  function focusTagWorkspace(idx) { wsIndicator.focusWorkspace(idx) }
```

- [ ] **Step 2: Popup anchor offset.** Read `bar/PopupBase.qml:30-60` and `bar/Bar.qml:215-235` first. In `Bar.qml` lines 227 and 229, add `+ Config.tagStripOffset` to both `popupAnchorY` assignments (the bar moved down by that amount; popups anchor in screen coordinates). In `PopupBase.qml`, add `+ Config.tagStripOffset` to `topMarginFloor`'s definition so popups never overlap the strip. Notification toast and OSD anchor to screen edges and need no change; confirm by eye in Step 5.

- [ ] **Step 3: Hide the in-bar workspace widget under elena.** Keep it `visible` (its refresher and debounce are gated on `root.visible`), but collapse and hide it. In the `WorkspaceIndicator { id: wsIndicator ... }` block replace:

```qml
          Layout.preferredWidth: Settings.ccShowWorkspaces
```
with
```qml
          opacity: Config.elenaTheme ? 0 : 1
          enabled: !Config.elenaTheme
          Layout.preferredWidth: (Settings.ccShowWorkspaces && !Config.elenaTheme)
```
and the same `&& !Config.elenaTheme` on `Layout.preferredHeight`'s condition. Leave `visible: Settings.ccShowWorkspaces` unchanged.

- [ ] **Step 4: Instantiate the strip** in `shell.qml`, after the `Bar { id: bar ... }` block:

```qml
  TagStrip {
    screen: bar.screen
    visible: Config.elenaTheme && bar.visible
    workspaces: bar.tagWorkspaces
    reserveZone: !(bar.horizontal && bar.dockedTop)
    onActivated: function(idx) { bar.focusTagWorkspace(idx) }
  }
```
Check `shell.qml` imports `"bar"` and `"config"` (it already instantiates `Bar` and reads `Settings`). Run `bash scripts/m3-qmllint-gate.sh`.

- [ ] **Step 5: Live check** (QML is live on save; nothing to restart)

```bash
qs ipc call shell style elena ""
qs ipc call shell mediaStatus >/dev/null   # shell responsive
scripts/capture-screen.sh /tmp/elena-top.png   # read scripts/capture-screen.sh for its usage first
```
Look at `/tmp/elena-top.png`: strip across the top edge with focused block in a full accent, the bar fully below it, no workspace numbers in the bar. Then:
- `niri msg action focus-workspace 2` then `3`: focused block moves, colors animate.
- Click a block: that workspace focuses.
- Open a window: its top edge sits below the bar (`niri msg -j windows | jq` tile position vs bar height + 8).
- Open the audio popup (`qs ipc call shell popup audio`): it sits under the bar, not overlapping it. Then `qs ipc call shell dismissPopups`.
- Settings > Appearance: tile "Elena" selects, palette controls show Fixed + Elenapam; switching source to Live uses wallpaper colors and the strip follows.
Restore: `qs ipc call shell style material3 ""; qs ipc call shell dismissPopups; jq .themeStyle ~/.config/quickshell/settings.json`.

- [ ] **Step 6: Commit**

```bash
yadm add bar/Bar.qml bar/PopupBase.qml shell.qml
yadm commit -m "elena: mount tag strip, offset bar and popups, hide in-bar workspaces"
```

---

### Task 5: Gates, baseline, ship

**Files:** none new.

- [ ] **Step 1: Full gate run**

```bash
node tests/elena/test.mjs && node tests/bar-form/test.mjs && node tests/settings-tabs/test.mjs
bash scripts/tests/test_niri_shape.sh && bash scripts/tests/test_accent_override.sh
bash scripts/tag-strip-render.sh
bash scripts/m3-qmllint-gate.sh
scripts/controls-behavior.sh .
```
Expected: all pass. `tests/settings-tabs/test.mjs` may assert the style tile count; if it fails on the 6 to 7 change, update its expected count in the same commit.

- [ ] **Step 2: Golden baseline.** The golden list now includes `elena:classic`, so the stored baseline lacks `elena.png`. Run `scripts/controls-golden-baseline.sh update`, then `scripts/controls-golden-baseline.sh check`. Expected: `ok` for every style, existing five unchanged.

- [ ] **Step 3: Push**

```bash
yadm status --short | grep -v settings.json
yadm push origin main
```

- [ ] **Step 4: Report** (completion status, what to restart: nothing, QML hot reloads and scripts are read per run; if the strip does not appear after the first style switch, `systemctl --user restart quickshell.service`). Update memory: add `quickshell-elena-theme.md` with the ride-the-material-path decision and the margin.top stacking choice.

---

## Self-review

- **Spec coverage:** identity (T2), palette fixed + Matugen optional via existing source toggle and select-time default (T1, T2), strip with states, click, motion tokens, hidden in-bar widget (T3, T4), Niri rounded lock (T2), tests and golden (T1, T2, T3, T5). The spec's `tagStates(workspaces, count)` signature and "excluded from material3Theme" are amended in T1 Step 6 with reasons.
- **Placeholders:** none. Unread spots are explicit read-then-edit steps (PopupBase floor, `capture-screen.sh` usage) because their exact text was not needed to design the change.
- **Types:** `tagStates` item shape `{idx, state, accent}` matches `TagStripBlocks.fill(block)`; `activated(int idx)` flows `TagStripBlocks -> TagStrip -> shell.qml -> Bar.focusTagWorkspace -> WorkspaceIndicator.focusWorkspace(idx)`; `Config.tagStripHeight/Offset` used identically in Bar, PopupBase and TagStrip.
- **Known risk:** layer-shell margin-in-exclusive-zone behavior in Niri is verified live in T4 Step 5 (window top edge check); fallback is giving the strip `exclusiveZone: 8` and dropping the Bar margin.
