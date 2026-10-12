# dwm theme (bar + dmenu)

Date: 2026-10-12

## Outcome
Selecting "dwm" in Settings > Appearance turns the bar into a dwm-style
one-line bar and the launcher into a dmenu-style strip drawn over it.
Measured by: style tile selects, `Settings.themeStyle === "dwm"`, screenshots
of bar and strip match the layout below, key navigation works in the strip.

## Theme id
- `themeStyle = "dwm"`, `Config.dwmTheme` (`config/Config.qml`).
- Excluded from `Config.material3Theme`.
- New tile in `bar/settings/AppearanceTab.qml` `styleChoices`; selector
  column/row math moves from 5 to 6 choices.

## Colors
Wallpaper-driven (Matugen), no fixed palette. `Colors.qml` `style*` roles:
- surface: `surfaceContainerLowest`
- text: `fgSurface`
- selected scheme (dwm SchemeSel): `primary` bg, `fgPrimary` text
- outline: `outline`
Square corners, no shadow, no blur, `monospace` font. Palette source stays
selectable as for Material.

## Bar
Top, full-width, flat one-liner, same path as `ghostHorizontalOneLiner`.
While dwm is active, bar form resolves to full and workspace style to
numbers without writing saved settings. Left to right:
1. tags 1..N (honors workspace-count setting): focused = inverted block,
   occupied = small corner square, empty = dimmed
2. layout symbol (existing `layout` widget, text like `[]=`)
3. focused window title, fills remaining width
4. status text: clock, audio, battery etc. as plain text, no icons or pills

## dmenu
`bar/LauncherPopup.qml` reshapes itself under dwm: anchored top/left/right at
bar height over the bar, overlay layer, exclusive keyboard focus. The vertical
list is replaced by a horizontal row bound to the same `filteredModel` and
`selectedIndex`: prompt block, input, inline items, `<` `>` overflow marks,
selected item in the selected scheme.
Keys: Left/Right and Tab move, Enter launches, Esc dismisses.
Search, launch, clipboard, actions and `@` wallpapers keep current logic.
No new window, no duplicated search code.

## Verification
Scratch-HOME harness plus IPC: switch style, screenshot bar and strip, test
key navigation and overflow with a long result list. Add the style to the
existing gate scripts under `scripts/` and `scripts/tests/`.

## Out of scope
Vertical bars (dwm style forces horizontal top), fixed suckless palette,
dwm keybindings/tiling behavior.
