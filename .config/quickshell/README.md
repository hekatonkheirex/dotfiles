# Quickshell Desktop Shell

A custom desktop shell built with [Quickshell](https://quickshell.outfoxxed.me/), running on **Niri or Mango**.

## Overview

This replaces a traditional status bar (waybar) and panel infrastructure with a unified QML-based shell. It provides:

- **Workspace strip** (`bar/Bar.qml`, `bar/TagStripBlocks.qml`, `config/TagStrip.js`): the whole top bar is an 8px row of workspace blocks in her color order (x1 x3 x2 x6 x4 x5, repeating). Niri workspaces are dynamic, so the row holds the workspaces that exist, not her fixed ten slots. Focused is solid, occupied 0.3, the empty trailing workspace is invisible (0.2 on hover; a non-focused block is 0.6 on hover), and bottom corners round against an empty neighbor. Click focuses, right click moves the focused window there without following it, the wheel steps to the previous or next workspace. Check: `node tests/tag-strip/model.test.mjs`, `bash scripts/tag-strip-render.sh`.
- **Sidebar and dock**: a three-page sidebar (Home, Agenda, Media) that also opens from the left screen edge and a full-width bottom bar (page buttons, volume, app dock, clock, battery, network) that reserves its height. Saved bar forms, placement and widget settings remain stored, but Elena forces the top strip and hides the old in-bar widget layout; re-homing that machinery is a separate change.
- **Lock screen** in her power-menu look (lock ring, masked LOCKDOWN line) with PAM + fingerprint authentication.
- **Notification handling** with dashed Elena history cards and her dunst-style toast stack (R6): urgency-colored glyph rows, up to five cards with duplicate counts, critical toasts that stay.
- **Do Not Disturb** suppresses toast popups while retaining incoming notifications in the bell history; toggle it in Settings > Notifications (persisted).
- **Battery alert watcher**: warning at 20%, critical alert at 10%, persistent `notify-send` notifications driven off `UPower.onBattery` (not raw charge state, which sawtooths under charge-conservation thresholds).
- **App launcher** with fuzzy app search that honors hidden/unavailable desktop entries and user overrides, shell actions via `>`, clipboard history via `;`, and wallpaper search via `@`. Speech recognition is removed.
- **On-Screen Display (OSD)** overlay for volume, brightness, mic mute, airplane mode, bluetooth, and keyboard backlight (polled from sysfs since the EC never emits a key event for it).
- **LLM usage**: Read-only Codex and Claude quota popup (`qs ipc call shell popup llm`), including five-hour and weekly usage, reset countdowns, and available reset credits. It has no bar widget any more; the popup is reachable only through IPC.
- **Settings panel**: A multi-functional, resizable and draggable panel launched via `XF86Tools` with ten tabs:
  - **Account**: Profile, session, uptime, machine information, lock, and Quickshell restart actions
  - **General**: Motion, uptime, notification timestamp format, calendar week start, and weather location/refresh/privacy/unit settings
  - **Appearance**: Wallpaper filmstrip and random wallpaper, Auto/Light/Dark mode, Live wallpaper colors or Fixed palettes (including Elenapan), accent shortlist, contrast, dock pins, power menu quote and author line, shared interface font/icon/spacing controls, color reload, and confirmed appearance reset (which also restores the quote). No UI-style picker, retired bar controls, or separate compact-control density setting.
  - **Display & Input**: Per-output mode, scale, and transform controls plus touchpad, mouse, trackpoint, and edge-gesture settings
  - **Bluetooth**: Bluetooth power, discovery, pairing, connected-device, and rename controls; Bluetooth is Settings-only and has no compact bar indicator
  - **Media**: Media artwork, progress, and control visibility
  - **Lock & Power**: Idle lock/suspend timeouts, Caffeine, and TLP power profiles
  - **Notifications**: Do Not Disturb, quiet hours, critical bypass, toast position/duration, history retention, clear-history, and test-notification controls
  - **System**: CPU, memory, disk, swap, thermal, fan, battery health/cycles, diagnostics copy, reload, and confirmed reset actions
  - **Shortcuts**: Curated active-compositor keybind reference with source open and copy actions
- **Persisted user settings** (`settings.json`, `config/Settings.qml`) separate from build-time layout/typography tokens (`config/Config.qml`).

## Project Structure

```
~/.config/quickshell/
├── shell.qml                  # Entry point — ShellRoot, IpcHandler, popups, battery alert, file triggers
├── settings.json              # Persisted user settings (JsonAdapter-backed)
├── layout                     # Persisted bar placement ("top" | "bottom" | "left" | "right")
├── config/
│   ├── Config.qml             # Build-time layout, typography, shape, and motion tokens
│   ├── Settings.qml           # Persisted preferences singleton (FileView + JsonAdapter over settings.json)
│   ├── Colors.qml             # Semantic roles, Live/Fixed palette resolution, Matugen fallback and dark-mode tracking
│   ├── PaletteCatalog.js      # Elenapan, Catppuccin, Gruvbox and TokyoNight palette families
│   ├── AudioService.qml       # Shared PipeWire sink/source state and watcher
│   ├── BrightnessService.qml  # Shared backlight state and watcher
│   ├── BatteryService.qml     # Shared UPower battery-device selection
│   ├── MediaService.qml       # Shared MPRIS monitor state
│   ├── WeatherService.qml     # Shared weather fetch/cache state
│   ├── LlmUsageService.qml    # Shared quota polling and stale-reading state
│   ├── CodexUsageService.qml  # Codex quota singleton
│   ├── ClaudeUsageService.qml # Claude quota singleton
│   ├── WindowService.qml       # Read-only Niri window stream
│   ├── WindowState.js          # Window-event reducer
│   ├── DockModel.js            # Pin order and running-app grouping
│   ├── DockSymbols.js          # App id -> icomoon glyph and accent slot (elenapan's dock table)
│   ├── BottomBarModel.js       # Pure bottom-bar decisions (clock, battery, signal, nmcli parsing, page toggle, wheel notches)
│   ├── NetworkStatusService.qml # Wi-Fi signal bucket and VPN state for the bottom bar
│   ├── Alarms.js               # Pure alarm logic: next occurrence, entry keys, due, file parse
│   ├── AlarmService.qml        # Alarms: file store, single re-armed timer, sound and notification (command seam)
│   ├── NetworkList.js          # Pure nmcli parsers, signal buckets, name cut, ping lines, MB/s label
│   ├── NetworkListService.qml  # Networks window: Wi-Fi list, scan, ping, connect/disconnect/forget (one command seam)
│   ├── BottomBarFonts.qml      # Icon and text font families for the bottom bar
│   └── cava.ini               # cava config for the real-time audio visualizer
├── bar/
│   ├── Bar.qml                # Top workspace strip, popup routing, workspace state, tray watcher
│   ├── Sidebar.qml            # Home/Agenda/Media sidebar window, left+bottom anchored
│   ├── SidebarActivator.qml   # 1 px left-edge hover strip that opens the sidebar
│   ├── sidebar/               # SidebarContent, HomePage, AgendaPage, MediaPage, SliderTile, PageIndicators, SeekLine, SymbolDisc, InfoPill, TextPill, StepArrows, PadButton
│   ├── BottomBar.qml          # Bottom bar window (content in bottombar/)
│   ├── bottombar/             # BottomBarContent, BarButton, DockGlyph, ValuePill, VolumeRing, BatteryStack, SignalBars
│   ├── SettingsPanel.qml       # Settings panel shell (state, processes, tab bar) — content in settings/
│   ├── settings/
│   │   ├── AccountTab.qml
│   │   ├── AppearanceTab.qml
│   │   ├── DisplayInputTab.qml
│   │   ├── GeneralTab.qml
│   │   ├── LockMediaTab.qml
│   │   ├── MediaTab.qml
│   │   ├── PowerProfileCard.qml
│   │   ├── BluetoothTab.qml
│   │   ├── NotificationsTab.qml
│   │   ├── ShortcutsTab.qml
│   │   └── SystemTab.qml
│   ├── LockScreen.qml          # PAM auth, fingerprint and compositor-enforced session lock
│   ├── WorkspaceIndicator.qml  # Niri/mango workspace state and actions (no visuals)
│   ├── LauncherPopup.qml       # App/provider search (apps, clipboard, wallpapers, actions)
│   ├── AudioPopup.qml          # Volume + mic sliders (shared bordered surface, correct active/mute states)
│   ├── BrightnessPopup.qml     # Brightness slider (shared bordered surface)
│   ├── BatteryPopup.qml        # Detailed battery info (shared bordered surface)
│   ├── MediaPopup.qml          # Media controls and circular cava visualizer
│   ├── WeatherPopup.qml        # Current conditions and forecast
│   ├── LlmUsagePopup.qml       # Combined Codex and Claude usage popup
│   ├── LlmUsageSection.qml     # Provider usage, resets, and refresh state
│   ├── NetworksWindow.qml       # Her networks window, right+bottom anchored overlay (route "networks")
│   ├── networks/                # NetworksContent, NetworkRow, PassphraseRow, BandwidthRow, ToolbarButton
│   ├── AlarmsWindow.qml         # Her alarms window, right+bottom anchored overlay (route "alarms")
│   ├── alarms/                  # AlarmsContent, AlarmButton
│   ├── BtPanel.qml              # Bluetooth controls used by the Settings Bluetooth tab
│   ├── SystemTrayArea.qml      # StatusNotifier tray icons (orientation-aware)
│   ├── PowerMenu.qml           # Full-screen power menu overlay (route "quickmenu")
│   ├── powermenu/              # PowerMenuContent, its pieces and LockSurfaceContent (the lock look)
│   ├── OsdOverlay.qml          # Volume/brightness/mic/airplane/bluetooth/kbd-backlight OSD popup
│   ├── CalendarLogic.js        # Calendar weekday ordering and day-cell model
│   ├── CalendarPopup.qml       # Calendar month grid (shared bordered surface)
│   ├── NotificationPopup.qml   # Notification history popup list
│   ├── NotificationToast.qml   # Her dunst toast stack (R6b): five cards, duplicate counts, urgency colors
│   ├── MicIndicator.qml        # Her top-center microphone tab (R6a)
│   ├── PopupBase.qml           # Shared popup background, border and spring entrance
│   ├── PopupShield.qml         # Full-screen click-outside-to-dismiss surface
│   ├── PopupDivider.qml        # Reusable popup section divider
│   ├── PowerConfirmation.qml   # Confirmation surface for destructive power actions
│   ├── FocusDismiss.qml        # Popup dismissal on app focus loss
│   ├── FileTrigger.qml         # Private runtime trigger-file watcher (single inotifywait for all triggers)
│   ├── SliderControl.qml       # Elena slider facade (volume/brightness/etc.)
│   ├── SwitchControl.qml       # Elena switch facade
│   ├── WaveProgressBar.qml     # Single wave-progress canvas
│   ├── primitives/             # Shared buttons, list items, and text fields
│   │   ├── ActionButton.qml
│   │   ├── IconGlyph.qml          # Shared Material Symbols font glyph; no per-style icon implementation
│   │   ├── IconButton.qml
│   │   ├── ListDivider.qml
│   │   ├── ListItem.qml
│   │   ├── LoadingIndicator.qml
│   │   ├── StyledSurface.qml
│   │   └── TextFieldControl.qml
│   └── controls/               # Elena-native controls with shared input/accessibility bases
│       ├── ElenaActionButton.qml
│       ├── ElenaIconButton.qml
│       ├── ElenaSliderControl.qml
│       ├── ElenaSwitchControl.qml
│       └── LevelTile.qml
├── scripts/
│   ├── launcher                # Launcher trigger (private runtime trigger)
│   ├── quickmenu                # Power menu trigger (private runtime trigger)
│   ├── settings                 # Settings trigger (private runtime trigger)
│   ├── commandcenter            # Legacy alias for settings
│   ├── lock                     # Lock helper; waits for Niri's secure session-lock state
│   ├── emit-trigger             # Validated private runtime trigger writer
│   ├── runtime-dir.sh            # Shared private runtime-directory setup
│   ├── toggle-airplane.sh       # Bounded Wi-Fi/Bluetooth airplane-mode toggle
│   ├── toggle-bluetooth.sh      # Bounded Bluetooth power toggle
│   ├── apply-wallpaper.sh       # Wallpaper selection + Matugen/theme refresh
│   ├── capture-screen.sh         # Full-screen/region capture, save, and clipboard copy
│   ├── sync-active-palette.sh   # Renders the active cache and refreshes every theme consumer
│   ├── apply-accent-color.sh    # Compatibility stub — palette is fixed by Matugen, not user-selectable
│   ├── generate-thumbnails.sh   # Generates/caches 200×130 wallpaper thumbnails for the filmstrip slices
│   ├── random-wallpaper.sh      # Applies a random wallpaper, avoiding the current one
│   ├── generate-previews.sh     # Sharp 1600 px previews for the wallpaper filmstrip (one file or all missing)
│   ├── m3-qmllint-gate.sh       # QML regression gate, including native controls and shared primitives
│   ├── install-ui-suite.sh      # Installs palette-driven Matugen desktop companions
│   ├── verify-ui-suite.sh       # Verifies only those companion assets
│   ├── install-sddm-integration.sh # Installs the root SDDM bridge and polkit policy
│   ├── verify-sddm-integration.sh # Verifies the bridge and light/dark Matugen greeters
│   ├── idle.sh                  # Caffeine-controlled swayidle timeouts: dim, lock, display off, suspend
│   ├── idle-brightness-off      # Saves and dims brightness in the runtime directory
│   ├── idle-brightness-restore  # Validates and restores saved brightness
│   ├── sync-theme-mode-locked.sh # Serialized wrapper for the external theme synchronizer
│   ├── lid.sh                   # Lid close: lock
│   ├── safe-logout.sh           # Clean Niri/Mango quit, falls back to a session kill
│   ├── mpris_monitor.py         # Active MPRIS state broadcaster (DBus + private FIFO listener)
│   ├── mpris_control.py         # MPRIS play/pause/stop/next/prev control for the active player
│   ├── weather.py               # Open-Meteo weather fetcher script
│   ├── codex-usage.py           # Read-only OpenAI subscription usage/reset inventory
│   └── claude-usage.py          # Read-only Anthropic subscription usage/reset inventory
└── bin/
    └── desktop-parser.py        # .desktop → JSON for launcher
```

## WM Integration

Quickshell runs as a Wayland layer surface (panel) on top of the compositor. It integrates with **Niri** through the Niri socket and with **Mango** through mmsg IPC.

### Compositor Startup

Quickshell is managed via a systemd user service to ensure rate-limiting and session-binding (prevents infinite coredump storms in case of Wayland crashes/logouts).

Service file at `~/.config/systemd/user/quickshell.service`:

```ini
[Unit]
Description=Quickshell Desktop Panel
PartOf=graphical-session.target
After=graphical-session.target
# Stop restarting if it crashes more than 5 times in 10 seconds.
StartLimitIntervalSec=10s
StartLimitBurst=5

[Service]
ExecStart=/usr/bin/quickshell
Restart=on-failure
RestartSec=2s

[Install]
WantedBy=graphical-session.target
```

In `~/.config/niri/startup.kdl`:

```
spawn-sh-at-startup "exec swayidle -w before-sleep $HOME/.config/quickshell/scripts/lock"
spawn-sh-at-startup "~/.config/quickshell/scripts/idle.sh"
spawn-sh-at-startup "dbus-update-activation-environment --systemd --all && systemctl --user start quickshell.service"
```

Mango starts the same helper set from ~/.config/mango/autostart.conf,
including the idle watcher and quickshell.service. Its mmsg environment is
carried through the user manager, so the service does not hardcode a
compositor name.

Quickshell auto-discovers `~/.config/quickshell/shell.qml` as the default config when run without arguments.

### GPU Hang Watchdog

The Intel i915 driver has hung Quickshell's render thread twice in production (`GPU HANG: ecode 9:1:85dffffb`, preemption timeout on `rcs0`). Qt's QRhiGles2 backend doesn't recover from the resulting context loss — the process stays alive but never renders again, so `Restart=on-failure` on `quickshell.service` never fires.

`quickshell-gpu-watchdog.service` (unit at `~/.config/systemd/user/quickshell-gpu-watchdog.service`, script at `scripts/gpu-hang-watchdog.sh`) tails the `quickshell.service` journal for the `Context is lost` / `Graphics device lost` signature and force-restarts `quickshell.service` when it appears. Enabled alongside `quickshell.service` via `graphical-session.target`.


### Lid Switch

Lid close is handled in `~/.config/niri/config.kdl`:

```kdl
switch-events {
  lid-close { spawn "/home/mura/.config/quickshell/scripts/lock"; }
}
```

`scripts/lid.sh` (an equivalent standalone entry point for non-Niri lid handlers) locks via the same `scripts/lock` helper.

## Keybindings

Keybindings live in Niri's `~/.config/niri/keybinds.kdl` and spawn Quickshell's trigger scripts or the bounded `wpctl`/`brightnessctl`/radio helpers:

| Key | Action | Mechanism |
|---|---|---|
| `Mod+D` | Toggle app launcher popup | `scripts/launcher` → private runtime trigger |
| `Mod+Escape` | Toggle power menu | `scripts/quickmenu` → private runtime trigger |
| `Mod+Shift+D` | Toggle the sidebar (Home, Agenda and Media pages) | `qs ipc call shell popup sidebar` (direct IPC, no trigger script) |
| `XF86Tools` | Toggle Settings popup | `scripts/settings` → private runtime trigger |
| `Mod+Alt+L` | Lock screen | `scripts/lock` → Niri secure-lock acknowledgement |
| `XF86AudioRaiseVolume` / `LowerVolume` / `Mute` | Volume up/down/mute | `wpctl` + private runtime trigger |
| `XF86AudioMicMute` | Mic mute toggle | `wpctl` + private runtime trigger |
| `XF86AudioPlay/Stop/Prev/Next` | Media transport controls | `playerctl` |
| `XF86MonBrightnessUp/Down` | Brightness up/down | `brightnessctl` + private runtime trigger |
| `XF86WLAN` / `Mod+F8` / `F8` | Toggle airplane mode (wifi + bluetooth) | bounded `toggle-airplane.sh` helper |
| `XF86Bluetooth` / `Mod+F10` / `F10` | Toggle bluetooth power | bounded `toggle-bluetooth.sh` helper |

Keyboard backlight brightness is controlled by the ThinkPad EC firmware directly (`Fn+Space`), not by a Niri bind — `OsdOverlay.qml` polls the sysfs LED brightness file to show its OSD.

`playerctl` is only needed when a keyboard exposes the optional XF86 media-key bindings. It is not required by the Quickshell MPRIS popup or its on-screen controls.

### External Triggers

Any script or keybinding can trigger Quickshell actions by creating these files under `$XDG_RUNTIME_DIR/quickshell`:

- `$XDG_RUNTIME_DIR/quickshell/qslauncher-trigger` — toggles the launcher popup
- `$XDG_RUNTIME_DIR/quickshell/qsquickmenu-trigger` — toggles the power menu
- `$XDG_RUNTIME_DIR/quickshell/qssettings-trigger` — toggles the Settings popup
- `$XDG_RUNTIME_DIR/quickshell/qscommandcenter-trigger` — legacy alias for the Settings popup
- `$XDG_RUNTIME_DIR/quickshell/qslock-trigger` — activates the lock screen
- `$XDG_RUNTIME_DIR/quickshell/qsosd-vol` / `qsosd-bright` / `qsosd-mic` / `qsosd-airplane` / `qsosd-bluetooth` — show the corresponding OSD

When `XDG_RUNTIME_DIR` is unavailable, Quickshell uses
`~/.cache/quickshell/runtime` instead. The directory is created with mode
`0700`.

`bar/FileTrigger.qml` watches the private runtime directory with a single persistent `inotifywait` process (zero CPU while idle, one watcher for every registered trigger) and dispatches to the matching `IpcHandler` method or `OsdOverlay.show()` call. Any trigger file already present on startup fires immediately. Triggers can also be invoked directly via `quickshell ipc call shell <name>`.

## IPC

`shell.qml` defines an `IpcHandler` with `target: "shell"` exposing:

- `ipc.launcher()` — toggle launcher popup
- `ipc.lock()` — activate lock screen
- `ipc.quickmenu()` — toggle power menu
- `ipc.settings()` — toggle Settings popup
- `ipc.commandcenter()` — legacy alias for `ipc.settings()`
- `ipc.layout()` — toggle bar orientation
- `ipc.popup(name)`: toggle a popup by route (`audio`, `brightness`, `media`, `weather`, `llm`, `battery`, `notification`, `calendar`, `quickmenu`, `launcher`, `sidebar`, `networks`, `alarms`); `false` for an unknown name
- `ipc.settingsTab(n)`: dev/testing: select Settings tab `n` (0-9: Account, General, Appearance, Display & Input, Bluetooth, Media, Lock & Power, Notifications, System, Shortcuts) in memory
- `ipc.forgetPrompt(name)`: dev/testing: open the networks window with the "forget <name>?" row shown (never forgets by itself); `""` clears the row

- `ipc.alarmState()`: dev/testing: pending alarms as JSON (`count`, `loaded`, `lastRung`, `alarms`)
- `ipc.alarmAdd(minutes, label)`: dev/testing: schedule a real alarm `minutes` from now (fractions allowed); returns the count
- `ipc.alarmRemove(index)`: dev/testing: delete the alarm at sorted position `index`
- `ipc.openSidebarPage(n)`: bottom-bar page toggle: opens the sidebar at page `n` (clamped to the pages that exist), closes it when that page is already open, switches otherwise; `false` while locked
- `ipc.bottomBarState()`: dev/testing: bottom bar inputs as JSON (`items`, `clockText`, `dateText`, `volume`, `muted`, `batteryPct`, `charging`, `signal`, `connected`, `vpn`, `alarmCount`, `height`, `page`)
- `ipc.dockState()`: dev/testing: dock items and window inputs as JSON (`workspaceEmpty`, `windows`, `items`)

Callable externally via `quickshell ipc call shell launcher` (and similarly for the others).

### Launcher providers

The launcher keeps provider selection explicit so the normal app search stays uncluttered:

- `>` opens shell actions, including full-screen and region capture. Captures are saved under `~/Pictures/Screenshots` and copied to the clipboard when `wl-copy` is available.
- `;` opens clipboard history from `cliphist`. Enter restores the selected entry, the trailing delete button removes one entry, and `Clear clipboard history` requires a second confirmation activation before wiping all entries.
- `@` searches wallpapers from `~/Pictures/Walls`.

Clipboard previews are shown only after opening the provider. The enabled `clipboard-history.service` records new text through `scripts/clipboard-history-capture`. Clipboard history can contain passwords, tokens, and private messages; use the clear action when that history should be removed.

App discovery follows XDG desktop-file precedence: a user `Hidden=true` entry masks the matching system entry, `TryExec` entries appear only when their executable is available, and edits to desktop files invalidate the private launcher cache.

## Lock Screen

On Niri, `bar/LockScreen.qml` provides the themed lock surface using
`WlSessionLock`. Mango uses `swaylock -f` for a compositor-enforced session
lock; the Quickshell layer-shell overlay is not used as a security boundary.
The Niri lock surface includes:

- **PAM password auth** via `Quickshell.Services.Pam`
- **Fingerprint reader** via `fprintd-verify` (auto-retries on failure), started/stopped imperatively in `onLockedChanged` to avoid QML declarative binding breaks
- **Her look**: `bar/powermenu/LockSurfaceContent.qml` on both surfaces (the `WlSessionLockSurface` and the non-Niri layer-shell fallback): opaque `surface` backdrop, the power menu content in locked mode (no buttons), a lock symbol ring and the "[ L O C K D O W N ]" terminal line showing the masked input in x1. The ring border follows the last key: cleared x0 (`outlineVariant`), each insert cycles x1, x3, x2, x6, x4, x5 by length, delete alternates x8 and `outline` 0.3. A failed authentication swaps the ring glyph until the next key. The content fades in over 1.2 s (instant under Reduced Motion). A hidden password field keeps keyboard focus; Enter runs PAM.
- No wallpaper, clock, date, media, avatar or power buttons on the lock surface; their settings (`lockClockSize`, `lockShowMedia`, `lockUseWallpaper`) are gone and stale keys in `settings.json` are ignored on load.
- **Lock & Power settings** configure automatic lock and suspend timeouts plus TLP power profiles; the existing dim/display-off stages remain fixed, and suspend locks first
- Lock requests are available through `IpcHandler.lock()`, `scripts/lock`, or the private runtime trigger; Mango routes them to `swaylock`

Niri starts an independent swayidle before-sleep watcher. It remains active
when Caffeine pauses the idle timeout watcher, and the lock helper waits for
WlSessionLock to report that every output is covered before returning.

The panel's compositor-lock gate observes `WlSessionLock.secure` before
`locked`: Quickshell 0.3.2 can omit the `locked` change notification on
unlock, leaving a `locked`-only binding stale and the panel hidden until a
manual restart. File watching remains disabled while the lock is active.

## Popup System

Popup visibility is driven entirely by the bar's `openPopup` string property, held on `Bar.qml` and read by `shell.qml`. Each indicator widget signals a popup name, and the corresponding popup shows/hides accordingly.

Popup positioning follows the active bar placement (computed in `shell.qml`'s `popupMarginLeft`/`popupMarginTop`):
- **Top/bottom**: Anchored past the bar edge and horizontally centered on the clicked widget's X coordinate, clamped to fit the screen.
- **Left/right**: Anchored past the bar edge and vertically aligned to the triggering widget's Y coordinate.

All bar-owned popups, the shield, Settings, notifications, and power confirmation use the bar's display. Placement and wallpaper-launcher sizing are clamped in that display's local coordinates rather than the primary monitor's dimensions.

Escape or clicking outside (on another window) dismisses the active popup. All popups use `WlrLayer.Top` and `PopupShield` sits on `WlrLayer.Bottom` to intercept outside clicks. `FocusDismiss` arms dismissal after the popup acquires focus, ignoring initial inactive/null-focus events while it maps. The popup content uses a `FocusScope` so moving between controls or disabling a focused refresh button does not dismiss it; genuine focus loss is rechecked on the next event-loop turn. The full-page Settings surface remains open through Mango's transient layer-focus changes so switching tags or clients does not dismiss it. `PopupBase.qml` supplies the shared background/border/entry-animation chrome that most popups build on; backdrop effects remain compositor-owned.

| Popup | Trigger | Content |
|---|---|---|
| Launcher | `Launcher` button / `Mod+D` | App/provider search (`>` actions and capture, `;` clipboard history, `@` wallpapers) + `.desktop` list |
| Audio | `qs ipc call shell popup audio` | Volume + mic sliders (Elena switches; active check = sound enabled, unchecked = muted). Pointer adjustments do not leave a focus outline; keyboard focus stays visible while adjusting and resets when the popup closes. |
| Brightness | `qs ipc call shell popup brightness` | Brightness slider (shared bordered surface) |
| Battery | `qs ipc call shell popup battery` | Percentage, energy capacity, status, rate, cycles, model (shared bordered surface) |
| LLM usage | Themed LLM indicator / `qs ipc call shell popup llm` | Codex and Claude five-hour/weekly usage, reset countdowns, available reset credits, and per-provider refresh |
| Calendar | `qs ipc call shell popup calendar` | Month grid with navigation (shared bordered surface) |
| Notifications | `qs ipc call shell popup notification` | Dashed history cards with timestamp, live actions and dismiss/remove controls |
| Power Menu | bottom-bar logout / `Mod+Escape` | Full-screen overlay: greeting, quote, palette; poweroff, reboot, exit (confirmed), hibernate, suspend, lock |
| Networks | Bottom-bar network button / `qs ipc call shell popup networks` | Her networks window: Wi-Fi list, connect/disconnect/forget, bandwidth, vpn, scan, speedtest, ping (see Networks window (R4)) |
| Alarms | Bottom-bar alarm button / `qs ipc call shell popup alarms` | Her alarms window: ring in / ring at, browse and delete, real scheduling (see Alarms window (R5)) |
| Settings | `XF86Tools` | 10 tabs: Account, General, Appearance, Display & Input, Bluetooth, Media, Lock & Power, Notifications, System, Shortcuts (responsive surface with persisted last tab, drag-to-move, and resize handle) |
| OSD | volume/brightness/mic/airplane/bluetooth/kbd-backlight keys | Auto-dismissing bottom-anchored status card (not part of the `openPopup` system — a separate always-on-top window) |

## Configuration

### `config/Config.qml`

Build-time layout, typography, shape and motion tokens: the 8px workspace strip, type sizes, independent clock typography, spacing, 8/12/20px shapes, motion durations (zeroed under Reduced Motion), popup dimensions, Settings bounds and audio/brightness step sizes. The shell has one UI style; colors remain independently configurable.

Popup and toast entrances retain the existing Elena spatial springs. Workspace selection keeps its own spring damping, and Reduced Motion suppresses spatial transitions.

Named text roles use the existing 12px UI-size baseline (body medium 14px, body large 16px, title large 22px). Font sizes and line heights scale with the general font-size preference. Settings rows grow and wrap rather than clipping.

Icon buttons and switches reserve 48px minimum input targets independently of visual size. The switch track is a 58×30 pill; sliders are level-fill tiles; selected icon buttons use a white round badge. Switch-bearing Settings rows activate from the label or Enter/Space, honor disabled/busy controls and do not double-activate a direct switch click.

Shared icon and action-button tooltips appear only while their control is visible and enabled. Hiding a control also hides its tooltip, so clearing notification history does not leave a hint covering the empty-state message.

Control-color effects retain the existing non-overshooting RGBA springs. Reduced Motion snaps color effects, including in-flight transitions, and removes spatial entrances.


### Codex and Claude subscription usage

One angular-sparkle indicator opens a single **LLM usage** popup with Codex and Claude sections. It uses the shared indicator color, input target, keyboard activation, loading spinner, tooltip and error badge.

Usage bars and media progress use the single wave renderer. Normal usage uses the semantic primary accent; usage at or above 90% retains the error color. Quota values and reset times are independent of palette choices.

`scripts/codex-usage.py` reads the existing OAuth sign-in from `$CODEX_HOME/auth.json`, or `~/.codex/auth.json` when unset. Sign in with `codex login`; API keys cannot report ChatGPT-plan Codex quota. The helper calls OpenAI's `wham/usage` and `wham/rate-limit-reset-credits` endpoints using Python's standard library. These account endpoints can change independently of the public API. Credentials are not passed through QML, written to settings, logged, refreshed, or modified. The helper emits quota data only, without account identifiers.

`scripts/claude-usage.py` reads the existing Claude Code OAuth sign-in from `$CLAUDE_CONFIG_DIR/.credentials.json`, or `~/.claude/.credentials.json` when unset. The sign-in needs `user:profile` scope; an inference-only token or API key is not a subscription reporting credential. It reads Anthropic's OAuth usage endpoint with the optional `cedar_ember` reset inventory. Reset eligibility requires a supported installed Claude Code version: the helper runs only `claude --version` to identify that version, never an interactive session or login. Missing or ineligible inventory remains unavailable. Supported, active, unpaused grants contribute their remaining resets; exhausted, future, and expired grants do not.

Codex polls every five minutes and Claude every 15 minutes while the single indicator or popup is visible; opening the popup reuses readings or failed attempts younger than that provider's polling interval. Each section's refresh button only refreshes that provider. Scheduled polling makes at most 12 Codex refreshes and four Claude refreshes per hour, with two OpenAI reads per Codex refresh and one Anthropic read per Claude refresh. These are account endpoints, not public reporting APIs with a guaranteed polling allowance. A Claude HTTP 429 starts a cooldown of at least five minutes, honoring longer `Retry-After` delays in seconds or HTTP-date form; automatic and manual refreshes are blocked until it expires, and the section shows a countdown. Provider failures are independent: a failed refresh retains its usage as explicitly **stale**, but clears its reset inventory. The indicator's red `!` means a provider failed or has stale data, including failures before its first successful reading. Missing windows or unreadable reset inventory show **Unavailable**, not zero; valid empty inventory shows zero. Expired cached inventory is hidden until refreshed. `ccShowLlm` controls visibility; the `llm` entry in `barWidgetOrder` controls placement. Former `codex` and `claude` entries collapse to `llm` at the first saved provider position without reordering other widgets. The old visibility preferences migrate to one toggle, enabled if either provider was enabled.

Successful readings become stale only after twice the provider's polling interval: over 10 minutes for Codex or 30 minutes for Claude. Refresh errors still warn immediately. Run `scripts/test-llm-usage.sh` for isolated native Quickshell regression checks of freshness boundaries and errors; it makes no account requests.

### `config/Settings.qml`

Persisted user preferences singleton (`FileView` + `JsonAdapter` over `~/.config/quickshell/settings.json`, created on first run if missing). It owns layout preferences, motion, clock/calendar/timezone, indicator settings, workspaces, palette/contrast/accent, dock pins, notifications, idle timeouts and weather. Obsolete style-selector, variant, compact-density, transparency, alternate-clock and lock-look (`lockClockSize`, `lockShowMedia`, `lockUseWallpaper`) keys are ignored on load and omitted when settings are next saved. The persisted format remains `schemaVersion: 2`; the existing combined LLM-widget migration is unchanged. Preferences update through `watchChanges: true`; call `Settings.save()` after mutating a persisted value.

### `config/Colors.qml`

Semantic color roles resolve from Live Matugen or a Fixed palette in `PaletteCatalog.js`. Elenapan remains a fixed family alongside Catppuccin, Gruvbox and TokyoNight. Material role names are Matugen data vocabulary, not a remaining Material UI implementation. Color strings are converted before applying alpha, and contrast remains independent of palette source.

Format: `l_<token>` (light), `d_<token>` (dark), and flat resolved `<token>` properties (no prefix) for current mode. Text/icon colors are prefixed with `fg` (e.g. `fgSurface`, `fgPrimary`) to prevent conflicts with QML's internal signal handler compiler rules.

System dark mode is read once and monitored through `gsettings` (owned by `Colors.qml` itself, since it's the single instance everyone reads from). Mode toggles in the launcher or Settings call the existing desktop mode synchronizer, while the shell selects the matching Matugen light/dark roles locally.

Auto/Light/Dark controls the color mode; Live/Fixed controls the source; contrast and the accent shortlist remain configurable. Appearance has no style chooser or revert-style action.

The desktop companion scripts install and synchronize only the existing palette-driven GTK, icon, Qt and light/dark SDDM assets. Their external project and asset names still contain `Material3-Expressive`; those names identify the Matugen backend, not a selectable shell UI. Nothing/Ghost terminal generation and MacTahoe synchronization are removed. Already installed assets outside this repository are not deleted.

### `bar/PopupShield.qml`

Full-screen transparent surface on `WlrLayer.Bottom` that catches clicks outside popups and dismisses them via `onShieldClicked`. The shield sits behind popups (which are on `WlrLayer.Top`) so clicks on popup content work normally while clicks outside reach the shield.

### `bar/FocusDismiss.qml`

Handles popup dismissal on app focus loss with target null checks. It observes focus acquisition on all compositors and arms dismissal only after focus enters the popup, resetting when it hides or its native window changes. On Niri and Mango, it also observes native focus loss, deferring the outside-focus check so transient changes can settle. `PopupBase` wraps its content in a `FocusScope`, preserving focus when a focused control becomes disabled. The guarded `Qt.application.activeChanged` check runs on all WMs and closes an already-focused popup when the user switches to another application.

## Widget Details

- **Wallpaper filmstrip** (`bar/WallpaperFilmstrip.qml`, layout and list helpers in `config/WallpaperFilmstrip.js`, tested by `node tests/wallpaper-filmstrip/test.mjs` and `bash tests/wallpaper-filmstrip/previews.test.sh`, `random.test.sh`, and `node tests/settings-tabs/test.mjs` for tab numbering): a full-width picker of tall leaning slices with one wide accent-bordered card and its name and date below, sized from the screen width to match a reference capture. Typing `@` in the launcher opens it (the launcher closes; text typed after `@` pre-selects the first match), and `qs ipc call shell wallpapers` toggles it directly. Left/Right, Home/End or the wheel move; typing jumps to the first name that starts with or contains the text (Backspace edits, Escape clears it, then closes); Enter or a click on the card applies through `scripts/apply-wallpaper.sh`. It reads `~/Pictures/Walls`, uses the Wallpaper tab's thumbnails for slices, starts on the current wallpaper (from `awww query`) and shows a sharp 1600 px preview on the selected card once it has rested (`scripts/generate-previews.sh`: one preview on demand if missing, plus one niced bulk run per session into `~/.cache/quickshell/wallpaper-previews`; the original is the fallback). Slices avoid `clip`, which is stencil-only and jagged under a shear, and use edge antialiasing and mipmaps. Items are placed from a fractional position (not a `ListView`, whose origin drifts as delegates load), and only a window of delegates is alive. The launcher no longer has its own wallpaper grid; `@` is only the hand-off (the Settings > Wallpaper tab keeps its grid).
- **Bar.qml**: The top workspace strip, popup routing (`openPopup`, anchors, `togglePopupByName`), the workspace data owner and the system-tray watcher. The old indicator widgets and form/order layout are removed; saved widget keys stay in `settings.json` and `config/BarForm.js` only supplies the strip geometry.
- **Clock presentation**: The bottom-bar clock shows system-local 24-hour time (`HHmm`). Seconds and timezone preferences belong to the hidden legacy clock and are no longer exposed in Settings. The retained `clock24h` preference controls notification-history timestamps, labeled “24-hour notification times” in General.
- **Calendar**: Month navigation, a circular today badge and the Sunday/Monday week-start preference remain unchanged.
- **WorkspaceIndicator**: Streams Niri (or mango) workspace state through the event stream and exposes `focusWorkspace`, `moveFocusedWindowTo` and `stepWorkspace`. It has no visuals; focused-window tracking and the mango layout symbol were removed with their only consumers.
- **Audio, brightness, media and weather services**: Event-driven watchers and polling loops are bound to the active/visible state of the bottom bar, sidebar pages and popups that use them (weather refreshes on a timer only while one is open). Audio writes for sink and microphone are serialized and coalesced during rapid slider/toggle input, with a final state read after the latest write.
- **BatteryService**: Utilizes UPower property bindings (no timers) to react directly to battery changes.
- **BtPanel**: Bluetooth controls live in the Settings Bluetooth tab, including discovery/pairing and connected-device actions. Wi-Fi lives in the networks window (bottom-bar network button).
- **SystemTrayArea**: Renders StatusNotifier items with left-click activate and right-click context menu, orientation-aware layout.
- **PowerMenu**: her powermenu as a full-screen Overlay layer with exclusive keyboard focus over a 0.7 surface backdrop. Six glyph buttons (poweroff x1, reboot x2, exit x4, hibernate x6, suspend x3, lock x5) fade in staggered; hover dims the rest to 0.3 and writes the action into the terminal line. Arrows step the 3x2 grid (`PowerMenuModel.step`), Enter acts, Esc, middle click or a click outside the buttons closes. Poweroff, reboot and exit close the menu and open the existing confirmation overlay; hibernate and suspend run `systemctl` (failures logged); lock takes the secure lock route. The QuickMenu caffeine, airplane and Bluetooth toggles are gone: Caffeine lives in Settings > Lock & Power, DND in Settings > Notifications, airplane mode and Bluetooth power stay on their keys (`XF86WLAN`/`F8`/`Mod+F8`, `XF86Bluetooth`/`F10`/`Mod+F10`), and Bluetooth devices in Settings > Bluetooth.
  Hover selection follows direct button-to-button movement; a departing button
  only clears its own selection, so its late exit cannot erase the next action.
  The menu title is `/ Y Ū G E N /`; the locked title remains `[ L O C K D O W N ]`.
  A single seated cat is traced from the supplied reference and rendered as
  themed vector strokes, without mixed-script font dependencies. Its relaxed
  eyes become `> <` on hover; pixel checks verify that the entire body stays
  unchanged. The mascot is 96 × 104 px at the current scale. Both menu frames
  share one content-driven height, keeping their top and bottom edges aligned.
- **Launcher**: App/action/clipboard search uses her rofi layout (R6c): centered, half the screen wide (min `dp(560)`), a solid 6 S x0 border with 12 S radius, an input bar with her prompt glyph in x1, a message bar with provider/count/keys, and eight fixed lines with the selected row in x0 and x4 text. Ctrl+F returns to search, arrows, Ctrl+N/P, Alt+J/K and Tab select results, Enter, Ctrl+M, Alt+M, Alt+A or a click activates. Right-click or Shift+F10/Menu exposes opening, copying parsed POSIX-shell-quoted application arguments, or deleting a clipboard entry; Escape closes the context menu before dismissing. `@` still hands off to the wallpaper filmstrip. Speech recognition, its microphone button, recording/transcription processes and helper are removed; system packages and downloaded models outside the repo are untouched.
- **Settings**: Provides ten tabs, remembers the last selected tab, and keeps Bluetooth Settings-only. The QuickMenu Settings tile was dropped with the QuickMenu and the Network tab with R4; reach Settings from `XF86Tools`. The panel moves from its header and resizes from the bottom-right corner, with a 560px minimum width and a maximum height bounded by screen margins. Sidebar navigation scrolls on overflow without a visible scrollbar; keyboard navigation brings the selected tab into view. Search prioritizes control titles, reports result counts or an empty state, and opens and highlights matching controls.
- **Settings presentation**: Defaults to 1100×900 when no saved size exists, can expand to 1440px, and bounds the navigation pane and page width. General sections become side-by-side above 800px and stack below. Narrow labels elide with tooltips; rows wrap and grow. Ctrl+F searches from any control, without stealing content editing/navigation keys.
- **Settings support**: Retired hidden-bar visibility/order, placement/form, workspace count/marker, bar/clock size, coupled Bar Scale, seconds and timezone controls are removed along with their search entries. Font, icon and spacing controls remain independently available under **Interface sizing** and do not resize the fixed 8px workspace strip or 48px bottom bar. Legacy saved keys and hidden service owners are intentionally retained; this UI cleanup does not rewrite personal preferences or implement R5/R6.
- **ActionButton**: Label-only buttons reserve no icon height or icon-to-label spacing; compact Settings actions retain centered labels.
- **Weather**: Uses a configured manual location by default, optionally supports IP geolocation, refreshes on the persisted interval and reports the last update time. Refreshes coalesce rather than aborting an active fetch; invalid responses and command failures appear as popup errors.
- **Notifications**: History keeps dashed rounded framing and monospace metadata; toasts follow her dunst look (R6b, below). DND/quiet hours suppress toasts without discarding history; critical bypass, placement and retention stay persisted. Default/named actions and closed-entry behavior remain. Named toast actions capture the owner before invocation because an action can synchronously close its notification and destroy the button delegate.
- **Dark Mode Preference**: Event-driven tracking via a one-time startup query (`gsettings get`) and a continuous background monitor (`gsettings monitor`) with a `SplitParser` listener, saving CPU cycles. Because `Colors.qml` hot-reloads reset `systemDark` to its template default, a polling re-query runs in `shell.qml` after reloads.
- **Palette ownership**: Live comes from wallpaper-driven Matugen; Fixed comes from `PaletteCatalog.js`. `sync-active-palette.sh` activates separate source caches and refreshes the generated companions. Wallpaper changes still refresh Live while Fixed is selected. SDDM updates remain explicit.
- **Deployment**: `scripts/install-ui-suite.sh` installs only the palette-driven Matugen companions and optional light/dark greeters. Use `--dry-run` or `--skip-sddm`; `verify-ui-suite.sh` checks the matching assets. Existing outside-tree themes are untouched. Installing the updated SDDM bridge requires an explicit privileged action; no system installation is performed by the cutover.
- **Appearance**: Palette, accent, contrast, wallpaper, dock pins, power menu quote and author line (`powerMenuQuote`, default "Take a breath."; `powerMenuQuoteAuthor`, empty hides the line), shared interface sizing and confirmed reset remain. Removed styles and retired bar preferences have no picker, preview or search entry.
- **Display & Input tab**: Reads and safely edits Niri output, input, and edge-gesture settings through the validated `scripts.niri_config` CLI. Remote controls only read while their Settings page is active.
- **Wallpaper thumbnails**: `scripts/generate-thumbnails.sh` produces 200×130 center-cropped thumbnails under `~/.cache/quickshell/wallpaper-thumbs`, regenerating only when the source is newer, with bounded concurrency, atomic publishing and a nonzero exit status on failure. The filmstrip runs it, then `scripts/generate-previews.sh`, once per shell session at low priority. There is no Wallpaper tab: choose from Appearance, the launcher's `@`, or `qs ipc call shell wallpapers`; `qs ipc call shell randomWallpaper` (and Ctrl+R in the filmstrip) applies a random one through `scripts/random-wallpaper.sh`.
- **Lock & Power**: Owns idle lock/suspend timeouts, Caffeine and automatic AC/battery power-profile restoration.
- **Media tab**: Owns media artwork, progress, and always-visible-control preferences for the media popup.
- **Media / MPRIS**: `scripts/mpris_monitor.py` broadcasts the active player's state as newline-delimited JSON over stdout (consumed via `SplitParser`), and also listens on a private runtime named pipe for out-of-band pokes. `scripts/mpris_control.py` sends play/pause/next/prev to whichever player is currently active (preferring a "Playing" one); the visualizer is available in the Settings media controls.
- **OSD**: A separate centered icon/value surface, outside the popup state machine. Continuous readings show a meter; mic, airplane, Bluetooth and muted volume show status instead. It auto-hides after 1.5s and polls sysfs for ThinkPad keyboard backlight changes.
- **Lock Screen Security**: Employs imperative start/stop handlers in `onLockedChanged` for `fprintdProcess` to prevent QML declarative property binding breaks.

## Dependencies

- **Quickshell** — the shell framework
- **Qt6** (QtQuick, QtWayland)
- **Niri** — compositor, workspace/window state, actions, and shell integration
- **Python 3** — for `.desktop` parsing, weather and MPRIS
- **python-dbus** / **PyGObject** — MPRIS monitoring and control
- **wpctl** (WirePlumber) — audio control
- **playerctl** — media transport keys
- **brightnessctl** — backlight and keyboard-LED control
- **UPower** — battery monitoring
- **fprintd** — fingerprint authentication
- **nmcli**, **bluetoothctl**: the networks window, the Bluetooth tab, airplane mode and OSD; nmcli also feeds the bottom bar's Wi-Fi signal and VPN state (`nmcli monitor` plus a cached-scan poll)
- **lm-sensors** (`sensors`) — optional thermal and fan readings in the System tab
- **jq**: parses `sensors -j` output for System diagnostics, and picks the pavucontrol window to focus from the bottom bar's media button
- **pavucontrol**: opened (or focused) by a right click on the bottom bar's media button
- **ImageMagick** (`magick`/`convert`) — wallpaper thumbnail generation
- **Matugen** — wallpaper-derived Material You palette generation
- **awww** — wallpaper daemon
- **cava** — real-time audio visualizer (raw ASCII output consumed by the media popup visualizer)
- **swayidle** — idle timeout handling (dim/lock/DPMS/suspend), configured by Lock & Power settings
- **inotify-tools** (`inotifywait`) — trigger-file and brightness-file watching
- **cliphist**, **wl-clipboard** (`wl-copy`) — clipboard history provider and restore/capture copy
- **grim**, **slurp**, **libnotify** (`notify-send`) — full-screen/region capture feedback

---

## Disclaimer

This theme suite and shell configuration was generated and vibe-coded using **Antigravity**, an AI agentic coding assistant designed by the Google DeepMind team.

---

## License

This project is licensed under the terms of the GNU General Public License v3.0 (GPL-3.0). See the [LICENSE](file:///home/mura/.config/quickshell/LICENSE) file for details.

## Control golden test

`scripts/controls-golden.sh <root> <out>` renders only Elena controls under
a throwaway `$HOME` (`tests/controls-golden/shell.qml`).
`scripts/controls-golden-baseline.sh` wraps it:

- `update` renders the current tree and replaces the baseline.
- `check` compares only `elena.png` and fails above 40 differing pixels. Historical other-style images are ignored.

The baseline lives outside the repo, in `~/.local/state/quickshell-golden/controls`
(override with `QS_GOLDEN_DIR`), because fonts and Qt version change pixels per
machine. Run `update` on a clean tree first, then `check` after a control
change. After a deliberate visual change, review the result and run `update`.

## Control behaviour test

`scripts/controls-behavior.sh` runs the Elena QtTest contract: keyboard and
mouse activation, disabled inputs, switch-row activation, slider keys, hover,
reduced motion and tooltip visibility. Input, focus and accessibility live in
`bar/controls/*Base.qml`; adjacent `Elena*` implementations supply the visuals.
Muted level tiles show clipped diagonal stripes instead of an active fill;
unmuting restores the existing level. The render check covers both states and
the rounded corners.
`controls-render.sh`, `sidebar-render.sh`, `bottom-bar-render.sh` and
`tag-strip-render.sh` provide isolated Elenapan-palette pixel checks.
`config-dump.sh check` compares the original role/token oracle, allowing only
explicitly removed properties and the intended shape change. Its legacy-key
fixture proves stale settings cannot activate a removed style or density.

After QML cutovers, cold-restart Quickshell before live IPC verification:
`systemctl --user restart quickshell.service`. Launcher and session/power
presentation redesigns are implemented, including notification history and toasts.
Bindings, confirmation execution and authentication remain unchanged.

## Bottom bar

`bar/BottomBar.qml` is a full-width layer-shell window on the Top layer,
anchored to the bottom. It reserves 48 px (`Config.bottomBarHeight`),
so windows tile above it, and stays screen-fixed during workspace transitions
and overview rather than moving with each workspace preview.
`Config.bottomBarScale = 48 / 43` and `Config.bottomBarDp()` size only its
content: side clusters are 335 px wide, button icons 18 px, dock icons 24 px
and value pills 26 px tall. Sidebar, networks and power-menu sizing remains
on the separate `elenaScale = 1.5`; their bottom offsets follow the bar height.
It shows while the top bar is visible and the session is unlocked. The
content (`bar/bottombar/BottomBarContent.qml`) has three parts:

- **Left cluster**: glance (clock pill) opens the sidebar at Home, right
  click toggles the launcher; tasks (date pill) opens the sidebar at
  Agenda; media (volume ring) opens it at Media. Click, middle click mutes,
  the wheel steps `Config.volumeStep` % per full notch, right click focuses a
  running pavucontrol or starts one. Page buttons toggle: the open page
  closes the sidebar, another page switches (`BottomBarModel.sidebarToggle`).
- **Dock** (center): pinned apps (Settings > Appearance > dock pins) always
  appear; running apps follow. Glyphs come from `config/DockSymbols.js`.
  Click focuses or launches, middle click closes, the wheel cycles windows
  one per notch.
- **Right cluster**: network (VPN shield or link, then four signal bars),
  alarms (count pill or a slash), battery (three parts and a charging bolt).

The network button toggles her networks window (R4), the alarm button her
alarms window (R5), logout the power menu (R3). The sidebar and bottom-right toasts
leave the bar's height free so its buttons stay clickable.

**Fonts.** The icons come from her icomoon font set in
`~/.local/share/fonts/icomoon`. Four files there share the family `icomoon`
and repeat codepoints, so the fontconfig rule
`~/.config/fontconfig/conf.d/61-elena-icons.conf` renames three of them to
`ElenaIcons1`/`2`/`3` (icomoon-feather.ttf, remix.ttf, iconic.ttf) and
appends 2 and 3 to any request for `ElenaIcons1`; Qt then falls back per
glyph like her Pango setup. After installing the fonts or editing the rule run
`fc-cache -f ~/.local/share/fonts/icomoon`. Side effect: a request for the
family `icomoon` now only reaches icomoon_Regular.ttf. The clock and date
pills use her text font Kyok (`Kyok medium`) when installed, else the shell
font; her text fonts (Kyok, Baro, BattleAndy) come from the font zip linked in
her dotfiles README.

Checks: `node tests/bottom-bar/*.mjs` (pure model, dock symbols, structural
wiring), `bash scripts/bottom-bar-render.sh` (pixel checks of the content
under the Elenapan palette, and the pill font), `bash scripts/bar-font-check.sh`
(every icon codepoint the bar and dock use, read from `BottomBarContent.qml`
and `DockSymbols.js`, must render from the file Pango would pick; fails when
the ElenaIcons families are missing), and `scripts/popup-ipc-check.sh` for the
live `openSidebarPage` toggle.

## Sidebar (R2)

`bar/Sidebar.qml` is a `dp(300)` wide overlay anchored to the left and bottom
screen edges, `dp(7)` above the bottom bar, as tall as its pages and the page
indicators (`dp(554) + dp(106)`, capped to the free height). Left corners are
square, right corners round `dp(20)`, no outline. It reuses the shared popup
entry (scale, slide and fade from the left edge; instant under reduced
motion). Three pages:

- **Home** (0): clock, Sunday-first weekday strip, weather pill, a 3x3 grid of
  tiles (volume and brightness drag to set; battery, CPU, temperature, RAM,
  swap, disk, network) and a hostname/uptime chip.
- **Agenda** (1): month grid (week start follows Settings), month and year
  arrows, and the task list (empty until a task feed exists).
- **Media** (2): cover art with a progress ring, title and artist, a 20-cell
  seek line, play/pause, previous/next, stop, volume (system and player) and
  favorite. Favorite appends `artist - title` to `~/Music/playlists/songs`.

Open it with the bottom bar's glance, tasks or media button (page 0, 1, 2),
`Mod+Shift+D`, or by resting the pointer on the left screen edge for 120 ms
(`bar/SidebarActivator.qml`, a 1 px layer-shell strip). The edge opens the page
last shown, never closes an open sidebar, and ignores hovers within 300 ms of
the sidebar closing (Esc or a middle click with the pointer on the edge). Turn it off with Settings >
Appearance > Open sidebar at the left screen edge (`Settings.sidebarEdgeHover`,
default on). The strip stops short of the top strip and the bottom bar. The
edge is off while the session is locked. niri reports no fullscreen flag, so
there is no fullscreen gate; niri draws fullscreen windows above the Top layer,
so the strip sits under them anyway.

Close it with the open page's bar button, Esc, a middle click on the panel, or a
click outside. Ctrl+PageUp/PageDown and the wheel over the page dots step pages
(clamped, no wrap); clicking a dot selects its page.

Metrics (`config/SystemMetricsService.qml`, polled every 2 s only while Home is
shown): CPU from `/proc/stat` deltas, RAM and swap from `/proc/meminfo`,
network rate from `/proc/net/dev`, uptime from `/proc/uptime`, hostname from
`/etc/hostname`, disk from `df -P /`, temperature from
`/sys/class/thermal/thermal_zone*/temp`. Volume comes from `AudioService`,
brightness from `BrightnessService`, battery from `BatteryService`, weather from
`WeatherService`. Home holds the metrics, weather, audio and brightness services
active while it is shown; other consumers (the bottom bar, the media indicator,
the wave) may keep audio and media running, and battery is always live. The
Media page's position is polled once a second (`mpris_control.py position`)
only while that page is open and a player is Playing; the MPRIS monitor itself
reports position only on state changes and seeks. Hovering a seek line
highlights it.

Checks: `node tests/sidebar/*.mjs` (metric parsing, page stepping, month grid,
media math, structural wiring of the window, activator and shell) and
`bash scripts/sidebar-render.sh` (pixel checks of every page and the
indicators, keyboard and wheel paging, seek clicks). `KEEP_PNG=/tmp/sidebar.png`
keeps the render. Specification:
`docs/superpowers/specs/2026-10-13-elena-sidebar-pages-r2-design.md`.

## Networks window (R4)

`bar/NetworksWindow.qml` is her networks window: a `dp(300)` wide Overlay
layer anchored to the right and bottom edges, `dp(10)` above the bottom bar,
left corners `dp(20)`, no reserved space, keyboard focus on demand while
open. The bottom bar's network button toggles it (route `"networks"`); Esc,
a middle click, a click outside (the popup shield) or focus moving to another
window close it. The Settings Network tab and the old Wi-Fi panel are gone; this
window is the only Wi-Fi UI.
Its layer namespace is `quickshell-popup-networks`, matching the compositor's
existing no-blur popup rule so transparent corners do not expose a rectangular
blur patch. The IPC route remains `"networks"`.

Settings persists a numeric `lastSettingsTab`, clamped to the current 0-9 range,
not a page identity. Removing Network shifts the later pages: saved index 4 now
opens Bluetooth. Existing values are not automatically migrated or reset.
The removed Wi-Fi power toggle and per-network autoconnect controls are not
replaced in this window; `XF86WLAN` still toggles airplane mode.

- **List** (4 rows of `dp(60)`, scrolls): a `dp(6)` left border by signal
  (>= 75 and >= 50 x4, >= 25 x3, else x8; dotted, solid on the connected row),
  a saved/new type disc, the name cut at 22 characters (19 + "...") and
  further elided to the available width before the action buttons, and
  forget (x3, saved), disconnect (x1, connected) or connect (x2). Empty:
  a symbol and "No networks found".
- **Connect**: saved or open networks connect at once; a new secured one opens
  an inline masked passphrase row (Enter connects, Esc cancels; the text is
  cleared whenever the row hides). Forget asks yes/no inline; its prompt
  elides before the confirmation buttons. Failures run
  `notify-send -u low Networks "Could not connect to <name>"` (or disconnect,
  forget).
- **Bandwidth**: down x1 and up x2 in MB/s from `SystemMetricsService` (all
  interfaces). The service runs while the sidebar Home page or this window
  wants it (`sidebarActive || networksActive`).
- **Toolbar**: vpn on/off (opens `nm-connection-editor`), scan (`nmcli dev
  wifi rescan` plus 5 list polls 1 s apart, count of nets), speedtest
  (`xdg-open https://www.speedtest.net`), ping (`ping -c 10 -w 30 1.1.1.1`
  streamed: `NNms`, the average, `dc` when unreachable).

`config/NetworkListService.qml` runs every nmcli process through
`commandFor(kind, args)` and polls only while the window is shown. It lists
on open and during a scan with nmcli's default rescan, and on `nmcli monitor`
events, after an action and on the 10 s fallback poll with `--rescan no`
(NM's cache). The connect, disconnect and forget commands are the old
Settings Wi-Fi panel ones, byte for byte.

Checks: `node --test tests/networks/*.test.mjs` (parsers, buckets, wiring, Settings
tab removal) and `bash scripts/networks-render.sh` (rows, empty state,
bandwidth, toolbar and passphrase pixels, long-name elision, keys and clicks,
and the service against fixture nmcli output; connect, disconnect and forget never run for
real). Dev IPC: `qs ipc call shell popup networks`, `qs ipc call shell
forgetPrompt <name>`. Specification:
`docs/superpowers/specs/2026-10-14-elena-networks-r4-design.md`.

## Memory notes

Measured 2026-10-14 on a fresh shell with the R1 to R7 surfaces: opening and
closing each popup 25 times moves anonymous memory by less than 2 MB either way
(no per-open leak; the sidebar's first open adds about 20 MB once). **Hot reload
inflates the process**: the first file save adds about 19 MB and each further
save a few MB (7 saves: 174 to 199 MB), so a session spent editing is not
evidence of a leak; restart `quickshell.service` after editing. Idle sessions
were flat (PID 1647: 434 to 442 MB over 10.7 h after warm-up).
`qs-rss-monitor.service` logs every 2 minutes to `~/.cache/qs-rss/progress.log`;
`python3 scripts/qs-rss-report.py` fits MB/hour per PID after a 10 minute
warm-up and exits 1 on growth above 5 MB/h over at least an hour
(`python3 scripts/tests/test_qs_rss_report.py` is its gate).

## Microphone tab, toasts and launcher (R6)

**Microphone tab** (`bar/MicIndicator.qml`, `config/MicService.qml`): an 18 S by
10 S tab at the top center, square top and round bottom. Live mic is x1 at full
opacity, muted is x8 at 0.4. Click toggles the default source's mute, middle
click hides it until the mute state changes. One `pactl subscribe` reader
(source events only) runs while Settings > Appearance > Microphone indicator is
on; a change of default source posts a low "Recording device" notice. Namespace
`quickshell-popup-mic`.

**Toasts** (`bar/NotificationToast.qml`, `config/ToastModel.js`): top right, 20 S
offsets; card `xbg` in an 8 S x0 frame, 18 S radius. Row one is the heart glyph
(U+E944) in the urgency color (low x6, normal x2, critical x1) and the summary;
row two the arrow glyph (U+E90D) in x8 and the body. At most five cards; the same
app, summary and body stack into one with `(N)`. Timeouts: the app's own value
(Quickshell reports milliseconds) wins; unset means low 3 s, normal 8 s
(`notificationToastDurationMs`, migrated from the old 5 s default once), critical
sticky. Left click closes, middle click runs the default action then closes,
right click closes every card; action buttons stay. Delivery, history, DND and
quiet hours are unchanged, and dropped cards remain in history.

**Launcher** (`bar/LauncherPopup.qml`, `config/LauncherLayout.js`): see the
Launcher entry above; providers, ranking, `>`, `;` and `@` are unchanged.

Checks: `node tests/r6/*.test.mjs` (mic parsers, toast rules, launcher geometry,
wiring) and `bash scripts/r6-render.sh` (mic service against fixture pactl,
tab pixels, toast urgency colors, clicks, duplicates, limit, expiry; mutation
proven). The launcher is verified live. Specification:
`docs/superpowers/specs/2026-10-14-elena-r6-indicators-notifications-launcher-design.md`.

## Alarms window (R5)

`bar/AlarmsWindow.qml` is her alarms window: a `dp(300)` Overlay anchored
right and bottom above the bottom bar (route `"alarms"`, namespace
`quickshell-popup-alarms`, covered by the popup no-blur rule). The bar's alarm
button toggles it; Esc (a time entry first), middle click, click outside, focus
loss and the button dismiss it.

- **Left column**: "ring in" (quick) and "ring at" (standard) buttons around an
  expanding cancel/confirm row. **Quick** steps +1 +5 +10 +60 minutes from now.
  **Standard** steps -h +h -m +m to the next occurrence of HH:MM (tomorrow if
  past). Both accept typed digits (hours up to 23, minutes up to 59), Tab and
  Shift+Tab cycle hours, minutes and the 16-character label, Backspace and
  Ctrl+Backspace edit, Enter confirms, Esc cancels. The mouse wheel over the
  hour or minute steps by 60 or 1; as in her script, wheel up steps back.
- **Browse**: previous, delete, next move through pending alarms, soonest first;
  "no alarms" and "all clear" when empty. Default label is `beep beep`.
- **Persistence**: `~/.local/state/quickshell/alarms.json` (`[{id, at, label}]`,
  `at` in epoch ms). Her version keeps sleeping processes in `/tmp`; this one
  survives a shell restart. An alarm that came due while the shell was down, or
  more than 90 s late after a suspend, rings once with "(missed, was HH:MM)".
- **Scheduling**: `config/AlarmService.qml` keeps one timer armed to the earliest
  deadline, never beyond 30 s, and compares against the clock on each tick.
- **Ring**: `pw-play` plays the freedesktop `alarm-clock-elapsed.oga` once and
  `notify-send -u critical -t 0 -a quickshell-alarm Alarm <label>` posts a
  notification that stays; critical bypasses DND and quiet hours, and it rings
  while locked. Adding shows a 2 s "Will ring at HH:MM" notice.
- **Bar**: the bottom bar's alarm pill shows the pending count (a slash at 0).

Checks: `node tests/alarms/alarms.test.mjs` (model), `node
tests/alarms/wiring.test.mjs` and `bash scripts/alarms-render.sh` (every state,
clicks and keys, plus the service against a fake clock with fake sound and
notify commands: add, early tick, ring once, cancel, late wake, restart with a
past and a future alarm, corrupt file). Dev IPC: `qs ipc call shell popup
alarms`, `alarmState`, `alarmAdd 1 test` (a real alarm), `alarmRemove 0`.
Specification: `docs/superpowers/specs/2026-10-14-elena-alarms-r5-design.md`.

## Launcher redesign and speech removal

The reference supplies the dashed-card and tracked-monospace grammar, not a
replacement launcher workflow. App discovery/ranking, `>` actions, `;`
clipboard history and `@` wallpaper handoff remain. Ordinary microphone
volume/mute controls are independent and remain available.

The isolated native launcher scenario passed 17 checks covering real desktop
entries, keyboard/context-menu interaction, an isolated clipboard fixture,
empty/long-name/short-height layouts, `initialQuery` handoff and a harmless
application activation. Six mode/layout captures were produced and the
application/action/clipboard/short-height views visually inspected; the
captured frame contains both dashes and gaps. No destructive power, clipboard
wipe or microphone capture was exercised.

QML lint, all 14 Node regression commands, 31 control behavior checks and
33 provider/desktop-parser Python cases passed. The live launcher check
requires the user's cold restart; these are isolated runtime results.
Specification: `docs/superpowers/specs/2026-10-13-elena-launcher-design.md`.


## Session/power presentation

`bar/primitives/DashedFrame.qml` now shares static rounded dashed framing among
the launcher, session menu and power confirmation. The confirmation retains
its public color overrides for both lock-screen callsites, signal contract,
initial Cancel focus and outside/keyboard cancellation.

Isolated native scenarios passed 19 session-grid/action checks and nine
confirmation checks. All four power selections and cancellation paths were
exercised. Executor verification used only owned temporary `touch` commands;
confirmation keyboard checks ran without an attached executor. No real
logout, shutdown, reboot, suspend, lock or radio/caffeine toggle was invoked.
Session menu, normal and lock-customized confirmations, and the extracted
launcher frame were rendered and visually inspected.

QML lint, 14 Node regression commands, 31 control behavior checks, three
safe-logout Python cases and the obsolete-style gate passed. Live
display-only checks await the user's cold restart. Specification:
`docs/superpowers/specs/2026-10-13-elena-power-menu-design.md`.

## Notification redesign

History and toasts use the shared dashed-frame primitive; critical toasts keep
their solid error outline and an explicit urgency label. Summary/body text,
placement, action labels, persistent/held-toast rules, DND, quiet hours and
history retention remain unchanged.

A private D-Bus full-shell scenario passed 15 checks using real notifications
and a real action-observing client: delivery, timeout retaining history,
persistent restoration, close/archive/removal, DND and critical bypass,
default/named action invocation, quiet hours, history trimming and clearing.
Normal/critical toast and populated/empty history captures were visually
inspected. It reproduced and fixed a named-action delegate-lifetime
ReferenceError; the corrected run has no new QML errors.

QML lint, 14 Node regression commands, 31 control behavior checks and the
obsolete-style gate passed. Live delivery/display verification awaits the
user's cold restart. Specification:
`docs/superpowers/specs/2026-10-13-elena-notifications-design.md`.
