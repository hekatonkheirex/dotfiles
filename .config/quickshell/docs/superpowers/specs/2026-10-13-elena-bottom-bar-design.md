# Elena bottom bar (R1 of the SwayFX + eww replication)

Date: 2026-10-13

## Outcome
A full-width bottom bar replaces the auto-hide dock: left cluster (clock, date,
volume ring), centre dock (glyph per app, focus indicator), right cluster
(network, alarms, battery). It reserves space (windows never overlap it).
Measured by: node gates for the pure modules pass, the render check
(`scripts/bottom-bar-render.sh`) shows the clusters, glyphs, indicator, battery
parts and ring in the expected colors, `qs ipc call shell dockState` still
matches `niri msg -j windows`, and `niri msg layers` shows the bottom layer
surface with an exclusive zone of the bar height.

## Reference
`config/eww/windows/bottom-bar.yuck`, `bottom-bar.scss` and
`config/eww/scripts/daemons/sway-dock.py` in github.com/elenapan/dotfiles
(master, 2025-09-07), and the Aphelion showcase video. Her scale is 1.5 on a
1080p screen; every `dpi(Npx)` below is `N * S` with `S = Config.elenaScale = 1.5`
(one constant, no setting).

## Decisions (user, 2026-10-13)
- Replicate her widgets exactly; keep OUR palette ("minus the new color theme").
- Her text fonts (Kyok, Baro, BattleAndy) are installed by the user from her
  zip; the shell falls back to the current fonts when they are missing.
  Icons use the installed `icomoon` family (`remix.ttf`, 79 of her 88 glyphs
  present; absent glyphs render the font's replacement and are listed in the
  plan).
- Binding-mode and split indicators are dropped (niri has neither).
- The auto-hide dock and its reveal logic are removed; the bar is always
  visible.

## Layout
- Window: anchors left, right, bottom; `WlrLayer.Bottom`; exclusive zone equal
  to the bar height; height `43 * S` (65 px at S = 1.5); transparent window.
- Left cluster: width `300 * S`, background `Colors.surface`, top-right radius
  `20 * S`; three buttons spread evenly.
- Right cluster: width `300 * S`, background `Colors.surface`, top-left radius
  `20 * S`; three buttons spread evenly.
- Centre: dock row, bottom-aligned, no background.
- Button: min width `67 * S`, glyph size `12pt * S` in `icomoon`, 3 `* S`
  bottom border, transparent until hover (then the button's accent). A value
  pill is a `23 * S` circle on `Colors.surfaceContainerHighest`, 8pt text, left
  margin `10 * S`.

## Buttons
| Button | Accent | Content | Left click | Other |
|---|---|---|---|---|
| glance | x1 | clock glyph + `HHMM` pill (min width 34 S) | sidebar page 0 | right click: launcher |
| tasks | x2 | calendar glyph + day-of-month pill | sidebar page 1 | |
| media | x5 | speaker glyph + volume ring: 5 S thick, backdrop `surfaceContainerHighest`, starts at 75 %, counter-clockwise; muted ring uses x8 | sidebar page 2 (clamped to existing pages) | scroll up/down: volume +/- (one step per notch); middle: mute; right: focus or spawn pavucontrol |
| network | x4 | VPN glyph (on/off) + 4 signal bars (heights `23S-16S`, `-10.5S`, `-5.5S`, `23S`; 5 S wide; active up to the signal level, disconnected = one short x8 bar) | Settings > Network (tab 4) until R4 | |
| alarms | x3 | alarm glyph + count pill; with no alarms a 4 S slashed line rotated 38 degrees | no-op until R5 | |
| logout | x6 | charger or battery glyph + 3-part vertical battery stack (14 S wide parts, thresholds 66/83, 33/49, 0/16: part is `full` above the half threshold, `half` (50 % opacity) above the lower one, else `surfaceContainerHighest`) | quick menu until R3 | |

## Dock (centre)
- Items: pinned apps first (`Settings.dockPinned` order), then running apps in
  first-open order (existing `DockModel.dockItems`).
- Item: glyph (16pt * S, icomoon) in the app's accent; min size `35 * S` x
  `26 * S`; indicator `6 * S` x `3 * S` (opacity 1 when focused, 0 otherwise)
  under the glyph; empty (pinned, no window) uses x8 and no indicator.
- Symbols and accents come from `config/DockSymbols.js`, a verbatim port of
  `window_information` in `sway-dock.py` keyed by `app_id` (matched
  case-insensitively like `DockModel`), with `___default___` for unknown ids.
- Click: focus or launch (`shell.dockActivate`); click on the focused app
  cycles its windows; middle click closes (`shell.dockClose`); wheel cycles
  (`shell.dockCycle`), as the current dock does.

## Accent ramp (our palette)
Her `x1..x6` and `x8` map to our roles; the dock cycles the same ramp by her
per-app color index (`"1"`..`"10"`, 7 to 10 wrap onto 1 to 4).

| Slot | Role |
|---|---|
| x1 | `Colors.error` |
| x2 | `Colors.secondary` |
| x3 | `Colors.tertiary` |
| x4 | `Colors.primary` |
| x5 | `Colors.inversePrimary` |
| x6 | `Colors.fgTertiaryContainer` |
| x8 | `Colors.outline` (muted) |

The mapping lives in one function (`Colors.elenaAccent(n)`) so it can change
without touching the bar.

## Data and files
| File | Role |
|---|---|
| `config/DockSymbols.js` (pure) | `symbolFor(appId)` -> `{symbol, color}`; the ported table |
| `config/BottomBarModel.js` (pure) | `batteryParts(pct)`, `signalParts(signal, connected)`, `clockText(date)`, `dateText(date)`, `dockViewItems(items, symbols, focusedId)` |
| `config/NetworkStatusService.qml` | `signal` (0..4), `connected`, `vpn`; `nmcli monitor` triggers a refresh, 10 s fallback poll; runs `nmcli -t -f ACTIVE,SIGNAL dev wifi` and `nmcli -t -f TYPE,STATE con show --active` |
| `bar/BottomBar.qml` | the window, clusters, input |
| `bar/bottombar/{BarButton,VolumeRing,BatteryStack,SignalBars,DockItem}.qml` | pieces; `BottomBarContent.qml` is the window-less content (render-checkable) |
| `config/Config.qml` | `elenaScale` constant, bar height helper |
| `config/Colors.qml` | `elenaAccent(n)` |
| `shell.qml` | instance, `openSidebarPage(n)`, `bottomBarState()` IPC, removes `Dock`, `dockReveal` |
| deleted | `bar/Dock.qml`, `bar/dock/*`, `scripts/dock-render.sh`, `tests/dock/{item,window}.test.mjs` (replaced by the new gates), `dockReveal` IPC |
| kept | `DockModel.js`, `WindowService.qml`, `Settings.dockPinned`, `DockSection.qml`, IPC `dockState` |

`openSidebarPage(n)`: closed -> open at page n; open at page n -> close; open at
another page -> switch. n is clamped to the pages the sidebar has today (0 and
1); R2 adds the third.

## Verification
- Node: `tests/bottom-bar/dock-symbols.test.mjs` (every key of the ported
  table resolves, case-insensitive, default fallback, color slot wrap),
  `tests/bottom-bar/model.test.mjs` (battery thresholds at 0, 16, 17, 33, 34,
  49, 50, 66, 67, 83, 84, 100; signal bar counts; clock/date strings),
  `tests/bottom-bar/wiring.test.mjs` (the sidebar page toggle sequence, the
  button to action table).
- Render check `scripts/bottom-bar-render.sh` (scratch HOME, the content item
  at a fixed size): cluster background colors and the rounded outer corners,
  glance accent border under a forced hover, focused indicator color under the
  second item, empty item muted, battery stack at 100 / 50 / 10 %, signal bars
  at 4 / 2 / disconnected, ring arc drawn and muted variant; mutation-proven.
- Existing gates: m3-qmllint, `config-dump.sh check` (new Config/Colors keys go
  in the allow list as added), controls-behavior, controls-render,
  sidebar-render, tag-strip-render, popup-ipc, style-refs.
- Live (after the user's cold restart): `niri msg layers` bottom surface with
  exclusive zone, `niri msg -j windows` geometry does not overlap the bar,
  `qs ipc call shell dockState` matches, `openSidebarPage` toggle sequence over
  IPC, RSS sample before and after 10 minutes (the Image leak is unresolved).

## Out of scope
The networks window (R4), the alarms window (R5), the power-menu look and lock
(R3), the sidebar rebuild and the media page (R2), indicators, notification and
launcher looks (R6), workspace-row parity (R7), the order-file agenda, and her
text-font installation (the user's step).

## Usage
Always visible at the bottom. Click the glance, tasks or media buttons to open
the sidebar pages (again to close). Pinned apps: Settings > Appearance > Dock
pinned apps. Dev IPC: `qs ipc call shell dockState`, `bottomBarState`,
`openSidebarPage <n>`.
