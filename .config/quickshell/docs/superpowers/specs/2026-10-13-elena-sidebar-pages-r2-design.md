# Elena sidebar, her three pages (R2 of the SwayFX + eww replication)

Date: 2026-10-13

Supersedes `2026-10-13-elena-sidebar-pages-design.md` (the Status and Dashboard
pages) and the search field of `2026-10-12-elena-sidebar-search-design.md`.

## Outcome
The sidebar is her sidebar: Home, Agenda and Media pages with the page
indicators, a left-edge hover activator, the 3x3 slider tiles and the media
controls. Measured by: node gates for the metric parsers, the page/indicator
logic and the media seek math pass; render checks for each page show the
expected tile fills, indicators, calendar highlight and ring; live
`openSidebarPage 0|1|2` toggles through all three pages; `popup-ipc-check.sh`
passes; no search field, profile, quick links or stats card remain.

## Reference
`config/eww/windows/sidebar.yuck`, `sidebar.scss`, `widgets/circular-symbol-*`,
`scripts/daemons/{media,volume,gpu,uptime,days-of-the-week}.sh` in
github.com/elenapan/dotfiles (master, 2025-09-07) and the Aphelion video. Scale
S = `Config.elenaScale` (1.5), sizes through `Config.dp()`.

## Decisions (user, 2026-10-13)
- Replicate her pages exactly; keep our palette (accent ramp `Colors.elenaAccent`).
- Slider grid: swap kdeconnect and gpu for swap use and network speed so every
  tile has real data.
- Add the left-edge hover activator.
- Remove the old Status/Dashboard pages, search field, battery pill, profile,
  quick links and stats card.
- Agenda tasks are not fed (no org files): the page shows her empty state.
- Weekday strip stays Sunday-first (earlier user request); the month grid
  follows `Settings.calendarWeekStartsMonday`.

## Surface
- Window: anchors left and bottom (not top), width `dp(300)`, height
  `min(dp(554) + dp(106), screen free height)` (pages `dp(554)`, indicator
  section `dp(106)`), `margins.bottom = Config.bottomBarHeight + dp(7)`, right
  corners radius `dp(20)`, color `Colors.surface`, layer Top, exclusion Ignore.
- Reveal: slides in from the left over `Config.motionLong`; reduced motion makes
  it instant.
- Dismiss: existing click-outside shield, middle click on the sidebar, Esc, the
  bar button for the open page.
- Page indicators: three pills 14 S high, 14 S wide, the selected one 27 S wide,
  colors x1, x2, x5 for pages 0, 1, 2 (unselected opacity 0.3); a separator
  (8 S high, 34 S side margins, `surfaceContainerHighest`) above them; click
  selects a page, scrolling over the area steps pages (clamped, no wrap); Esc
  and Ctrl+PageUp/PageDown also step.
- Pages are 0 Home, 1 Agenda, 2 Media (`Sidebar.pageCount` = 3; the bottom bar's
  page 2 clamp no longer applies).

## Page 0, Home
Top to bottom, centered, 40 S top padding:
1. **Time:** `HH` in `BottomBarFonts.clockFamily` ("Baro Plain" when installed,
   else the body font) and `mm` in `BottomBarFonts.clockMinutesFamily`
   ("Baro LineThree", same fallback) colored x1, both at 44pt scaled by S. Minute precision clock.
2. **Weekday strip:** seven items: letter (S M T W T F S) over the date number;
   today selected (accent highlight and filled round); dates are the current
   week, Sunday-first.
3. **Weather pill:** round icon, temperature, description from
   `WeatherService` (empty state "Loading weather" while `status` is loading).
4. **Tiles (3 rows of 3):** 64 S squares, radius 23 S, trough
   `surfaceContainerHighest`; fill color per tile, rises from the bottom, fill
   radius 3 S; value >= 70 rounds the fill corners as hers (`no-round` under
   70); a 26 S round label glyph at the bottom-right corner shows the value on
   hover.

   | Tile | Value | Fill | Interactive |
   |---|---|---|---|
   | volume | `AudioService.volume * 100` | x5 (muted: x8) | drag sets volume |
   | battery | `BatteryService.pct` | x6 (charging glyph while charging) | no |
   | cpu | busy % (1 s delta) | x2 | no |
   | brightness | `BrightnessService.pct` | x1 | drag sets brightness |
   | temperature | hottest `/sys/class/thermal` zone, deg C scaled 0..100 | x1 | no |
   | ram | used % | x3 | no |
   | swap | used % | x4 | no |
   | disk | `/` used % | x5 | no |
   | network | max(down, up) as % of the 100 MB/s ceiling, label shows MB/s | x4 | no |
5. **Hostname chip:** computer glyph, hostname, separator dot, uptime (`1w 1d
   30m` style: weeks, days, hours, minutes, two largest non-zero units).

## Page 1, Agenda
- **Header:** her task-count ring shows `0` with the caption "tasks" (no task
  source). Beside it month name and year with up/down arrows for
  month and for year (selected month resets to the current month when the
  sidebar closes).
- **Weekday header:** `m t w t f s s` or `s m t w t f s` per
  `calendarWeekStartsMonday`, today's column letter in accent.
- **Month grid:** six rows of seven numbers, other-month days dimmed, today in
  a filled round (inverse colors), weekend numbers in the secondary color.
- **Task list:** empty state: "You have no tasks" with her symbol, in the same
  scroll container she uses (ready for a future source).

## Page 2, Media
- **Art and ring:** 160 S round cover (`MediaService.artUrl`; neutral disc and
  note glyph when empty); a half-circle progress along the bottom (start at 50
  %, counter-clockwise, 8 S thick, backdrop `surfaceContainerHighest`, fill x5)
  showing `position / length`; position text at the left end and length at the
  right end of the arc. Hovering the art hides the ring and dims the cover with
  a play or pause glyph; click toggles play/pause.
- **Text:** title pill (note glyph) and artist pill (person glyph) in scroll
  containers (horizontal scroll when too long).
- **Seek line:** 20 vertical lines; lines left of the progress fraction are
  colored, others muted; click a line to seek to that fraction; scrolled
  hover highlights.
- **Buttons:** previous, next (right click: seek -10 s, +10 s); play/pause
  (right click: not used; scroll: player volume +/- 0.02); volume up and down
  (right click: player volume +/- 0.1; left click: system volume +/- 5 %); stop;
  favorite (appends `artist - title` to `~/Music/playlists/songs`, creating the
  directory; the button flashes its accent for 600 ms; a missing title is a
  no-op).

## Edge activator
`bar/SidebarActivator.qml`: a layer-shell window, 1 px wide, anchored left, top
and bottom, layer Top, exclusion Ignore, transparent, with a `HoverHandler`;
hovering for 120 ms opens the sidebar at the page last shown (page 0 when never
opened). It is disabled while the lock screen is active and when
`Settings.sidebarEdgeHover` is
false (new setting, default true, in Settings > Appearance next to the dock
pins).

## Data and files
| File | Role |
|---|---|
| `config/SystemMetrics.js` (pure) | `cpuPercent(prev, cur)`, `tempC(text)`, `diskPercent(text)`, `swapPercent(text)`, `netRate(prev, cur, dtSec)`, `uptimeParts(seconds)`, `memoryPercent(text)` (own meminfo parser; `SidebarStats.js` is deleted) |
| `config/BottomBarFonts.qml` | adds `clockFamily` and `clockMinutesFamily` (case-insensitive `Qt.fontFamilies()` match, fallback `Config.fontFamily`) |
| `config/SystemMetricsService.qml` | singleton; `active` flag set by the Home page; a 2 s tick reloading FileViews for `/proc/stat`, `/proc/meminfo`, `/proc/net/dev`, `/proc/uptime` and `/etc/hostname`, plus `df -P /` and `cat /sys/class/thermal/thermal_zone*/temp` Processes |
| `config/MediaService.qml`, `scripts/mpris_monitor.py`, `scripts/mpris_control.py` | `positionSec` (monitor emits `position_sec` on state changes and `Seeked`; MediaService polls `mpris_control.py position` each second only while `sidebarActive` and Playing), `seekBy(deltaSec)`, `seekTo(sec)`, `stop()`, `playerVolumeBy(delta)`; controls through `mpris_control.py` |
| `bar/CalendarLogic.js` | new `buildMonthGrid(date, startsMonday)` returning 42 cells `{day, other}` |
| `bar/sidebar/{HomePage,AgendaPage,MediaPage,SliderTile,PageIndicators,SeekLine}.qml` | pages and pieces; `SidebarContent.qml` hosts them |
| `bar/SidebarActivator.qml`, `shell.qml`, `config/Settings.qml`, `bar/settings/AppearanceTab.qml` | activator, wiring, new setting + row |
| `config/SidebarPages.js` (pure) | `stepPage(current, delta, count)`, `indicatorWidth(selected)` (wheel paging uses `BottomBarModel.notchSteps`) |
| deleted | `bar/sidebar/{BatteryPill,CalendarCard,ClockCard,DashboardPage,LevelBar,LevelBars,MediaCard,SearchField,StatsCard,WeatherCard}.qml`, `tests/sidebar/{search,stats}.test.mjs` (stats parsing moves to `tests/sidebar/metrics.test.mjs`), IPC `sidebarSearch`, `Sidebar.searchSubmitted` and `settingsRequested`, `config/Weekdays.js` (the strip is built in `HomePage.qml` from the clock) |
| kept | `LauncherPopup.initialQuery`, IPC `launcherQuery`, `shell.openLauncherWith` (no caller left; kept for the launcher `initialQuery` hook) |

## Verification
- Node: `tests/sidebar/metrics.test.mjs` (cpu delta incl. counter wrap and zero
  total, temp zone selection and unavailable, disk and swap parse, net rate with
  a counter reset, uptime parts at 59 s, 1 h, 1 d 1 h, 8 d), `tests/sidebar/pages.test.mjs`
  (`stepPage` clamps, `indicatorWidth`),
  `tests/sidebar/calendar.test.mjs` (`buildMonthGrid`: 42 cells, Feb leap year,
  Dec/Jan boundaries, Sunday/Monday first), `tests/sidebar/media.test.mjs`
  (position fraction, `fractionOfLine`,
  position text mm:ss), wiring assertions for the activator (1 px, left/top/
  bottom anchors, disabled under lock, setting gate). No fullscreen gate: niri
  26.04 window JSON has no fullscreen flag, and niri draws fullscreen windows
  above the Top layer, which covers the strip.
- Render checks (scratch HOME, fixed stage per page): Home (tile fill pixel at
  25 % and 75 % of a 50 % tile, volume muted fill color, weekday today fill, the
  weather pill), Agenda (today round, dimmed other-month number, empty state
  text pixels), Media (ring arc present at 50 %, seek line colored count,
  controls row), indicators (selected pill width, colors per page); each
  mutation-proven.
- Existing gates unchanged (m3-qmllint, controls, config-dump with new keys
  allow-listed, bottom-bar render, bar-font-check, style-refs).
- Live after the user's cold restart: `openSidebarPage 0/1/2` and the toggle
  sequence, edge hover opens (pointer warp via `niri msg action` is not
  available; the check is a log line from the activator plus `currentPopup`),
  media seek with a real player, RSS sample.

## Out of scope
Task feed for the agenda (org files), the networks window (R4), alarms (R5),
power menu (R3), notifications and launcher look (R6), workspace-row parity
(R7), multi-monitor sidebars, drag-reordering of tiles.

## Usage
Click the bar's glance, tasks or media button (page 0, 1, 2), press
`Mod+Shift+D`, or move the pointer to the left screen edge. Scroll over the
page dots or use Ctrl+PageUp/PageDown to switch. Dev IPC:
`qs ipc call shell openSidebarPage <0|1|2>`, `bottomBarState` (includes `page`).
