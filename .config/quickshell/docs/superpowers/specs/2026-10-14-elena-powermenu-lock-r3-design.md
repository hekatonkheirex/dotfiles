# Elena powermenu and lock look (R3 of the SwayFX + eww replication)

Date: 2026-10-14

## Outcome
Her powermenu overlay replaces the QuickMenu and doubles as the lock surface.
Measured by: node gates for the pure modules pass; render checks show the
overlay (six glyph colors, hover dimming, palette row, terminal line) and the
lock state (ring border per action, masked input, lockdown flavor); the lock
tests still prove PAM and `WlSessionLock` are untouched; `popup-ipc-check.sh`
passes; live: logout button and `Mod+Escape` open the overlay, dismiss paths
work, lock and unlock work.

## Reference
`config/eww/windows/powermenu.yuck` and `powermenu.scss` in
github.com/elenapan/dotfiles (master, 2025-09-07). Scale S = `Config.elenaScale`
(1.5), sizes through `Config.dp()`; colors through `Colors.elenaAccent(n)`.

## Decisions (user, 2026-10-14)
- Replace the QuickMenu entirely. Caffeine, airplane and bluetooth toggles and
  the control hints are dropped (no home in her rice).
- Lock: her look, keep PAM and `WlSessionLock`. Wallpaper, clock and MPRIS leave
  the lock surface with their settings.
- Destructive actions confirm (poweroff, reboot, exit) through the existing
  PowerConfirmation; hibernate, suspend, lock run immediately.
- Greeting and bunny stay; quote and author come from settings.

## Overlay
`bar/PowerMenu.qml`: layer Overlay, anchors all edges, exclusion Ignore,
keyboard focus exclusive while open, background `Colors.surface` at 0.7 alpha
(locked: opaque).

- **Left side** (border 6 S `outline` at 0.3, no right border, radius 27 S left
  corners, padding 27/74/54/47 S): greeting "Hello" in BattleAndy 80pt S
  (x6) with a small heart glyph (x1) and the subtitle "(again)" 17pt (x15 role
  `fgSurfaceVariant`); quote block (marks glyph 27pt, text 14pt italic, author
  right aligned `fgSurfaceVariant`); palette row of six 29 S circles on a 4 S
  `surface` border in order x1, x3, x2, x6, x4, x5.
- **Right side** (radius 27 S, color `surface`, border 6 S dashed `outline` 0.3,
  padding 0/47 S): bunny block `(\ /)`, head, `c(")(")` with the quotes in x1;
  hover on the bunny shows `( ^ ^)`; button grid 3x2, buttons 54 S square,
  glyph 30pt S in the icon font; terminal line "/ A P H E L I O N /" and
  `$ <hovered action>_` with a blinking underscore (1 s, 2 steps).
- **Buttons:** poweroff x1, reboot x2, exit x4, hibernate x6, suspend x3, lock
  x5; muted (`outline` 0.6) until revealed, then colors fade in staggered
  (0.5 s, 0.1 s steps). Hover dims the others to 0.3.
- **Input:** click acts; click outside the buttons and middle click dismiss
  (not while locked); Esc dismisses; arrows move the selection, Enter acts.
- **Actions:** `poweroff`/`reboot`/`exit` open PowerConfirmation with the
  existing executor and `scripts/safe-logout.sh` for exit; `hibernate`,
  `suspend` run `systemctl`; `lock` requests the lock.
- **Settings:** `powerMenuQuote` (default "Take a breath."), `powerMenuQuoteAuthor`
  (default empty hides the author line), in Settings > Appearance.
- **Availability:** hibernate is shown regardless; if `systemctl hibernate` is
  unavailable the executor logs and the menu closes (no silent crash).

## Lock state
`LockScreen.qml` keeps `WlSessionLock`, `PamContext`, the secure unlock path and
its reload guard unchanged. The lock surface content becomes the overlay with
`locked` true: buttons hidden, centered symbol ring (47 pt glyph, 6 S border,
radius max, padding 12 S) and the terminal "[ L O C K D O W N ]" with `> ` and
masked input; terminal color x1.

- Ring border by last action: clear x0 role (`outlineVariant`); insert cycles by
  `(length - 1) % 6` over x1, x3, x2, x6, x4, x5; delete alternates x8 and
  `outline` 0.3 by index parity.
- Glyph: unlocked symbol normally, failed-auth symbol when authentication
  failed.
- Removed settings: `lockShowSeconds`, `lockFontSize`, `lockClockSize`,
  `lockShowMedia`, `lockUseWallpaper`, `lockInFlow` if unused (verified by
  grep). Stale keys are ignored at load. Removed lock-only helpers: wallpaper
  loader, MPRIS fields.

## Data and files
| File | Role |
|---|---|
| `config/PowerMenuModel.js` (pure) | `buttons()` order/colors, `ringColorIndex(len, action)`, `maskInput(len)`, `selectionStep(index, key)` |
| `bar/PowerMenu.qml` | overlay window |
| `bar/powermenu/{PowerButton,BunnyBlock,PaletteRow,TerminalLine,LockRing}.qml` | pieces; `PowerMenuContent.qml` is window-less (render-checkable) |
| `bar/LockScreen.qml` | surface uses `PowerMenuContent` in locked mode; PAM/session lock unchanged |
| `shell.qml` | instance, `togglePowerMenu`, repoint `quickmenu` IPC and runtime trigger; bar logout button; remove QuickMenu |
| `config/Settings.qml`, `bar/settings/AppearanceTab.qml` | quote settings and rows; removal of lock settings and rows |
| deleted | `bar/QuickMenu.qml`, QuickMenu-only tests and checks, `MenuIndicator` popup route |
| kept | `bar/PowerConfirmation.qml`, `scripts/safe-logout.sh`, IPC `quickmenu` (alias) |

## Verification
- Node: `tests/power-menu/model.test.mjs` (order and colors, ring index at 0,
  1, 6, 7 characters, delete parity, selection step wrap/clamp, mask length).
- Wiring: logout button and `quickmenu` IPC open the overlay; PAM and
  `WlSessionLock` source lines unchanged (assert on the unmodified strings).
- Render checks (scratch HOME, fixed stage): overlay glyph colors under reveal,
  hovered-dims-others pixel, palette row colors, terminal text pixels; lock
  ring border color per action, masked input count; mutation-proven.
- Existing gates: m3-qmllint, config-dump (removed keys leave the allow list),
  controls, bottom-bar and sidebar render, bar-font-check, style-refs,
  popup-ipc-check, lock tests in `scripts/`.
- Live after the user's cold restart: open from the bar and `Mod+Escape`,
  dismiss by click outside/middle/Esc, confirmation on poweroff cancelled,
  lock with a wrong then right password, journal clean, RSS sample.

## Risks
The lock is security-critical: no change to PAM, `WlSessionLock` or the
reload guard; the wiring test pins them. The overlay covers our bottom bar so
it needs the Overlay layer and exclusive keyboard focus; checked live.

## Out of scope
Settings panel rework, notification and launcher looks (R6), session or PAM
behavior changes, new power commands.

## Usage
Click the bar's logout button or press `Mod+Escape`. Edit the quote in Settings
> Appearance. Dev IPC: `qs ipc call shell quickmenu`.
