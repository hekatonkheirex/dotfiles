# elena theme (elenapam AwesomeWM rice, phase 1: tag strip)

Date: 2026-10-12

## Outcome
Selecting "elena" in Settings > Appearance applies the elenapam palette and
adds a thin row of colored workspace blocks along the top screen edge.
Measured by: style tile selects, `Settings.themeStyle === "elena"`, screenshot
shows the strip with focused/occupied/empty blocks matching the layout below,
clicking a block focuses that workspace.

Reference: elenapam's AwesomeWM rice (dark navy cards, pink/mint/cyan/purple
accents, colored tag blocks on the top edge). Phase 1 covers the palette and
the strip only.

## Theme id
- `themeStyle = "elena"`, `Config.elenaTheme` (`config/Config.qml`).
- Excluded from `Config.material3Theme`.
- New tile in `bar/settings/AppearanceTab.qml` `styleChoices`; selector math
  moves from 6 to 7 choices.
- Shape tokens stay Material (rounded). No change to bar, launcher or popups
  layout.

## Palette
- New fixed family `elenapam` in `PaletteCatalog`: navy surface ~#1a1f2b,
  accents pink, mint, cyan, purple, green sampled from the reference image.
- Under `elena`, `Settings.colorSource` defaults to fixed with that family.
  Setting the existing palette-source toggle to wallpaper gives Matugen.
  `Colors.paletteSourceSelectable` already allows this for styles other than
  Nothing and Ghost.
- Dark only. Light mode reuses the dark palette.

## Tag strip
- `bar/TagStrip.qml`, one per screen, layer-shell top edge, 8px tall, full
  width, reserves its own exclusive zone. The existing bar sits below it.
- N equal blocks. N follows the workspace-count setting (active / 5 / 10); a
  focused workspace outside a fixed range is still shown.
- Each block has a fixed accent, cycling purple, pink, cyan, mint, green.
  States: focused = full accent, occupied = accent at about 35% over the
  surface, empty = faint track.
- Click focuses that workspace. Color changes use the existing motion tokens.
- Reads the model `WorkspaceIndicator` already holds (`workspaces`, focused,
  occupied). No second Niri poll.
- Under `elena` the in-bar workspace widget is hidden; the strip replaces it.
- State mapping lives in a pure function `tagStates(workspaces, count)` in a
  small `.js` file (same pattern as `bar/CalendarLogic.js`) so it can be gated.

## Niri
`scripts/sync-niri-shape.sh` must leave corners rounded for `elena`. dwm
squares them; the script is checked so unknown ids fall through to the
default, and fixed if they do not.

## Verification
- Gate test under `scripts/tests/`: `tagStates` for focused/occupied/empty,
  count active/5/10, focused workspace outside the fixed range, empty input.
- Style added to `scripts/controls-golden*.sh` so the pixel baseline covers it.
- Scratch-HOME harness plus IPC style switch, screenshot of the strip in each
  state, then restore `style material3 ""` and `dismissPopups`. See memory
  notes on testing hazards (in-memory style can be persisted by `Settings.save()`).
- No LLM calls in this feature, so no LLM eval. The golden pixel compare is
  the periodic check.

## Out of scope
Left sidebar, bottom dock, center music window, dashboard grid, notification
restyle, window gaps, light variant, fixed strip height setting.
