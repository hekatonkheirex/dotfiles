# Quickshell Desktop Shell

A custom desktop shell built with [Quickshell](https://quickshell.outfoxxed.me/), running on **Niri**.

## Overview

This replaces a traditional status bar (waybar) and panel infrastructure with a unified QML-based shell. It provides:

- **A single collapsible bar** (`bar/Bar.qml`) that toggles between vertical and horizontal orientation, and between a collapsed pill and an expanded strip. The collapsed state shows only the workspace indicator; hovering (or opening a popup) expands the rest of the widgets in with a spring animation. A "keep expanded" setting (`fullBar`) pins it open permanently.
- **Layout Toggling**: Switch orientation via the Settings Appearance tab, persisted across reboots (saved to `~/.config/quickshell/layout`).
- **Lock screen** with PAM + fingerprint authentication.
- **Notification handling** with history and toasts, styled in Material 3 Expressive.
- **Do Not Disturb** suppresses toast popups while retaining incoming notifications in the bell history; the Quick Menu and Notifications tab share the persisted setting.
- **Battery alert watcher**: warning at 20%, critical alert at 10%, persistent `notify-send` notifications driven off `UPower.onBattery` (not raw charge state, which sawtooths under charge-conservation thresholds).
- **App launcher** with fuzzy app search, local offline **voice search**, allowlisted shell actions via `>`, and wallpaper search via `@`.
- **On-Screen Display (OSD)** overlay for volume, brightness, mic mute, airplane mode, bluetooth, and keyboard backlight (polled from sysfs since the EC never emits a key event for it).
- **Settings panel**: A multi-functional panel launched via `XF86Tools` with nine tabs:
  - **Account**: Profile, session, uptime, machine information, lock, and Quickshell restart actions
  - **Appearance**: Light/dark mode, bar alignment, sizing controls, and wallpaper selection with cached thumbnails
  - **General**: Motion, uptime, clock, calendar week start, timezone, bar indicator visibility, and weather unit settings
  - **Lock & Media**: Lock-screen media/clock options plus media artwork, progress, and control visibility
  - **Network**: Wi-Fi power, scan, connect, and disconnect controls; Wi-Fi is Settings-only and has no compact bar indicator
  - **Bluetooth**: Bluetooth power and connected-device controls; Bluetooth is Settings-only and has no compact bar indicator
  - **Notifications**: Do Not Disturb, toast duration, test notifications, and history guidance
  - **Shortcuts**: Curated Niri keybind reference
  - **System**: CPU, memory, disk, swap, thermal, fan, battery, and load diagnostics
- **Persisted user settings** (`settings.json`, `config/Settings.qml`) separate from build-time layout/typography tokens (`config/Config.qml`).

## Project Structure

```
~/.config/quickshell/
├── shell.qml                  # Entry point — ShellRoot, IpcHandler, popups, battery alert, file triggers
├── settings.json              # Persisted user settings (JsonAdapter-backed)
├── layout                     # Persisted orientation preference ("horizontal" | "vertical")
├── config/
│   ├── Config.qml             # Build-time layout, typography, shape, and motion tokens
│   ├── Settings.qml           # Persisted preferences singleton (FileView + JsonAdapter over settings.json)
│   ├── Colors.qml             # Matugen-backed Material You roles with fallbacks + system dark-mode tracking
│   └── cava.ini                # cava config for the real-time audio visualizer
├── bar/
│   ├── Bar.qml                 # The panel itself — collapsible/expandable, orientation-aware active indicators
│   ├── CommandCenter.qml       # Settings panel shell (state, processes, tab bar) — content in commandcenter/
│   ├── commandcenter/
│   │   ├── AccountTab.qml
│   │   ├── AppearanceTab.qml
│   │   ├── GeneralTab.qml
│   │   ├── LockMediaTab.qml
│   │   ├── NetworkTab.qml
│   │   ├── BluetoothTab.qml
│   │   ├── NotificationsTab.qml
│   │   ├── ShortcutsTab.qml
│   │   └── SystemTab.qml
│   ├── LockScreen.qml          # PAM auth, fingerprint, clock, power buttons (secure binding fixes)
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
│   ├── QuickMenu.qml           # Caffeine, airplane, DND, lock, and power actions
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
│   ├── SliderControl.qml       # Reusable M3 slider (volume/brightness/etc.)
│   ├── SwitchControl.qml       # Reusable M3 switch/toggle
│   ├── WaveProgressBar.qml     # Reusable wavy progress bar canvas (progress, lineWidth, dotRadius, trackLineWidth)
│   └── primitives/             # Shared buttons, list items, and text fields
│       ├── ActionButton.qml
│       ├── IconButton.qml
│       ├── ListItem.qml
│       ├── StatusIndicator.qml
│       └── TextFieldControl.qml
├── scripts/
│   ├── launcher                # Launcher trigger (touches /tmp/qslauncher-trigger)
│   ├── quickmenu                # Quick menu trigger (touches /tmp/qsquickmenu-trigger)
│   ├── commandcenter            # Settings trigger (touches /tmp/qscommandcenter-trigger)
│   ├── lock                     # Lock trigger (touches /tmp/qslock-trigger)
│   ├── apply-wallpaper.sh       # Wallpaper selection + Matugen/theme refresh
│   ├── apply-accent-color.sh    # Compatibility stub — palette is fixed by Matugen, not user-selectable
│   ├── generate-thumbnails.sh   # Generates/caches wallpaper thumbnails for the Appearance tab
│   ├── m3-qmllint-gate.sh       # QML regression gate for the M3 refactor, including shared primitives
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
| `XF86Tools` | Toggle Settings popup | `scripts/commandcenter` → `touch /tmp/qscommandcenter-trigger` |
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
- `/tmp/qscommandcenter-trigger` — toggles the Settings popup
- `/tmp/qslock-trigger` — activates the lock screen
- `/tmp/qsosd-vol` / `qsosd-bright` / `qsosd-mic` / `qsosd-airplane` / `qsosd-bluetooth` — show the corresponding OSD

`bar/FileTrigger.qml` watches `/tmp` with a single persistent `inotifywait` process (zero CPU while idle, one watcher for every registered trigger) and dispatches to the matching `IpcHandler` method or `OsdOverlay.show()` call. Any trigger file already present on startup fires immediately. Triggers can also be invoked directly via `quickshell ipc call shell <name>`.

## IPC

`shell.qml` defines an `IpcHandler` with `target: "shell"` exposing:

- `ipc.launcher()` — toggle launcher popup
- `ipc.lock()` — activate lock screen
- `ipc.quickmenu()` — toggle quick menu
- `ipc.commandcenter()` — toggle Settings popup
- `ipc.layout()` — toggle bar orientation

Callable externally via `quickshell ipc call shell launcher` (and similarly for the others).

## Lock Screen

`bar/LockScreen.qml` is a standalone component using `WlSessionLock` with:

- **PAM password auth** via `Quickshell.Services.Pam`
- **Fingerprint reader** via `fprintd-verify` (auto-retries on failure), started/stopped imperatively in `onLockedChanged` to avoid QML declarative binding breaks
- Profile image (`~/Pictures/profile.jpg`), live clock, suspend/reboot/poweroff buttons
- Animated background (`AnimatedBackground.qml`), with text colors fixed to white regardless of the desktop's light/dark mode
- Controlled via `IpcHandler.lock()`, `scripts/lock`, or directly via `touch /tmp/qslock-trigger`

## Popup System

Popup visibility is driven entirely by the bar's `openPopup` string property, held on `Bar.qml` and read by `shell.qml`. Each indicator widget signals a popup name, and the corresponding popup shows/hides accordingly.

Popup positioning is dynamic depending on the active bar orientation (computed in `shell.qml`'s `popupMarginLeft`/`popupMarginTop`):
- **Horizontal mode**: Anchored beneath the bar, horizontally centered on the clicked widget's X coordinate, clamped to fit the screen.
- **Vertical mode**: Anchored past the bar's right edge, vertically aligned to the triggering widget's Y coordinate.

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
| Settings | Settings bar icon / `XF86Tools` | 9 tabs: Account, Appearance, General, Lock & Media, Network, Bluetooth, Notifications, Shortcuts, System (responsive M3 surface) |
| OSD | volume/brightness/mic/airplane/bluetooth/kbd-backlight keys | Auto-dismissing bottom-anchored status card (not part of the `openPopup` system — a separate always-on-top window) |

## Configuration

### `config/Config.qml`

Build-time layout, typography, shape, and motion tokens: `barWidth`, `widgetSize`, M3 type sizes, spacing, shape scale, motion durations (`motionShort`/`Medium`/`Long`/`ExtraLong`, all zeroed when `reducedMotion` is on), `popupWidth`, Settings min/max dimensions, and step sizes for volume/brightness.

### `config/Settings.qml`

Persisted user preferences singleton (`FileView` + `JsonAdapter` over `~/.config/quickshell/settings.json`, created on first run if missing). Backs `fullBar` (keep bar expanded), motion and sizing, clock/calendar/timezone settings, bar indicator visibility, notification behavior, lock and media options, and weather city/units. Values round-trip live via `watchChanges: true`; call `Settings.save()` after mutating an alias to persist.

### `config/Colors.qml`

Material You / Material 3 semantic roles are resolved in `Colors.qml` from Matugen's `~/.cache/matugen/current_palette.json`. The file keeps authored light/dark fallbacks for first boot and generator failures, while the active light and dark roles are shared by the bar, popups, Settings, OSD, notifications, and lock screen.

Format: `l_<token>` (light), `d_<token>` (dark), and flat resolved `<token>` properties (no prefix) for current mode. Text/icon colors are prefixed with `fg` (e.g. `fgSurface`, `fgPrimary`) to prevent conflicts with QML's internal signal handler compiler rules.

System dark mode is read once and monitored through `gsettings` (owned by `Colors.qml` itself, since it's the single instance everyone reads from). Mode toggles in QuickMenu or Settings call the existing desktop mode synchronizer, while the shell selects the matching Matugen light/dark roles locally.

### `bar/PopupShield.qml`

Full-screen transparent surface on `WlrLayer.Bottom` that catches clicks outside popups and dismisses them via `onShieldClicked`. The shield sits behind popups (which are on `WlrLayer.Top`) so clicks on popup content work normally while clicks outside reach the shield.

### `bar/FocusDismiss.qml`

Handles popup dismissal on app focus loss with target null checks. The `activeFocusChanged` check is gated behind `config.isNiri`. The `Qt.application.activeChanged` check runs on all WMs — it correctly detects when the user switches to another application.

## Widget Details

- **Bar.qml**: Single component for both orientations and both bar states (collapsed pill / expanded strip), driven by `horizontal`, `expanded`/`expandProgress`, and `fullBar` properties. Hovering the bar (or opening a popup while hovering) expands it; a 5-second `collapseTimer` re-collapses it once the mouse leaves and no popup is open, unless `fullBar` is set. `mask: Region { item: barBg }` keeps the click/hover region matched to the visible pill/strip shape during the animation.
- **WorkspaceIndicator**: 100% event-driven. Streams workspaces from Niri (`niri msg event-stream`) using `SplitParser`. Runs only when visible. Anchored directly in the workspace zone so it stays stationary through the bar's expand/collapse transition in both orientations.
- **AudioIndicator / BrightnessIndicator / MediaIndicator / WeatherIndicator**: Event-driven watchers and polling loops are bound to their active/visible state, so they are suspended when their parent bar is hidden, saving CPU wakeups and RAM.
- **BatteryIndicator**: Utilizes UPower property bindings (no timers) to react directly to battery changes.
- **WifiPanel / BtPanel**: Network and Bluetooth controls live in Settings tabs. They are intentionally not rendered as compact bar indicators.
- **SystemTrayArea**: Renders StatusNotifier items with left-click activate and right-click context menu, orientation-aware layout.
- **QuickMenu**: Caffeine mode, airplane mode, DND, lock, and confirmed power actions.
- **Settings**: Provides the nine tabs listed above, with Network and Bluetooth kept Settings-only.
- **Dark Mode Preference**: Event-driven tracking via a one-time startup query (`gsettings get`) and a continuous background monitor (`gsettings monitor`) with a `SplitParser` listener, saving CPU cycles. Because `Colors.qml` hot-reloads reset `systemDark` to its template default, a polling re-query runs in `shell.qml` after reloads.
- **Theme ownership**: Matugen is the dynamic palette source. `scripts/apply-wallpaper.sh` applies the wallpaper via `awww`, refreshes the Matugen cache, regenerates the existing Material 3 desktop themes, and re-runs the light/dark synchronizer. `config/Colors.qml` consumes the cached semantic roles with authored fallbacks. `scripts/apply-accent-color.sh` is a compatibility stub — the palette is fully wallpaper-derived and not user-selectable at runtime.
- **Appearance tab**: Lists images from `~/Pictures/Walls`; `scripts/generate-thumbnails.sh` produces and caches 200×130 center-cropped thumbnails under `~/.cache/quickshell/wallpaper-thumbs`, regenerating only when the source is newer than the cached thumbnail.
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
- **swayidle** — idle timeout handling (dim/lock/DPMS/suspend)
- **inotify-tools** (`inotifywait`) — trigger-file and brightness-file watching

---

## Disclaimer

This theme suite and shell configuration was generated and vibe-coded using **Antigravity**, an AI agentic coding assistant designed by the Google DeepMind team.

---

## License

This project is licensed under the terms of the GNU General Public License v3.0 (GPL-3.0). See the [LICENSE](file:///home/mura/.config/quickshell/LICENSE) file for details.
