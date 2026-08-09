# Task 7 Report: Wire the 4 surfaces into Pill.qml and shell.qml

## Summary

Modified `pill/Pill.qml` and `pill/shell.qml` exactly per the brief's specified diffs. No deviations, no judgment calls required — everything matched expectations from Tasks 1-6.

## Changes

### pill/Pill.qml
1. Added `batteryOpen`, `brightnessOpen`, `wifiOpen`, `bluetoothOpen` readonly bool properties alongside `mixerOpen`.
2. Replaced the `width`/`height` bindings with `anySurfaceOpen`, `openWidth` (uses `Config.popupWidth` for wifi/bluetooth, `mixerWidth` otherwise), and `openContentHeight` (switches on which surface is open), then bound `width`/`height` to those.
3. Added four new indicator icons (`BatteryIndicator`, `BrightnessIndicator`, `WifiIndicator`, `BtIndicator`) into `restRow`, each 20*s square, `horizontal: true`, wired to `pill.requestSurface(...)` toggle pattern identical to the existing volume icon.
4. Added four new surface instances (`BatterySurface`, `BrightnessSurface`, `WifiSurface`, `BtSurface`) as siblings of `audioSurface`, each using the identical `anchors.fill: parent` / `opacity` / `visible: opacity > 0` / `Behavior on opacity` cross-fade pattern.
5. Changed `restRow`'s `opacity: pill.mixerOpen ? 0 : 1` to `opacity: pill.anySurfaceOpen ? 0 : 1` so the rest-state row hides for any open surface, not just the mixer.

### pill/shell.qml
Added `battery(mon)`, `brightness(mon)`, `wifi(mon)`, `bluetooth(mon)` IPC handler functions to the `IpcHandler { target: "pill" }` block, each calling `root.toggleSurface(mon, "<name>")`, following the existing `mixer(mon)` pattern exactly.

## Verification

- `qmllint pill/Pill.qml pill/shell.qml` — clean (no output after filtering expected noise).
- Environment check: Rodrigo's live pill instance (PID 235563, `qs -p /home/mura/.config/quickshell/pill`) was already running as his active bar. Per instructions, this process was never killed or relaunched. Because Quickshell hot-reloads QML on save (confirmed via `pill-live.log`: "Reloading configuration... Configuration Loaded" after every edit), all 4 edits picked up live on the running instance with zero errors/warnings/ReferenceErrors in the log at any point.
- `qs -p ~/.config/quickshell/pill ipc show` confirmed all 4 new IPC functions (`battery`, `brightness`, `wifi`, `bluetooth`) registered alongside `mixer` and `hide`.
- Exercised each surface via IPC (`ipc call pill <handler> ""` then `ipc call pill hide`) and captured `grim` screenshots on output `eDP-1`:
  - Battery: shows 77%, Charging, 38.6 Wh, charge rate, cycle count — renders correctly at mixerWidth.
  - Brightness: shows 100% with slider — renders correctly at mixerWidth.
  - Wifi: shows "Wi-Fi Networks" header, toggle, refresh, and a scrollable network list (Websteros 5G connected, Websteros, Flow, Laura, OBI WAN KENOBI, Pilar) — renders at the wider `Config.popupWidth` as intended.
  - Bluetooth: shows "Bluetooth" header, toggle, refresh, and paired device list (GMK70-1, Lenovo WL310 with battery percentages) — renders at `Config.popupWidth`.
- Final rest-state screenshot confirms all 4 new indicator icons appear in the pill alongside the existing workspace dots and volume icon: battery 77%, brightness icon, wifi 68%, bluetooth — correctly sized and spaced.
- No stray test process was launched or killed; the live process (235563) was left running exactly as found, now serving the updated QML.

Screenshots saved under the session scratchpad:
- `task7-battery-surface.png`
- `task7-brightness-surface.png`
- `task7-wifi-surface.png`
- `task7-bluetooth-surface.png`
- `task7-rest-state.png`

## Commit

`c366ea53` — "Wire battery, brightness, wifi, bluetooth surfaces into Pill.qml and shell.qml" (2 files changed, 90 insertions, 3 deletions). Only `pill/Pill.qml` and `pill/shell.qml` were staged; unrelated working-tree changes (Kvantum theme files, niri colors/windowrules, `layout` — from unrelated matugen/niri activity during the session) were left untouched, not part of this task.

## Notes for Task 8

The 4 new IPC handlers (`battery(mon)`, `brightness(mon)`, `wifi(mon)`, `bluetooth(mon)`) are live and confirmed working — ready for niri keybinds to call via `qs -p ~/.config/quickshell/pill ipc call pill <handler> "$mon"`.
