# elena theme (elenapam AwesomeWM rice, phase 1: tag strip)

Date: 2026-10-12

## Outcome
Selecting "elena" in Settings > Appearance applies the elenapam palette and
turns the bar into a thin row of colored workspace blocks along the top
screen edge. Measured by: style tile selects, `Settings.themeStyle === "elena"`, screenshot
shows the strip with focused/occupied/empty blocks matching the layout below,
clicking a block focuses that workspace.

Reference: elenapam's AwesomeWM rice (dark navy cards, pink/mint/cyan/purple
accents, colored tag blocks on the top edge). Phase 1 covers the palette and
the block row only.

## Theme id
- `themeStyle = "elena"`, `Config.elenaTheme` (`config/Config.qml`).
- Stays inside `Config.material3Theme` (the facades in `bar/SliderControl.qml`, `bar/primitives/ActionButton.qml` pick Material controls from it). `Config.elenaTheme` is an extra flag only.
- New tile in `bar/settings/AppearanceTab.qml` `styleChoices`; selector math
  moves from 6 to 7 choices.
- Shape tokens stay Material (rounded). No change to bar, launcher or popups
  layout.

## Palette
- New fixed family `elenapam` in `PaletteCatalog`: navy surface ~#1a1f2b,
  the palette defines purple (primary), pink (secondary) and cyan (tertiary)
  accents plus an error red, sampled from the reference image.
- Under `elena`, `Settings.colorSource` defaults to fixed with that family.
  Setting the existing palette-source toggle to wallpaper gives Matugen.
  `Colors.paletteSourceSelectable` already allows this for styles other than
  Nothing and Ghost.
- Dark only. Light mode reuses the dark palette.

## Tag strip
- Under `elena` the bar itself is the block row: the Bar window is
  `Config.tagStripHeight` (8 px) tall, full width, top edge (position forced to
  top, form forced to full, saved values untouched), exclusive zone 8,
  transparent (no fill, border or shadow). There is no second window: niri
  orders layer surfaces by map order, so a separate strip could not sit above
  the bar. `Config.barWidth` is forced to 8 so zone and popup insets follow.
- Clock, tray, status and the rest of the bar content are hidden (opacity 0,
  disabled; the workspace widget stays `visible` so its refreshers run) until
  the sidebar phase moves them. Mask is the bar body, so clicks reach only the
  blocks.
- N equal blocks. N follows the workspace-count setting (active / 5 / 10); a
  focused workspace outside a fixed range is still shown.
- Each block takes its accent from `primary`, `secondary`, `tertiary` by workspace `idx` modulo 3 (purple, pink, cyan in elenapam).
  States: focused = full accent, occupied = accent at about 35% over the
  surface, empty = faint track.
- Click focuses that workspace. Color changes use the existing motion tokens.
- Reads the model `WorkspaceIndicator` already holds (`workspaces`, focused,
  occupied). No second Niri poll.
- State mapping lives in a pure function in a small `.js` file (same pattern as
  `bar/CalendarLogic.js`) so it can be gated. `tagStates(workspaces)` maps the
  items `WorkspaceIndicator.visibleWorkspaces` already builds, so count rules
  (active/5/10, focused outside range) stay in one place.

## Niri
`scripts/sync-niri-shape.sh` must leave corners rounded for `elena`. dwm
squares them; the script is checked so unknown ids fall through to the
default, and fixed if they do not.

## Verification
- Gate test `tests/elena/test.mjs`: `tagStates` states, accent by idx, junk input; elenapam palette roles and catalog wiring.
- Style added to `scripts/controls-golden*.sh` so the pixel baseline covers it.
- Scratch-HOME harness plus IPC style switch, screenshot of the strip in each
  state, then restore `style material3 ""` and `dismissPopups`. See memory
  notes on testing hazards (in-memory style can be persisted by `Settings.save()`).
- No LLM calls in this feature, so no LLM eval. The golden pixel compare is
  the periodic check.

## Out of scope
Left sidebar, bottom dock, center music window, dashboard grid, notification
restyle, window gaps, light variant, fixed strip height setting, relocating
the hidden bar widgets (sidebar phase).
