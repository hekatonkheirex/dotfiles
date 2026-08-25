# Quickshell Desktop Shell

A custom desktop shell built with [Quickshell](https://quickshell.outfoxxed.me/), running on **Niri**.

## Overview

This replaces a traditional status bar (waybar) and panel infrastructure with a unified QML-based shell. It provides:

- **A single bar** (`bar/Bar.qml`) that supports top, bottom, left, and right placement, with a choice between one continuous full bar and a pills bar where each widget floats in its own pill. The display-style setting (`fullBar`) is persisted with the other Appearance preferences.
- **Bar Placement**: Choose top, bottom, left, or right in the Settings Appearance tab, persisted across reboots (saved to `~/.config/quickshell/layout`). Legacy `horizontal` and `vertical` values remain supported as top and left.
- **Lock screen** with PAM + fingerprint authentication.
- **Ghost startup welcome**: when the Ghost style is selected, the original post-SDDM cyberbrain boot trace and female figure artwork briefly appear after Quickshell starts.
- **Notification handling** with history and toasts, styled through the selected UI system.
- **Do Not Disturb** suppresses toast popups while retaining incoming notifications in the bell history; the Quick Menu and Notifications tab share the persisted setting.
- **Battery alert watcher**: warning at 20%, critical alert at 10%, persistent `notify-send` notifications driven off `UPower.onBattery` (not raw charge state, which sawtooths under charge-conservation thresholds).
- **App launcher** with fuzzy app search, local offline **voice search**, allowlisted shell actions via `>`, and wallpaper search via `@`.
- **On-Screen Display (OSD)** overlay for volume, brightness, mic mute, airplane mode, bluetooth, and keyboard backlight (polled from sysfs since the EC never emits a key event for it).
- **Settings panel**: A multi-functional panel launched via `XF86Tools` with eleven tabs:
  - **Account**: Profile, session, uptime, machine information, lock, and Quickshell restart actions
  - **General**: Motion, uptime, clock, calendar week start, timezone, bar contents, and weather location/refresh/privacy/unit settings
  - **Appearance**: Color mode, independent UI style (Material 3, Neo Brutalism, Nothing Classic, Nothing Evolution, or Ghost), bar placement, sizing controls, palette source, color reload, and confirmed appearance reset
  - **Wallpaper**: Active-wallpaper tracking, cached thumbnails, keyboard navigation, random selection, and wallpaper switching
  - **Network**: Wi-Fi power, scan, connect, disconnect, saved-network, and autoconnect controls; Wi-Fi is Settings-only and has no compact bar indicator
  - **Bluetooth**: Bluetooth power, discovery, pairing, connected-device, and rename controls; Bluetooth is Settings-only and has no compact bar indicator
  - **Media**: Media artwork, progress, and control visibility
  - **Lock & Power**: Lock-screen media/clock and wallpaper options, idle lock/suspend timeouts, Caffeine, and TLP power profiles
  - **Notifications**: Do Not Disturb, quiet hours, critical bypass, toast position/duration, history retention, clear-history, and test-notification controls
  - **System**: CPU, memory, disk, swap, thermal, fan, battery health/cycles, diagnostics copy, reload, and confirmed reset actions
  - **Shortcuts**: Curated Niri keybind reference with source open and copy actions
- **Persisted user settings** (`settings.json`, `config/Settings.qml`) separate from build-time layout/typography tokens (`config/Config.qml`).

## Project Structure

```
~/.config/quickshell/
├── shell.qml                  # Entry point — ShellRoot, IpcHandler, popups, battery alert, file triggers
├── settings.json              # Persisted user settings (JsonAdapter-backed)
├── layout                     # Persisted bar placement ("top" | "bottom" | "left" | "right")
├── resources/
│   └── images/welcome-cyberbrain.png # Recovered Ghost startup artwork
├── ui/
│   └── WelcomeScreen.qml       # Post-SDDM Ghost startup overlay
├── config/
│   ├── Config.qml             # Build-time layout, typography, shape, and motion tokens
│   ├── Settings.qml           # Persisted preferences singleton (FileView + JsonAdapter over settings.json)
│   ├── Colors.qml             # Material roles, fixed Classic Nothing/Ghost palettes, adaptive Evolution roles, Matugen fallback + system dark-mode tracking
│   └── cava.ini                # cava config for the real-time audio visualizer
├── bar/
│   ├── Bar.qml                 # The panel itself — full-bar/pills-bar styles, orientation-aware active indicators
│   ├── SettingsPanel.qml       # Settings panel shell (state, processes, tab bar) — content in settings/
│   ├── settings/
│   │   ├── AccountTab.qml
│   │   ├── AppearanceTab.qml
│   │   ├── WallpaperTab.qml
│   │   ├── GeneralTab.qml
│   │   ├── LockMediaTab.qml
│   │   ├── MediaTab.qml
│   │   ├── PowerProfileCard.qml
│   │   ├── NetworkTab.qml
│   │   ├── BluetoothTab.qml
│   │   ├── NotificationsTab.qml
│   │   ├── ShortcutsTab.qml
│   │   └── SystemTab.qml
│   ├── LockScreen.qml          # PAM auth, fingerprint, adaptive clock faces, power buttons
│   ├── WorkspaceIndicator.qml  # Workspace/tag pills + focused-window state (orientation-aware)
│   ├── Launcher.qml            # App launcher button
│   ├── LauncherPopup.qml       # App search (text/voice input) popup
│   ├── AudioIndicator.qml      # Volume icon + scroll control (orientation-aware)
│   ├── AudioPopup.qml          # Volume + mic sliders (M3 bordered, correct active/mute states)
│   ├── BrightnessIndicator.qml # Brightness icon (orientation-aware)
│   ├── BrightnessPopup.qml     # Brightness slider (M3 bordered)
│   ├── BatteryIndicator.qml    # Battery via UPower (orientation-aware)
│   ├── BatteryPopup.qml        # Detailed battery info (M3 bordered)
│   ├── MediaIndicator.qml      # Active MPRIS player indicator
│   ├── MediaPopup.qml          # Media controls and circular cava visualizer
│   ├── WeatherIndicator.qml    # Current weather indicator
│   ├── WeatherPopup.qml        # Current conditions and forecast
│   ├── WifiPanel.qml            # Wi-Fi controls used by the Settings Network tab
│   ├── BtPanel.qml              # Bluetooth controls used by the Settings Bluetooth tab
│   ├── SystemTrayArea.qml      # StatusNotifier tray icons (orientation-aware)
│   ├── MenuIndicator.qml       # Quick Menu and Settings bar triggers
│   ├── QuickMenu.qml           # Nothing Quick Settings plus caffeine, radio, DND, lock, and power actions
│   ├── OsdOverlay.qml          # Volume/brightness/mic/airplane/bluetooth/kbd-backlight OSD popup
│   ├── CalendarLogic.js        # Calendar weekday ordering and day-cell model
│   ├── CalendarPopup.qml       # Calendar month grid (M3 bordered)
│   ├── NotificationIndicator.qml # Notifications counter (orientation-aware)
│   ├── NotificationPopup.qml   # M3 notification history popup list
│   ├── NotificationToast.qml   # M3 notification toast banner
│   ├── AnimatedBackground.qml  # Reusable animated M3 blob background (popups/Settings)
│   ├── PopupBase.qml           # Shared popup chrome (background, border, entry animation)
│   ├── PopupShield.qml         # Full-screen click-outside-to-dismiss surface
│   ├── PopupDivider.qml        # Reusable popup section divider
│   ├── PowerConfirmation.qml   # Confirmation surface for destructive power actions
│   ├── FocusDismiss.qml        # Popup dismissal on app focus loss
│   ├── FileTrigger.qml         # Generic /tmp trigger-file watcher (single inotifywait for all triggers)
│   ├── SliderControl.qml       # Theme-selected slider facade (volume/brightness/etc.)
│   ├── SwitchControl.qml       # Theme-selected switch/toggle facade
│   ├── WaveProgressBar.qml     # Reusable wavy progress bar canvas (progress, lineWidth, dotRadius, trackLineWidth)
│   ├── primitives/             # Shared buttons, list items, and text fields
│   │   ├── ActionButton.qml
│   │   ├── IconButton.qml
│   │   ├── ListItem.qml
│   │   ├── PillSurface.qml
│   │   ├── StatusIndicator.qml
│   │   ├── StyledSurface.qml
│   │   └── TextFieldControl.qml
│   └── themes/                 # Separate UI-style implementations
│       ├── material3/          # Material 3 controls and ThemeTokens.qml
│       ├── neo_brutalism/      # Neo Brutalism controls and ThemeTokens.qml
│       ├── nothing/             # Nothing controls, Evolution clock face, and ThemeTokens.qml
│       └── ghost/               # Ghost (GITS) controls and ThemeTokens.qml
├── scripts/
│   ├── launcher                # Launcher trigger (touches /tmp/qslauncher-trigger)
│   ├── quickmenu                # Quick menu trigger (touches /tmp/qsquickmenu-trigger)
│   ├── settings                 # Settings trigger (touches /tmp/qssettings-trigger)
│   ├── commandcenter            # Legacy alias for settings
│   ├── lock                     # Lock trigger (touches /tmp/qslock-trigger)
│   ├── apply-wallpaper.sh       # Wallpaper selection + Matugen/theme refresh
│   ├── generate-neo-kitty-theme.sh # Generates the Neo Brutalism Kitty/Starship pair from Matugen
│   ├── apply-accent-color.sh    # Compatibility stub — palette is fixed by Matugen, not user-selectable
│   ├── generate-thumbnails.sh   # Generates/caches wallpaper thumbnails for the Wallpaper tab
│   ├── m3-qmllint-gate.sh       # QML regression gate for the M3 refactor, including shared primitives
│   ├── install-ui-suite.sh      # Clones and installs all four external UI style families
│   ├── verify-ui-suite.sh       # Verifies user-level assets across all four UI style families
│   ├── install-sddm-integration.sh # Installs the root SDDM bridge and polkit policy
│   ├── verify-sddm-integration.sh  # Verifies the bridge and all supported SDDM theme assets
│   ├── idle.sh                  # swayidle: dim, lock, display off, suspend
│   ├── lid.sh                   # Lid close: lock
│   ├── safe-logout.sh           # Clean Niri quit, falls back to a session kill
│   ├── mpris_monitor.py         # Active MPRIS state broadcaster (DBus + /tmp/qsmpris-fifo listener)
│   ├── mpris_control.py         # MPRIS play/pause/next/prev control for the active player
│   ├── weather.py               # Open-Meteo weather fetcher script
│   └── voice-search.py          # Local speech transcription via python-vosk (downloads its model to ~/.local/share/vosk-model on first use)
└── bin/
    └── desktop-parser.py        # .desktop → JSON for launcher
```

## WM Integration

Quickshell runs as a Wayland layer surface (panel) on top of the compositor. It integrates with **Niri** using the Niri socket.

### Niri Startup

Quickshell is managed via a systemd user service to ensure rate-limiting and session-binding (prevents infinite coredump storms in case of Wayland crashes/logouts).

Service file at `~/.config/systemd/user/quickshell.service`:

```ini
[Unit]
Description=Quickshell Desktop Panel
PartOf=graphical-session.target
After=graphical-session.target

[Service]
ExecStart=/usr/bin/quickshell
Restart=on-failure
RestartSec=2s
# Stop restarting if it crashes more than 5 times in 10 seconds.
StartLimitIntervalSec=10s
StartLimitBurst=5

[Install]
WantedBy=graphical-session.target
```

In `~/.config/niri/startup.kdl`:

```
spawn-sh-at-startup "~/.config/quickshell/scripts/idle.sh"
spawn-sh-at-startup "dbus-update-activation-environment --systemd --all && systemctl --user start quickshell.service"
```

Quickshell auto-discovers `~/.config/quickshell/shell.qml` as the default config when run without arguments.

When `Settings.themeStyle` is `ghost`, `ui/WelcomeScreen.qml` starts automatically after the shell is ready. It can also be replayed with `quickshell ipc call shell welcome`; other styles leave the overlay disabled.

### Lid Switch

Lid close is handled in `~/.config/niri/config.kdl`:

```kdl
switch-events {
  lid-close { spawn "/home/mura/.config/quickshell/scripts/lock"; }
}
```

`scripts/lid.sh` (an equivalent standalone entry point for non-Niri lid handlers) locks via the same `scripts/lock` trigger.

## Keybindings

Keybindings live in Niri's `~/.config/niri/keybinds.kdl` and spawn Quickshell's trigger scripts or `wpctl`/`brightnessctl`/`nmcli`/`bluetoothctl` directly:

| Key | Action | Mechanism |
|---|---|---|
| `Mod+D` | Toggle app launcher popup | `scripts/launcher` → `touch /tmp/qslauncher-trigger` |
| `Mod+Escape` | Toggle quick settings menu | `scripts/quickmenu` → `touch /tmp/qsquickmenu-trigger` |
| `XF86Tools` | Toggle Settings popup | `scripts/settings` → `touch /tmp/qssettings-trigger` |
| `Mod+Alt+L` | Lock screen | `scripts/lock` → `touch /tmp/qslock-trigger` |
| `XF86AudioRaiseVolume` / `LowerVolume` / `Mute` | Volume up/down/mute | `wpctl` + `touch /tmp/qsosd-vol` |
| `XF86AudioMicMute` | Mic mute toggle | `wpctl` + `touch /tmp/qsosd-mic` |
| `XF86AudioPlay/Stop/Prev/Next` | Media transport controls | `playerctl` |
| `XF86MonBrightnessUp/Down` | Brightness up/down | `brightnessctl` + `touch /tmp/qsosd-bright` |
| `XF86WLAN` / `Mod+F8` / `F8` | Toggle airplane mode (wifi + bluetooth) | `nmcli`/`bluetoothctl` + `touch /tmp/qsosd-airplane` |
| `XF86Bluetooth` / `Mod+F10` / `F10` | Toggle bluetooth power | `bluetoothctl` + `touch /tmp/qsosd-bluetooth` |

Keyboard backlight brightness is controlled by the ThinkPad EC firmware directly (`Fn+Space`), not by a Niri bind — `OsdOverlay.qml` polls the sysfs LED brightness file to show its OSD.

### External Triggers

Any script or keybinding can trigger Quickshell actions by creating these files under `/tmp`:

- `/tmp/qslauncher-trigger` — toggles the launcher popup
- `/tmp/qsquickmenu-trigger` — toggles the quick settings menu
- `/tmp/qssettings-trigger` — toggles the Settings popup
- `/tmp/qscommandcenter-trigger` — legacy alias for the Settings popup
- `/tmp/qslock-trigger` — activates the lock screen
- `/tmp/qsosd-vol` / `qsosd-bright` / `qsosd-mic` / `qsosd-airplane` / `qsosd-bluetooth` — show the corresponding OSD

`bar/FileTrigger.qml` watches `/tmp` with a single persistent `inotifywait` process (zero CPU while idle, one watcher for every registered trigger) and dispatches to the matching `IpcHandler` method or `OsdOverlay.show()` call. Any trigger file already present on startup fires immediately. Triggers can also be invoked directly via `quickshell ipc call shell <name>`.

## IPC

`shell.qml` defines an `IpcHandler` with `target: "shell"` exposing:

- `ipc.launcher()` — toggle launcher popup
- `ipc.lock()` — activate lock screen
- `ipc.quickmenu()` — toggle quick menu
- `ipc.welcome()` — replay the Ghost startup welcome overlay when Ghost is selected
- `ipc.settings()` — toggle Settings popup
- `ipc.commandcenter()` — legacy alias for `ipc.settings()`
- `ipc.layout()` — toggle bar orientation

Callable externally via `quickshell ipc call shell launcher` (and similarly for the others).

## Lock Screen

`bar/LockScreen.qml` is a standalone component using `WlSessionLock` with:

- **PAM password auth** via `Quickshell.Services.Pam`
- **Fingerprint reader** via `fprintd-verify` (auto-retries on failure), started/stopped imperatively in `onLockedChanged` to avoid QML declarative binding breaks
- Profile image (`~/Pictures/profile.jpg`), live clock, suspend/reboot/poweroff buttons
- **Lock & Power settings** configure automatic lock and suspend timeouts plus TLP power profiles; the existing dim/display-off stages remain fixed, and suspend locks first
- Animated background (`AnimatedBackground.qml`) for Material 3; Nothing Classic uses a static neutral fallback, while Nothing Evolution uses its selectable Gooey or Micrographics clock face and adaptive accent
- Controlled via `IpcHandler.lock()`, `scripts/lock`, or directly via `touch /tmp/qslock-trigger`

## Popup System

Popup visibility is driven entirely by the bar's `openPopup` string property, held on `Bar.qml` and read by `shell.qml`. Each indicator widget signals a popup name, and the corresponding popup shows/hides accordingly.

Popup positioning follows the active bar placement (computed in `shell.qml`'s `popupMarginLeft`/`popupMarginTop`):
- **Top/bottom**: Anchored past the bar edge and horizontally centered on the clicked widget's X coordinate, clamped to fit the screen.
- **Left/right**: Anchored past the bar edge and vertically aligned to the triggering widget's Y coordinate.

Escape or clicking outside (on another window) dismisses the active popup. All popups use `WlrLayer.Top` and `PopupShield` sits on `WlrLayer.Bottom` to intercept outside clicks. `FocusDismiss` handles dismissal on app focus loss with platform-specific gating for the `activeFocusChanged` check. `PopupBase.qml` supplies the shared M3 background/border/entry-animation chrome that most popups build on.

| Popup | Trigger | Content |
|---|---|---|
| Launcher | `Launcher` button / `Mod+D` | App search bar (offline voice search, `>` actions, `@` wallpapers) + `.desktop` list |
| Audio | `AudioIndicator` click | Volume + mic sliders (M3 switches; active check = sound enabled, unchecked = muted) |
| Brightness | `BrightnessIndicator` click | Brightness slider (M3 bordered) |
| Battery | `BatteryIndicator` click | Percentage, energy capacity, status, rate, cycles, model (M3 bordered) |
| Calendar | Clock click | Month grid with navigation (M3 bordered) |
| Notifications | `NotificationIndicator` click | M3-compliant card layout list tracked via `modelData` |
| Quick Menu | `MenuIndicator` click / `Mod+Escape` | Caffeine, airplane mode, DND, lock, and confirmed power actions (M3 bordered) |
| Settings | Settings bar icon / `XF86Tools` | 11 tabs: Account, General, Appearance, Wallpaper, Network, Bluetooth, Media, Lock & Power, Notifications, System, Shortcuts (responsive M3 surface with persisted last tab) |
| OSD | volume/brightness/mic/airplane/bluetooth/kbd-backlight keys | Auto-dismissing bottom-anchored status card (not part of the `openPopup` system — a separate always-on-top window) |

## Configuration

### `config/Config.qml`

Build-time layout, typography, shape, and motion tokens: `barWidth`, `widgetSize`, type sizes, independent bar clock typography, spacing, style-dependent shape/border/shadow tokens, motion durations (`motionShort`/`Medium`/`Long`/`ExtraLong`, all zeroed when `reducedMotion` is on), `popupWidth`, Settings min/max dimensions, and step sizes for volume/brightness. `Settings.themeStyle` selects the component styling independently from the generated palette, while `Settings.nothingVariant` selects Classic or Evolution inside the Nothing family. Classic uses the installed `NType 82` family; Evolution uses Geist and Geist Mono, layered radii, adaptive accent roles, and translucent surface tokens.

### `config/Settings.qml`

Persisted user preferences singleton (`FileView` + `JsonAdapter` over `~/.config/quickshell/settings.json`, created on first run if missing). Backs `fullBar` (continuous full bar versus floating pills), motion and sizing, independent bar clock font size, clock/calendar/timezone settings, last Settings tab, bar indicator visibility, color theme preference, UI style (`material3`, `neo-brutalism`, `nothing`, or `ghost`), Nothing variant, lock-screen clock face, notification behavior, lock/power and media options, idle timeouts, and weather location/refresh/privacy/units. IP-based weather geolocation is a separate opt-in setting and is disabled by default. The persisted format is currently `schemaVersion: 1`; future breaking renames or removals must increment that marker and migrate the stored data before writing the new schema. Values round-trip live via `watchChanges: true`; call `Settings.save()` after mutating an alias to persist. The Appearance tab can restore appearance-owned defaults, while the confirmed System reset restores all settings and the default top bar placement.

### `config/Colors.qml`

Material You / Material 3 semantic roles are resolved in `Colors.qml` from Matugen's `~/.cache/matugen/current_palette.json`. The file keeps authored light/dark fallbacks for first boot and generator failures. Classic Nothing and Ghost select authored light/dark palettes; Nothing Evolution consumes the Matugen cache and applies adaptive translucent surface roles. The cache remains available to Material 3, Neo Brutalism, and external desktop integrations.

Format: `l_<token>` (light), `d_<token>` (dark), and flat resolved `<token>` properties (no prefix) for current mode. Text/icon colors are prefixed with `fg` (e.g. `fgSurface`, `fgPrimary`) to prevent conflicts with QML's internal signal handler compiler rules.

System dark mode is read once and monitored through `gsettings` (owned by `Colors.qml` itself, since it's the single instance everyone reads from). Mode toggles in the launcher or Settings call the existing desktop mode synchronizer, while the shell selects the matching Matugen light/dark roles locally.

`Settings.themePreference` is the persisted owner of the color mode (`0` Auto, `1` Light, `2` Dark). `Settings.themeStyle` is the UI style selector (`material3`, `neo-brutalism`, `nothing`, or `ghost`), and `Settings.nothingVariant` selects Classic or Evolution within the Nothing branch. Nothing Classic and Ghost use fixed, wallpaper-neutral authored roles; Nothing Evolution reads the existing Matugen cache for wallpaper-aware roles, then applies translucent layered surfaces, Geist typography, and a red/adaptive signal accent. Ghost is a fourth style branch alongside Neo and Nothing: it uses fixed, wallpaper-neutral light/dark roles, a cyan HUD accent, square (`0`-radius) surfaces, and the dedicated controls in `bar/themes/ghost/`. The shared surfaces, indicators, workspace state, launcher, lock screen, Settings panel, and OSD consume those semantic Ghost roles instead of falling back to Matugen colors. `shell.qml` reapplies the color-mode and UI-style preference through `sync-theme-mode.sh` at startup and whenever either changes, keeping GTK, icons, Qt/Kvantum, fonts, Kitty, Starship, Niri, btop, Neovim, and SDDM synchronized without editing generated Matugen files. Ghost selects the recovered `Ghost-Light`/`Ghost-Dark` GTK and icon themes, the `Ghost`/`Ghost-Dark` Kvantum pair, JetBrains Mono, fixed `ghost-light.conf`/`ghost-dark.conf` Kitty palettes, matching Starship files, the fixed dark Ghost btop palette, `ghost`/`ghost-light` Neovim colorschemes, a cyan-on-hairline Niri focus ring with no shadow and `0` corner radius, the recovered `ghost-section9` Xcursor theme (GTK `cursor-theme` plus Niri's `decorations.kdl`/`environments.kdl`), and the dark-only `Ghost-SDDM` greeter for both modes. btop and Neovim state is written by `sync-terminal-theme.sh`; new Neovim sessions select the resolved variant, while an already-running Neovim or btop process needs its normal restart/reload behavior. The SDDM bridge updates a root-owned drop-in on explicit style or mode changes and does not restart the display manager; the new theme applies at the next greeter start. Nothing and Neo Brutalism retain their existing GTK, icon, Kvantum, font, terminal, Niri, and SDDM behavior. Neo Brutalism retains its 18px gaps, high-contrast ring, and hard offset shadow. The Neo full bar uses a 14px edge inset so its visible edge aligns with the focused Niri window, and reserves the full floating footprint through Quickshell's layer-shell `exclusiveZone`; Material 3 and Nothing keep the normal reservation.

Neo Brutalism uses JetBrains Mono, bold semantic ink outlines, pastel semantic fills, and hard offset shadows through shared surfaces and controls. Its dark mode is the negative treatment: dark surfaces use light semantic ink for the thick borders and hard offsets. Material 3 retains its Roboto Flex typography, tonal surfaces, and expressive shape/elevation treatment. Nothing Classic uses NType 82, NType 82 Mono, and NType 82 Headline, flat neutral tonal surfaces, rounded controls, segmented sliders, and restrained red signal accents. Nothing Evolution uses Geist and Geist Mono, wallpaper-aware adaptive roles, translucent layers, and selectable Gooey/Micrographics lock-screen faces.

### `bar/PopupShield.qml`

Full-screen transparent surface on `WlrLayer.Bottom` that catches clicks outside popups and dismisses them via `onShieldClicked`. The shield sits behind popups (which are on `WlrLayer.Top`) so clicks on popup content work normally while clicks outside reach the shield.

### `bar/FocusDismiss.qml`

Handles popup dismissal on app focus loss with target null checks. The `activeFocusChanged` check is gated behind `config.isNiri`. The `Qt.application.activeChanged` check runs on all WMs — it correctly detects when the user switches to another application.

## Widget Details

- **Bar.qml**: Single component for all four placements and both display styles (continuous full bar / floating pills bar), driven by `barPosition`, `horizontal`, `pillsBar`, and `fullBar` properties. In pills mode, every visible widget receives its own floating surface while the transparent panel still provides the input region for gaps and outside-click dismissal. Surface geometry follows the selected UI style.
- **WorkspaceIndicator**: 100% event-driven. Streams workspaces from Niri (`niri msg event-stream`) using `SplitParser`. Runs only when visible. Anchored directly in the workspace zone so it stays stationary in both display styles and orientations.
- **AudioIndicator / BrightnessIndicator / MediaIndicator / WeatherIndicator**: Event-driven watchers and polling loops are bound to their active/visible state, so they are suspended when their parent bar is hidden, saving CPU wakeups and RAM.
- **BatteryIndicator**: Utilizes UPower property bindings (no timers) to react directly to battery changes.
- **WifiPanel / BtPanel**: Network and Bluetooth controls live in Settings tabs, including saved Wi-Fi profiles, Bluetooth discovery/pairing, and connected-device actions. They are intentionally not rendered as compact bar indicators.
- **SystemTrayArea**: Renders StatusNotifier items with left-click activate and right-click context menu, orientation-aware layout.
- **QuickMenu**: Nothing Evolution presents a five-tile Quick Settings row for Caffeine, airplane mode, Bluetooth, DND, and lock; Classic retains the same controls with the existing Power Options title and confirmed power actions.
- **Settings**: Provides the eleven tabs listed above, remembers the last selected tab, keeps Network and Bluetooth Settings-only, and preserves Settings/power entry points even when bar content switches are disabled.
- **Weather**: Uses a configured manual location by default, optionally supports IP geolocation, refreshes on the persisted interval, reports the last update time, and shows an explicit unavailable/offline state when data cannot be fetched.
- **Notifications**: Retains history while DND or quiet hours suppress toast delivery; critical-notification bypass, toast placement, retention, and clear-history actions are persisted.
- **Dark Mode Preference**: Event-driven tracking via a one-time startup query (`gsettings get`) and a continuous background monitor (`gsettings monitor`) with a `SplitParser` listener, saving CPU cycles. Because `Colors.qml` hot-reloads reset `systemDark` to its template default, a polling re-query runs in `shell.qml` after reloads.
- **Theme ownership**: Matugen remains the dynamic palette source for Material 3, Neo Brutalism, Nothing Evolution, and external desktop themes. `scripts/apply-wallpaper.sh` applies the wallpaper via `awww`, refreshes the Matugen cache, regenerates the existing Material 3 and Neo Brutalism desktop themes, and re-runs the light/dark synchronizer. `config/Colors.qml` consumes those cached semantic roles for Material 3, Neo Brutalism, and Nothing Evolution; Nothing Classic and Ghost select authored light/dark Quickshell palettes. `sync-theme-mode.sh` selects the matching GTK, icon, Kvantum, Qt6ct, Kitty, Starship, btop, and Neovim settings for each available style, with `generate-neo-kitty-theme.sh` refreshing Neo's terminal files from the cache. The root-owned `scripts/sync-sddm-theme-root.sh` helper, installed at `/usr/local/libexec/quickshell-sync-sddm-theme` with its polkit action, supports the single dark-only `Ghost-SDDM` greeter for both modes and updates the SDDM drop-in only when the explicit selector changes. `scripts/apply-accent-color.sh` is a compatibility stub. The independent `Settings.themeStyle` choice is propagated to GTK, icons, Qt/Kvantum, fonts, Kitty, Starship, btop, Neovim, and SDDM by the theme synchronizers and to Niri focus-ring/window-border width/colors by `sync-terminal-theme.sh`, while Neo full-bar geometry owns its extra layer-shell reservation in `Bar.qml`.
- **New deployment**: `yadm bootstrap` (or `/home/mura/install.sh`) offers to run `scripts/install-ui-suite.sh`. The installer clones the Material 3, Neo Brutalism, Nothing, and Ghost source projects into `~/Projects`, reuses their existing build/install scripts, installs the system SDDM outputs and bridge, syncs the active terminal/editor/desktop state, and leaves generated theme assets outside yadm. Run it directly with `./scripts/install-ui-suite.sh`; use `--dry-run`, `--skip-sddm`, `--skip-cursors`, or `--skip-nvim` for controlled deployments. `scripts/verify-ui-suite.sh` checks GTK, icons, Kvantum, cursors, Kitty, Starship, btop, Neovim, and SDDM across the full suite.
- **Appearance tab**: Owns color mode, UI style, palette source/reload, bar placement, bar display style, UI sizing, independent bar-clock sizing controls, and the confirmed appearance-default reset.
- **Wallpaper tab**: Lists images from `~/Pictures/Walls`; `scripts/generate-thumbnails.sh` produces and caches 200×130 center-cropped thumbnails under `~/.cache/quickshell/wallpaper-thumbs`, regenerating only when the source is newer than the cached thumbnail. The tab tracks the active wallpaper, supports keyboard selection, and exposes randomize/apply actions.
- **Lock & Power tab**: Owns lock-screen options, idle lock/suspend timeouts, Caffeine, TLP power-profile selection with automatic AC/battery restore, and the Evolution-only Gooey/Micrographics clock-face selector.
- **Media tab**: Owns media artwork, progress, and always-visible-control preferences for the media popup.
- **Media / MPRIS**: `scripts/mpris_monitor.py` broadcasts the active player's state as newline-delimited JSON over stdout (consumed via `SplitParser`), and also listens on a `/tmp/qsmpris-fifo` named pipe for out-of-band pokes. `scripts/mpris_control.py` sends play/pause/next/prev to whichever player is currently active (preferring a "Playing" one); the visualizer is available in the Settings media controls.
- **OSD**: A separate always-on-top `PanelWindow` (`bar/OsdOverlay.qml`), not part of the popup/`openPopup` system. Auto-hides after 1.5s. Polls sysfs directly for the ThinkPad keyboard backlight since the EC never emits a Wayland key event for `Fn+Space`.
- **Lock Screen Security**: Employs imperative start/stop handlers in `onLockedChanged` for `fprintdProcess` to prevent QML declarative property binding breaks.

## Dependencies

- **Quickshell** — the shell framework
- **Qt6** (QtQuick, QtWayland)
- **Niri** — compositor, workspace/window state, actions, and shell integration
- **Python 3** — for `.desktop` parsing, weather, MPRIS, and voice search
- **python-vosk** — offline speech recognition (model auto-downloaded to `~/.local/share/vosk-model` on first use)
- **python-dbus** / **PyGObject** — MPRIS monitoring and control
- **pw-record** (from `pipewire-utils`) — recording mic input
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
- **cava** — real-time audio visualizer (raw ASCII output consumed by the Settings waveform)
- **swayidle** — idle timeout handling (dim/lock/DPMS/suspend), configured by Lock & Power settings
- **inotify-tools** (`inotifywait`) — trigger-file and brightness-file watching

---

## Disclaimer

This theme suite and shell configuration was generated and vibe-coded using **Antigravity**, an AI agentic coding assistant designed by the Google DeepMind team.

---

## License

This project is licensed under the terms of the GNU General Public License v3.0 (GPL-3.0). See the [LICENSE](file:///home/mura/.config/quickshell/LICENSE) file for details.
