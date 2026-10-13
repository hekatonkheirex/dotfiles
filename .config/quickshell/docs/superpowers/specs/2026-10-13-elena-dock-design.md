# elena dock (phase 2c)

Date: 2026-10-13

## Outcome
Under the elena style a floating dock of app icons sits at the bottom of the
screen. It is visible when the current workspace has no windows, hides while a
window is open, and slides in when the pointer reaches the bottom edge. Pinned
apps are always present; running apps appear while they have windows. Clicking
focuses (or launches) the app. Measured by: gate tests for the window-state
reducer and the dock model pass, render check shows the item tiles and the
focused indicator, live `qs ipc call shell dockState` reports the expected
items, and the dock does nothing in any other style.

Reference: `config/awesome/noodle/dock.lua` in github.com/elenapan/dotfiles
(squircle 50 px items, 8 px spacing, a dot under running apps, a wide bar under
the focused app, pinned apps always shown, grouped by window class).

## Behavior
- **Visibility.** `shown = elena && !locked && (workspaceEmpty || pointerInZone
  || pointerOnDock)`. `workspaceEmpty` is true when the focused workspace has
  no windows. Showing is immediate; hiding waits 400 ms after the pointer
  leaves. Slide + fade with the existing motion tokens (instant under reduced
  motion).
- **Hot zone.** One window only. The dock window is anchored to the bottom edge
  and always mapped; its input mask is the union of a permanent 2 px full-width
  strip at the very bottom edge (the pointer reaching the edge anywhere reveals
  the dock) and, while shown, a body-sized hit area, so the dock never steals
  clicks from windows outside its body. The window reserves no space (`ExclusionMode.Ignore`)
  and takes no keyboard focus.
- **Items.** Pinned apps first, in the settings order, then running apps that
  are not pinned, in the order their first window opened. Items are keyed by
  niri `app_id`, matched case-insensitively (pinned spelling wins for display);
  windows of one app share one item.
- **Indicators.** No window: none. Running and not focused: a dot. Focused: a
  wide bar. Urgent: the indicator pulses in the error accent. Indicator color
  cycles `primary`, `secondary`, `tertiary` by item position (same as the
  workspace blocks).
- **Left click.** App has no window and is pinned: launch it. Otherwise focus
  the most relevant window of the app (urgent, else most recently focused,
  else first). Clicking the already-focused app cycles to its next window if it
  has more than one.
- **Middle click.** Close the most relevant window of the app.
- **Scroll.** Cycle focus through the app's windows.
- **Icons.** `DesktopEntries.heuristicLookup(app_id)` then
  `Quickshell.iconPath(entry.icon, true)`; if either is missing, a tile with the
  app's first letter. Tile color `Colors.surfaceContainer`, radius
  `Config.shapeLarge`.

## Data
- `config/WindowState.js` (`.pragma library`, pure): `applyEvent(state, event)`
  folds niri event-stream events (`WindowsChanged`, `WindowOpenedOrChanged`,
  `WindowClosed`, `WindowFocusChanged`, `WindowUrgencyChanged`,
  `WorkspaceActivated`, `WorkspacesChanged`) into
  `{windows: [...], focusedWindowId, focusedWorkspaceId, clock}` and never mutates its
  input. `workspaceEmpty(state)` derives the visibility input.
- `config/WindowService.qml` (singleton): runs `niri msg -j event-stream` only
  while `Config.elenaTheme`, feeds `WindowState.applyEvent`, exposes `windows`,
  `workspaceEmpty`. Seeds from the event stream's initial snapshot (no separate
  `niri msg -j windows`/`workspaces` call). Retries on a fixed 1 s while elena
  (no escalation); no second poll while not elena.
- `config/DockModel.js` (`.pragma library`, pure): `normalizePinned(csv)`,
  `dockItems(pinned, windows)` -> `[{appId, pinned, count, windowIds, focused,
  urgent}]`, `relevantWindow(windows, appId)`, `nextWindow(windows, appId,
  focusedId, direction)`.
- Settings: `Settings.dockPinned` (CSV of `app_id`s, same storage style as
  `barWidgetOrder`), default `brave-origin,kitty` (the apps your niri binds
  launch). Normalized on load: trims, drops empties and duplicates.

## Settings UI
New section "Dock", the last section of the Appearance tab (`bar/settings/DockSection.qml`):
- The pinned list with remove and move-up/down buttons (the `BarOrderRow`
  pattern).
- An "Add app" field that filters `DesktopEntries.applications` by name and
  appends the chosen entry's `app_id` guess (the entry id when it is reverse-DNS,
  else StartupWMClass, else the id); the row
  shows the entry's icon and name.
- A note that the dock only runs under the Elena style.
- A search entry in `SettingsPanel.searchEntries` ("Dock pinned apps").
No new top-level tab, so the settings-tabs gate keeps its tab list.

## Files
| File | Role |
|---|---|
| `config/WindowState.js`, `config/DockModel.js` | pure logic, gate-tested |
| `config/WindowService.qml` (+ `config/qmldir`) | event-stream singleton |
| `bar/Dock.qml` | the layer-shell window, mask, auto-hide |
| `bar/dock/DockItem.qml`, `bar/dock/DockContent.qml` | item tile + indicator; content row (no window, render-checkable) |
| `bar/settings/DockSection.qml` | pinned-apps editor |
| `config/Settings.qml`, `bar/settings/AppearanceTab.qml`, `bar/SettingsPanel.qml` | setting + wiring + search entry |
| `shell.qml` | instance, IPC `dockState()`, `dockReveal(bool)` |
| `tests/dock/*`, `scripts/dock-render.sh` | gates and render check |

## Verification
- Gate tests (node): `WindowState.applyEvent` for each event type, unknown
  events, immutability, duplicate open, close of unknown id; `DockModel`
  ordering, grouping, pinned-with-no-window, relevance (urgent > recent >
  first), cycling wrap-around, `normalizePinned` edge cases.
- Render check `scripts/dock-render.sh` (scratch HOME): `DockContent` with a
  fixed model; asserts no QML errors, tile surface pixels, a focused wide bar
  and a running dot in the accent colors, and that the pinned-but-closed item
  has no indicator.
- Live (after a cold restart, in-memory style, restore `elena`): `dockState`
  JSON matches `niri msg -j windows`; with windows open `dockReveal true`
  shows it and the mask covers the body, `dockReveal false` hides it; empty
  workspace shows it by itself.

## Out of scope
Right-click window picker, drag-to-reorder on the dock, move-window-to-
workspace, notification badges, per-output docks, tooltips, minimize (niri has
none; click-on-focused cycles instead), the 2d dashboard, 2e, 2f.

## Usage
- Automatic: visible on an empty workspace, hidden while windows are open,
  revealed by moving the pointer to the bottom edge. Left click launches or
  focuses (clicking the focused app cycles its windows), middle click closes,
  wheel cycles.
- Pinned apps: Settings > Appearance > Dock pinned apps, or `dockPinned` (CSV of
  niri `app_id`s) in settings.json. Default `brave-origin,kitty`.
- Dev IPC: `qs ipc call shell dockState` (JSON: revealed, workspaceEmpty,
  windows, items) and `qs ipc call shell dockReveal true|false`.
- Inert outside the Elena style: no event stream, no window input.
