# Quickshell Desktop Shell

A custom desktop shell built with [Quickshell](https://quickshell.outfoxxed.me/), running on **Niri**.

## Overview

This replaces a traditional status bar (waybar) and panel infrastructure with a unified QML-based shell. It provides:

- **Vertical & Horizontal panel layouts** with workspace/tag indicators, system status widgets, and popup panels
- **Layout Toggling**: Switch between vertical and horizontal layouts dynamically via a toggle button in the Quick Settings menu, with selection persistent across reboots (saved to `~/.config/quickshell/layout`)
- **Lock screen** with PAM + fingerprint authentication
- **Notification handling** with history and toasts, styled in Material Design 3
- **App launcher** with fuzzy search and local offline **voice search** capabilities
- **Tabbed Command Center / Control Panel**: A multi-functional panel launched via `XF86Tools` featuring:
  - **Overview tab**: System greeting, profile avatar, active session info, system uptime, clock, date, and sliders
  - **Media Player tab**: Audio playback widget with wave visualizer animation around album art, dynamic volume adjustment wheel, source mute toggle, device mixer shortcut (`pavucontrol`), and active player switcher (`mpris_monitor.py` IPC)
  - **Wallpapers tab**: Visual selector grid displaying local wallpapers with auto-scrolling to the active image and a dynamic title naming the selected filename
  - **Weather tab**: Detailed 5-day weather forecasts and a conditions grid (Feels Like, Humidity, Wind Speed, Pressure, UV Index, Precipitation chance)
  - **Settings tab**: Quick toggles for alignment layouts, dark/light theme modes, caffeinate/sleep inhibit behavior, and live CPU/Memory/Disk storage diagnostics gauges

## Project Structure

```
~/.config/quickshell/
├── shell.qml                  # Entry point — ShellRoot, IpcHandler, layout toggle, triggers
├── config/
│   ├── Config.qml             # Layout constants, centralized WM detection
│   └── Colors.qml             # Material Design 3 light/dark theme color tokens
├── bar/
│   ├── VerticalBar.qml        # Main vertical panel — the side bar itself
│   ├── HorizontalBar.qml      # Main horizontal panel — the top bar itself
│   ├── CommandCenter.qml      # Centered tabbed command center (Session, Media, Wallpapers, Weather, Settings)
│   ├── LockScreen.qml         # PAM auth, fingerprint, clock, power buttons (secure binding fixes)
│   ├── WorkspaceIndicator.qml # Workspace/tag pills (Niri) for vertical mode
│   ├── HorizontalWorkspaceIndicator.qml # Workspace/tag pills for horizontal mode
│   ├── Launcher.qml           # App launcher button
│   ├── LauncherPopup.qml      # App search (text/voice input) popup
│   ├── AudioIndicator.qml     # Volume icon + scroll control (orientation-aware)
│   ├── AudioPopup.qml         # Volume + mic sliders (M3 bordered, correct active/mute states)
│   ├── BrightnessIndicator.qml # Brightness icon (orientation-aware)
│   ├── BrightnessPopup.qml    # Brightness slider (M3 bordered)
│   ├── BatteryIndicator.qml   # Battery via UPower (orientation-aware)
│   ├── BatteryPopup.qml       # Detailed battery info (M3 bordered)
│   ├── WifiIndicator.qml      # Wifi strength indicator (orientation-aware)
│   ├── WifiPopup.qml          # Wifi scan/connect (checkmark contrast fix)
│   ├── BtIndicator.qml        # Bluetooth status + connected device battery (orientation-aware)
│   ├── BtPopup.qml            # Bluetooth devices + battery info & disconnect hover action
│   ├── SystemTrayArea.qml     # StatusNotifier tray icons for vertical bar
│   ├── HorizontalSystemTrayArea.qml # StatusNotifier tray icons for horizontal bar
│   ├── MenuIndicator.qml      # Quick settings trigger
│   ├── QuickMenu.qml          # Layout toggle, idle, dark mode, power options (wallpaper changer relocated here)
│   ├── CalendarPopup.qml      # Calendar month grid (M3 bordered)
│   ├── NotificationIndicator.qml # Notifications counter (orientation-aware)
│   ├── NotificationPopup.qml  # M3 notification history popup list
│   ├── NotificationToast.qml  # M3 notification toast banner
│   └── WallpaperChanger.qml   # Periodic wallpaper rotation
├── resources/
│   ├── lock_bg.png            # Lock screen background wallpaper
│   └── vosk-model/            # Offline speech recognition acoustic model folder
├── scripts/
│   ├── lock                   # Lock trigger (touches /tmp/qslock-trigger)
│   ├── commandcenter          # Command Center trigger script (touches /tmp/qscommandcenter-trigger)
│   ├── idle.sh                # swayidle: dim, lock, display off, suspend
│   ├── idle.sh.bak            # Previous idle script backup
│   ├── lid.sh                 # Lid close: lock + suspend
│   ├── mpris_monitor.py       # Active MPRIS state broadcaster and /tmp/qsmpris-fifo listener
│   ├── weather.py             # Open-Meteo weather fetcher script
│   └── voice-search.py        # Local speech transcription via python-vosk
└── bin/
    └── desktop-parser.py      # .desktop → JSON for launcher
```

## WM Integration

Quickshell runs as a Wayland layer surface (side panel) on top of the compositor. It integrates with **Niri** using the Niri socket.

### Niri Startup

Quickshell can be managed via a systemd user service to ensure rate-limiting and session-binding (recommended to prevent infinite coredump storms in case of Wayland crashes/logouts).

Create a service file at `~/.config/systemd/user/quickshell.service`:

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

Then in `~/.config/niri/startup.kdl`:

```
spawn-sh-at-startup "~/.config/quickshell/scripts/idle.sh"
spawn-at-startup "systemctl" "--user" "start" "quickshell.service"
```

Quickshell auto-discovers `~/.config/quickshell/shell.qml` as the default config when run without arguments.



### Lid Switch

Both compositors handle lid close via `~/.config/quickshell/scripts/lid.sh`, which locks then suspends:

| WM | Lid Close Handler |
|---|---|
| **Niri** | `config.kdl`: `switch-events { lid-close { spawn "/home/mura/.config/quickshell/scripts/lock"; } }` |

## Keybindings

Five keyboard shortcuts are handled by Quickshell:

| Key | Action | Mechanism |
|---|---|---|
| `SUPER+d` | Toggle app launcher popup | `touch /tmp/qslauncher-trigger` |
| `SUPER+Escape` | Toggle quick menu (power/logout) | `touch /tmp/qsquickmenu-trigger` |
| `XF86Tools` | Toggle Command Center popup | `~/.config/quickshell/scripts/commandcenter` |
| `CTRL+ALT+l` | Lock screen | `~/.config/quickshell/scripts/lock` |
| `SUPER+Alt+l` (Niri) | Lock screen | `~/.config/quickshell/scripts/lock` |

On Niri, these keybindings are managed by Niri's config instead.

### External Triggers

Any script or keybinding can trigger Quickshell actions by creating these files:

- `/tmp/qslauncher-trigger` — toggles the launcher popup
- `/tmp/qsquickmenu-trigger` — toggles the quick settings menu
- `/tmp/qscommandcenter-trigger` — toggles the command center popup (created by `scripts/commandcenter`)
- `/tmp/qslock-trigger` — activates the lock screen (created by `scripts/lock`)

Quickshell watches for these files via `Process` + `inotifywait` (zero CPU while idle) and responds instantly. The file triggers delegate to `IpcHandler` methods, which can also be invoked directly via `quickshell ipc call shell.<name>`.

### OSD Triggers (Quick Settings toggles)

- `/tmp/qsosd-vol` — show volume OSD
- `/tmp/qsosd-bright` — show brightness OSD
- `/tmp/qsosd-mic` — show mic mute OSD

## IPC

`shell.qml` defines an `IpcHandler` with `target: "shell"` exposing three functions:

- `ipc.launcher()` — toggle launcher popup
- `ipc.lock()` — activate lock screen
- `ipc.quickmenu()` — toggle quick menu

These are callable externally via `quickshell ipc call shell.launcher` (and similar) and are also invoked by the file trigger watchers for backward compatibility.

## Lock Screen

The lock screen (`bar/LockScreen.qml`) was extracted from `shell.qml` as a standalone component. It uses `WlSessionLock` with:

- **PAM password auth** via `Quickshell.Services.Pam`
- **Fingerprint reader** via `fprintd-verify` (auto-retries on failure)
- Profile image, live clock, suspend/reboot/poweroff buttons
- Background image from `resources/lock_bg.png`
- Controlled via `IpcHandler.lock()`, `scripts/lock`, or directly via `touch /tmp/qslock-trigger`

## Popup System

Popup visibility is driven entirely by the bar's `openPopup` string property. Each indicator widget signals a popup name, and the corresponding popup shows/hides accordingly.

Popup positioning and animations are dynamic depending on the active bar orientation:
- **Vertical mode**: Anchored to the triggering widget's Y coordinate, sliding out from the left.
- **Horizontal mode**: Anchored directly beneath the bar (`barWidth + 4`), horizontally centered on the clicked widget's X coordinate, and clamped to fit the screen.

Escape or clicking outside (on another window) dismisses the active popup. All popups use `WlrLayer.Top` and `PopupShield` sits on `WlrLayer.Bottom` to intercept outside clicks. `FocusDismiss` handles dismissal on app focus loss with platform-specific gating for the `activeFocusChanged` check.

| Popup | Trigger | Content |
|---|---|---|
| Launcher | `Launcher` button / `SUPER+d` | App search bar (I-beam text pointer + offline voice search) + `.desktop` list |
| Audio | `AudioIndicator` click | Volume + mic sliders (M3 switches; active check = sound enabled, unchecked = muted) |
| Brightness | `BrightnessIndicator` click | Brightness slider (M3 bordered) |
| Battery | `BatteryIndicator` click | Percentage, energy capacity, status, rate, cycles, model (M3 bordered) |
| Bluetooth | `BtIndicator` click | Bluetooth devices, battery percentages, disconnect button, power switch |
| Calendar | Clock click | Month grid with navigation (M3 bordered) |
| Notifications | `NotificationIndicator` click | M3-compliant card layout list tracked via `modelData` |
| Quick Menu | `MenuIndicator` click / `SUPER+Escape` | Layout toggle, idle inhibit, dark mode, power (M3 bordered) |
| Command Center | `XF86Tools` | 5 tabs: Session Overview, Media Player, Wallpapers selection, Weather forecasts, and Settings/System Diagnostics (M3 bordered, 800x600 size) |

## Configuration

### `config/Config.qml`

Layout and behavior constants: `barWidth`, `widgetSize`, `iconSize`, `fontPixelSize`, `animationDuration`, `popupWidth`, `borderRadius`, etc.

### `config/Colors.qml`

Material Design 3 color tokens with runtime dark/light theme switching. System dark mode is detected by polling `gsettings get org.gnome.desktop.interface color-scheme` every 5s. Text/icon colors are prefixed with `fg` (e.g. `fgSurface`, `fgPrimary`) to prevent conflicts with QML's internal signal handler compiler rules.

### `bar/PopupShield.qml`

Full-screen transparent surface on `WlrLayer.Bottom` that catches clicks outside popups and dismisses them via `onShieldClicked`. The shield sits behind popups (which are on `WlrLayer.Top`) so clicks on popup content work normally while clicks outside reach the shield.

### `bar/FocusDismiss.qml`

Handles popup dismissal on app focus loss with target null checks. The `activeFocusChanged` check is gated behind `config.isNiri`. The `Qt.application.activeChanged` check runs on all WMs — it correctly detects when the user switches to another application.

## Widget Details

- **WorkspaceIndicator / HorizontalWorkspaceIndicator**: 100% event-driven. Streams workspaces from Niri (`niri msg event-stream`) using `SplitParser`. Runs only when visible. When the bar is in its collapsed pill state, the container is anchored directly in the workspace zone (50px offset) instead of centered on the screen, keeping the workspace indicator completely stationary during the entire expand/collapse transition in both orientations.
- **AudioIndicator / BrightnessIndicator / BtIndicator / WifiIndicator**: Event-driven watchers and polling loops are bound to `root.visible`, so they are fully suspended when their parent bar is hidden, saving CPU wakeups and RAM.
- **BatteryIndicator**: Utilizes UPower property bindings (no timers) to react directly to battery changes.
- **SystemTrayArea / HorizontalSystemTrayArea**: Renders StatusNotifier items with left-click activate and right-click context menu.
- **QuickMenu (Layout Toggle)**: The WiFi button was replaced with a layout toggle. When clicked, it toggles `isHorizontal` and persists the state. The wallpaper changer was relocated inside the Quick Settings layout.
- **BtIndicator & BtPopup**: Displays the battery percentage of the connected device directly underneath the bluetooth icon. The popup lists connected devices with their MAC, names, and battery level, offering a `link_off` disconnect button on hover.
- **Dark Mode Preference**: Event-driven tracking via a one-time startup query (`gsettings get`) and a continuous background monitor (`gsettings monitor`) with a `SplitParser` listener, saving CPU cycles.
- **Lock Screen Security**: Employs imperative start/stop handlers in `onLockedChanged` for `fprintdProcess` to prevent QML declarative property binding breaks.

## Dependencies

- **Quickshell** — the shell framework
- **Qt6** (QtQuick, QtWayland)
- **Python 3** — for `.desktop` parsing & `vosk` voice search
- **python-vosk** — offline speech recognition API
- **pw-record** (from `pipewire-utils`) — recording mic input
- **wpctl** (WirePlumber) — audio control
- **brightnessctl** — backlight control
- **UPower** — battery monitoring
- **fprintd** — fingerprint authentication
- **brightnessctl**, **nmcli**, **bluetoothctl** — quick settings
- **swayosd-client** — OSD feedback for media keys

---

## Disclaimer

This theme suite and shell configuration was generated and vibe-coded using **Antigravity**, an AI agentic coding assistant designed by the Google DeepMind team.

---

## License

This project is licensed under the terms of the GNU General Public License v3.0 (GPL-3.0). See the [LICENSE](file:///home/mura/.config/quickshell/LICENSE) file for details.
