# Elena only: remove the other styles and Material, native controls (S1)

Date: 2026-10-13

## Outcome
Elena is the only UI style. `Settings.themeStyle`, the style picker and every
other style's code, assets and tests are gone; so is the Material 3 control
implementation. The controls (slider, switch, action button, icon button, list
row, text field) are rebuilt in her grammar: level-fill squircle tiles, white
round icon, solid round action buttons, pill chips. Measured by: the controls
behavior suite passes for the single style, the Config/Colors property dump
matches the pre-change dump except the removed properties and the intended
radius change, `grep` finds no reference to a removed flag, the render and node
gates pass, and the live shell (cold restart) shows bar, sidebar, dock,
launcher, lock screen and OSD working.

Repo: `hekatonkheirex/dotfiles` (elena history). `dotfiles-old` stays frozen at
the dwm theme.

## Decisions (user, 2026-10-13)
- Keep palettes, Matugen and the accent picker; remove only the style axis.
- Full removal, not "hide the selector".
- Remove Material 3 too; build new Elena-native controls now (grammar D:
  20 px squircles, from the reference screenshot and the Aphelion showcase).
- Launcher, power menu, notifications, lock screen: layout and keybinds
  unchanged here; they get the new controls and tokens and are redesigned in a
  later change.
- The bottom dock stays as shipped (no taskbar). The 2d dashboard becomes
  sidebar pages (separate spec, S2).

## Boundary
**Removed**
- Flags: `nothingDesign`, `nothingEvolution`, `ghostTheme`, `dwmTheme`,
  `liquidGlassTheme`, `material3Theme`; `Settings.themeStyle`,
  `Settings.nothingVariant`; `materialCompact` and the Material type-scale
  setting.
- Directories: `bar/themes/{material3,styled,ghost,nothing,shared}`.
- Primitives and assets used only by the removed styles (inventory in the plan,
  found by `grep`, deleted only when unreferenced): for example `GlassSheen`,
  `PacmanMarker`, `GroupCapsule`, style-specific fonts and icon sets.
- The style picker tiles and Material-only settings rows; their search entries.
- Tests and harness loops for the removed styles; docs of the removed styles
  keep their text (history) but get a "superseded" note.

**Kept**
- `Config.elenaTheme` stays as a constant `true` so call sites compile while
  they are collapsed; the last stage deletes it.
- Palettes (`PaletteCatalog`), Matugen sync, accent picker, contrast options.
- Bar widgets, forms and position settings (hidden under elena today; cleanup
  is a separate follow-up, 2e may re-home them).
- Material 3 role names in `Colors` (Matugen emits them); only the Material
  control look goes.
- Everything outside `~/.config/quickshell`.

**Scripts** that only serve a removed style are deleted; scripts parameterized
by style collapse to elena; any script whose purpose is unclear is listed in
the plan and decided with the user before deletion (candidates:
`ensure-style-terminal-assets.sh`, `sync-mactahoe-theme.sh`, `sync-niri-shape.sh`,
the SDDM scripts).

## Controls
New `bar/controls/` holds the implementations; the existing facades
(`bar/SliderControl.qml`, `bar/SwitchControl.qml`,
`bar/primitives/{ActionButton,IconButton,ListItem,TextFieldControl,...}.qml`)
keep their properties, signals and accessibility API, so the 41 call sites do
not change. Facades stop loading by style and instantiate the one
implementation.

| Control | Look |
|---|---|
| ActionButton | solid pill or round, accent fill, dark label; tonal and outline variants map to `surfaceContainer`, hairline border |
| IconButton | 20 px squircle tile on `surfaceContainer`, white round icon; round variant for power-style actions |
| SwitchControl | 58x30 pill, white knob; on = accent fill, off = `surfaceContainerHighest` |
| SliderControl | flat tile, fill from the left in the accent, white round icon at the start when `iconLabel` is set; vertical orientation fills from the bottom (sidebar level bars) |
| LevelTile (new) | 58 px squircle, level fill from the bottom, white round icon, striped when off |
| ListItem | 16 px squircle row on `surfaceContainer`, accent bar when selected |
| TextFieldControl | 14 px squircle field on `surfaceContainerLowest`, accent underline on focus |

States: hover and press use opacity steps on the surface (no Material state
layers); focus ring is a 2 px accent outline; disabled is 38 % opacity.
Motion keeps the existing spring tokens.

## Tokens
- Shapes: compact 8, medium 12, large 20, pill full. The sidebar cards and dock
  tiles follow `shapeLarge` (intended visual change).
- Typography: the Material type scale collapses to its current scale-1 values
  (no visible shift). Fonts unchanged.
- `Config` loses every style conditional; each ternary collapses to its elena
  value. Because the elena values are known, collapsing is deterministic and is
  checked by the dump gate below.

## Stages (each a commit, gates after each)
1. **Dump gate.** `tests/elena/config-dump` loads `Config` and `Colors` in a
   scratch HOME and prints every property as sorted JSON. Capture the
   baseline from the pre-change tree. No code change.
2. **Controls.** Add `bar/controls/*`, the LevelTile, a render check
   `scripts/controls-render.sh`; facades load the new implementations;
   behavior suite and golden baseline updated deliberately.
3. **Config/Colors/Settings.** Collapse flags and conditionals; delete removed
   settings; load-time ignore of stale keys (`themeStyle`, `nothingVariant`,
   `materialCompact`, type scale). Dump gate compares.
4. **Call sites.** Collapse conditionals in `bar/*` popups, lock screen, OSD,
   notifications, settings tabs, indicators (about 30 files, grouped by area;
   one commit per group). Delete the style picker and Material-only rows.
5. **Deletion.** Remove the theme directories, unreferenced primitives and
   assets, removed-style scripts and tests; shrink harness loops to the single
   style; delete `Config.elenaTheme`; README and memory notes.
6. **Live check** after a user cold restart; restore nothing (there is no
   style to restore).

## Verification
- Dump gate: no diff other than removed keys and `shape*` values.
- `scripts/controls-behavior.sh`: one style, same checks (adapted where a check
  tested a Material-only behavior, each adaptation justified in the commit).
- `scripts/controls-render.sh`: tile fill, white round icon, pill and switch
  colors, striped off tile, mutation-proven like the existing render checks.
- Existing gates: node tests (`tests/dock`, `tests/elena`, ...), sidebar, dock
  and tag-strip render checks, `m3-qmllint-gate`, `scripts/tests/*`.
- `grep -rIE "nothingDesign|ghostTheme|dwmTheme|liquidGlassTheme|material3Theme|themeStyle|nothingVariant"`
  over the tree (excluding `docs/`) returns nothing.
- Golden baseline retaken once, after stage 2, and checked twice.
- Live: `qs ipc call shell dockState`, `popup sidebar`, `popup launcher`,
  OSD trigger, lock screen render check, settings panel opens; RSS soak with
  `~/.cache/qs-rss` since the Image leak is unresolved.

## Risks
- A mis-collapsed `a && !b ? x : y` (covered by the dump gate and the golden
  image); popups not covered pixel-for-pixel (live check and your eyes).
- Settings.json carries removed keys; the adapter must ignore them without
  crashing (stage 3 gate loads a fixture with every removed key).
- Behavior checks tied to Material details; adaptations are explicit.

## Out of scope
Bar-widget machinery cleanup, files outside the quickshell dir, the bottom
taskbar, dashed card frames and mono-caps status text (they land with the
launcher, power menu and notification redesign), the sidebar pager (S2), the
center music window.

## Usage
No new commands. After this change Settings > Appearance has no style picker;
palette, accent and bar settings are unchanged. Cold restart recommended after
the final stage: `systemctl --user restart quickshell.service`.
