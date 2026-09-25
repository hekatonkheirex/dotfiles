# Quickshell Desktop Shell

A custom desktop shell built with [Quickshell](https://quickshell.outfoxxed.me/), running on **Niri or Mango**.

## Overview

This replaces a traditional status bar (waybar) and panel infrastructure with a unified QML-based shell. It provides:

- **A single bar** (`bar/Bar.qml`) that supports top, bottom, left, and right placement, with a choice between one continuous full bar and a pills bar where each widget floats in its own pill. The display-style setting (`fullBar`) is persisted with the other Appearance preferences.
- **Bar Placement**: Choose top, bottom, left, or right in the Settings Appearance tab, persisted across reboots (saved to `~/.config/quickshell/layout`). Legacy `horizontal` and `vertical` values remain supported as top and left.
- **Lock screen** with PAM + fingerprint authentication.
- **Ghost startup welcome**: when the Ghost style is selected, the original post-SDDM cyberbrain boot trace and female figure artwork briefly appear after Quickshell starts.
- **Notification handling** with history and toasts, styled through the selected UI system.
- **Do Not Disturb** suppresses toast popups while retaining incoming notifications in the bell history; the Quick Menu and Notifications tab share the persisted setting.
- **Battery alert watcher**: warning at 20%, critical alert at 10%, persistent `notify-send` notifications driven off `UPower.onBattery` (not raw charge state, which sawtooths under charge-conservation thresholds).
- **App launcher** with fuzzy app search that honors hidden/unavailable desktop entries and user overrides, local offline **voice search**, shell actions via `>` (including capture), clipboard history via `;`, and wallpaper search via `@`.
- **On-Screen Display (OSD)** overlay for volume, brightness, mic mute, airplane mode, bluetooth, and keyboard backlight (polled from sysfs since the EC never emits a key event for it).
- **Settings panel**: A multi-functional, resizable and draggable panel launched via `XF86Tools` with twelve tabs:
  - **Account**: Profile, session, uptime, machine information, lock, and Quickshell restart actions
  - **General**: Motion, reduced transparency, uptime, clock, calendar week start, timezone, bar contents, and weather location/refresh/privacy/unit settings
  - **Appearance**: Color mode, Live wallpaper-generated Material 3 colors or Fixed Catppuccin/Gruvbox/TokyoNight palettes, UI style previews with one-click revert, contrast, bar placement, workspace button shapes, sizing controls, color reload, and confirmed appearance reset
  - **Wallpaper**: Active-wallpaper tracking, cached thumbnails, keyboard navigation, random selection, and wallpaper switching
  - **Display & Input**: Per-output mode, scale, and transform controls plus touchpad, mouse, trackpoint, and edge-gesture settings
  - **Network**: Wi-Fi power, scan, connect, disconnect, saved-network, and autoconnect controls; Wi-Fi is Settings-only and has no compact bar indicator
  - **Bluetooth**: Bluetooth power, discovery, pairing, connected-device, and rename controls; Bluetooth is Settings-only and has no compact bar indicator
  - **Media**: Media artwork, progress, and control visibility
  - **Lock & Power**: Lock-screen media/clock and wallpaper options, idle lock/suspend timeouts, Caffeine, and TLP power profiles
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
├── resources/
│   └── images/welcome-cyberbrain.png # Recovered Ghost startup artwork
├── ui/
│   └── WelcomeScreen.qml       # Post-SDDM Ghost startup overlay
├── config/
│   ├── Config.qml             # Build-time layout, typography, shape, and motion tokens
│   ├── Settings.qml           # Persisted preferences singleton (FileView + JsonAdapter over settings.json)
│   ├── Colors.qml             # Material roles, palette resolution, fixed Classic Nothing/Ghost palettes, adaptive Evolution roles, Liquid Glass regular/clear roles, Matugen fallback + system dark-mode tracking
│   ├── PaletteCatalog.js      # Fixed Material 3, Catppuccin, Gruvbox, and TokyoNight semantic palettes
│   ├── AudioService.qml       # Shared PipeWire sink/source state and watcher
│   ├── BrightnessService.qml  # Shared backlight state and watcher
│   ├── BatteryService.qml     # Shared UPower battery-device selection
│   ├── MediaService.qml       # Shared MPRIS monitor state
│   ├── WeatherService.qml     # Shared weather fetch/cache state
│   └── cava.ini               # cava config for the real-time audio visualizer
├── bar/
│   ├── Bar.qml                 # The panel itself — full-bar/pills-bar styles, orientation-aware active indicators
│   ├── SettingsPanel.qml       # Settings panel shell (state, processes, tab bar) — content in settings/
│   ├── settings/
│   │   ├── AccountTab.qml
│   │   ├── AppearanceTab.qml
│   │   ├── WallpaperTab.qml
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
│   ├── LockScreen.qml          # PAM auth, fingerprint, adaptive clock faces, power buttons
│   ├── WorkspaceIndicator.qml  # Workspace/tag pills + focused-window state (orientation-aware)
│   ├── Launcher.qml            # App launcher button
│   ├── LauncherPopup.qml       # App/provider search (apps, clipboard, wallpapers, actions)
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
│   ├── MenuIndicator.qml       # Quick Settings bar trigger
│   ├── QuickMenu.qml           # Quick Settings plus caffeine, radio, DND, Settings, lock, and power actions
│   ├── OsdOverlay.qml          # Volume/brightness/mic/airplane/bluetooth/kbd-backlight OSD popup
│   ├── CalendarLogic.js        # Calendar weekday ordering and day-cell model
│   ├── CalendarPopup.qml       # Calendar month grid (M3 bordered)
│   ├── NotificationIndicator.qml # Notifications counter (orientation-aware)
│   ├── NotificationPopup.qml   # M3 notification history popup list
│   ├── NotificationToast.qml   # M3 notification toast banner
│   ├── AnimatedBackground.qml  # Reusable animated M3 blob background (popups/Settings)
│   ├── PopupBase.qml           # Shared popup chrome (background, border, Liquid Glass sheen, entry animation)
│   ├── PopupShield.qml         # Full-screen click-outside-to-dismiss surface
│   ├── PopupDivider.qml        # Reusable popup section divider
│   ├── PowerConfirmation.qml   # Confirmation surface for destructive power actions
│   ├── FocusDismiss.qml        # Popup dismissal on app focus loss
│   ├── FileTrigger.qml         # Private runtime trigger-file watcher (single inotifywait for all triggers)
│   ├── SliderControl.qml       # Theme-selected slider facade (volume/brightness/etc.)
│   ├── SwitchControl.qml       # Theme-selected switch/toggle facade
│   ├── WaveProgressBar.qml     # Reusable wavy progress bar canvas (progress, lineWidth, dotRadius, trackLineWidth)
│   ├── primitives/             # Shared buttons, list items, and text fields
│   │   ├── ActionButton.qml
│   │   ├── GlassSheen.qml
│   │   ├── IconGlyph.qml          # Liquid Glass symbolic icons; Material fallback elsewhere
│   │   ├── IconButton.qml
│   │   ├── ListDivider.qml
│   │   ├── ListItem.qml
│   │   ├── LoadingIndicator.qml
│   │   ├── PillSurface.qml
│   │   ├── StatusIndicator.qml
│   │   ├── StyledSurface.qml
│   │   └── TextFieldControl.qml
│   └── themes/                 # Separate UI-style implementations
│       ├── material3/          # Material 3 controls and ThemeTokens.qml
│       ├── nothing/             # Nothing controls, Evolution clock face, and ThemeTokens.qml
│       └── ghost/               # Ghost (GITS) controls and ThemeTokens.qml
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
│   ├── ensure-style-terminal-assets.sh # Restores fixed Nothing/Ghost terminal companions
│   ├── apply-accent-color.sh    # Compatibility stub — palette is fixed by Matugen, not user-selectable
│   ├── generate-thumbnails.sh   # Generates/caches wallpaper thumbnails for the Wallpaper tab
│   ├── m3-qmllint-gate.sh       # QML regression gate for the M3 refactor, including shared primitives
│   ├── install-ui-suite.sh      # Clones and installs Material 3, Nothing, and Ghost companion themes
│   ├── verify-ui-suite.sh       # Verifies user-level assets across supported UI styles
│   ├── install-sddm-integration.sh # Installs the root SDDM bridge and polkit policy
│   ├── verify-sddm-integration.sh  # Verifies the bridge and all supported SDDM theme assets
│   ├── idle.sh                  # Caffeine-controlled swayidle timeouts: dim, lock, display off, suspend
│   ├── idle-brightness-off      # Saves and dims brightness in the runtime directory
│   ├── idle-brightness-restore  # Validates and restores saved brightness
│   ├── sync-theme-mode-locked.sh # Serialized wrapper for the external theme synchronizer
│   ├── sync-mactahoe-theme.sh   # Selects MacTahoe GTK, icon, Kvantum, and cursor assets for Liquid Glass
│   ├── lid.sh                   # Lid close: lock
│   ├── safe-logout.sh           # Clean Niri/Mango quit, falls back to a session kill
│   ├── mpris_monitor.py         # Active MPRIS state broadcaster (DBus + private FIFO listener)
│   ├── mpris_control.py         # MPRIS play/pause/stop/next/prev control for the active player
│   ├── weather.py               # Open-Meteo weather fetcher script
│   └── voice-search.py          # Local speech transcription via python-vosk (downloads its model to ~/.local/share/vosk-model on first use)
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

When `Settings.themeStyle` is `ghost`, `ui/WelcomeScreen.qml` starts automatically after the shell is ready. It can also be replayed with `quickshell ipc call shell welcome`; other styles leave the overlay disabled.

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
- `ipc.welcome()` — replay the Ghost startup welcome overlay when Ghost is selected
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
- Liquid Glass always uses the active wallpaper with a full-screen blur and a restrained veil; its lock surface follows the macOS two-zone layout with a top date/time and a bottom identity prompt that reveals authentication on click, while other styles keep the existing wallpaper toggle and animated/flat fallback
- Lock requests are available through `IpcHandler.lock()`, `scripts/lock`, or the private runtime trigger; Mango routes them to `swaylock`

Niri starts an independent swayidle before-sleep watcher. It remains active
when Caffeine pauses the idle timeout watcher, and the lock helper waits for
WlSessionLock to report that every output is covered before returning.

## Popup System

Popup visibility is driven entirely by the bar's `openPopup` string property, held on `Bar.qml` and read by `shell.qml`. Each indicator widget signals a popup name, and the corresponding popup shows/hides accordingly.

Popup positioning follows the active bar placement (computed in `shell.qml`'s `popupMarginLeft`/`popupMarginTop`):
- **Top/bottom**: Anchored past the bar edge and horizontally centered on the clicked widget's X coordinate, clamped to fit the screen.
- **Left/right**: Anchored past the bar edge and vertically aligned to the triggering widget's Y coordinate.

All bar-owned popups, the shield, Settings, notifications, and power confirmation use the bar's display. Placement and wallpaper-launcher sizing are clamped in that display's local coordinates rather than the primary monitor's dimensions.

Escape or clicking outside (on another window) dismisses the active popup. All popups use `WlrLayer.Top` and `PopupShield` sits on `WlrLayer.Bottom` to intercept outside clicks. `FocusDismiss` watches the popup window's active focus item so moving focus between controls inside a popup does not dismiss it, while application deactivation closes transient popups. The full-page Settings surface remains open through Mango's transient layer-focus changes so switching tags or clients does not dismiss it. `PopupBase.qml` supplies the shared M3 background/border/entry-animation chrome that most popups build on; Liquid Glass adds translucent functional surfaces and a restrained sheen to that same path. Actual backdrop blur remains compositor-owned and is optional when the compositor has background effects enabled.

| Popup | Trigger | Content |
|---|---|---|
| Launcher | `Launcher` button / `Mod+D` | App/provider search (offline voice search, `>` actions and capture, `;` clipboard history, `@` wallpapers) + `.desktop` list |
| Audio | `AudioIndicator` click | Volume + mic sliders (M3 switches; active check = sound enabled, unchecked = muted) |
| Brightness | `BrightnessIndicator` click | Brightness slider (M3 bordered) |
| Battery | `BatteryIndicator` click | Percentage, energy capacity, status, rate, cycles, model (M3 bordered) |
| Calendar | Clock click | Month grid with navigation (M3 bordered) |
| Notifications | `NotificationIndicator` click | M3-compliant card layout list tracked via `modelData` |
| Quick Menu | `MenuIndicator` click / `Mod+Escape` | Caffeine, airplane mode, DND, Settings, lock, and confirmed power actions (M3 bordered) |
| Settings | Quick Settings entry / `XF86Tools` | 12 tabs: Account, General, Appearance, Wallpaper, Display & Input, Network, Bluetooth, Media, Lock & Power, Notifications, System, Shortcuts (responsive surface with persisted last tab, drag-to-move, and resize handle) |
| OSD | volume/brightness/mic/airplane/bluetooth/kbd-backlight keys | Auto-dismissing bottom-anchored status card (not part of the `openPopup` system — a separate always-on-top window) |

## Configuration

### `config/Config.qml`

Build-time layout, typography, shape, and motion tokens: `barWidth`, `widgetSize`, type sizes, independent bar clock typography, spacing, style-dependent shape/border/shadow tokens, motion durations (`motionShort`/`Medium`/`Long`/`ExtraLong`, all zeroed when `reducedMotion` is on), `popupWidth`, Settings min/max dimensions, and step sizes for volume/brightness. `Settings.themeStyle` selects the component styling independently from the generated palette, while `Settings.nothingVariant` selects Classic or Evolution inside the Nothing family. Classic keeps NType 82 Headline and NType 82 Mono for its signature typography but uses Noto Sans for dense copy; small type has a 12px floor. Evolution uses Geist and Geist Mono, a shared Settings card radius, adaptive accent roles, and translucent chrome tokens. Ghost reserves a wider Settings rail for monospaced navigation labels. Liquid Glass uses a restrained macOS-like radius hierarchy, regular/clear materials, and its own motion tokens.

### `config/Settings.qml`

Persisted user preferences singleton (`FileView` + `JsonAdapter` over `~/.config/quickshell/settings.json`, created on first run if missing). Backs bar layout, motion, independent `reduceTransparency`, clock/calendar/timezone, indicator visibility, workspaces, color source/palette/contrast, UI style (`material3`, `nothing`, `ghost`, or `liquid-glass`), Nothing variant, lock screen, notifications, idle timeouts, and weather. A saved `neo-brutalism` selection migrates to Nothing Evolution on load. The persisted format remains `schemaVersion: 1`. Preferences update through `watchChanges: true`; call `Settings.save()` after mutating an alias. The Appearance tab restores appearance-owned defaults; the confirmed System reset restores all settings and top bar placement.

### `config/Colors.qml`

Material 3 semantic roles resolve from Live Matugen or a Fixed palette in `PaletteCatalog.js` (Catppuccin, Gruvbox, TokyoNight). Nothing Classic and Ghost use authored light/dark palettes; Nothing Evolution uses the active wallpaper palette. Palette roles supplied as color strings are converted to colors before applying alpha, so translucent roles keep their wallpaper tint instead of rendering black. Evolution's Settings, launcher, and notification history use opaque reading surfaces; cards use tinted surfaces, while compact popup and bar chrome stays translucent. `reduceTransparency` also makes that chrome opaque, independently of motion and contrast. Liquid Glass uses a neutral light/dark scale for functional materials; `reduceTransparency` or high contrast makes its chrome opaque. Fixed palettes export their light/dark roles to the shared Matugen cache for desktop integrations. See [Apple's materials guidance](https://developer.apple.com/design/human-interface-guidelines/materials).

Format: `l_<token>` (light), `d_<token>` (dark), and flat resolved `<token>` properties (no prefix) for current mode. Text/icon colors are prefixed with `fg` (e.g. `fgSurface`, `fgPrimary`) to prevent conflicts with QML's internal signal handler compiler rules.

System dark mode is read once and monitored through `gsettings` (owned by `Colors.qml` itself, since it's the single instance everyone reads from). Mode toggles in the launcher or Settings call the existing desktop mode synchronizer, while the shell selects the matching Matugen light/dark roles locally.

`Settings.themePreference` owns color mode (Auto/Light/Dark); `colorSource` chooses Live or Fixed and `colorContrast` adjusts outline/text roles. `themeStyle` selects Material 3, Nothing, Ghost, or Liquid Glass; `nothingVariant` retains Classic and Evolution until an actual OS 5 release justifies reevaluating Classic. Evolution uses Geist, wallpaper-adaptive roles, and layered surfaces; Classic and Ghost retain fixed authored palettes. The Appearance chooser shows illustrative miniatures of each style's bar, reading card, type, and action control. It switches from three to two columns when content width cannot fit the miniatures, applies a selection immediately, and offers a one-click revert to the preceding style while Settings remains open. `shell.qml` synchronizes GTK, icons, Kvantum, terminals, Neovim, Niri, and SDDM on style or mode changes.

Liquid Glass is available as `liquid-glass`: neutral translucent chrome, compact controls, macOS-style switches and sliders, and Matugen accents. Settings uses a stronger reading backdrop than transient chrome so text remains legible over busy windows, without disabling glass elsewhere. `reduceTransparency` or high contrast selects opaque surfaces. The bar uses monochrome foregrounds at rest. External synchronization selects MacTahoe GTK/icon/Kvantum/cursor companions while keeping Matugen terminal/editor assets; missing companions retain their respective fallbacks.

`ensure-style-terminal-assets.sh` supplies fixed Nothing/Ghost Starship prompts and the recovered dark Ghost btop palette. Material 3 retains Roboto Flex and tonal surfaces. Nothing Classic retains NType display labels, neutral surfaces, and red accents, with Noto Sans for readable body copy; Evolution uses Geist and adaptive colors. Ghost uses its cyan HUD palette and square controls.

### `bar/PopupShield.qml`

Full-screen transparent surface on `WlrLayer.Bottom` that catches clicks outside popups and dismisses them via `onShieldClicked`. The shield sits behind popups (which are on `WlrLayer.Top`) so clicks on popup content work normally while clicks outside reach the shield.

### `bar/FocusDismiss.qml`

Handles popup dismissal on app focus loss with target null checks. On Niri and Mango, it observes the popup window's active focus item, preserving focus transitions between popup controls while dismissing when focus leaves the window. The `Qt.application.activeChanged` check runs on all WMs and closes the popup when the user switches to another application.

## Widget Details

- **Bar.qml**: Single component for all four placements and both display styles (continuous full bar / floating pills bar), driven by `barPosition`, `horizontal`, `pillsBar`, and `fullBar` properties. In pills mode, every visible widget receives its own floating surface while the transparent panel still provides the input region for gaps and outside-click dismissal. Surface geometry follows the selected UI style. The horizontal Ghost clock shows only the time in a compact right-side slot between notifications and Quick Settings; vertical Ghost keeps hours and minutes, while other styles keep the centered clock and date.
- **WorkspaceIndicator**: 100% event-driven. Streams workspaces from Niri (`niri msg event-stream`) using `SplitParser`. Runs only when visible. Anchored directly in the workspace zone so it stays stationary in both display styles and orientations. Horizontal markers center within their allocated track, including Classic's numbered controls.
- **Mango layout indicator**: Reads the active tag's layout from the shared `mmsg watch all-monitors` stream and displays its readable name between the workspace and focused-window indicators. Visibility is controlled from General > Bar Contents.
- **AudioIndicator / BrightnessIndicator / MediaIndicator / WeatherIndicator**: Event-driven watchers and polling loops are bound to their active/visible state. Audio writes for sink and microphone are serialized and coalesced during rapid slider/toggle input, with a final state read after the latest write.
- **BatteryIndicator**: Utilizes UPower property bindings (no timers) to react directly to battery changes.
- **WifiPanel / BtPanel**: Network and Bluetooth controls live in Settings tabs, including saved Wi-Fi profiles, Bluetooth discovery/pairing, and connected-device actions. They are intentionally not rendered as compact bar indicators.
- **SystemTrayArea**: Renders StatusNotifier items with left-click activate and right-click context menu, orientation-aware layout.
- **QuickMenu**: Groups five Quick Settings tiles (Caffeine, airplane mode, Bluetooth, DND, Settings) separately from five power actions (including lock and confirmed power actions); headings and power-action tooltips identify the two icon rows in every style.
- **Settings**: Provides the twelve tabs listed above, remembers the last selected tab, keeps Network and Bluetooth Settings-only, and preserves Settings/power entry points even when bar content switches are disabled. The panel moves from its header and resizes from the bottom-right corner, with a 560px minimum width on desktop and a maximum height bounded by screen margins rather than a fixed 820px ceiling. Page headings and subtitles lead the content; Ghost keeps its uppercase HUD headings and wider nav rail. Sidebar navigation can scroll when it overflows without displaying a scrollbar; keyboard navigation brings the selected tab into view. Search prioritizes matching control titles over incidental mentions, reports result counts or an empty-state hint, and opens and scrolls to the matching control with keyboard focus and a brief highlight.
- **ActionButton**: A label-only button does not reserve icon height or icon-to-label spacing; compact Settings actions such as Weather > Apply keep their text centered in every UI style.
- **Weather**: Uses a configured manual location by default, optionally supports IP geolocation, refreshes on the persisted interval, and reports the last update time. Refreshes coalesce rather than aborting an active fetch; invalid responses and command failures appear in the popup as errors.
- **Notifications**: Retains history while DND or quiet hours suppress toast delivery; critical-notification bypass, toast placement, retention, and clear-history actions are persisted.
- **Dark Mode Preference**: Event-driven tracking via a one-time startup query (`gsettings get`) and a continuous background monitor (`gsettings monitor`) with a `SplitParser` listener, saving CPU cycles. Because `Colors.qml` hot-reloads reset `systemDark` to its template default, a polling re-query runs in `shell.qml` after reloads.
- **Theme ownership**: Live is Matugen's wallpaper palette for Material 3 and Nothing Evolution; Fixed palettes come from `config/PaletteCatalog.js`. `scripts/sync-active-palette.sh` activates the selected cache, regenerates Material 3 desktop companions, and refreshes synchronizers. Classic Nothing and Ghost keep authored Quickshell colors. `scripts/apply-wallpaper.sh` still refreshes Live while Fixed is selected. The root-owned SDDM bridge changes the greeter only on explicit style/mode changes.
- **New deployment**: `yadm bootstrap` (or `/home/mura/install.sh`) offers `scripts/install-ui-suite.sh`, which installs Material 3, Nothing, and Ghost companion projects and SDDM themes. Run directly with `--dry-run`, `--skip-sddm`, `--skip-cursors`, or `--skip-nvim` as needed. `scripts/verify-ui-suite.sh` checks supported GTK, icon, Kvantum, cursor, terminal, btop, Neovim, and SDDM assets. Existing installed themes outside the managed set are not deleted.
- **Appearance tab**: Presents all five illustrative styles in one row when space allows, or a balanced compact grid; the active style is outlined, the entire tile and its keyboard-focusable button select it, and the text-only revert action sits beside the style description when space allows. Changes save immediately. Contrast, palette, bar, sizing, and appearance reset remain below; General holds the independent Reduce transparency switch.
- **Display & Input tab**: Reads and safely edits Niri output, input, and edge-gesture settings through the validated `scripts.niri_config` CLI. Remote controls only read while their Settings page is active.
- **Wallpaper tab**: Lists images from `~/Pictures/Walls`; `scripts/generate-thumbnails.sh` produces 200×130 center-cropped thumbnails under `~/.cache/quickshell/wallpaper-thumbs`, regenerating only when the source is newer. Conversions run with bounded concurrency and publish complete files atomically; failures return a nonzero exit status. The tab tracks the active wallpaper, supports keyboard selection, and exposes randomize/apply actions.
- **Lock & Power tab**: Owns lock-screen options, idle lock/suspend timeouts, Caffeine, TLP power-profile selection with automatic AC/battery restore, and the Evolution-only Gooey/Micrographics clock-face selector.
- **Media tab**: Owns media artwork, progress, and always-visible-control preferences for the media popup.
- **Media / MPRIS**: `scripts/mpris_monitor.py` broadcasts the active player's state as newline-delimited JSON over stdout (consumed via `SplitParser`), and also listens on a private runtime named pipe for out-of-band pokes. `scripts/mpris_control.py` sends play/pause/next/prev to whichever player is currently active (preferring a "Playing" one); the visualizer is available in the Settings media controls.
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
- **cliphist**, **wl-clipboard** (`wl-copy`) — clipboard history provider and restore/capture copy
- **grim**, **slurp**, **libnotify** (`notify-send`) — full-screen/region capture feedback

---

## Disclaimer

This theme suite and shell configuration was generated and vibe-coded using **Antigravity**, an AI agentic coding assistant designed by the Google DeepMind team.

---

## License

This project is licensed under the terms of the GNU General Public License v3.0 (GPL-3.0). See the [LICENSE](file:///home/mura/.config/quickshell/LICENSE) file for details.
