# Ryoku review

Review date: 2026-08-26

## Executive decision

Ryoku is a useful source of patterns, but it should not be ported wholesale. It is a Hyprland distribution with a Quickshell desktop, a Go-backed settings hub, an update/override system, and a plugin ecosystem. This configuration is Niri-based, already has a strong Matugen pipeline, and already covers much of Ryoku's visible shell surface.

The best additions are small, self-contained capabilities:

1. A clipboard-history provider in the existing launcher.
2. A lightweight screenshot/capture surface using tools already installed here.
3. More hierarchy and preview/reset affordances in Settings.
4. An optional desktop-widget layer only if persistent wallpaper widgets are desired.

## What Ryoku does well

Ryoku's public site presents the bar, launcher, lock screen, and capture tool as one cohesive shell surface, with wallpaper-driven theming and a single settings hub. Its documentation describes a global fuzzy search, live section editors with preview/reset, workspace overview, clipboard history, a capture tool, desktop widgets, and optional plugins.

Useful references:

- [Ryoku overview](https://ryoku.dev/)
- [Desktop tour](https://docs.ryoku.dev/docs/tour)
- [Navigation](https://docs.ryoku.dev/docs/navigation)
- [Settings](https://docs.ryoku.dev/docs/settings)
- [Apps and tools](https://docs.ryoku.dev/docs/apps)
- [Theming](https://docs.ryoku.dev/docs/theming)
- [Plugins](https://docs.ryoku.dev/docs/plugins)
- [Ryoku source structure](https://github.com/neur0map/ryoku-arch/blob/main/docs/structure.md)

The reusable design principle is ownership: the shell owns placement, focus, motion, surfaces, and theming, while individual features supply only their content and actions. That maps well to the existing shared `Config`, `Colors`, `PopupBase`, settings primitives, and Niri event-driven services here.

## Comparison with this configuration

| Ryoku capability | Current local coverage | Recommendation |
| --- | --- | --- |
| Unified bar, launcher, notifications, OSD, lock screen, quick controls | Already implemented across `bar/` and `shell.qml` | Keep the current Niri-native implementation. |
| Global settings hub and live editors | Twelve settings tabs, global search, persistent tab, draggable/resizable panel, reset actions | Keep the architecture. Add clearer groups and richer search metadata before adding more pages. |
| Wallpaper-driven and fixed themes | Matugen-backed Live mode, fixed palette catalog, semantic `Colors` roles, system synchronization | Keep Matugen as the source of truth. Audit consumers rather than copying Ryoku's theme daemon. |
| Workspace indicator and workspace styling | Event-driven `WorkspaceIndicator` with many shapes, counts, and Niri actions | Keep it. Do not duplicate Ryoku's Hyprland overview. Niri already provides native overview navigation. |
| Launcher providers | App launch, shell action mode, and wallpaper search exist; clipboard/files/windows/calculator providers are not unified | Add clipboard history first. Consider file/window providers later. |
| Clipboard history | No local clipboard panel/provider; `cliphist`, `wl-copy`, and `wl-paste` are installed | High-value, low-dependency addition. Treat copied secrets as a privacy concern. |
| Screenshot/capture | No dedicated capture surface; `grim`, `slurp`, and `wf-recorder` are installed | Add a small full-screen/region capture flow. Defer annotation until an editor is explicitly chosen. |
| Desktop widgets | No persistent desktop widget layer; weather, calendar, media, and system information already exist in bar/popups | Optional only. Avoid adding an always-on layer for the sake of parity. |
| Plugin host | Not present | Defer. Arbitrary QML/scripts need trust, lifecycle, reload, sandboxing, and state policies. |
| Distro update/recovery overlays | Yadm and focused sync/deployment scripts already own configuration delivery | Do not mix Ryoku's distro update model into the shell. |

## Recommended additions

### 1. Clipboard launcher provider

Use a launcher prefix such as `;` to search `cliphist`, preview the selected entry, and restore it with `wl-copy`. Include explicit delete and clear-history actions, and keep the feature opt-in or clearly discoverable because clipboard history may contain passwords, tokens, and private messages.

This reuses installed tools and fits the current launcher model. It should not require a new package or a separate popup unless the launcher becomes too cramped for previews.

### 2. Capture surface

Add a shell-owned capture action with these initial modes:

- full screen
- selected region
- save to a predictable screenshots directory
- copy the result to the clipboard

`grim` and `slurp` cover the first implementation, and `wf-recorder` can remain the existing recording path. Window capture can follow after the Niri window JSON output is mapped reliably. Annotation should remain a later decision because `swappy` and the other capture helpers are not installed.

### 3. Settings hierarchy, not a second settings application

Ryoku's strongest Settings idea is information architecture: grouped destinations, one search surface, and immediate preview/reset. The local panel already has the hard parts. The next useful refinement is to give each indexed setting a category, short description, and owning tab, then present search results grouped by tab/category. Appearance can expose preview/revert for theme and workspace-shape changes without introducing a backend.

Possible groups are:

- General UI
- Color and theme
- Bar and workspaces
- Window manager
- Devices and input
- Network and media
- Power and notifications

### 4. Optional widgets

If persistent desktop information is wanted, start with one opt-in widget host backed by existing services, not a general plugin system. A clock/calendar or media widget would be the least surprising first widget. It needs explicit placement, lock/hide behavior, monitor handling, and a reduced-motion path before it is worth adding.

## Explicitly defer

- Ryoku's Hyprland-specific window rules, plugins, gestures, and compositor controls.
- A custom Quickshell overview, since Niri already owns overview behavior.
- The complete 479-setting Hub or a Go control plane. It would duplicate the current QML settings model and broaden the persistence surface substantially.
- Arbitrary third-party plugin execution. If plugins become important, begin with a declarative provider contract rather than loading untrusted QML.
- Additional package installation for calculator, annotation, OCR, or GPU recording. The current review found `qalc`, `swappy`, `tesseract`, `gpu-screen-recorder`, and `fd` unavailable; installing them is a separate decision.

## Local ownership map

- Launcher providers: `bar/LauncherPopup.qml`
- Shared popup behavior: `bar/PopupBase.qml`, `bar/PopupShield.qml`, `shell.qml`
- Settings navigation/search: `bar/SettingsPanel.qml`
- Shared settings surfaces and controls: `bar/primitives/`, `bar/settings/`
- Workspace behavior: `bar/WorkspaceIndicator.qml`
- Theme tokens and palette activation: `config/Colors.qml`, `config/Config.qml`, `config/PaletteCatalog.js`, `scripts/sync-active-palette.sh`
- Existing media, weather, and calendar surfaces: `bar/MediaPopup.qml`, `bar/WeatherPopup.qml`, `bar/CalendarPopup.qml`
- Niri keybindings and native overview: `/home/mura/.config/niri/keybinds.kdl`

## Suggested order

1. Clipboard provider, because it has the clearest feature gap and uses existing dependencies.
2. Capture surface, starting with save/copy and two selection modes.
3. Settings search hierarchy and preview/reset polish.
4. Widgets only after a concrete daily-use case is chosen.

## Implemented in the shell

The first two additions from this review now live in the existing launcher surface:

- `;` opens a `cliphist` provider with filtering, selected-entry preview, restore, per-entry delete, and a two-step clear action.
- `>` exposes full-screen and region capture actions backed by `grim` and `slurp`. Captures are saved under `~/Pictures/Screenshots`, copied with `wl-copy` when available, and reported with `notify-send`.

The provider work intentionally avoids a second popup and package installation. The enabled `clipboard-history.service` records new text through `scripts/clipboard-history-capture`, while the existing `cliphist` database remains the source of truth. Region-selection cancellation is treated as a normal exit.

## Remaining TODO

### High priority

- [ ] Make Settings search jump to, focus, and briefly highlight the exact matching control instead of only opening its tab.
- [ ] Add preview/revert affordances for appearance changes, especially themes and workspace marker styles.
- [ ] Add window capture using Niri's window data after the target-window mapping is reliable.

### Medium priority

- [ ] Decide whether clipboard history should also capture images; the current watcher records text only.
- [ ] Consider file, window, and calculator launcher providers without making normal app search noisy.
- [ ] Choose an annotation workflow before adding screenshot editing support. This may require an explicit package decision such as `swappy`.

### Optional

- [ ] If there is a concrete daily-use case, add an opt-in desktop widget host backed by the existing clock, calendar, media, or weather services.
- [ ] Update this review's implementation section when the Settings hierarchy and search polish are complete.

The following remain intentionally out of scope for now: Hyprland-specific controls, a second Go-backed settings hub, arbitrary third-party plugin execution, and Ryoku's distro update/recovery system.
