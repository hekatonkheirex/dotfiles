# Quickshell Desktop Shell

A custom desktop shell built with [Quickshell](https://quickshell.outfoxxed.me/), running on **Niri** or **MangoWM** (dwl-based).

## Overview

This replaces a traditional status bar (waybar/polybar) and panel infrastructure with a unified QML-based shell. It provides:

- **Vertical side panel** with workspace/tag indicators, system status widgets, and popup panels
- **Lock screen** with PAM + fingerprint authentication
- **Notification handling** with history and toasts
- **App launcher** that reads `.desktop` files

## Project Structure

```
~/.config/quickshell/
├── shell.qml                  # Entry point — ShellRoot, IpcHandler, triggers
├── config/
│   ├── Config.qml             # Layout constants (sizes, fonts, animation)
│   └── Colors.qml             # Material Design 3 light/dark theme, gsettings polling
├── bar/
│   ├── VerticalBar.qml        # Main panel — the side bar itself
│   ├── LockScreen.qml         # PAM auth, fingerprint, clock, power buttons
│   ├── WorkspaceIndicator.qml # Workspace/tag pills (Niri & MangoWM), 80ms polling
│   ├── Launcher.qml           # App launcher button
│   ├── LauncherPopup.qml      # App search & launch popup
│   ├── AudioIndicator.qml     # Volume icon + scroll control
│   ├── AudioPopup.qml         # Volume + mic sliders
│   ├── BrightnessIndicator.qml
│   ├── BrightnessPopup.qml
│   ├── BatteryIndicator.qml   # Battery via UPower
│   ├── BatteryPopup.qml       # Detailed battery info
│   ├── SystemTrayArea.qml     # StatusNotifier tray icons
│   ├── MenuIndicator.qml      # Quick settings trigger
│   ├── QuickMenu.qml          # WiFi, Bluetooth, idle, dark mode, power
│   ├── CalendarPopup.qml
│   ├── NotificationIndicator.qml
│   ├── NotificationPopup.qml  # Notification history (manual JS array tracking)
│   ├── NotificationToast.qml  # Transient toast popup
│   └── WallpaperChanger.qml   # Periodic wallpaper rotation
├── resources/
│   └── lock_bg.png            # Lock screen background wallpaper
├── scripts/
│   ├── lock                   # Lock trigger (touches /tmp/qslock-trigger)
│   ├── idle.sh                # swayidle: dim, lock, display off, suspend
│   ├── idle.sh.bak            # Previous idle script backup
│   └── lid.sh                 # Lid close: lock + suspend
└── bin/
    └── desktop-parser.py      # .desktop → JSON for launcher
```

## WM Integration

Quickshell runs as a Wayland layer surface (side panel) on top of the compositor. It auto-detects the WM via environment variables:

| WM | Detection | Workspace IPC |
|---|---|---|
| **Niri** | `XDG_CURRENT_DESKTOP=Niri` or `NIRI_SOCKET` set | `niri msg -j workspaces` |
| **MangoWM** | `MANGO_INSTANCE_SIGNATURE` set | `mmsg get all-tags` |

### Niri Startup

In `~/.config/niri/startup.kdl`:

```
spawn-sh-at-startup "~/.config/quickshell/scripts/idle.sh"
spawn-at-startup "sh" "-c" "while true; do quickshell --no-duplicate; done"
```

Quickshell auto-discovers `~/.config/quickshell/shell.qml` as the default config when run without arguments.

### MangoWM Startup

In `~/.config/mango/autostart.sh`:

```sh
~/.config/quickshell/scripts/idle.sh >/dev/null 2>&1 &
killall -q quickshell 2>/dev/null
sleep 0.5
while true; do
  WAYLAND_DISPLAY="$WAYLAND_DISPLAY" quickshell --no-duplicate 2>&1
done &
```

A restart loop in the autostart ensures quickshell recovers from crashes.

### Lid Switch

Both compositors handle lid close via `~/.config/quickshell/scripts/lid.sh`, which locks then suspends:

| WM | Lid Close Handler |
|---|---|
| **Niri** | `config.kdl`: `switch-events { lid-close { spawn "/home/mura/.config/quickshell/scripts/lock"; } }` |
| **MangoWM** | `keybinds.conf`: `switchbind=fold,spawn,~/.config/quickshell/scripts/lid.sh` |

## Keybindings

Four keyboard shortcuts are handled by Quickshell. MangoWM dispatches the keys but the actions are owned by Quickshell:

| Key | Action | Mechanism |
|---|---|---|
| `SUPER+d` | Toggle app launcher popup | `touch /tmp/qslauncher-trigger` |
| `SUPER+Escape` | Toggle quick menu (power/logout) | `touch /tmp/qsquickmenu-trigger` |
| `CTRL+ALT+l` | Lock screen | `~/.config/quickshell/scripts/lock` |
| `SUPER+Alt+l` (Niri) | Lock screen | `~/.config/quickshell/scripts/lock` |

On Niri, these keybindings are managed by Niri's config instead.

### External Triggers

Any script or keybinding can trigger Quickshell actions by creating these files:

- `/tmp/qslauncher-trigger` — toggles the launcher popup
- `/tmp/qsquickmenu-trigger` — toggles the quick settings menu
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

Popup visibility is driven entirely by the bar's `openPopup` string property. Each indicator widget signals a popup name, and the corresponding popup shows/hides accordingly. Popup positioning is anchored to the triggering widget's Y coordinate. Escape or clicking outside (on another window) dismisses the active popup.

All popups use `WlrLayer.Top` and `PopupShield` sits on `WlrLayer.Bottom` to intercept outside clicks. `FocusDismiss` handles dismissal on app focus loss with platform-specific gating for the `activeFocusChanged` check (off on MangoWM/dwl due to false positives).

| Popup | Trigger | Content |
|---|---|---|---|
| Launcher | `Launcher` button / `SUPER+d` | App search bar + `.desktop` list |
| Audio | `AudioIndicator` click | Volume + mic sliders |
| Brightness | `BrightnessIndicator` click | Brightness slider |
| Battery | `BatteryIndicator` click | Percentage, capacity, health, model |
| Calendar | Clock click | Month grid with navigation |
| Notifications | `NotificationIndicator` click | Notification history with dismiss (manual JS array tracking) |
| Quick Menu | `MenuIndicator` click / `SUPER+Escape` | WiFi, BT, idle inhibit, dark mode, power |

## Configuration

### `config/Config.qml`

Layout and behavior constants: `barWidth`, `widgetSize`, `iconSize`, `fontPixelSize`, `animationDuration`, `popupWidth`, `borderRadius`, etc.

### `config/Colors.qml`

Material Design 3 color tokens with runtime dark/light theme switching. System dark mode is detected by polling `gsettings get org.gnome.desktop.interface color-scheme` every 5s (since `Qt.styleHints.colorScheme` is unreliable in Quickshell). The light palette uses green tones matching the SDDM material-you theme.

### `bar/PopupShield.qml`

Full-screen transparent surface on `WlrLayer.Bottom` that catches clicks outside popups and dismisses them via `onShieldClicked`. The shield sits behind popups (which are on `WlrLayer.Top`) so clicks on popup content work normally while clicks outside reach the shield.

### `bar/FocusDismiss.qml`

Handles popup dismissal on app focus loss. The `activeFocusChanged` check is gated behind `config.isNiri` (MangoWM/dwl fires it falsely on any click). The `Qt.application.activeChanged` check runs on all WMs — it correctly detects when the user switches to another application.

## Widget Details

- **WorkspaceIndicator**: Polls the WM every ~80ms (restarting the process on completion). Parses JSON into pills; click to focus, scroll to cycle. Mango filters inactive tags; Niri shows all workspaces. Focused tag uses distinct colors per mode (light: primaryContainer bg + white text; dark: primary bg + onPrimary text).
- **AudioIndicator/BrightnessIndicator**: Poll `wpctl`/`brightnessctl` every 2 seconds. Scroll adjusts by 5%.
- **BatteryIndicator**: Reads UPower properties every 1 second. Shows charging/alert icons.
- **SystemTrayArea**: Renders StatusNotifier items with left-click activate and right-click context menu.
- **QuickMenu (idle toggle)**: Coffee button toggles `swayidle`. When lit (inhibitor ON), `swayidle` is killed so the screen never locks. When dimmed (inhibitor OFF), `swayidle` runs with normal timeouts (dim → lock → display off → suspend).
- **LauncherPopup**: Runs `desktop-parser.py` to index `.desktop` files, filters by search input, launches via kitty for terminal apps.

## Dependencies

- **Quickshell** — the shell framework
- **Qt6** (QtQuick, QtWayland)
- **Python 3** — for `.desktop` parsing
- **wpctl** (WirePlumber) — audio control
- **brightnessctl** — backlight control
- **UPower** — battery monitoring
- **fprintd** — fingerprint authentication
- **brightnessctl**, **nmcli**, **bluetoothctl** — quick settings
- **swayosd-client** — OSD feedback for media keys
