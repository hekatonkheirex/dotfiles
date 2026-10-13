# elena sidebar (phase 2a: core status column)

Date: 2026-10-12

## Outcome
Under the elena style, `qs ipc call shell popup sidebar` opens a left-edge
panel with clock, weekday row, battery pill, weather, media controls and
three level bars. Esc or a click outside closes it. Measured by: render check
passes with no QML errors, `weekRow` gate test passes, live screenshot shows
the five cards, Esc closes, and the previous style restores cleanly.

Gives the widgets elena hides (clock, battery, weather, media, volume,
brightness) a home. Phase 1 spec: `2026-10-12-elena-theme-design.md`.

## Roadmap (separate specs and plans, in this order)
| Phase | Sub-project | Notes |
|---|---|---|
| 2a | Sidebar core (this spec) | clock, weekday row, battery, weather, media, level bars |
| 2b | Sidebar search field | field at the foot of the sidebar, wired to the existing launcher search |
| 2c | Bottom app dock | icon row with running-app dots, per the reference |
| 2d | Dashboard grid | profile, quick links, calendar, uptime/stats cards |
| 2e | Tray and notification homes | indicators hidden by elena get a place (sidebar footer or dock) |
| 2f | Hover gesture | hovering the left end of the block row opens the sidebar |

Out of scope for every phase: the center music window.

## Surface
- `bar/Sidebar.qml`: `PopupBase`-style layer-shell window. Anchors left, top
  and bottom; width 320 px; top margin = block-row height + `Config.spacingMedium`;
  bottom and left margins `Config.spacingMedium`; `ExclusionMode.Ignore`
  (overlay, windows do not move).
- Single-open-popup model: visible when `bar.openPopup === "sidebar"`, so Esc,
  click-away and the popup shield behave like the other popups.
- `Bar.togglePopupByName("sidebar")` is a special case (no anchor widget) and
  returns false unless `Config.elenaTheme`. No effect in any other style.
- Cards use `Colors.surfaceContainer`, radius `Config.shapeLarge`, text
  `Colors.fgSurface`, accents `primary`, `secondary`, `tertiary`.

## Cards
All data comes from existing services; no new polling. While the sidebar is
open it sets each service's own `sidebarActive` flag (added to Media, Weather,
Audio and Brightness services and OR'd into their `active` gates). It does not
reuse `popupActive`: the existing popups bind that property to their own
visibility, and two writers on one property would race when switching popups.

| Card | File | Source |
|---|---|---|
| Clock + weekday row | `bar/sidebar/ClockCard.qml` | minute-aligned `Timer` (`config/ClockTiming.js`), `Weekdays.weekRow` |
| Battery pill | `bar/sidebar/BatteryPill.qml` | `BatteryService.pct`, charging state |
| Weather | `bar/sidebar/WeatherCard.qml` | `WeatherService.desc`, `.temp` |
| Media | `bar/sidebar/MediaCard.qml` | `MediaService.title/artist/status`; prev/play/next through the same control `MediaPopup` uses |
| Level bars | `bar/sidebar/LevelBars.qml` | volume, mic, brightness via `AudioService.setVolume/setMicVolume`, `BrightnessService` |

- Clock: large `HH : MM`, stacked-dot separator; honors `Settings.clock24h`
  only (no seconds); the 12h format shows the hour without AM/PM.
- Weekday row: `M T W T F S S`, Monday first, today circled in `secondary`.
- Level bars: vertical bars, drag or click to set, mute toggle on the icon.

## Logic
`config/Weekdays.js` (`.pragma library`): `weekRow(date) -> [{letter, isToday}]`,
7 entries, Monday first, letters `M T W T F S S`. Pure, so it is gate-tested.

## Verification
- Gate test `tests/sidebar/test.mjs`: `weekRow` for each weekday as today,
  a Sunday (last entry), a month boundary, a year boundary, a DST change day.
- Render check `scripts/sidebar-render.sh`: scratch HOME, loads the sidebar
  content, fails on any QML error in the log, pixel-checks the card surface
  color and today's circle.
- Live: cold restart, switch to elena in memory, `popup sidebar`, screenshot,
  Esc closes, restore `material3`. Do not use keystrokes beyond what the
  compositor needs; follow the testing-gotchas notes.

## Out of scope (this phase)
Search field, dock, dashboard, tray and notification homes, hover gesture,
center music window, a niri keybinding (the bind line is given in the final
report; the niri config is not edited).

## Usage
- Toggle: `qs ipc call shell popup sidebar` (returns `false` and does nothing
  outside the elena style). Esc or a click outside closes it.
- Niri bind, to add to `~/.config/niri/keybinds.kdl` (not edited by this
  work; `Mod+Shift+S` is unused in the current config):
  `Mod+Shift+S hotkey-overlay-title="Open Sidebar" { spawn "qs" "ipc" "call" "shell" "popup" "sidebar"; }`
- Services poll for the sidebar through their own `sidebarActive` flag, so
  they stop polling when it closes.
