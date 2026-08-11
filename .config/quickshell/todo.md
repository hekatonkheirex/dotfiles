# Quickshell follow-up TODO

This list captures the review of the current Settings refactor. Work from top to bottom. Items marked P0 are correctness issues. Items marked P1 are important for stability, deployment, or usability. Items marked P2 are useful additions after the current behavior is reliable.

## Current assessment

- [x] Keep the current direction: the tab-based Settings page, extracted Network and Bluetooth panels, shared controls, and semantic Matugen colors are good foundations.
- [ ] Do not treat the refactor as finished until the unwired settings, yadm state, and compact-layout matrix are addressed.

## P0: Fix settings that currently do not work

### Notifications and DND

- [x] Make `Settings.doNotDisturb` effective in `shell.qml`.
- [x] Decide and document DND behavior: suppress toast popups while retaining notification history.
- [x] Keep the Notifications tab and Quick Menu switch synchronized with the actual behavior.
- [x] Test enabling and disabling DND from both locations.

Relevant files: `shell.qml`, `bar/QuickMenu.qml`, `bar/commandcenter/NotificationsTab.qml`.

### General settings

- [x] Wire “Show uptime” so the Account tab hides or shows uptime according to `Settings.systemShowUptime`.
- [x] Wire “Week starts Monday” through the calendar model and verify both week layouts.
- [x] Remove legacy settings with no consumers: `ccShowWifi`, `ccShowBluetooth`, and `ccShowNightLight`.
- [x] Keep Wi-Fi and Bluetooth Settings-only; use the Network and Bluetooth tabs instead of compact bar indicators.

Relevant files: `bar/commandcenter/GeneralTab.qml`, `bar/commandcenter/AccountTab.qml`, `bar/CalendarPopup.qml`, `bar/CalendarLogic.js`, `bar/Bar.qml`, `config/Settings.qml`.

### Weather correctness and privacy

- [x] Add a manual-location setting and use it instead of IP geolocation when configured (no persisted field exists yet — add one only alongside the UI that sets it).
- [x] Add a clear privacy option to disable IP-based geolocation.
- [x] Replace the HTTP IP geolocation endpoint with HTTPS, or avoid IP geolocation when no location is configured.
- [x] Make the offline fallback date dynamic instead of hardcoding a past date.
- [x] Make offline fallback units follow metric or imperial settings.
- [x] Show a clear unavailable or offline state instead of silently presenting stale weather.

Relevant file: `scripts/weather.py`.

### Theme persistence

- [x] Move the Light, Dark, and Auto preference into `Settings.qml` and persist it in `settings.json`.
- [x] Keep Matugen and system theme synchronization working after restarting Quickshell.
- [x] Test switching modes, restarting Quickshell, and switching back to Auto.

Relevant files: `config/Colors.qml`, `config/Settings.qml`, `settings.json`, `scripts/sync-theme-mode.sh`.

## P1: Finish the refactor safely

### yadm and source ownership

- [x] Ensure all new active files are tracked by yadm, especially the new Settings tabs and Network/Bluetooth panels.
- [x] Confirm deleted legacy files are intentionally removed and are not still referenced.
- [ ] Check that a fresh yadm checkout or restore contains the complete working configuration.
- [x] Remove the generated `scripts/__pycache__/weather.cpython-314.pyc` from the configuration tree if it is still present.

### Accessibility and motion verification

- [x] Route shared and popup transitions through the reduced-motion tokens, disable the animated background and voice-search rotation when reduced motion is enabled, and verify a live reduced-motion reload.
- [x] Add keyboard activation and accessible focus semantics for the launcher microphone, bar calendar clock, and system-tray items.
- [ ] Perform a physical keyboard-only pass when an input-injection utility is available; the source-level contract is verified, but this session has no `wtype`, `ydotool`, or `xdotool`.

New files to verify include:

- `bar/BtPanel.qml`
- `bar/MediaIndicator.qml`
- `bar/MediaPopup.qml`
- `bar/WeatherIndicator.qml`
- `bar/WeatherPopup.qml`
- `bar/WifiPanel.qml`
- `bar/commandcenter/AccountTab.qml`
- `bar/commandcenter/AppearanceTab.qml`
- `bar/commandcenter/WallpaperTab.qml`
- `bar/commandcenter/BluetoothTab.qml`
- `bar/commandcenter/GeneralTab.qml`
- `bar/commandcenter/LockMediaTab.qml`
- `bar/commandcenter/MediaTab.qml`
- `bar/commandcenter/PowerProfileCard.qml`
- `bar/commandcenter/NetworkTab.qml`
- `bar/commandcenter/NotificationsTab.qml`
- `bar/commandcenter/ShortcutsTab.qml`
- `bar/commandcenter/SystemTab.qml`

### Documentation and settings schema

- [x] Update `README.md` to describe the current eleven-tab Settings page.
- [x] Update the file tree and popup table in `README.md`.
- [x] Document the current runtime dependencies used by System, including `sensors` and `jq` if they remain required.
- [x] Update `M3_EXPRESSIVE_X390_REFACTOR_PLAN.md` so completed work and remaining validation match the current code.
- [x] Add `schemaVersion: 1` to the settings file and document the migration policy for future removed or renamed keys; no current breaking settings migration is required.
- [x] Document the source of truth for generated Matugen colors and theme mode.

## P1: Responsive layout and accessibility tuning

### Compact and alternate layouts

- [x] Test Settings at the configured minimum size of 320x360.
- [x] Test the normal horizontal layout at 1920x1080.
- [x] Test vertical-bar mode.
- [x] Test both light and dark modes.
- [x] Open every Settings tab in every tested layout.
- [x] Fix any clipping caused by the fixed 132px sidebar, eleven sidebar rows, two-column cards, or fixed wallpaper cells.
- [x] Ensure Flickable content remains reachable when the window is short.
- [x] Verify the selected tab and current focus remain visible after resizing.

### Shared sizing and controls

- [x] Replace repeated literal font sizes, spacing, and radii in the new tabs with `Config` or shared primitive tokens where practical.
- [ ] Verify that Font Size, Icon Size, Spacing, and Bar Size controls affect all relevant Settings content consistently.
- [x] Debounce settings writes or save on slider release instead of calling `Settings.save()` on every slider movement.
- [x] Check that sliders expose an accurate value and range to assistive technology.
- [x] Give the current sidebar delegates (`ListItem`) proper page-tab semantics and selected-state announcements. (The unused `TabItem` primitive that used to be suggested here was removed — it was never wired to anything.)

Relevant files: `bar/CommandCenter.qml`, `bar/primitives/ListItem.qml`, `bar/primitives/SliderControl.qml`, `bar/commandcenter/AppearanceTab.qml`.

### Usability polish

- [x] Keep a workspace number visible for the focused or occupied workspace, or add a useful workspace tooltip.
- [x] Remember the last selected Settings tab, while keeping Account as the default after a reset.
- [x] Keep Wi-Fi and Bluetooth without a compact at-a-glance state; use the Network and Bluetooth Settings tabs.
- [x] Lazy-load Account machine-information commands only when the Account tab becomes visible.

## P1: Hardware and system robustness

- [x] Detect CPU thread count dynamically instead of normalizing CPU usage against eight threads.
- [x] Handle systems without `/sys/class/power_supply/BAT0` gracefully.
- [x] Prefer UPower or a detected battery path for battery information.
- [x] Show “Unavailable” for optional sensors or battery data instead of displaying misleading zero values.
- [x] Verify `sensors`, `jq`, `niri`, `nmcli`, and `bluetoothctl` failures do not break the System, Network, or Bluetooth tabs.

Relevant files: `bar/CommandCenter.qml`, `bar/BatteryPopup.qml`, `bar/WifiPanel.qml`, `bar/BtPanel.qml`, `bar/commandcenter/AccountTab.qml`, and `bar/commandcenter/SystemTab.qml`.

## P2: Fill the Settings page with useful options

Only add an option when its behavior has a clear backend and can be tested. Prefer one useful card over decorative filler.

### General: Bar contents

- [x] Add a Bar Contents card with switches for the active compact indicators: launcher, workspaces, focused-window title, clock, notifications, battery, tray, audio, display brightness, weather, and media. Wi-Fi and Bluetooth remain Settings-only.
- [x] Remove controls that do not correspond to an active bar component.
- [x] Keep a safe default so users cannot hide the only way to reopen Settings or the power menu.

### Appearance: Theme and palette

- [x] Add persisted Auto, Light, and Dark mode selection.
- [x] Show the active palette or theme source.
- [x] Add a safe “Reload theme” action if the existing theme scripts support it.
- [x] Keep generated Matugen files read-only from the Settings UI.

### Wallpaper

- [x] Move wallpaper discovery, thumbnails, active-wallpaper tracking, keyboard navigation, randomize, and apply actions into a dedicated tab directly below Appearance.

### General: Weather

- [x] Add manual city/location selection.
- [x] Add refresh interval.
- [x] Add privacy mode for location lookup.
- [x] Show the last successful update time and offline state.

### Notifications

- [x] Add quiet hours or a schedule.
- [x] Add critical-notification bypass.
- [x] Add toast position and history retention controls if the notification backend supports them.
- [x] Add clear notification history.

### Network and Bluetooth

- [x] Add saved Wi-Fi network management and autoconnect controls.
- [x] Add Bluetooth discoverability, pairing, and device rename actions if supported by the current scripts.

### Lock and Power

- [x] Add lock-screen background selection if the wallpaper system can provide it safely.
- [x] Keep the existing lock-screen media and clock-size controls.
- [x] Add lock timeout and suspend behavior through the existing `swayidle` backend.
- [x] Keep Caffeine with idle lock, display-off, suspend, and power-profile controls.
- [x] Move TLP power-profile controls into Lock & Power.

### Media

- [x] Give media artwork, progress, and control visibility settings their own tab.

### System

- [x] Add power-profile selection if the current system exposes it.
- [x] Add battery health and cycle information when available.
- [x] Add a concise thermal and sensor summary.
- [x] Add “Reload Quickshell” and “Copy diagnostics” actions.
- [x] Add a safe reset-settings action with confirmation and a clear recovery path.

### Shortcuts

- [x] Clearly label the shortcut list as curated and show the Niri source path.
- [x] Add “Copy keybinds” and “Open full keybind configuration”.
- [ ] Avoid an editable shortcut editor until persistence, validation, and reload behavior are defined.

## Final validation checklist

- [x] Run `bash scripts/m3-qmllint-gate.sh`.
- [x] Run `niri validate` from `/home/mura`.
- [x] Run `yadm diff --check -- .config/quickshell`.
- [x] Compile-check `scripts/weather.py`.
- [x] Restart Quickshell and confirm a clean service journal.
- [ ] Test all P0 settings manually.
- [x] Test all eleven Settings tabs in normal, minimum-size, vertical, light, and dark configurations.
- [x] Confirm no new generated files, secrets, or unrelated changes are present.

The fresh committed yadm restore check remains open because the current worktree changes are intentionally uncommitted; validating it by restoring `HEAD` would discard the work being reviewed.
