# Niri config editor (Display & Input + Decorations) — design

Date: 2026-08-25
Status: approved pending user sign-off on this document

## Motivation

Prompted by a request to build a settings page inspired by ryoku.dev. Ryoku's
"Hub" exposes far more configuration than this shell's Settings panel does,
largely because it surfaces niri (their Hub targets Hyprland, but the
philosophy transfers) window-manager config through its UI. This shell
currently only *displays* niri config (`ShortcutsTab.qml` shows
`keybinds.kdl` read-only) and never writes it.

This spec covers a real read/write editor for three of niri's four
config domains: **Outputs** (monitors), **Input** (mouse/touchpad/keyboard/
gestures), and **Decorations** (gaps, focus-ring, border, shadow,
animations, blur, cursor). **Window rules** (`windowrules.kdl`) is
explicitly out of scope — it's a variable-length, order-sensitive list of
match/action blocks rather than a fixed set of fields, and needs its own
design.

## Non-goals

- Window rules editing (separate future spec).
- A generic KDL parser/serializer. Rejected: `python-kdl-py` (AUR) exists,
  but generic parse→reserialize reformats the whole file and risks
  dropping the hand-written comments already in these files (e.g.
  `// Active and inactive colors are dynamically managed in colors.kdl`
  in `decorations.kdl`). Confirmed via Ryoku's own `ryoku-shell-installer/
  niri.go`, which uses the same targeted-regex approach for its (read-only,
  one-way) config importer — so this isn't a novel or unusual technique for
  this exact file format.
- Multi-monitor topology editing (adding/removing outputs, arranging via
  drag). Only editing fields on outputs that already exist in
  `outputs.kdl`.

## Architecture

### `scripts/niri_config/` (new Python package)

One function pair per exposed field: `read_<field>(text) -> value` and
`write_<field>(text, value) -> text`, each backed by a targeted regex or
line-scan anchored to that field's exact KDL shape (matching the patterns
in `inputs.kdl`, `outputs.kdl`, `decorations.kdl` today). No general
parse tree — each function only knows about its own field, so a bug in one
cannot corrupt another.

A `NiriConfigFile` wrapper per file (`outputs.kdl`, `inputs.kdl`,
`decorations.kdl`) provides:

```
read(field) -> str|bool|float
write(field, value) -> WriteResult(ok, error, backup_path)
```

`write()`:
1. Read the current file.
2. Apply the in-memory text replacement for that field only.
3. Write the result to a temp file next to the real one.
4. Run `niri validate -c <temp>`.
5. On success: copy the *original* file to
   `~/.config/niri/.backups/<file>.<unix-timestamp>.kdl` (prune to the
   last 10 backups per file), then atomically `rename()` the temp file
   over the real one.
6. On failure: delete the temp file, leave the real file untouched, return
   the validator's stderr as `error`.

A thin CLI entry point (`python -m scripts.niri_config <file> read <field>`
/ `... write <field> <value>`) is what QML's `Process` shells out to,
matching the existing `statsProc`/`uptimeProc` pattern in
`SettingsPanel.qml` — stdout carries the value (read) or `OK`/`ERROR:
<message>` (write).

### Live reload

niri watches `config.kdl` and reloads on change. Whether it also watches
files pulled in via `include` (i.e. whether writing `outputs.kdl` alone
triggers a reload, or whether `config.kdl` itself needs a touch) is
unconfirmed — first implementation task is to verify this empirically
(edit a `.kdl` include directly, watch `niri validate`'s cousin, the
running compositor's log/behavior, for a reload) and if includes aren't
watched, touch `config.kdl`'s mtime after a successful write.

## Field inventory (phase 1)

Extracted from the actual files on this machine (`~/.config/niri/`).

**Outputs** (`outputs.kdl`), per output block keyed by name (`eDP-1`,
`HDMI-A-2`, ...):
- `mode` (string, e.g. `"1920x1080@60.020"`) — expose as a dropdown of
  available modes (read via `niri msg outputs` at UI-open time, not stored
  in the kdl file).
- `scale` (number)
- `transform` (string enum: normal/90/180/270/flipped/flipped-90/
  flipped-180/flipped-270)
- `position` (`x=`, `y=` integers)

**Input** (`inputs.kdl`):
- `touchpad`: `tap` (flag/bool), `natural-scroll` (flag/bool),
  `scroll-method` (string enum)
- `mouse`: `natural-scroll` (flag/bool), `accel-speed` (float),
  `accel-profile` (string enum, currently unset/commented)
- `trackpoint`: `natural-scroll` (flag/bool), `accel-speed` (float)
- `gestures.dnd-edge-view-scroll`: `trigger-width`, `delay-ms`, `max-speed`
  (numbers)
- `gestures.dnd-edge-workspace-switch`: `trigger-height`, `delay-ms`,
  `max-speed` (numbers)
- `gestures.hot-corners`: on/off (block presence) + which corners enabled

**Decorations** (`decorations.kdl`) — surfaces as a new section in
`AppearanceTab.qml`:
- `layout.gaps` (number)
- `layout.always-center-single-column` (bool)
- `layout.center-focused-column` (string enum: never/always/on-overflow)
- `layout.focus-ring`: on/off, `width` (number)
- `layout.border`: on/off
- `layout.shadow`: on/off, `softness`, `spread` (numbers), `offset x/y`,
  `color` (hex string)
- `animations`: on/off (global), plus per-animation `duration-ms` for the
  duration-based ones (`workspace-switch`, `window-open`, `window-close`,
  `screenshot-ui-open`) — the spring-based ones
  (`horizontal-view-movement`, `window-movement`, `window-resize`,
  `config-notification-open-close`, `overview-open-close`) are read-only
  in phase 1 (editing spring physics via three coupled numbers is a UI
  problem worth its own pass, not a blocker for the rest)
- `blur`: on/off, `passes`, `offset`, `noise`, `saturation` (numbers)
- `cursor`: `xcursor-theme` (string — dropdown from installed cursor
  themes on disk), `xcursor-size` (number)

Colors (`focus-ring`/`border` active/inactive colors) stay out of this
editor — the file's own comment says they're "dynamically managed in
colors.kdl" by the existing Matugen pipeline, and touching that would
cross into the theming system this spec doesn't touch.

## UI

- New sidebar tab **"Display & Input"** (icon: `monitor`), positioned
  after Wallpaper, before Network. Two sections: Outputs (one card per
  detected output) and Input (touchpad/mouse/trackpoint/gestures).
- Decorations become a new **"Window Manager"** section at the bottom of
  `AppearanceTab.qml`, below the existing Sizing section, using the same
  `SliderControl`/`SwitchControl`/segmented-picker primitives already used
  there.
- Every control follows this shell's existing optimistic-update pattern:
  the toggle/slider updates immediately in the UI; the write happens
  async via `Process`; on `ERROR:` from the CLI, revert the control to its
  last-known-good value and show an inline status message (same pattern
  as `ShortcutsTab.qml`'s `actionStatus`).

## Testing

Gate tests (deterministic, no LLM, run in `<2s`) under
`scripts/niri_config/tests/`, using **copies** of this machine's real
`outputs.kdl`/`inputs.kdl`/`decorations.kdl` as fixtures (checked into the
repo as `tests/fixtures/*.kdl`, since the real files under `~/.config/niri/`
are outside this repo and not something tests should touch):

- Round-trip: read a field, write the same value back, assert the file is
  byte-identical (proves the surgical edit doesn't drift formatting).
- Write-then-read: write a new value, read it back, assert it matches.
- Every field's write leaves all *other* lines in the file byte-identical
  (proves isolation between fields).
- Validation-failure path: monkeypatch `niri validate` to fail, assert the
  real file is untouched and no backup was created.
- Backup pruning: write the same field 12 times, assert exactly 10
  backups remain (oldest 2 pruned).
- Comment preservation: assert files with comments (`decorations.kdl`'s
  focus-ring/border comments) keep those comments verbatim after a write
  to an unrelated field.

No eval suite — this is deterministic text transformation, not
LLM-judged output.

## Risks / open questions

1. **Live reload confirmation** (noted above) — first implementation
   task, blocks everything else in practice since an editor that doesn't
   take effect until a manual `niri` restart is a broken feature, not a
   finished one.
2. Cursor theme dropdown needs a way to enumerate installed themes
   (likely scanning `/usr/share/icons/*/cursor.theme` or similar) — small
   sub-task, not yet scoped in detail.

### Resolved during design

- **`niri validate` scope**: confirmed empirically — it validates a
  standalone include fragment on its own, no `config.kdl` tree needed.
  `niri validate -c outputs.kdl` (copied verbatim from this machine)
  exits 0; a deliberately broken fragment exits 1 with a clear parse
  error pointing at the exact line. The temp-file-then-validate step in
  `write()` works exactly as designed with no extra tree-assembly step.
