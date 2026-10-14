# Elena workspace row parity (R7 of the SwayFX + eww replication)

Date: 2026-10-14. Status: implemented. Revised after the user's correction: niri does not behave well with many workspaces, so decisions 1, 3 and 4 below were dropped. The row keeps one block per existing workspace, the background was already transparent, and the row never pads to ten slots. Everything else (colors, opacities, hover, rounding, right click, wheel) is as specified; wheel up is previous.

## Outcome
The top workspace strip behaves and looks like her `workspaces` window:
ten fixed slots in her color order, invisible when empty, dim when occupied,
full when focused, hover reveals, rounded ends on each run of workspaces,
right click moves the focused window, wheel changes workspace. Measured by:
pure-model gate (slot states, accent order, rounding, move/scroll targets), a
render check of every state with pixel checks, existing bar gates, and live
checks on the hot-reloaded shell (click, right click on a throwaway window,
wheel).

## Reference
`config/eww/windows/workspaces.{yuck,scss}`, `scripts/daemons/sway-workspaces.py`
(github.com/elenapan/dotfiles, master). Our adaptation stays: 8 px strip on the
top layer (`Config.tagStripHeight`), niri instead of sway.

## Her behavior
- Always 10 slots across the full width, each `width / 10`. States: `focused`
  opacity 1, occupied 0.3, `empty` opacity 0. Hover: a non-focused slot 0.6, an
  empty one 0.2. Transition 0.2 s.
- Slot colors in order: x1, x3, x2, x6, x4, x5, x1, x3, x2, x6.
- Bottom corners round (`dpi(10)`) on the left of a slot whose left neighbor is
  empty (slots 2 to 10) and on the right of one whose right neighbor is empty
  (slots 1 to 9); slot 1 never rounds left and slot 10 never rounds right.
- Click focuses the workspace, right click moves the focused container there
  without following it, wheel up goes to the previous workspace and down to
  the next.
- Window height `dpi(3px)`; background transparent.

## Decisions I am making (change any)
1. **Slots instead of one equal block per existing workspace.** Today the strip
   shows only existing workspaces, each `width / count`. Hers shows fixed
   numbered positions, so workspace 3 sits at 30 to 40 percent of the width
   even when 2 is empty. This is the parity point and the visible change.
2. **Height stays 8 px**, not her 4.5 px: it is the approved strip height and
   its exclusive zone. Corner radius clamps to the strip height.
3. **Strip background becomes transparent**, as hers is; empty slots are
   invisible and the wallpaper or window shows through the strip. (Input mask
   stays the full strip so every slot is clickable, empty ones too.)
4. **More than 10 workspaces:** the row grows to the focused index so the
   location is never ambiguous (same rule as the current "keep focused
   visible"), slots narrow accordingly. Colors continue the cycle.
5. **Right click** runs `niri msg action move-window-to-workspace --focus false
   <idx>` for the focused window (niri has no sway `container` distinction);
   **wheel** runs `focus-workspace-up` or `focus-workspace-down`. Wheel up is
   previous, as hers.
6. `Settings.workspaceCount` and the legacy hidden widget keep their meaning for
   the hidden machinery; the strip ignores them.

## Files
| File | Role |
|---|---|
| `config/TagStrip.js` | `slots(workspaces, minSlots)` returns `{idx, state, slot, roundLeft, roundRight}`; `accentSlot(idx)`; `hoverOpacity(state)`; `scrollTarget(focusedIdx, direction, count)` |
| `bar/TagStripBlocks.qml` | slots, hover, click, right click, wheel; signals `activated`, `moveRequested`, `stepRequested` |
| `bar/Bar.qml` | passes the raw workspace list, handles the two new signals, strip background transparent |
| `bar/WorkspaceIndicator.qml` | `moveFocusedWindowTo(idx)` helper next to `focusWorkspace` |
| `scripts/tag-strip-render.sh`, `tests/tag-strip/shell.qml` | updated for slots and states |
| `tests/tag-strip/model.test.mjs` | pure gate |

## Verification
- Node: slots for [] (10 empty), [focused 1], gaps, focused 12 (row grows),
  rounding edges (slot 1 left square, slot 10 right square, isolated slot both
  round, run of three round only at ends), accent order for 1 to 12, hover
  opacities, scroll targets at the ends (no wrap).
- Render (extends the existing script): each state's opacity and color, rounded
  bottom corners at run ends, empty invisible, hover state via forced hover.
- Existing gates: bottom-bar and sidebar renders, config-dump, style-refs,
  QML lint, all Node suites; live: click, wheel, right click with a test window.

## Risks
- A transparent strip changes how the top 8 px looks on bright wallpapers.
- Right click moving a window is easy to hit by accident; it is her behavior.

## Out of scope
Per-monitor strips, workspace names or numbers on the strip, dragging windows
onto slots, changing the strip height, the hidden legacy workspace widget.
