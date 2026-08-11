# Quickshell follow-up TODO

This list captures the review of the current Settings refactor. Work from top to bottom. Items marked P0 are correctness issues. Items marked P1 are important for stability, deployment, or usability. Items marked P2 are useful additions after the current behavior is reliable.

## Current assessment

- [ ] Keep the current direction: the tab-based Settings page, extracted Network and Bluetooth panels, shared controls, and semantic Matugen colors are good foundations.
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

- [ ] Add a manual-location setting and use it instead of IP geolocation when configured (no persisted field exists yet — add one only alongside the UI that sets it).
- [ ] Add a clear privacy option to disable IP-based geolocation.
- [ ] Replace the HTTP IP geolocation endpoint with HTTPS, or avoid IP geolocation when no location is configured.
- [ ] Make the offline fallback date dynamic instead of hardcoding a past date.
- [ ] Make offline fallback units follow metric or imperial settings.
- [ ] Show a clear unavailable or offline state instead of silently presenting stale weather.

Relevant file: `scripts/weather.py`.

### Theme persistence

- [ ] Move the Light, Dark, and Auto preference into `Settings.qml` and persist it in `settings.json`.
- [ ] Keep Matugen and system theme synchronization working after restarting Quickshell.
- [ ] Test switching modes, restarting Quickshell, and switching back to Auto.

Relevant files: `config/Colors.qml`, `config/Settings.qml`, `settings.json`, `scripts/sync-theme-mode.sh`.

## P1: Finish the refactor safely

### yadm and source ownership

- [ ] Ensure all new active files are tracked by yadm, especially the new Settings tabs and Network/Bluetooth panels.
- [ ] Confirm deleted legacy files are intentionally removed and are not still referenced.
- [ ] Check that a fresh yadm checkout or restore contains the complete working configuration.
- [ ] Remove the generated `scripts/__pycache__/weather.cpython-314.pyc` from the configuration tree if it is still present.

New files to verify include:

- `bar/BtPanel.qml`
- `bar/MediaIndicator.qml`
- `bar/MediaPopup.qml`
- `bar/WeatherIndicator.qml`
- `bar/WeatherPopup.qml`
- `bar/WifiPanel.qml`
- `bar/commandcenter/AccountTab.qml`
- `bar/commandcenter/AppearanceTab.qml`
- `bar/commandcenter/BluetoothTab.qml`
- `bar/commandcenter/GeneralTab.qml`
- `bar/commandcenter/LockMediaTab.qml`
- `bar/commandcenter/NetworkTab.qml`
- `bar/commandcenter/NotificationsTab.qml`
- `bar/commandcenter/ShortcutsTab.qml`
- `bar/commandcenter/SystemTab.qml`

### Documentation and settings schema

- [x] Update `README.md` to describe the current nine-tab Settings page.
- [x] Update the file tree and popup table in `README.md`.
- [x] Document the current runtime dependencies used by System, including `sensors` and `jq` if they remain required.
- [ ] Update `M3_EXPRESSIVE_X390_REFACTOR_PLAN.md` so completed work and remaining validation match the current code.
- [ ] Decide whether the settings file needs a `schemaVersion` and migration path for removed or renamed keys.
- [ ] Document the source of truth for generated Matugen colors and theme mode.

## P1: Responsive layout and accessibility tuning

### Compact and alternate layouts

- [ ] Test Settings at the configured minimum size of 320x360.
- [ ] Test the normal horizontal layout at 1920x1080.
- [ ] Test vertical-bar mode.
- [ ] Test both light and dark modes.
- [ ] Open every Settings tab in every tested layout.
- [ ] Fix any clipping caused by the fixed 132px sidebar, nine sidebar rows, two-column cards, or fixed wallpaper cells.
- [ ] Ensure Flickable content remains reachable when the window is short.
- [ ] Verify the selected tab and current focus remain visible after resizing.

### Shared sizing and controls

- [ ] Replace repeated literal font sizes, spacing, and radii in the new tabs with `Config` or shared primitive tokens where practical.
- [ ] Verify that Font Size, Icon Size, Spacing, and Bar Size controls affect all relevant Settings content consistently.
- [ ] Debounce settings writes or save on slider release instead of calling `Settings.save()` on every slider movement.
- [ ] Check that sliders expose an accurate value and range to assistive technology.
- [ ] Give the current sidebar delegates (`ListItem`) proper page-tab semantics and selected-state announcements. (The unused `TabItem` primitive that used to be suggested here was removed — it was never wired to anything.)

Relevant files: `bar/CommandCenter.qml`, `bar/primitives/ListItem.qml`, `bar/primitives/SliderControl.qml`, `bar/commandcenter/AppearanceTab.qml`.

### Usability polish

- [ ] Keep a workspace number visible for the focused or occupied workspace, or add a useful workspace tooltip.
- [ ] Consider opening Settings on Appearance or remembering the last selected tab instead of always opening Account.
- [x] Keep Wi-Fi and Bluetooth without a compact at-a-glance state; use the Network and Bluetooth Settings tabs.
- [ ] Lazy-load Account machine-information commands only when the Account tab becomes visible.

## P1: Hardware and system robustness

- [ ] Detect CPU thread count dynamically instead of normalizing CPU usage against eight threads.
- [ ] Handle systems without `/sys/class/power_supply/BAT0` gracefully.
- [ ] Prefer UPower or a detected battery path for battery information.
- [ ] Show “Unavailable” for optional sensors or battery data instead of displaying misleading zero values.
- [ ] Verify `sensors`, `jq`, `niri`, `nmcli`, and `bluetoothctl` failures do not break the System, Network, or Bluetooth tabs.

Relevant file: `bar/commandcenter/SystemTab.qml`.

## P2: Fill the Settings page with useful options

Only add an option when its behavior has a clear backend and can be tested. Prefer one useful card over decorative filler.

### General: Bar contents

- [ ] Add a Bar Contents card with switches for launcher, workspaces, focused-window title, clock, notifications, battery, tray, audio, display brightness, weather, media, Wi-Fi, and Bluetooth.
- [ ] Remove controls that do not correspond to an active bar component.
- [ ] Keep a safe default so users cannot hide the only way to reopen Settings or the power menu.

### Appearance: Theme and palette

- [ ] Add persisted Auto, Light, and Dark mode selection.
- [ ] Show the active palette or theme source.
- [ ] Add a safe “Reload theme” action if the existing theme scripts support it.
- [ ] Keep generated Matugen files read-only from the Settings UI.

### General: Weather

- [ ] Add manual city/location selection.
- [ ] Add refresh interval.
- [ ] Add privacy mode for location lookup.
- [ ] Show the last successful update time and offline state.

### Notifications

- [ ] Add quiet hours or a schedule.
- [ ] Add critical-notification bypass.
- [ ] Add toast position and history retention controls if the notification backend supports them.
- [ ] Add clear notification history.

### Network and Bluetooth

- [ ] Add saved Wi-Fi network management and autoconnect controls.
- [ ] Add Bluetooth discoverability, pairing, and device rename actions if supported by the current scripts.
- [ ] Add a combined connectivity summary so users can see state without opening two tabs.

### Lock and Media

- [ ] Add lock-screen background selection if the wallpaper system can provide it safely.
- [ ] Keep the existing media visibility, progress, artwork, and clock-size controls.
- [ ] Consider lock timeout or suspend behavior only if there is already a reliable system backend.

### System

- [ ] Add power-profile selection if the current system exposes it.
- [ ] Add battery health and cycle information when available.
- [ ] Add a concise thermal and sensor summary.
- [ ] Add “Reload Quickshell” and “Copy diagnostics” actions.
- [ ] Add a safe reset-settings action with confirmation and a clear recovery path.

### Shortcuts

- [ ] Generate the shortcut list from the actual Niri configuration, or clearly label it as curated.
- [ ] Add “Copy keybinds” or “Open full keybind configuration”.
- [ ] Avoid an editable shortcut editor until persistence, validation, and reload behavior are defined.

## Final validation checklist

- [ ] Run `bash scripts/m3-qmllint-gate.sh`.
- [ ] Run `niri validate` from `/home/mura`.
- [ ] Run `yadm diff --check -- .config/quickshell`.
- [ ] Compile-check `scripts/weather.py`.
- [ ] Restart Quickshell and confirm a clean service journal.
- [ ] Test all P0 settings manually.
- [ ] Test all nine Settings tabs in normal, minimum-size, vertical, light, and dark configurations.
- [ ] Confirm no new generated files, secrets, or unrelated changes are present.
