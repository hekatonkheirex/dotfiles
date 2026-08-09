# Ukishima-style pill shell for Niri — design

## Goal

Replicate the [amanhex/ukishima](https://github.com/amanhex/ukishima) dynamic-island Quickshell shell — a single morphing pill per monitor that every module expands out of in place, instead of separate popup windows — adapted to run on Niri instead of Hyprland. Reference architecture credit: Ukishima itself is built on [Gakuseei/Ricelin](https://github.com/Gakuseei/Ricelin).

Built alongside the current `bar/`/`config/` shell, not in place of it. Nothing in the existing shell is touched until the new one is ready to cut over.

## Non-goals (v1)

Wallpaper shuffle + live-palette system, screen recorder, clipboard manager (cliphist), night light, game mode, keep-awake inhibitor. These are real Ukishima features but out of scope for v1 — tracked as follow-up specs once the pill itself is working.

## Compositor mismatch (why this isn't a straight port)

Ukishima is Hyprland-specific: `Quickshell.Hyprland` for workspaces/monitors/fullscreen/dispatch, `hyprctl`, `hyprsunset.conf` generation, and a Hyprland-flavored IPC keybind convention (`bind = ... exec qs -c ukishima ipc call ukishima ...`). Quickshell has no native Niri module. The current repo already solves this for workspace state (`bar/WorkspaceIndicator.qml`: `niri msg event-stream` parsed via `Process`) — that pattern is generalized into a shared `Niri` singleton and reused everywhere Ukishima would call into `Quickshell.Hyprland`.

## Architecture

New self-contained directory: `pill/` at repo root — own `shell.qml`, `Singletons/`, `components/`, `surfaces/`. Launched separately (`qs -c pill`) for side-by-side testing against the current default config.

Two `PanelWindow`s per monitor via `Variants { model: Quickshell.screens }`, mirroring Ukishima's `shell.qml`:

- **`reserve`** — zero-content strip, `exclusionMode: Normal`, claims an exclusive zone the height of the resting pill so tiled Niri windows always sit below it, collapsed or expanded.
- **`overlay`** — full-screen transparent `WlrLayer.Overlay` window hosting one `Pill` item anchored top-center. Never resizes as a window; the `Pill` item inside it grows/shrinks. Input mask:
  - pill rect only, when collapsed (rest of screen clicks through to windows)
  - full window, when a surface is open or the pill is pinned/hovered-held
  - a thin top-center reveal strip, if auto-hide is enabled (matches Ukishima's reveal-region trick)

`Pill.qml`: one `Item` carrying all state (`surface: string`, `hovered`, `pinned`). Width/height driven by `state`, `Behavior on width/height` using the same no-overshoot morph easing as Ukishima (`Motion.morph` duration + custom bezier — port the curve values, don't reinvent them). Surfaces stack absolutely inside and cross-fade; only one is opaque/interactive at a time.

## Niri integration

`Singletons/Niri.qml` (new):

- Keeps one `Process` running `niri msg event-stream` (same `NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock | head -1)` discovery already used in `WorkspaceIndicator.qml`), line-buffered JSON parse.
- Exposes `workspaces`, `focusedWindow`, `focusedMonitor`, `fullscreenByMonitor` as bound properties, refreshed only on relevant event types (`WorkspacesChanged`, `WindowFocusChanged`, `WindowOpenedOrChanged`, `WindowClosed`) — mirrors Ukishima's `refreshEvents` allowlist so window-drag/resize spam doesn't trigger refresh storms.
- Auto-restart on stream death (same retry-timer pattern already in `WorkspaceIndicator.qml`'s `niriWatcherRetry`).
- Fullscreen detection: niri's IPC (verified live against the running 26.04 instance — `niri msg -j windows`, `focused-window`, and every `event-stream` payload, including mid-toggle) carries no `is_fullscreen` field at all. The only observable signal is that a fullscreened window's `layout.window_size` grows to match its output's logical `width`/`height` from `niri msg -j outputs`. The singleton computes `fullscreenByMonitor` by comparing each output's focused window's `window_size` against that output's logical size on every relevant event — an equality heuristic, not a flag. This is a real behavioral gap versus Hyprland's explicit `hasfullscreen`: a legitimately maximized-but-not-fullscreen window at the exact same size as its output would be a false positive. Acceptable for v1 given niri's scrolling layout makes that an unlikely combination; noted as a known limitation rather than solved.

`IpcHandler { target: "pill" }` in `shell.qml`: ports Ukishima's handler block essentially unchanged (`toggleSurface(mon, name)` per handler) since `qs ipc call` is compositor-agnostic. Keybinds move from Hyprland `bind = ... exec qs -c ukishima ipc call ...` to Niri's `spawn "qs" "-c" "pill" "ipc" "call" "pill" "<handler>" ""` in `niri.kdl` — added as part of this work, not assumed pre-existing.

## Surfaces (v1)

Each becomes a component under `pill/surfaces/`, stacked inside `Pill.qml`, replacing the corresponding standalone popup window:

| Surface | Ported from |
|---|---|
| workspace dots (rest-state content) | `bar/WorkspaceIndicator.qml` |
| `ClockSurface` | clock in `bar/Bar.qml` + `bar/CalendarPopup.qml` |
| `AudioSurface` | `bar/AudioIndicator.qml` + `bar/AudioPopup.qml` |
| `BatterySurface` | `bar/BatteryIndicator.qml` + `bar/BatteryPopup.qml` |
| `WifiSurface` | `bar/WifiIndicator.qml` + `bar/WifiPopup.qml` |
| `BtSurface` | `bar/BtIndicator.qml` + `bar/BtPopup.qml` |
| `BrightnessSurface` | `bar/BrightnessIndicator.qml` + `bar/BrightnessPopup.qml` |
| `LauncherSurface` | `bar/Launcher.qml` + `bar/LauncherPopup.qml` |
| `PowerSurface` | `bar/PowerConfirmation.qml` |
| `NotificationSurface` | `bar/NotificationIndicator.qml` + `bar/NotificationPopup.qml` |
| `MenuSurface` (tabs) | `bar/CommandCenter.qml` + `bar/QuickMenu.qml`, tabs from `bar/commandcenter/*` minus `WallpapersTab` (deferred) |

Stay independent of the pill (unchanged from today, matching Ukishima's own choice to keep these separate):

- `bar/NotificationToast.qml` — toasts are transient overlays, not pill-grown, in Ukishima too.
- `bar/OsdOverlay.qml` — volume/brightness OSD stays a lightweight standalone overlay.
- `bar/SystemTrayArea.qml` — tray icons render in the pill's rest row but keep their own popup menus (tray protocol dictates its own menu windows; not a Quickshell surface to absorb).

## Styling

Uses the existing Matugen/M3 Expressive `config/Colors.qml` tokens throughout — not Ukishima's fixed vermillion palette. Dynamic wallpaper-derived color already covers what Ukishima's `wallcolors.py` palette system does for the UI chrome; no separate palette generator needed for v1.

## Testing

Each surface is functionally a restyle of an existing working popup — behavior parity is checked by running `pill/` via `qs -c pill` on a live Niri session and exercising every handler (`launcher`, `mixer`→audio, `calendar`, `power`, `battery`, `wifi`/`bt`/brightness via `page`, `hide`) plus: fullscreen retract, auto-hide reveal strip, multi-monitor (pill per screen, correct focused-monitor resolution on empty-string IPC arg), and Niri event-stream reconnect after a `pkill niri` restart (soak-test pattern, matching the existing MPRIS soak-testing approach in this repo). No unit-test framework exists for QML in this repo today — this stays manual/soak, consistent with how the rest of the shell is validated.

## Rollout

`pill/` ships and is iterated on with the default shell untouched. Cutover (making `pill/` the thing that actually launches at session start, retiring `bar/`+`config/`) is a separate decision made after the side-by-side testing above passes — not part of this spec.
