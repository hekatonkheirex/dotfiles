# Notch, Settings App, and Lock Screen Redesign

Status: approved design, pending implementation plan
Scope: Project 1 of 2. Project 2 (system-wide Matugen/Material You replacing the Ghost
theme) is a separate spec, deliberately not covered here, to be brainstormed after this
ships.

## Motivation

Rodrigo wants the top bar replaced with a macOS-Dynamic-Island-style notch (reference:
YouTube video "I Replaced My Whole Hyprland Bar With One Notch", identified as
DankMaterialShell), plus the settings app and lock screen shown in the same video,
adapted to this codebase's real architecture instead of copied blind.

## Out of scope (explicitly deferred, not forgotten)

- Ghost theme system removal / Matugen-Material You integration — Project 2.
- Spotlight-style search bar seen at the top of the video's screenshots — unrelated
  DankMaterialShell component, never asked for.
- Live in-shell color/theme picker — conflicts with the fixed Ghost palette architecture
  (Project 1 uses a separate hardcoded palette for its own new components only).
- Redesigning `apply-desktop-theme`, GTK/Qt/Kvantum/SDDM theming — untouched.

## 1. Notch (`bar/Notch.qml`, new)

Replaces `Bar.qml` for horizontal mode only. `Bar.qml` is untouched and still used
when the layout preference is `vertical` (existing IPC toggle in `shell.qml` keeps
working).

States, driven by the existing `expandProgress` pattern (reused from `Bar.qml`):

- **Idle**: pill showing only the clock. Collapsed width and bar height are config
  values (see §2), corner radius = "notch flare" config value, floating with a gap
  from the screen's top edge (also configurable) rather than flush-embedded.
- **Hover**: expands (width grows to fit content, height grows to the configured
  expanded height). Media player fades in on the left (album art, title/artist,
  transport controls, sourced from MPRIS), clock stays centered, a mini calendar
  month-grid fades in on the right (reusing the day-grid logic currently in
  `CalendarPopup.qml`, which is retired in favor of this inline view — no separate
  calendar popup needed anymore).
- **Click**: opens Control Center (existing `CommandCenter.qml`) as a dropdown
  anchored to the notch. Replaces the old gear-icon (`MenuIndicator`) trigger.

Everything currently in `Bar.qml`'s horizontal GridLayout that isn't clock/media/
calendar — workspaces, wifi, bluetooth, audio, brightness, battery, system tray,
notifications — is removed from the notch. Per Rodrigo's explicit decision:
- Wifi/bt/audio/brightness/battery/tray/notifications: Control Center only.
- Workspace switching: no visual indicator anywhere; Niri keybinds only.
- App launcher: no visual trigger; Niri keybind only (`LauncherPopup.qml` untouched,
  just no bar icon to click it).

### MPRIS state ownership

Currently `CommandCenter.qml` owns MPRIS polling/state (`mprisTitle`, `mprisArtist`,
etc., populated via `scripts/mpris_monitor.py`). The notch's hover media player needs
the same data. Rather than running a second independent MPRIS poller, this state
moves up to `shell.qml` (the existing single owner of cross-component IPC/state) and
both `Notch.qml` and `CommandCenter.qml`/`MediaTab.qml` bind to it as passed-in
properties.

## 2. Settings persistence (`config/Settings.qml`, new; `settings.json`, new)

`Config.qml` stays exactly as-is (build-time constants). A new `Settings.qml`
(QtObject) holds the values a user can actually change at runtime:

- Bar & Island: notch flare (corner radius, default `14px`), bar height (default
  `34px`), collapsed width (default `150px`), expanded height (default `135px`), gap
  from screen edge (default `11px`) — defaults taken directly from the video's
  reference numbers per Rodrigo's confirmation. Expanded width is content-driven
  (hugs the media+calendar layout + padding), not a fixed/floored value.
- Media: show album art, show progress bar, controls always-visible vs. hover-only.
- Clock & Date: 24h/12h format, show seconds, calendar week-start day.
- Appearance: font family/size, spacing unit, corner radius. **Not** colors/theme —
  that stays owned by `apply-desktop-theme` (Ghost system, Project 2 territory).
- Motion: movement/fade/hover-response durations, bounce %, reduce-motion switch.
- Notifications: toast duration (already exists as `config.notificationToastDurationMs`,
  becomes user-tunable), do-not-disturb toggle.
- Control Center: per-tile visibility (Wi-Fi/BT/Audio/Display/Night Light).
- Lock Screen: show media widget, clock size.
- System: weather city (currently hardcoded `"Asunción"` in `CommandCenter.qml`,
  becomes editable), uptime display toggle.
- Launcher: no editable settings — tab shows a read-only display of the configured
  Niri keybind. Editing Niri keybinds from Quickshell is out of scope (risk of
  desyncing `niri/config.kdl`).

Persisted to `~/.config/quickshell/settings.json` via Quickshell's native `FileView`
(`Quickshell.Io`) — chosen over the existing shell-`echo`-to-file pattern used for the
single-word `layout` preference, because writing structured JSON through shell
redirection risks quoting bugs; `FileView` is the correct native tool for this and
still fits the existing "flat file, no daemon" persistence philosophy. Read once at
startup, written on every change, applied live (matches the "no restart needed"
pattern already established across this config).

## 3. Settings window (`Settings/SettingsWindow.qml` + `Settings/tabs/*.qml`, new)

A normal top-level window (not layer-shell), sidebar + page layout matching the
video: search field that filters visible controls by simple string match, 10 nav
items (Bar & Island, Media, Clock & Date, Appearance, Motion, Launcher, Notifications,
Control Center, Lock Screen, System), back/forward history buttons. Opened via a new
gear entry inside Control Center — no new bar icon, consistent with "Control Center
only" for everything displaced from the notch.

Every control is real and wired to `Settings.qml` — no inert placeholders.

## 4. Fixed palette for new components

`Notch.qml`, the Settings window, and the redesigned lock screen use a small new
hardcoded palette object (Rosé Pine values, matching the theme selected in the video's
own screenshots) instead of the `colors_`/Ghost tokens used by the rest of the shell:

```
base    #191724   surface #1f1d2e   overlay #26233a
text    #e0def4   muted   #6e6a86
love (accent) #eb6f92   gold #f6c177   pine #31748f   foam #9ccfd8
```

Everything else in the shell (existing bar remnants for vertical mode, existing
popups, GTK/Qt/SDDM theming) keeps using the Ghost system unchanged. This is a
deliberate, scoped exception, not a precedent for removing Ghost elsewhere — that's
Project 2.

## 5. Lock screen (`bar/LockScreen.qml`, edit in place)

Keeps all existing functionality unchanged: `WlSessionLock`, PAM auth, fprintd
fingerprint retry logic, power buttons (suspend/reboot/poweroff).

Visual/behavioral changes to match the video:
- Date displayed above the clock (currently clock-above-date); larger clock text.
- Password field hidden by default, showing "Press Any Key to Enter Password";
  appears on first keypress instead of being always-visible.
- Small battery % / wifi status pills added, top-right corner.
- Restyled with the fixed palette from §4 instead of `colors_`.
- Note: the pink slider/play-pause control visible in one of the reference
  screenshots is the YouTube player's own scrubber bled through into the screenshot,
  not part of the actual lock screen — disregarded.

Cleanup while this file is open: `LockScreen.qml` currently has a complete duplicate
implementation gated on `!config.isNiri`, which is dead code since `config.isNiri` is
hardcoded `true`. Deleted as part of this edit (in scope: touching this exact file for
the reasons above, not a drive-by refactor).

## Testing / verification

Per the customize-rodrigo-linux skill's verification steps:
1. `qmllint` every new/edited file.
2. Hot-reload via Quickshell's file watcher (touch file if the watcher misses it,
   observed once already this session), confirm "Configuration Loaded" with no
   warnings in `~/.run/user/*/quickshell/by-id/*/log.log`.
3. Screenshot via `grim` for idle notch, hover-expanded notch (requires a working
   pointer-automation tool — none is currently installed on this machine; flagged as
   a gap, manual verification by Rodrigo needed for hover states unless one is added).
4. Exercise Settings window: change a Bar & Island value, confirm the notch updates
   live; restart Quickshell, confirm the value persisted from `settings.json`.
5. Lock screen: `loginctl lock-session` to trigger, verify PAM auth still unlocks,
   verify fprintd retry still fires, verify power buttons still work.
6. Confirm vertical-mode `Bar.qml` still works unchanged (layout toggle via existing
   IPC).
