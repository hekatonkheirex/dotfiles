# Quickshell Desktop Shell

A custom desktop shell built with [Quickshell](https://quickshell.outfoxxed.me/), running on **Niri or Mango**.

## Overview

This replaces a traditional status bar (waybar) and panel infrastructure with a unified QML-based shell. It provides:

- **Workspace strip** (`bar/Bar.qml`): the whole top bar is an 8px row of workspace color blocks.
- **Sidebar and dock**: a toggleable two-page sidebar (Status and Dashboard) and a bottom app dock. Saved bar forms, placement and widget settings remain stored, but Elena forces the top strip and hides the old in-bar widget layout; re-homing that machinery is a separate change.
- **Lock screen** with PAM + fingerprint authentication.
- **Notification handling** with history and toasts, using the single Elena control implementation.
- **Do Not Disturb** suppresses toast popups while retaining incoming notifications in the bell history; the Quick Menu and Notifications tab share the persisted setting.
- **Battery alert watcher**: warning at 20%, critical alert at 10%, persistent `notify-send` notifications driven off `UPower.onBattery` (not raw charge state, which sawtooths under charge-conservation thresholds).
- **App launcher** with fuzzy app search that honors hidden/unavailable desktop entries and user overrides, shell actions via `>`, clipboard history via `;`, and wallpaper search via `@`. Speech recognition is removed.
- **On-Screen Display (OSD)** overlay for volume, brightness, mic mute, airplane mode, bluetooth, and keyboard backlight (polled from sysfs since the EC never emits a key event for it).
- **LLM usage**: One read-only bar widget whose popup displays Codex and Claude side by side, including five-hour and weekly usage, reset countdowns, and available reset credits. Enabled by default; visibility and position are configurable in General → Bar Contents.
- **Settings panel**: A multi-functional, resizable and draggable panel launched via `XF86Tools` with eleven tabs:
  - **Account**: Profile, session, uptime, machine information, lock, and Quickshell restart actions
  - **General**: Motion, uptime, clock, calendar week start, timezone, bar widget visibility and order, and weather location/refresh/privacy/unit settings
  - **Appearance**: Wallpaper filmstrip and random wallpaper, Auto/Light/Dark mode, Live wallpaper colors or Fixed palettes (including Elenapan), accent shortlist, contrast, dock pins, retained bar preferences, sizing, color reload, and confirmed appearance reset. No UI-style picker or separate compact-control density setting.
  - **Display & Input**: Per-output mode, scale, and transform controls plus touchpad, mouse, trackpoint, and edge-gesture settings
  - **Network**: Wi-Fi power, scan, connect, disconnect, saved-network, and autoconnect controls; Wi-Fi is Settings-only and has no compact bar indicator
  - **Bluetooth**: Bluetooth power, discovery, pairing, connected-device, and rename controls; Bluetooth is Settings-only and has no compact bar indicator
  - **Media**: Media artwork, progress, and control visibility
  - **Lock & Power**: Lock-screen media, clock size and wallpaper options, idle lock/suspend timeouts, Caffeine, and TLP power profiles
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
│   └── cava.ini               # cava config for the real-time audio visualizer
├── bar/
│   ├── Bar.qml                # Top workspace strip and retained hidden widget machinery
│   ├── Sidebar.qml            # Status/Dashboard sidebar (content in sidebar/)
│   ├── Dock.qml               # Bottom app dock (content in dock/)
│   ├── SettingsPanel.qml       # Settings panel shell (state, processes, tab bar) — content in settings/
│   ├── settings/
│   │   ├── AccountTab.qml
│   │   ├── AppearanceTab.qml
│   │   ├── DisplayInputTab.qml
│   │   ├── GeneralTab.qml
│   │   ├── LockMediaTab.qml
│   │   ├── MediaTab.qml
│   │   ├── PowerProfileCard.qml
│   │   ├── NetworkTab.qml
│   │   ├── BluetoothTab.qml
│   │   ├── NotificationsTab.qml
│   │   ├── ShortcutsTab.qml
│   │   └── SystemTab.qml
│   ├── LockScreen.qml          # PAM auth, fingerprint and compositor-enforced session lock
│   ├── WorkspaceIndicator.qml  # Workspace/tag pills + focused-window state (orientation-aware)
│   ├── Launcher.qml            # App launcher button
│   ├── LauncherPopup.qml       # App/provider search (apps, clipboard, wallpapers, actions)
│   ├── AudioIndicator.qml      # Volume icon + scroll control (orientation-aware)
│   ├── AudioPopup.qml          # Volume + mic sliders (shared bordered surface, correct active/mute states)
│   ├── BrightnessIndicator.qml # Brightness icon (orientation-aware)
│   ├── BrightnessPopup.qml     # Brightness slider (shared bordered surface)
│   ├── BatteryIndicator.qml    # Battery via UPower (orientation-aware)
│   ├── BatteryPopup.qml        # Detailed battery info (shared bordered surface)
│   ├── MediaIndicator.qml      # Active MPRIS player indicator
│   ├── MediaPopup.qml          # Media controls and circular cava visualizer
│   ├── WeatherIndicator.qml    # Current weather indicator
│   ├── WeatherPopup.qml        # Current conditions and forecast
│   ├── LlmUsageIndicator.qml   # Single combined LLM usage indicator
│   ├── LlmUsageIcon.qml        # Angular sparkle using the shared indicator color
│   ├── LlmUsagePopup.qml       # Combined Codex and Claude usage popup
│   ├── LlmUsageSection.qml     # Provider usage, resets, and refresh state
│   ├── WifiPanel.qml            # Wi-Fi controls used by the Settings Network tab
│   ├── BtPanel.qml              # Bluetooth controls used by the Settings Bluetooth tab
│   ├── SystemTrayArea.qml      # StatusNotifier tray icons (orientation-aware)
│   ├── MenuIndicator.qml       # Quick Settings bar trigger
│   ├── QuickMenu.qml           # Four controls plus a 3×2 session/power/settings grid
│   ├── OsdOverlay.qml          # Volume/brightness/mic/airplane/bluetooth/kbd-backlight OSD popup
│   ├── CalendarLogic.js        # Calendar weekday ordering and day-cell model
│   ├── CalendarPopup.qml       # Calendar month grid (shared bordered surface)
│   ├── NotificationIndicator.qml # Notifications counter (orientation-aware)
│   ├── NotificationPopup.qml   # Notification history popup list
│   ├── NotificationToast.qml   # Notification toast banner
│   ├── AnimatedBackground.qml  # Reusable animated background (popups/Settings)
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
│   │   ├── PillSurface.qml
│   │   ├── StatusIndicator.qml
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
│   ├── quickmenu                # Quick menu trigger (private runtime trigger)
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
| `Mod+Escape` | Toggle quick settings menu | `scripts/quickmenu` → private runtime trigger |
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
- `$XDG_RUNTIME_DIR/quickshell/qsquickmenu-trigger` — toggles the quick settings menu
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
- `ipc.quickmenu()` — toggle quick menu
- `ipc.settings()` — toggle Settings popup
- `ipc.commandcenter()` — legacy alias for `ipc.settings()`
- `ipc.layout()` — toggle bar orientation

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
- Profile image (`~/Pictures/profile.jpg`), live clock, suspend/reboot/poweroff buttons
- **Lock & Power settings** configure automatic lock and suspend timeouts plus TLP power profiles; the existing dim/display-off stages remain fixed, and suspend locks first
- The wallpaper preference remains optional; the existing animated fallback and authentication layout are unchanged by the Elena-only cutover.
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
| Audio | `AudioIndicator` click | Volume + mic sliders (Elena switches; active check = sound enabled, unchecked = muted). Pointer adjustments do not leave a focus outline; keyboard focus stays visible while adjusting and resets when the popup closes. |
| Brightness | `BrightnessIndicator` click | Brightness slider (shared bordered surface) |
| Battery | `BatteryIndicator` click | Percentage, energy capacity, status, rate, cycles, model (shared bordered surface) |
| LLM usage | Themed LLM indicator / `qs ipc call shell popup llm` | Codex and Claude five-hour/weekly usage, reset countdowns, available reset credits, and per-provider refresh |
| Calendar | Clock click | Month grid with navigation (shared bordered surface) |
| Notifications | `NotificationIndicator` click | Elena card layout list tracked via `modelData` |
| Quick Menu | `MenuIndicator` click / `Mod+Escape` | Caffeine, airplane mode, Bluetooth, DND; Log Out, Shut Down, Restart, Sleep, Lock and Settings tiles |
| Settings | Quick Settings entry / `XF86Tools` | 11 tabs: Account, General, Appearance, Display & Input, Network, Bluetooth, Media, Lock & Power, Notifications, System, Shortcuts (responsive surface with persisted last tab, drag-to-move, and resize handle) |
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

Persisted user preferences singleton (`FileView` + `JsonAdapter` over `~/.config/quickshell/settings.json`, created on first run if missing). It owns layout preferences, motion, clock/calendar/timezone, indicator settings, workspaces, palette/contrast/accent, dock pins, lock screen, notifications, idle timeouts and weather. Obsolete style-selector, variant, compact-density, transparency and alternate-clock keys are ignored on load and omitted when settings are next saved. The persisted format remains `schemaVersion: 2`; the existing combined LLM-widget migration is unchanged. Preferences update through `watchChanges: true`; call `Settings.save()` after mutating a persisted value.

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
- **Bar.qml**: The visible surface is the top workspace strip. The saved Start/Middle/End order, forms and widget preferences remain in the hidden widget machinery for a later re-homing change. `config/BarForm.js` still handles those saved forms.
- **Clock scheduling**: The visible bar clock updates at minute boundaries unless seconds are enabled, in which case it updates at second boundaries. Showing the bar or changing the seconds preference resynchronizes it; timezone formatting remains independent. The local bar preference hides the focused-window label and centers the clock; both can be changed under General → Bar contents.
- **Calendar**: Month navigation, a circular today badge and the Sunday/Monday week-start preference remain unchanged.
- **WorkspaceIndicator**: Streams Niri workspaces and focused-window state. The Elena path renders color blocks; hidden widget machinery remains available to its existing consumers.
- **Mango layout indicator**: Reads the active tag's layout from the shared `mmsg watch all-monitors` stream. Defaults between Workspaces and Focused window, but can move independently under General > Bar contents.
- **AudioIndicator / BrightnessIndicator / MediaIndicator / WeatherIndicator**: Event-driven watchers and polling loops are bound to their active/visible state. Audio writes for sink and microphone are serialized and coalesced during rapid slider/toggle input, with a final state read after the latest write.
- **BatteryIndicator**: Utilizes UPower property bindings (no timers) to react directly to battery changes.
- **WifiPanel / BtPanel**: Network and Bluetooth controls live in Settings tabs, including saved Wi-Fi profiles, Bluetooth discovery/pairing, and connected-device actions. They are intentionally not rendered as compact bar indicators.
- **SystemTrayArea**: Renders StatusNotifier items with left-click activate and right-click context menu, orientation-aware layout.
- **QuickMenu**: Dashed Elena session card with monospace headings/hints, four live-state controls and a labeled 3×2 grid for Log Out, Shut Down, Restart, Sleep, Lock and Settings. Settings moved into the sixth tile rather than adding a new power command. Left/Right traverses tiles with wrapping; Up/Down changes grid rows in the same column. Tab/Enter/Space remain native. Each power action closes the menu before opening the existing confirmation overlay, which starts on Cancel, supports Escape/outside cancellation and uses 48px button hit height. The secure lock route and actual power commands are unchanged. Audio/brightness controls remain in their existing homes.
- **Launcher**: App/action/clipboard search uses a screen-bounded 460px single-column Elena card with a dashed rounded frame, monospace uppercase provider/count labels, contextual keyboard hints and an accent selection marker. Names and selected descriptions keep the regular body font and normal case; popup height follows content without a separate details pane. Ctrl+F returns to search, arrows select results, Enter activates, and Tab reaches provider controls. Right-click or Shift+F10/Menu exposes opening, copying parsed POSIX-shell-quoted application arguments, or deleting a clipboard entry; Escape closes the context menu before dismissing. `@` still hands off to the wallpaper filmstrip. Speech recognition, its microphone button, recording/transcription processes and helper are removed; system packages and downloaded models outside the repo are untouched.
- **Settings**: Provides eleven tabs, remembers the last selected tab, keeps Network and Bluetooth Settings-only, and preserves Settings/power entry points when bar content switches are disabled. The panel moves from its header and resizes from the bottom-right corner, with a 560px minimum width and a maximum height bounded by screen margins. Sidebar navigation scrolls on overflow without a visible scrollbar; keyboard navigation brings the selected tab into view. Search prioritizes control titles, reports result counts or an empty state, and opens and highlights matching controls.
- **Settings presentation**: Defaults to 1100×900 when no saved size exists, can expand to 1440px, and bounds the navigation pane and page width. General sections become side-by-side above 800px and stack below. Narrow labels elide with tooltips; rows wrap and grow. Ctrl+F searches from any control, without stealing content editing/navigation keys.
- **Bar widget preferences**: General retains visibility, order and Start/Middle/End placement settings. They do not replace the Elena workspace strip. Hidden widgets retain their saved positions; re-homing them is out of scope for S1.
- **ActionButton**: Label-only buttons reserve no icon height or icon-to-label spacing; compact Settings actions retain centered labels.
- **Weather**: Uses a configured manual location by default, optionally supports IP geolocation, refreshes on the persisted interval and reports the last update time. Refreshes coalesce rather than aborting an active fetch; invalid responses and command failures appear as popup errors.
- **Notifications**: Retains history while DND or quiet hours suppress toast delivery. Critical bypass, placement, retention and clear-history remain persisted. History cards are reading surfaces with explicit dismiss/remove controls; toast input and timeout behavior retain the existing Elena path.
- **Dark Mode Preference**: Event-driven tracking via a one-time startup query (`gsettings get`) and a continuous background monitor (`gsettings monitor`) with a `SplitParser` listener, saving CPU cycles. Because `Colors.qml` hot-reloads reset `systemDark` to its template default, a polling re-query runs in `shell.qml` after reloads.
- **Palette ownership**: Live comes from wallpaper-driven Matugen; Fixed comes from `PaletteCatalog.js`. `sync-active-palette.sh` activates separate source caches and refreshes the generated companions. Wallpaper changes still refresh Live while Fixed is selected. SDDM updates remain explicit.
- **Deployment**: `scripts/install-ui-suite.sh` installs only the palette-driven Matugen companions and optional light/dark greeters. Use `--dry-run` or `--skip-sddm`; `verify-ui-suite.sh` checks the matching assets. Existing outside-tree themes are untouched. Installing the updated SDDM bridge requires an explicit privileged action; no system installation is performed by the cutover.
- **Appearance**: Palette, accent, contrast, wallpaper, dock pins, retained bar preferences, sizing and confirmed reset remain. Removed styles have no picker, preview or search entry.
- **Display & Input tab**: Reads and safely edits Niri output, input, and edge-gesture settings through the validated `scripts.niri_config` CLI. Remote controls only read while their Settings page is active.
- **Wallpaper thumbnails**: `scripts/generate-thumbnails.sh` produces 200×130 center-cropped thumbnails under `~/.cache/quickshell/wallpaper-thumbs`, regenerating only when the source is newer, with bounded concurrency, atomic publishing and a nonzero exit status on failure. The filmstrip runs it, then `scripts/generate-previews.sh`, once per shell session at low priority. There is no Wallpaper tab: choose from Appearance, the launcher's `@`, or `qs ipc call shell wallpapers`; `qs ipc call shell randomWallpaper` (and Ctrl+R in the filmstrip) applies a random one through `scripts/random-wallpaper.sh`.
- **Lock & Power**: Owns clock size, wallpaper/media preferences, idle lock/suspend timeouts, Caffeine and automatic AC/battery power-profile restoration.
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
- **nmcli**, **bluetoothctl** — Settings-only Network/Bluetooth tabs, airplane mode, and OSD
- **lm-sensors** (`sensors`) — optional thermal and fan readings in the System tab
- **jq** — parses `sensors -j` output for System diagnostics
- **ImageMagick** (`magick`/`convert`) — wallpaper thumbnail generation
- **Matugen** — wallpaper-derived Material You palette generation
- **awww** — wallpaper daemon
- **cava** — real-time audio visualizer (raw ASCII output consumed by the Settings waveform; the Pill bar's signal wave only asks it whether there is sound)
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
`controls-render.sh`, `sidebar-render.sh`, `dock-render.sh` and
`tag-strip-render.sh` provide isolated Elenapan-palette pixel checks.
`config-dump.sh check` compares the original role/token oracle, allowing only
explicitly removed properties and the intended shape change. Its legacy-key
fixture proves stale settings cannot activate a removed style or density.

After QML cutovers, cold-restart Quickshell before live IPC verification:
`systemctl --user restart quickshell.service`. Launcher and session/power
presentation redesigns are implemented; notification redesign remains separate.
Bindings, confirmation execution and authentication remain unchanged.

## Sidebar pages (S2)

Toggle with `qs ipc call shell popup sidebar`. Status keeps the clock, battery,
weather, media and level controls. Dashboard adds the current user/session,
Account/Appearance/System settings links, a browsable calendar, uptime, memory
used/total and explicitly labeled one-minute CPU load average.

Use the page buttons or **Ctrl+PageUp / Ctrl+PageDown**. Tab, Enter and Space
work on the native buttons. Page selection stays in memory across close/open;
it does not write settings. Search stays fixed below either page, preserves
its query while switching, and clears on close. Enter retains the existing
launcher search and `@` wallpaper routing.

Both page bodies scroll on short outputs while navigation and search remain
visible. Status services activate only on Status; procfs statistics refresh
every five seconds only on the visible Dashboard. Calendar week start follows
the existing preference. Unavailable metrics are labeled, not shown as zero.
The profile uses an initial badge instead of adding another masked image.

`node tests/sidebar/stats.test.mjs` checks metric parsing boundaries.
`bash scripts/sidebar-render.sh` exercises keyboard navigation, search
retention, real metric refresh/stop, year/leap-day calendar behavior and
short-height scrolling. With `KEEP_PNG=/tmp/sidebar.png`, it keeps Status,
Dashboard (`/tmp/sidebar-dashboard.png`) and short-height
(`/tmp/sidebar-short.png`) captures. Full-shell quick-link routing is also
smoke-checked separately. Specification:
`docs/superpowers/specs/2026-10-13-elena-sidebar-pages-design.md`.

## Launcher redesign and speech removal

The reference supplies the dashed-card and tracked-monospace grammar, not a
replacement launcher workflow. App discovery/ranking, `>` actions, `;`
clipboard history and `@` wallpaper handoff remain. Ordinary microphone
volume/mute controls are independent and remain available.

The isolated native launcher scenario passed 17 checks covering real desktop
entries, keyboard/context-menu interaction, an isolated clipboard fixture,
empty/long-name/short-height layouts, sidebar query handoff and a harmless
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
