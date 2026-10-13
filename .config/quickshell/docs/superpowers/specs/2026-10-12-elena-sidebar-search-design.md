# elena sidebar search field (phase 2b)

Date: 2026-10-12

## Outcome
The sidebar ends with a search field. Typing text and pressing Enter closes
the sidebar and opens the existing launcher with that text already in its
search box, so apps, `>` actions, `@` wallpapers and clipboard behave exactly
as when typed in the launcher. Measured by: render check shows the field,
`qs ipc call shell sidebarSearch "<text>"` leaves `openPopup === "launcher"`
and the launcher's search text equal to `<text>`, the sidebar is closed, and
no other style is affected.

Roadmap context: `2026-10-12-elena-sidebar-design.md` (phase 2a, shipped).

## Behavior
- Field at the foot of the sidebar content, below the level bars card, using
  the existing `TextFieldControl` (`bar/primitives`), leading `search` icon,
  placeholder `Search`.
- Opening the sidebar focuses the field; closing it clears the field.
- Enter submits (an empty field still opens the launcher, empty). Esc closes
  the sidebar. No inline results: the launcher owns search.
- Submitting emits `searchSubmitted(string text)` from `Sidebar`; `shell.qml`
  hands the text to the launcher and switches `bar.openPopup` to `"launcher"`
  (single-popup model, so the sidebar closes by itself).

## Launcher hook
`bar/LauncherPopup.qml` gains `property string initialQuery: ""`. In its
`onVisibleChanged` (after the existing reset block that clears `searchText`,
the model and the input), if `initialQuery !== ""` it applies the text the way
the voice-search result path does today (`searchInputControl.text = q`,
`searchText = q`, `selectedIndex = 0`, `filterApps()`), then clears
`initialQuery`. The launcher's existing on-show focus timer focuses the input.
No other launcher behavior changes. Queries starting with `@` skip the launcher
and open the wallpaper filmstrip directly (same result as typing `@` there),
because wallpaper mode dismisses the launcher from inside its show handler.

## Launcher anchoring
Under elena the bar's launcher widget is hidden, so `shell.qml` anchors the
launcher the same way the existing `launcher()` IPC function does
(`bar.popupAnchorX = bar.getLauncherX()` for a horizontal bar,
`bar.popupAnchorY = 0` otherwise). One shared helper, not a copy.

## Testing hooks (IPC, dev/testing like `style` and `launcherMode`)
- `sidebarSearch(text: string): bool`: same path as pressing Enter with
  `text` (returns false unless the style is elena).
- `launcherQuery(): string`: the launcher's current search text.
These let the live check run without keystrokes.

## Files
- Create `bar/sidebar/SearchField.qml`: wraps `TextFieldControl`; signals
  `submitted(string text)` and `escaped()`; functions `focusField()`,
  `clear()`.
- Modify `bar/sidebar/SidebarContent.qml`: field row below the level bars;
  forwards `searchSubmitted` and `escaped`; takes `active` (already added in
  2a) to focus on open and clear on close.
- Modify `bar/Sidebar.qml`: expose `signal searchSubmitted(string text)`,
  route `escaped` to `dismissed()`.
- Modify `bar/LauncherPopup.qml`: `initialQuery` hook above.
- Modify `shell.qml`: handler, shared launcher-open helper, the two IPC
  functions.
- Modify `tests/sidebar/shell.qml`, `scripts/sidebar-render.sh`: the render
  check also asserts the field is drawn (outline-colored border pixels in the
  bottom region of the stage) and that the stage grows by the field height
  without clipping the level bars (`Layout.minimumHeight`).

## Verification
- Render check (above), with the 2a assertions unchanged.
- Gate: the existing node and lint gates; `scripts/controls-behavior.sh`
  unchanged (controls untouched).
- Live (after a cold restart, in-memory style only, restore afterward):
  `popup sidebar` -> `sidebarSearch "term"` -> `currentPopup` is `launcher`,
  `launcherQuery` is `term`; `sidebarSearch ">"` shows actions;
  `popup sidebar` outside elena returns false.

## Out of scope
Inline results, history, Down-arrow into results, voice input from the
sidebar, search in the bar block row, any change to launcher result logic.
