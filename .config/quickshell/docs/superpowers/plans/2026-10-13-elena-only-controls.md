# Elena only: styles removal and native controls Implementation Plan (S1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make elena the only UI style, remove the Material 3 control implementation, and rebuild the controls in the liquid-tile grammar.

**Architecture:** The facades (`bar/SliderControl.qml`, `bar/SwitchControl.qml`, `bar/primitives/{ActionButton,IconButton}.qml`) compute colors and geometry and pass them by `Binding` to a thin implementation loaded through a `Loader`; the input and accessibility logic lives in `bar/themes/shared/*Base.qml`. The plan moves the bases to `bar/controls/`, adds one implementation per control there, collapses every style conditional to the elena value (a fixed truth table), then deletes the dead code. A property dump of `Config` and `Colors` taken before the change is the regression oracle.

**Tech Stack:** QML (Quickshell, Qt 6), node (`.mjs` gate tests), bash gate scripts, python3 for compare scripts.

**Spec:** `docs/superpowers/specs/2026-10-13-elena-only-controls-design.md`

## Global Constraints

- VCS is yadm only: `cd ~ && yadm add <paths> && yadm commit -m ... && yadm push origin main`. Never stage `.config/quickshell/settings.json`, Kvantum, btop, kitty, niri or starship files. Never `--no-verify`, never force-push.
- Never edit `~/.config/quickshell/settings.json` directly. No wtype/keystrokes in tests.
- No em dashes in code comments or docs. Match surrounding comment density.
- Truth table (the elena runtime values; every collapse must use exactly these):

| Expression | Value under elena |
|---|---|
| `Config.nothingDesign`, `Config.nothingEvolution`, `Config.ghostTheme`, `Config.dwmTheme`, `Config.liquidGlassTheme` (and the `Colors.*` mirrors) | `false` |
| `Config.material3Theme`, `Config.elenaTheme` | `true` |
| `Settings.themeStyle` | `"elena"` |
| `Config.materialCompact` | `false` (setting removed) |
| `Config.spatialMotion`, `Config.expressiveMotion` | `true` |

  A collapse never removes a branch that is reachable with these values. If an expression mixes a removed flag with a live condition (`a && !ghostTheme`), keep the live part.
- Shape tokens after Task 3: `shapeCompact` 8, `shapeMedium` 12, `shapeLarge` 20 (intended change).
- Every task ends with all gates in "Gate set" green, then a commit and push.
- QML saves hot-reload the live shell. After a task that edits `config/*` or `shell.qml`, do not run `qs ipc` live checks until the user cold restarts (`systemctl --user restart quickshell.service`, the user's command).
- The repo gate bans `.claude/` inside the tree: delete `.claude/` under `~/.config/quickshell` before running gates.

## Gate set

Run from `~/.config/quickshell`:

```bash
bash scripts/m3-qmllint-gate.sh
bash scripts/tests/test_niri_shape.sh
for t in scripts/tests/test_*.py; do python3 -I "$t"; done
for t in tests/dock/*.test.mjs tests/elena/*.mjs; do node "$t"; done   # existing node gates
bash scripts/sidebar-render.sh && bash scripts/dock-render.sh && bash scripts/tag-strip-render.sh
bash scripts/controls-behavior.sh
bash scripts/config-dump.sh check          # from Task 1 on
```

Golden (`bash scripts/controls-golden-baseline.sh check`) runs where a task says so (Task 3 retakes the baseline).

## File Structure

| Path | Role |
|---|---|
| `scripts/config-dump.sh`, `scripts/config-dump-compare.py`, `tests/elena/config-dump/shell.qml`, `tests/elena/config-dump.baseline.json`, `tests/elena/config-dump.allow.json` | dump gate (Task 1) |
| `scripts/style-refs.sh` | lists remaining removed-flag references; exit 1 when any (Task 1) |
| `bar/controls/{SliderBase,SwitchBase,ActionButtonBase,IconButtonBase}.qml` | moved input/accessibility bases (Task 2) |
| `bar/controls/{ElenaSliderControl,ElenaSwitchControl,ElenaActionButton,ElenaIconButton}.qml` | implementations (Tasks 2, 3) |
| `bar/controls/LevelTile.qml` | liquid level tile (Task 3) |
| `tests/controls/shell.qml`, `scripts/controls-render.sh` | render check (Task 3) |
| `config/{Config,Colors,Settings}.qml`, `config/PaletteCatalog.js`, `config/BarForm.js` | collapse (Task 4) |
| `bar/**`, `shell.qml`, `ui/WelcomeScreen.qml` | call-site collapse (Tasks 5 to 8) |

---

### Task 1: Dump gate and style-refs inventory

**Files:**
- Create: `scripts/config-dump.sh`, `scripts/config-dump-compare.py`, `scripts/style-refs.sh`
- Create: `tests/elena/config-dump/shell.qml`, `tests/elena/config-dump.baseline.json`, `tests/elena/config-dump.allow.json`

**Interfaces:**
- Produces: `bash scripts/config-dump.sh capture` (writes the baseline), `bash scripts/config-dump.sh check` (exit 1 on any unexplained diff), `bash scripts/style-refs.sh [paths...]` (prints `file:count`, exit 1 if any reference).

- [ ] **Step 1: Write `tests/elena/config-dump/shell.qml`**

```qml
// Prints every Config and Colors property as one DUMP line of sorted JSON.
// Names come from names.js, generated by scripts/config-dump.sh from the
// property declarations in config/Config.qml and config/Colors.qml.
import QtQuick
import Quickshell
import "config"
import "names.js" as Names

ShellRoot {
  function ser(v) {
    if (v === undefined) return "undefined"
    if (v === null) return null
    if (typeof v === "function") return "function"
    if (typeof v === "object") {
      try { var s = JSON.stringify(v); if (s !== undefined) return JSON.parse(s) } catch (e) {}
      return String(v)
    }
    if (typeof v === "number") return Math.round(v * 10000) / 10000
    return typeof v === "boolean" ? v : String(v)
  }
  Component.onCompleted: {
    var out = {}
    var i
    for (i = 0; i < Names.config.length; i++) out["Config." + Names.config[i]] = ser(Config[Names.config[i]])
    for (i = 0; i < Names.colors.length; i++) out["Colors." + Names.colors[i]] = ser(Colors[Names.colors[i]])
    var keys = Object.keys(out).sort()
    var sorted = {}
    for (i = 0; i < keys.length; i++) sorted[keys[i]] = out[keys[i]]
    console.log("DUMP " + JSON.stringify(sorted))
    Qt.quit()
  }
}
```

- [ ] **Step 2: Write `scripts/config-dump.sh`**

```bash
#!/usr/bin/env bash
# Usage: config-dump.sh capture|check [quickshell-root]
# Dumps every Config/Colors property under the elena style in a scratch HOME.
#   capture  write tests/elena/config-dump.baseline.json
#   check    dump twice (determinism), compare with the baseline through
#            config-dump-compare.py and tests/elena/config-dump.allow.json
set -euo pipefail
mode=${1:-}
root=$(realpath "${2:-$(dirname "$0")/..}")

names() { # property names declared in a QML file (properties only, not aliases of functions)
  grep -oE '^[[:space:]]*(readonly )?property [A-Za-z.<>]+ [A-Za-z0-9_]+' "$1" | awk '{print $NF}' | sort -u
}

dump_once() {
  local home; home=$(mktemp -d)
  mkdir -p "$home/.config/quickshell" "$home/cfg"
  cp -r "$root/config" "$root/resources" "$home/cfg/" 2>/dev/null || cp -r "$root/config" "$home/cfg/"
  cp "$root/tests/elena/config-dump/shell.qml" "$home/cfg/shell.qml"
  {
    printf '.pragma library\nvar config = ['
    names "$root/config/Config.qml" | sed 's/.*/"&"/' | paste -sd, -
    printf '];\nvar colors = ['
    names "$root/config/Colors.qml" | sed 's/.*/"&"/' | paste -sd, -
    printf '];\n'
  } > "$home/cfg/names.js"
  printf '{"themeStyle":"elena","colorSource":"fixed","colorPalette":"elenapan","themePreference":1}\n' \
    > "$home/.config/quickshell/settings.json"
  HOME="$home" XDG_CURRENT_DESKTOP=niri XDG_SESSION_DESKTOP=niri timeout 40 qs -p "$home/cfg/shell.qml" 2>&1 \
    | sed -n 's/^.*DUMP //p' | head -1
  rm -rf "$home"
}

a=$(dump_once)
[ -n "$a" ] || { echo "config-dump: no DUMP line (qs failed)" >&2; exit 2; }
case "$mode" in
  capture)
    printf '%s\n' "$a" > "$root/tests/elena/config-dump.baseline.json"
    echo "baseline written: $(python3 -c 'import json,sys;print(len(json.loads(sys.argv[1])))' "$a") keys" ;;
  check)
    b=$(dump_once)
    [ "$a" = "$b" ] || { echo "config-dump: not deterministic between two runs" >&2; exit 2; }
    tmp=$(mktemp); printf '%s\n' "$a" > "$tmp"
    python3 -I "$root/scripts/config-dump-compare.py" "$root/tests/elena/config-dump.baseline.json" "$tmp" \
      "$root/tests/elena/config-dump.allow.json"
    rc=$?; rm -f "$tmp"; exit $rc ;;
  *) echo "usage: $0 capture|check [root]" >&2; exit 2 ;;
esac
```

- [ ] **Step 3: Write `scripts/config-dump-compare.py`**

```python
#!/usr/bin/env python3
"""Compare two config dumps. Usage: config-dump-compare.py BASE NEW ALLOW.json

ALLOW.json: {"removed": ["Config.nothingDesign", ...], "removedPrefixes": [...],
             "changed": {"Config.shapeLarge": [16, 20]}}
Exit 1 when a key disappears, changes value, or appears without being allowed.
"""
import json, sys

base = json.load(open(sys.argv[1]))
new = json.load(open(sys.argv[2]))
allow = json.load(open(sys.argv[3]))
removed_ok = set(allow.get("removed", []))
prefixes = tuple(allow.get("removedPrefixes", []))
changed_ok = allow.get("changed", {})

problems = []
for k in sorted(base):
    if k not in new:
        if k in removed_ok or k.startswith(prefixes):
            continue
        problems.append(f"missing  {k} (was {base[k]!r})")
    elif new[k] != base[k]:
        exp = changed_ok.get(k)
        if exp is not None and exp[0] == base[k] and exp[1] == new[k]:
            continue
        problems.append(f"changed  {k}: {base[k]!r} -> {new[k]!r}")
for k in sorted(new):
    if k not in base:
        problems.append(f"added    {k} = {new[k]!r}")

if problems:
    print("\n".join(problems))
    print(f"config-dump: {len(problems)} unexplained difference(s)")
    sys.exit(1)
print(f"config-dump: ok ({len(new)} keys, {len(base) - len(new)} removed)")
```

- [ ] **Step 4: Write `scripts/style-refs.sh`**

```bash
#!/usr/bin/env bash
# Usage: style-refs.sh [--elena] [paths...]
# Lists references to the removed style flags (default: whole tree minus docs
# and .superpowers). --elena also counts Config.elenaTheme. Exit 1 if any.
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
pat='nothingDesign|nothingEvolution|ghostTheme|dwmTheme|liquidGlassTheme|material3Theme|themeStyle|nothingVariant|materialCompact|liquidGlass[A-Z]|styleAccent|styleSurface|styleInk|styleOutline'
if [ "${1:-}" = "--elena" ]; then pat="$pat|elenaTheme"; shift; fi
cd "$root" || exit 2
if [ $# -gt 0 ]; then targets=("$@"); else targets=(.); fi
out=$(grep -rIcE "$pat" "${targets[@]}" --exclude-dir=docs --exclude-dir=.superpowers --exclude-dir=.git \
  --exclude=settings.json --exclude=config-dump.baseline.json --exclude=config-dump.allow.json \
  --exclude=style-refs.sh 2>/dev/null | grep -v ':0$' | sort)
[ -z "$out" ] && { echo "style-refs: none"; exit 0; }
echo "$out"; exit 1
```

- [ ] **Step 5: Capture the baseline and the empty allow list**

```bash
cd ~/.config/quickshell
printf '{"removed": [], "removedPrefixes": [], "changed": {}}\n' > tests/elena/config-dump.allow.json
bash scripts/config-dump.sh capture
bash scripts/config-dump.sh check          # Expected: "config-dump: ok (N keys, 0 removed)"
bash scripts/style-refs.sh | tail -3       # Expected: a list, exit 1 (this is the work remaining)
```

If `capture` fails with "no DUMP line", run `qs -p` manually with the scratch HOME and read the error: the likely causes are a property name in `names.js` that is a function or alias (exclude it in `names()`) or `Colors` needing a file the scratch HOME lacks (copy it). The fix belongs in `config-dump.sh`, not in the QML sources.

- [ ] **Step 6: Mutation check** (the gate must fail when it should)

```bash
cd ~/.config/quickshell && sed -i 's/readonly property int tagStripHeight: 8/readonly property int tagStripHeight: 9/' config/Config.qml
bash scripts/config-dump.sh check; echo "exit=$?"     # Expected: "changed  Config.tagStripHeight" ... exit=1
git -C ~ checkout -- .config/quickshell/config/Config.qml 2>/dev/null || yadm checkout -- .config/quickshell/config/Config.qml
bash scripts/config-dump.sh check                      # Expected: ok
```

- [ ] **Step 7: Commit**

```bash
cd ~ && yadm add .config/quickshell/scripts/config-dump.sh .config/quickshell/scripts/config-dump-compare.py \
  .config/quickshell/scripts/style-refs.sh .config/quickshell/tests/elena/config-dump \
  .config/quickshell/tests/elena/config-dump.baseline.json .config/quickshell/tests/elena/config-dump.allow.json
yadm commit -m "elena-only S1: config/colors dump gate and style-refs inventory" && yadm push origin main
```

---

### Task 2: Move the bases, add the implementations, collapse the four facades

Pure restructure: the look does not change, so the dump and the golden image must stay as they are.

**Files:**
- Move: `bar/themes/shared/{SliderBase,SwitchBase,ActionButtonBase,IconButtonBase}.qml` to `bar/controls/` (use `yadm mv`; fix the relative imports `../../../config` to `../../config` and `../../primitives` to `../primitives`)
- Create: `bar/controls/{ElenaSliderControl,ElenaSwitchControl,ElenaActionButton,ElenaIconButton}.qml` (collapsed copies of `bar/themes/material3/*`)
- Modify: `bar/SliderControl.qml`, `bar/SwitchControl.qml`, `bar/primitives/ActionButton.qml`, `bar/primitives/IconButton.qml`
- Modify: `scripts/controls-behavior.sh`, `tests/controls-behavior/shell.qml`

**Interfaces:**
- Produces: `ElenaSliderControl`, `ElenaSwitchControl`, `ElenaActionButton`, `ElenaIconButton` in `bar/controls/` with the property/signal API of the Base they extend (unchanged). The facades load them unconditionally.

- [ ] **Step 1: Move the bases**

```bash
cd ~ && mkdir -p .config/quickshell/bar/controls
for b in SliderBase SwitchBase ActionButtonBase IconButtonBase; do
  yadm mv .config/quickshell/bar/themes/shared/$b.qml .config/quickshell/bar/controls/$b.qml
done
cd .config/quickshell && sed -i 's|"../../../config"|"../../config"|; s|"../../primitives"|"../primitives"|' bar/controls/*Base.qml
# The old material/styled implementations still import "../shared"; keep them compiling until Task 9:
for f in bar/themes/material3/*.qml bar/themes/styled/*.qml; do sed -i 's|import "../shared"|import "../../controls"|' "$f"; done
```

- [ ] **Step 2: Create the four implementations as collapsed copies**

For each of `bar/themes/material3/{SliderControl,SwitchControl,ActionButton,IconButton}.qml`, copy to `bar/controls/Elena<Name>.qml` and apply the truth table:
- delete `ThemeTokens { id: theme }` and replace `theme.X` with the matching `Colors.*`/literal (`theme.focusBorderWidth` 2, `theme.borderWidth` 1, `theme.controlRadius` 12, `theme.outline` `Colors.outline`, `theme.primary` `Colors.primary`, `theme.surfaceContainerHigh(est)`, `theme.surfaceVariant` `Colors.surfaceVariant`, `theme.focus` `Colors.primary`, `theme.fontFamily` `Config.fontFamily`);
- remove the `liquidGlass` property and every `root.liquidGlass ? A : B` (keep B), delete `knobShadow`, delete `GlassSheen`;
- replace `Config.material3Theme ? X : Y` with `X`; `ColorSpring.animate` becomes `!root.reducedMotion && !Config.reducedMotion`; delete the now-dead `Behavior on color { enabled: !Config.material3Theme ... }` blocks;
- change the `import "."`/`import "../shared"` lines to `import "."` only (Base files live next to them now), and `../../primitives` to `../primitives`; `../../../config` to `../../config`.
- file/type names: `ElenaSliderControl`, `ElenaSwitchControl`, `ElenaActionButton`, `ElenaIconButton`; keep the root type (`SliderBase`, etc.).

- [ ] **Step 3: Collapse the facades**

In each of the four facades: add `import "../controls"` (path `"controls"` for `bar/*.qml`, `"../controls"` for `bar/primitives/*.qml`), delete the `Material3`/`Styled` imports and both extra `Component`s, set
`Loader { sourceComponent: elenaImplementation }` with `Component { id: elenaImplementation; ElenaSliderControl {} }` (matching name), and replace every style conditional by its elena value from the truth table. Examples that must come out exactly:

```qml
// bar/SliderControl.qml
property color surfaceContainerHigh: Colors.surfaceContainerHigh
property color surfaceContainerHighest: Colors.surfaceContainerHighest
property color outline: Colors.outline
property color focusColor: Colors.primary
// bar/primitives/ActionButton.qml
property bool horizontalContent: true
readonly property bool segmented: root.grouped && root.groupPosition !== "single"
implicitHeight: Math.max(Config.controlHitSize, Config.typeLabelMediumLineHeight + 24)
Layout.minimumHeight: implicitHeight
Layout.minimumWidth: Config.controlHitSize
// bar/primitives/IconButton.qml
implicitWidth: Math.max(Config.controlHitSize, size)
implicitHeight: Math.max(Config.controlHitSize, size)
property real radius: size / 2
```

Remove `readonly property bool material3Theme` from the facades only if no remaining line reads it (`grep -n material3Theme bar/SliderControl.qml ...`).

- [ ] **Step 4: Collapse the behavior suite to the single style**

In `scripts/controls-behavior.sh` replace the style list with `for s in elena:classic; do`. In `tests/controls-behavior/shell.qml` replace `if (Config.material3Theme) {` by an unconditional block (keep its body) and delete any `else` branch that only served other styles. Run it: it must print `ok   elena-classic: N checks` with N equal to the old material3 count (33).

- [ ] **Step 5: Run the gate set plus golden**

```bash
cd ~/.config/quickshell && rm -rf .claude
<gate set>; bash scripts/controls-golden-baseline.sh check   # Expected: all ok, diffs 0 to 3 px
bash scripts/style-refs.sh bar/controls bar/SliderControl.qml bar/SwitchControl.qml \
  bar/primitives/ActionButton.qml bar/primitives/IconButton.qml    # Expected: none
```

The dump gate must be unchanged (no config edits yet).

- [ ] **Step 6: Commit**

```bash
cd ~ && yadm add -A .config/quickshell/bar/controls .config/quickshell/bar/themes .config/quickshell/bar/SliderControl.qml \
  .config/quickshell/bar/SwitchControl.qml .config/quickshell/bar/primitives/ActionButton.qml \
  .config/quickshell/bar/primitives/IconButton.qml .config/quickshell/scripts/controls-behavior.sh \
  .config/quickshell/tests/controls-behavior/shell.qml
yadm commit -m "elena-only S1: controls live in bar/controls, facades load one implementation" && yadm push origin main
```

---

### Task 3: Liquid-tile look, tokens, LevelTile, render check

The intended visual change. Golden baseline is retaken at the end.

**Files:**
- Modify: `config/Config.qml` (shape tokens), `tests/elena/config-dump.allow.json`
- Modify: `bar/controls/{ElenaSliderControl,ElenaSwitchControl,ElenaIconButton,ElenaActionButton}.qml`, `bar/sidebar/LevelBar.qml`
- Create: `bar/controls/LevelTile.qml`, `tests/controls/shell.qml`, `scripts/controls-render.sh`

**Interfaces:**
- Produces: `LevelTile { property real value; property color accent; property string iconLabel; property bool muted; property bool enabled; signal moved(real value); signal iconClicked() }` (58x58 default implicit size, fills from the bottom, white round icon).
- Consumes: Task 2 implementations.

- [ ] **Step 1: Tokens**

In `config/Config.qml` set
`shapeCompact: 8`, `shapeMedium: 12`, `shapeLarge: 20` (collapse the ternaries at lines 186 to 188 to those literals). Record the intended changes in `tests/elena/config-dump.allow.json`:

```json
{"removed": [], "removedPrefixes": [], "changed": {
  "Config.shapeMedium": [12, 12], "Config.shapeLarge": [16, 20]}}
```

Delete any entry whose old and new values are equal (`shapeCompact`, `shapeMedium` already 8/12). Add every other key the dump reports as changed, but only if it follows from the radius change (`popupRadius`, `borderRadius`, `barRadius` if they alias `shapeLarge`); anything else is a bug to fix, not to allow.

- [ ] **Step 2: Switch**

In `bar/controls/ElenaSwitchControl.qml` set geometry and colors (58x30 track, white knob; replace the track/knob blocks):

```qml
height: 40
readonly property real trackWidth: Math.min(58, root.width)
readonly property real trackX: (root.width - trackWidth) / 2
readonly property real targetThumbSize: pressed ? 26 : 22
readonly property real targetX: trackX + (checked ? trackWidth - targetThumbSize - 4 : 4)
// track: y (height-30)/2, width trackWidth, height 30, radius 15,
//   color: checked ? activeColor : surfaceContainerHighest (tinted by stateOverlay), border 0
// knob: width/height thumbSize, radius thumbSize/2,
//   color: checked ? "#ffffff" : Colors.outline, centered on thumbX; no check glyph
```

Keep the focus ring, the spring `Behavior`s and the `ColorSpring`s as they are.

- [ ] **Step 3: Slider**

Replace the track/knob rectangles in `bar/controls/ElenaSliderControl.qml` with a flat tile:

```qml
height: 40
readonly property real fillWidth: value <= 0 ? 0 : Math.max(height, width * Math.max(0, Math.min(1, value)))
Rectangle {   // track tile
  anchors.fill: parent
  radius: Config.shapeMedium
  color: root.surfaceContainerHighest
  Rectangle {  // level fill
    width: root.fillWidth; height: parent.height; radius: parent.radius
    color: Qt.tint(root.muted ? root.outline : root.activeColor, root.stateOverlay)
  }
  Rectangle {  // white round thumb at the end of the fill
    visible: root.fillWidth > 0
    width: 24; height: 24; radius: 12
    x: Math.max(3, root.fillWidth - width - 3); anchors.verticalCenter: parent.verticalCenter
    color: "#ffffff"
  }
}
```

Keep the focus ring rectangle (radius `Config.shapeMedium + 4`) and the `MouseArea`, with `handleMouse` unchanged (drag anywhere on the tile sets `mx / width`; drop the `draggingThumb` offset logic).

- [ ] **Step 4: IconButton and ActionButton radii**

`bar/primitives/IconButton.qml`: `property real radius: variant === "round" ? size / 2 : size * 0.34` and keep `ElenaIconButton` drawing the container with `radius: root.radius`. `ElenaIconButton`: the glyph sits on a white round when `selected`: add, behind `IconGlyph`, `Rectangle { visible: root.selected; anchors.centerIn: parent; width: root.size * 0.72; height: width; radius: width / 2; color: "#ffffff" }` and use `Colors.surface` as the glyph color when selected. `bar/primitives/ActionButton.qml`: `radius` collapses to `root.height / 2` when `variant === "pill"` else `Config.shapeLarge` (20). Add `"pill"` as an allowed variant (same fill logic as `filled`).

- [ ] **Step 5: LevelTile and LevelBar**

`bar/controls/LevelTile.qml`:

```qml
import QtQuick
import "../../config"
import "../primitives"

// Liquid level tile: squircle that fills from the bottom, white round icon.
Item {
  id: root
  property real value: 0
  property color accent: Colors.primary
  property string iconLabel: ""
  property bool muted: false
  property string accessibleName: ""
  signal moved(real value)
  signal iconClicked()

  implicitWidth: 58
  implicitHeight: 58
  opacity: enabled ? 1 : 0.38

  Rectangle {
    id: tile
    anchors.fill: parent
    radius: Config.shapeLarge
    color: Colors.surfaceContainerHighest
    clip: true
    Rectangle {
      anchors.bottom: parent.bottom
      width: parent.width
      height: parent.height * Math.max(0, Math.min(1, root.value))
      color: root.muted ? Colors.outline : root.accent
    }
  }
  MouseArea {
    anchors.fill: parent
    enabled: root.enabled
    function setFrom(mouse) {
      var v = Math.max(0, Math.min(1, 1 - mouse.y / height))
      // Skip sub-1% jitter so a drag does not spawn a process per pixel.
      if (Math.abs(v - root.value) >= 0.01) root.moved(v)
    }
    onPressed: function(mouse) { setFrom(mouse) }
    onPositionChanged: function(mouse) { if (pressed) setFrom(mouse) }
  }
  Rectangle {
    id: badge
    visible: root.iconLabel !== ""
    width: 26; height: 26; radius: 13
    color: "#ffffff"
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 8
    IconGlyph {
      anchors.centerIn: parent
      iconLabel: root.iconLabel
      iconColor: Colors.surface
      iconSize: 16
    }
    MouseArea { anchors.fill: parent; enabled: root.enabled; onClicked: root.iconClicked() }
    Accessible.role: Accessible.Button
    Accessible.name: root.accessibleName
  }
}
```

`bar/sidebar/LevelBar.qml` becomes a thin wrapper keeping its public API (`value`, `accent`, `iconLabel`, `muted`, `accessibleName`, `moved`, `iconClicked`, 40x160): replace the track and the `IconButton` by `LevelTile { anchors.fill: parent; value: root.value; accent: root.accent; iconLabel: root.iconLabel; muted: root.muted; accessibleName: root.accessibleName; onMoved: function(v) { root.moved(v) }; onIconClicked: root.iconClicked() }`.

- [ ] **Step 6: Render check `scripts/controls-render.sh` and `tests/controls/shell.qml`**

Model it on `scripts/sidebar-render.sh` (scratch HOME, copy `config bar resources`, stage window 760x560, `grabToImage`, print `PASS|FAIL name`, then `DONE n fail`). The stage holds, on `Colors.surface`: a `SwitchControl` checked, a `SwitchControl` unchecked, a `SliderControl` at 0.6, an `IconButton` selected, an `ActionButton` variant `"pill"` filled, and a `LevelTile` at 0.5 with `iconLabel: "settings"`. Assertions (colors from `Colors`, tolerance 0.03 per channel, sampled after `wait(900)`):
1. checked switch track center pixel equals `Colors.primary`.
2. unchecked switch track center equals `Colors.surfaceContainerHighest`.
3. slider pixel at 30 % of width equals `Colors.primary`; pixel at 90 % equals `Colors.surfaceContainerHighest`.
4. selected icon button center pixel is white (`#ffffff`) within the glyph-free inset (sample the corner of the white round, not the glyph).
5. pill ActionButton corner-adjacent pixel at 1/2 height, 4 px from the left edge equals `Colors.primary` (fully round ends).
6. LevelTile: pixel at 25 % height from the bottom equals `Colors.primary`, pixel at 85 % equals `Colors.surfaceContainerHighest`.

Prove it by mutation: flip the slider fill color in `ElenaSliderControl.qml` to `"red"`, confirm assertion 3 FAILS, revert.

- [ ] **Step 7: Retake the golden baseline and run everything**

```bash
cd ~/.config/quickshell && rm -rf .claude
bash scripts/controls-golden-baseline.sh update   # intentional visual change
bash scripts/controls-golden-baseline.sh check && bash scripts/controls-golden-baseline.sh check
<gate set> ; bash scripts/controls-render.sh
```

Expected: behavior suite 33 checks unchanged (the behavior contract), dump gate ok with only the allowed `shape*` family, sidebar render check passes with the new LevelBar (adjust its geometry assertions to the tile only if the bar dimensions assertion fails: the bar is still 40x160).

- [ ] **Step 8: Commit**

```bash
cd ~ && yadm add .config/quickshell/config/Config.qml .config/quickshell/bar .config/quickshell/tests .config/quickshell/scripts
yadm commit -m "elena-only S1: liquid-tile controls, 8/12/20 shape tokens, LevelTile, render check" && yadm push origin main
```

(Verify `yadm status` shows no `settings.json`, Kvantum, kitty, niri, btop or starship in the staged set before committing.)

---

### Task 4: Collapse `Config`, `Colors`, `Settings`, `PaletteCatalog`, `BarForm`

**Files:**
- Modify: `config/Config.qml`, `config/Colors.qml`, `config/Settings.qml`, `config/PaletteCatalog.js`, `config/BarForm.js`, `config/WindowService.qml`
- Modify: `tests/elena/config-dump.allow.json`

**Interfaces:**
- Consumes: the truth table. Produces: `Config.elenaTheme` stays as `readonly property bool elenaTheme: true` until Task 9; `Config.material3Theme` and every other removed flag disappear.

- [ ] **Step 1: Collapse `Config.qml`**

For each removed flag, delete its declaration and substitute the truth-table value in every expression of the file (89 references), simplifying ternaries (`material3Theme ? Math.round(14 * materialTypeScale) : ...` becomes `Math.round(14 * materialTypeScale)` where `materialTypeScale` is the existing setting-backed property; its setting stays only if it is a general scale and not Material-specific; if the property is named `materialTypeScale`, collapse it to the literal `1` and remove the setting in Step 3 so no visible size shifts). `layerNamespace(kind)` returns `"quickshell-" + kind`. `BarForm.resolve(Settings.barForm, true)`.

- [ ] **Step 2: Collapse `Colors.qml`**

Delete the `nothing*`, `ghost*` and `liquidGlass*` palettes, `liquidGlassRole`, `paletteSource` branches for removed styles, `paletteSourceSelectable` flags that only existed for them, and the `style*` helpers (`styleInk`, `styleOutline`, `styleOutlineStrong`, `styleAccent`, `styleAccentText`, `styleSurface`, `styleSurfaceRaised`) only if `bash scripts/style-refs.sh bar ui shell.qml` shows no remaining reader after Tasks 5 to 8; otherwise keep the helper but collapse it to the elena branch now and delete it in Task 9. Every role property (`background`, `fgSurface`, ...) loses its `liquidGlassRole(...)` wrapper and keeps `paletteRole(...)`.

- [ ] **Step 3: Settings**

Remove `themeStyle`, `nothingVariant`, `materialCompact` (and the Material type-scale setting if present) from `defaults`, the aliases, the reset block and the adapter. Delete the `neo-brutalism` migration block (lines 140 to 142). Settings that read stale keys must not crash: the adapter ignores unknown JSON keys; the dump harness fixture proves it because its settings.json still carries `themeStyle`.

- [ ] **Step 4: `WindowService.qml`**

`running:` binding and the elena guard collapse to unconditional (`running: true` with the existing retry logic); keep the file's retry timer.

- [ ] **Step 5: Update the allow list from the dump**

```bash
cd ~/.config/quickshell && bash scripts/config-dump.sh check | head -80
```

Expected output: only `missing` lines for removed flags and style helpers, plus `changed` lines already allowed. Put the removed names in `removed` (and the `Colors.ghost*`, `Colors.nothing*`, `Colors.liquidGlass*` families in `removedPrefixes`), re-run until `config-dump: ok`. A `changed` line outside the shape family is a collapse bug: fix the code.

- [ ] **Step 6: Gates and commit**

```bash
rm -rf .claude; <gate set>; bash scripts/controls-golden-baseline.sh check
cd ~ && yadm add .config/quickshell/config .config/quickshell/tests/elena && yadm commit -m "elena-only S1: collapse Config, Colors and Settings to elena" && yadm push origin main
```

`bash scripts/style-refs.sh config` must print `none` except `elenaTheme` (not counted without `--elena`).

---

### Tasks 5 to 8: Call-site collapse (four groups)

Each group is one task, one commit, with the same procedure.

**Procedure (per file in the group):**
1. `bash scripts/style-refs.sh <file>` shows the count.
2. Replace each flag with its truth-table value, simplify, delete dead branches and then-unused properties, imports and helper functions. Drop `Colors.style*` / `Colors.liquidGlass*` readers by switching to the elena branch's role (`Colors.primary`, `Colors.surfaceContainer`, `Colors.outline`, ...), exactly the value that expression evaluated to under elena.
3. `bash scripts/style-refs.sh <file>` prints none.
4. After the group: gate set, `bash scripts/controls-render.sh`, golden check twice, the dump gate unchanged, then commit.

**Group files**

| Task | Group | Files |
|---|---|---|
| 5 | popups and panels | `bar/{MediaPopup,WeatherPopup,CalendarPopup,NotificationPopup,NotificationToast,NotificationIndicator,LauncherPopup,Launcher,PowerConfirmation,QuickMenu,PopupBase,WifiPanel,BtPanel,SettingsPanel,LlmUsageSection,LlmUsageIcon,LlmUsagePopup}.qml` |
| 6 | bar and indicators | `bar/{Bar,WorkspaceIndicator,SystemTrayArea,BatteryIndicator,AudioIndicator,BrightnessIndicator,MediaIndicator,WeatherIndicator,MenuIndicator,WaveProgressBar,SliderControl,SwitchControl}.qml`, `bar/primitives/{StatusIndicator,ListItem,StyledSurface,PillSurface,TextFieldControl,LoadingIndicator,IconGlyph,ColorSpring,SignalWave,MaterialEntrance,ExpressiveShape}.qml` |
| 7 | system surfaces | `bar/{LockScreen,OsdOverlay}.qml`, `ui/WelcomeScreen.qml`, `shell.qml` |
| 8 | settings UI and the picker | `bar/settings/*.qml` (AppearanceTab: delete the style tiles, the Nothing variant row, the Material density and type-scale rows and their `SettingsPanel.searchEntries`; `GeneralTab`, `DisplayInputTab`, `LockMediaTab`, `NotificationsTab`, `ShortcutsTab`, `SettingsPageHeader`, `SettingsSectionLabel`, `DockSection`, `BarOrderRow`, `PowerProfileCard`) |

Group-specific notes:
- Task 6: `Bar.qml` keeps its elena-hidden widget layout untouched (the widget machinery is out of scope); only style conditionals collapse. `WorkspaceIndicator` keeps the elena block-strip path and drops the dwm/ghost/nothing variants.
- Task 7: `shell.qml` may only lose style conditionals; do not touch IPC function names. If the file's sidebar/dock instantiation has `visible: ... && Config.elenaTheme`, it becomes the live condition without the flag but keeps `!lockScreen.locked`. The `style` IPC function (in-memory style switching) is deleted.
- Task 8: after the settings rows go, `scripts/tests/tst_bar_order.qml` and the settings-tabs gate (`tests/settings-tabs`) must still pass: the tab list is unchanged.
- In every task, run `bash scripts/style-refs.sh <group files>`; the commit message is `elena-only S1: collapse style conditionals in <group>`.

---

### Task 9: Delete the dead code, scripts, tests; delete `Config.elenaTheme`

**Files:**
- Delete: `bar/themes/` (whole directory), unreferenced primitives (`GlassSheen`, `PacmanMarker`, `GroupCapsule` and any other file for which `grep -rIl <Name> bar shell.qml ui | grep -v <its own file>` is empty), style-specific assets (fonts, icon sets) with no reader.
- Modify: `config/Config.qml` (remove `elenaTheme`), every remaining reader of `Config.elenaTheme`, `scripts/*` per the table below, `README.md`, harnesses.

**Interfaces:**
- Produces: a tree where `bash scripts/style-refs.sh --elena` prints `none`.

- [ ] **Step 1: Unreferenced-file inventory (deterministic)**

```bash
cd ~/.config/quickshell
for f in bar/primitives/*.qml bar/*.qml; do
  n=$(basename "$f" .qml)
  c=$(grep -rIlw "$n" bar shell.qml ui config tests scripts 2>/dev/null | grep -v "^$f$" | wc -l)
  [ "$c" -eq 0 ] && echo "UNREFERENCED $f"
done
```

Review the list (some files are loaded by dynamic path, such as settings tabs): delete only what is clearly style-specific or dead, and note the rest in the commit body.

- [ ] **Step 2: Delete `bar/themes`**

```bash
cd ~ && yadm rm -r -q .config/quickshell/bar/themes && cd .config/quickshell && bash scripts/m3-qmllint-gate.sh
```

If the lint gate lists a broken import, the importer still referenced a removed implementation: fix the importer (it is a Task 5 to 8 miss), not the deletion.

- [ ] **Step 3: Scripts (the user decides the unclear ones)**

| Script | Action |
|---|---|
| `scripts/controls-golden.sh`, `controls-behavior.sh`, `sidebar-render.sh`, `dock-render.sh`, `tag-strip-render.sh`, `popup-ipc-check.sh`, `m3-qmllint-gate.sh`, `scripts/tests/*` | collapse style loops/literals to elena |
| `scripts/sync-active-palette.sh`, `sync-theme-mode-locked.sh` | collapse style branches; palette sync stays |
| `scripts/ensure-style-terminal-assets.sh`, `sync-mactahoe-theme.sh`, `sync-niri-shape.sh`, `install-sddm-integration.sh`, `sync-sddm-theme-root.sh`, `verify-sddm-integration.sh`, `install-ui-suite.sh`, `verify-ui-suite.sh` | the controller reads each one and puts the keep/collapse/delete choice to the user (AskUserQuestion) before any change; none is deleted without that answer |

- [ ] **Step 4: Delete `Config.elenaTheme`**

```bash
bash scripts/style-refs.sh --elena            # lists remaining readers
```

Replace each reader by its live meaning (`true` branch kept) and remove the declaration. Keep `tagStripHeight`.

- [ ] **Step 5: Docs and notes**

README: remove style documentation, describe the single style and the palette options. Add a `Superseded by docs/superpowers/specs/2026-10-13-elena-only-controls-design.md` line at the top of `2026-10-12-dwm-theme-design.md` and plan (history stays). Update the memory notes `quickshell-elena-theme.md`, `quickshell-design-system.md`, `quickshell-dwm-theme.md` (dwm theme now lives only in `dotfiles-old`).

- [ ] **Step 6: Final grep gate and everything**

```bash
bash scripts/style-refs.sh --elena            # Expected: style-refs: none
rm -rf .claude; <gate set>; bash scripts/controls-render.sh
bash scripts/controls-golden-baseline.sh check; bash scripts/controls-golden-baseline.sh check
```

- [ ] **Step 7: Commit and push**

```bash
cd ~ && yadm add -A .config/quickshell/bar .config/quickshell/config .config/quickshell/scripts \
  .config/quickshell/tests .config/quickshell/ui .config/quickshell/shell.qml .config/quickshell/README.md \
  .config/quickshell/docs
yadm status --short | grep -E "settings.json|Kvantum|kitty|niri|btop|starship" | grep -v '^ M' || true   # none staged
yadm commit -m "elena-only S1: delete other styles, Material controls and style plumbing" && yadm push origin main
```

---

### Task 10: Live verification (user cold restart)

- [ ] **Step 1:** Ask the user to run `! systemctl --user restart quickshell.service` (their command). Wait for confirmation.
- [ ] **Step 2: Live checks**

```bash
cd ~/.config/quickshell
qs ipc call shell dockState | head -c 300
qs ipc call shell popup sidebar; sleep 1; qs ipc call shell currentPopup; qs ipc call shell popup sidebar
qs ipc call shell popup launcher; sleep 1; qs ipc call shell currentPopup; qs ipc call shell popup launcher
bash scripts/popup-ipc-check.sh
jq -r '.themeStyle // "absent"' settings.json   # stale key: harmless, dropped on the next settings write
```

Expected: dock JSON matches `niri msg -j windows`; popups report `sidebar` / `launcher` and close; `popup-ipc-check.sh` passes. Check `journalctl --user -u quickshell.service -n 80 --no-pager | grep -i -E "error|warn"` for QML errors (new ones only).
- [ ] **Step 3: RSS soak** with the `~/.cache/qs-rss` sampler: two samples 10 min apart with the settings panel opened and closed in between; record the delta in the final report (the unresolved Image leak is a known baseline, the change must not worsen it).
- [ ] **Step 4:** Final whole-branch review (opus) over `10e17d77..HEAD`, fix wave if needed, final report with DONE or DONE_WITH_CONCERNS, restart note, the open follow-ups (bar-widget machinery, outside-tree files, S2 sidebar pager, launcher/power/notification redesign).

---

## Self-review

- **Spec coverage:** boundary and removal (Tasks 4 to 9), controls table (Tasks 2, 3; TextFieldControl and ListItem receive the collapse in Task 6 and the 20/14 px radii follow from `shapeLarge`/`shapeMedium`, no separate implementation file because they have no per-style implementations), tokens (Task 3 and 4), dump gate (Task 1), render check (Task 3), behavior suite (Task 2), golden retake (Task 3), grep gate (Task 9), live check and RSS soak (Task 10), scripts decisions (Task 9). The spec's "shared bases are deleted" is superseded by this plan: they move to `bar/controls/`.
- **Spec correction:** the spec lists a vertical `SliderControl`; the plan realizes that need with `LevelTile` + the `LevelBar` wrapper instead (`SliderControl` stays horizontal).
- **Known soft spots:** Tasks 5 to 8 give a procedure and a truth table rather than per-line diffs; the dump gate cannot see `bar/*` call sites, so those groups rely on the render checks, the behavior suite, the lint gate, the golden image, `style-refs.sh` and the live check.
