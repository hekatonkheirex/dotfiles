# Material 3 Expressive Refactor Plan for the ThinkPad X390

Status: Phases 0-3.5 applied in the worktree; focused QML, script, JSON, Niri, yadm-diff, and current service checks pass. The Settings feature pass is also applied: bar-content visibility, theme reload/source, dedicated Wallpaper and Media tabs, weather refresh/status, notification quiet hours and retention, saved-network controls, Bluetooth actions, lock/power controls, system actions, shortcuts export, and persisted last-tab selection. The normal, minimum-size, vertical, light/dark, eleven-tab, optional-backend failure, reduced-motion live-reload, and keyboard-contract checks are complete; a physical keyboard-only pass and fresh-restore check remain open. Phase commits were intentionally not created per AGENTS.md.

## Goal

Bring the Quickshell UI closer to Material 3 Expressive as a coherent component system while preserving the existing Ghost visual identity, compact 14-inch layout, and current bar/popup architecture.

This is a desktop adaptation of M3 Expressive. It applies the useful principles of expressive shape, color, motion, hierarchy, and interaction states without importing mobile-first navigation or touch-only geometry.

Reference basis:

- [Material 3](https://m3.material.io/)
- [Interaction states](https://m3.material.io/foundations/interaction/states/overview)
- [Canonical adaptive layouts](https://m3.material.io/foundations/layout/canonical-examples/overview)

## X390 interaction contract

The primary input model is pointer plus keyboard:

- Use hover, pressed, focused, selected, disabled, and error states consistently.
- Keep visible keyboard focus rings and predictable Tab, arrow-key, Enter, Space, Escape, Home, and End behavior.
- Use wheel input for sliders and scrollable lists where it is useful.
- Keep tooltips for icon-only controls, especially when the pointer hovers over them.
- Do not introduce swipe navigation, pinch gestures, long-press behavior, bottom navigation, floating action buttons, or touch-first sheets.
- Do not inflate every control to a mobile 48dp touch target. Preserve compact visual bounds appropriate to the X390, using a larger invisible pointer hit area only where it does not change layout density.
- Preserve the current horizontal and vertical bar modes, popup anchors, keyboard shortcuts, and reduced-motion preference.

A full pre-Phase-2 audit of `bar/*.qml` and `bar/commandcenter/*.qml` found no `SwipeView`, `PinchArea`, `MultiPointTouchArea`, `Drawer`, `DragHandler`, FAB, or bottom-nav pattern anywhere — the shell was already clean of touch-first components. Two isolated 48dp mobile-touch-target row heights were found and fixed ahead of the refactor: [`bar/BtPopup.qml`](bar/BtPopup.qml) and [`bar/LauncherPopup.qml`](bar/LauncherPopup.qml) device/app list rows now use `height: 44`, matching the row height already used by the equivalent list in [`bar/WifiPopup.qml`](bar/WifiPopup.qml) rather than Android's 48dp minimum. `LauncherPopup.qml`'s pill radius was adjusted from 24 to 22 to stay a true pill (`height / 2`) at the new row height. `Config.qml`'s `iconSizeLarge` (28) was also found to have zero consumers anywhere in the tree and was removed in Phase 1 along with the other dead build-time tokens.

Expressiveness should come from clear state changes, restrained shape transitions, semantic color, and purposeful motion. It should not come from taller bars, oversized headers, or decorative cards that consume workspace.

## Phase 0: safety net — DONE

The worktree was inspected with yadm before editing and its pre-existing changes were preserved. A clean baseline commit was not created because AGENTS.md prohibits commits during this task. Phase boundaries are tracked by the checklist and focused validation results; a fresh yadm restore remains an explicit open check.

## Phase 1: establish ownership and tokens — DONE

Theme ownership confirmed already resolved (Matugen), no change needed there. Dead-token cleanup removed `commandCenterMinWidth`/`commandCenterMinHeight`/`iconSizeLarge` from `Config.qml` and the eleven dead `Settings.qml` aliases (`barHeight`, `collapsedWidth`, `cornerRadius`, `expandedHeight`, `gapFromScreenEdge`, `motionBouncePercent`, `motionFadeMs`, `motionHoverMs`, `motionMovementMs`, `notchFlare`, `spacingUnit`) after confirming zero consumers via repo-wide grep. The active Settings minimum bounds were subsequently reintroduced as `Config.qml` tokens and wired to `CommandCenter.qml` in the Phase 3 preflight. The persisted settings format now carries `schemaVersion: 1`; future breaking key changes require an explicit migration before removal or rename.

Theme ownership is already resolved, not open: Matugen is the authoritative, wallpaper-derived palette source. `Colors.qml`'s `l_*`/`d_*` constants are deterministic fallbacks for first boot and generator failure only, documented as such in the file's own header comment. The `customize-rodrigo-linux` skill's "Ghost" description is stale relative to the current Matugen pipeline (`scripts/apply-wallpaper.sh` → `matugen-and-cache.sh` → `generate-all-themes.sh` → `sync-theme-mode.sh` → `sync-terminal-theme.sh`) and must not be treated as a second source of truth. This phase's job is to make every visual token route through `Config.qml`/`Colors.qml`, not to re-litigate which palette wins.

Inspect and, if needed, consolidate:

- [`config/Config.qml`](config/Config.qml): compact spacing, control sizes, typography roles, shape families, state-layer opacity, popup dimensions, and motion durations.
- [`config/Colors.qml`](config/Colors.qml): semantic surface, content, status, outline, and interaction-state roles for both light and dark modes.
- [`config/Settings.qml`](config/Settings.qml): remove or reconnect unused visual preferences rather than adding more duplicated tokens.
- Existing theme scripts: change them only if the ownership decision requires it. Generated files remain generated.

The first token pass should define desktop density tiers, not mobile touch sizes. It should also make existing values such as popup dimensions and reduced-motion behavior actual sources of truth. Build-time tokens must be wired or deleted. Persisted `Settings.qml` fields are a separate schema concern: retain an unused key only when it is documented as compatibility data and remove it only with an explicit settings migration.

## Phase 2: build only the shared primitives that have repeated consumers — DONE

Five shared primitives exist under `bar/primitives/`, and each has at least one real consumer proving its contract:

1. `StatusIndicator` — used by the Battery, Audio, Brightness, Media, Weather, Menu, Notification, and Launcher indicators.
2. `ActionButton` — proven via all four tiles in `bar/QuickMenu.qml`'s quick-toggle row (layout, wallpaper, idle, theme).
3. `IconButton` — proven via `bar/CalendarPopup.qml`'s month-nav chevrons.
4. `ListItem` — used by Bluetooth and Wi-Fi device rows, launcher results, Settings navigation, and Settings rows.
5. `TextFieldControl` — used by the launcher search field and Wi-Fi/Settings text fields.
Settings navigation remains an existing `ListItem` delegate in `bar/CommandCenter.qml`; a standalone `TabItem` was not introduced because the tab count and arrow-key behavior belong to the Settings shell. Progress and surface primitives were not built because no duplication was found beyond what `SliderControl`, `WaveProgressBar`, and `PopupDivider` already handle; revisit only if a real repeated contract appears.

The implemented shared component contracts are:

1. `IconButton`

   For close, refresh, navigation, media, launcher, menu, and other icon-only actions. It needs compact desktop sizing, hover/pressed/focused/disabled/selected states, tooltip support, keyboard activation, and real Qt accessibility properties. The current custom `accessibleName` properties are not a substitute for attached accessibility semantics.

2. `ActionButton`

   For labeled actions with a small set of variants such as filled, tonal, outlined, and quiet. Do not add a generic button-group abstraction until an actual group needs coordinated selection or keyboard navigation.

3. `StatusIndicator`

   For the repeated bar pattern used by audio, brightness, battery, Wi-Fi, Bluetooth, notifications, launcher, menu, and related indicators. It should own icon/label layout, hover and pressed overlays, keyboard semantics, tooltip text, and semantic status coloring while allowing each indicator to supply its value and action. Compact indicators use their existing state layers rather than an enclosing rounded focus border.

4. `ListItem` and `TextFieldControl`

   For launcher results, Wi-Fi and Bluetooth devices, notification rows, and the Wi-Fi password field. Keep rows dense, keyboard navigable, and clear about current selection, connection, error, and disabled states.

5. Settings navigation in `bar/CommandCenter.qml`

   Keep the existing icon-plus-label layout and arrow-key navigation in the shell delegate, where the tab count and current index are available. The selected state is the navigation cue; do not add an enclosing focus box or a second tab abstraction without repeated consumers.

6. Progress and surface primitives only where duplication justifies them

   Standardize linear progress semantics and track/fill behavior while retaining `WaveProgressBar` as an expressive visual variant. Use a shared card/surface treatment for repeated cards, not as a requirement that every piece of information become a card.

The existing `SwitchControl`, `SliderControl`, `WaveProgressBar`, and `PopupDivider` should be improved and reused before introducing replacements.

## Phase 3: refactor by vertical slices

### 3.1 Bar and indicators — APPLIED

The bar and indicator components now use `StatusIndicator` and `IconButton` where their interaction contract is shared. Workspace expansion, collapsed mode, vertical orientation, tray behavior, clock layout, and existing IPC triggers remain intact.

The workspace indicator is already a good expressive pattern because its active state changes shape and width. Keep that behavior and use it as the reference for restrained stateful motion.

### 3.2 Quick Menu and launcher — APPLIED

[`bar/QuickMenu.qml`](bar/QuickMenu.qml) and [`bar/LauncherPopup.qml`](bar/LauncherPopup.qml) now use the shared action, list, and field primitives. The action grid remains keyboard traversable with pointer hover feedback, and the current search keyboard behavior is preserved.

Power, reboot, suspend, and logout actions must retain the existing safety policy. Destructive actions should not become more immediate merely because their visual treatment is standardized.

### 3.3 Edge popups and forms — APPLIED

[`bar/PopupBase.qml`](bar/PopupBase.qml) remains the common edge-popup owner. Bluetooth, launcher, Quick Menu, and related surfaces share overlay behavior where their contracts are genuinely common, while the centered Settings surface retains its distinct layout mode with shared surface, focus, and motion rules.

The primitives now cover audio, brightness, battery, Wi-Fi, Bluetooth, calendar, and notification interactions, including refresh/close/navigation buttons, device rows, password input, selected networks, calendar navigation, and notification action rows without unnecessary popup-height growth.

### 3.4 Settings — APPLIED

The Settings shell [`bar/CommandCenter.qml`](bar/CommandCenter.qml) now hosts the current eleven-tab surface in this order: Account, General, Appearance, Wallpaper, Network, Bluetooth, Media, Lock & Power, Notifications, System, and Shortcuts. The tab content lives in [`bar/commandcenter/AccountTab.qml`](bar/commandcenter/AccountTab.qml), [`bar/commandcenter/GeneralTab.qml`](bar/commandcenter/GeneralTab.qml), [`bar/commandcenter/AppearanceTab.qml`](bar/commandcenter/AppearanceTab.qml), [`bar/commandcenter/WallpaperTab.qml`](bar/commandcenter/WallpaperTab.qml), [`bar/commandcenter/NetworkTab.qml`](bar/commandcenter/NetworkTab.qml), [`bar/commandcenter/BluetoothTab.qml`](bar/commandcenter/BluetoothTab.qml), [`bar/commandcenter/MediaTab.qml`](bar/commandcenter/MediaTab.qml), [`bar/commandcenter/LockMediaTab.qml`](bar/commandcenter/LockMediaTab.qml), [`bar/commandcenter/NotificationsTab.qml`](bar/commandcenter/NotificationsTab.qml), [`bar/commandcenter/SystemTab.qml`](bar/commandcenter/SystemTab.qml), and [`bar/commandcenter/ShortcutsTab.qml`](bar/commandcenter/ShortcutsTab.qml). The filename remains `CommandCenter.qml` for internal IPC and deployment compatibility; the user-facing surface is Settings. The active `Config.qml` minimum and maximum bounds are preserved. Each tab uses a width-bound vertical `Flickable` when its content exceeds the available height; a targeted 320x360 harness confirmed reachable compact content and selected-tab sidebar scrolling. The full eleven-tab, vertical, light/dark, and reduced-motion matrix is covered by the current checks. Shared controls, Settings navigation, launcher lists, wallpaper grids, workspace items, power confirmation, the launcher microphone, the bar clock, and system-tray items now have source-verified keyboard paths; a physical keyboard-only pass remains open because no input-injection utility is installed in the session.

Media controls, navigation rows, wallpaper tiles, and diagnostics should all share the same focus and selection conventions. `SwitchControl` and `SliderControl` in the current General, Appearance, Media, Lock & Power, and Notifications tabs are the controls with the heaviest reuse here — extend them, do not fork per-tab variants. No swipe-based tab or carousel behavior is needed.

### 3.5 Feedback and security surfaces — APPLIED

The state language of [`bar/NotificationToast.qml`](bar/NotificationToast.qml), [`bar/NotificationPopup.qml`](bar/NotificationPopup.qml), and [`bar/OsdOverlay.qml`](bar/OsdOverlay.qml) is unified while their purposes remain distinct. Supported notification actions are exposed as focused action buttons instead of making the whole notification an unlabeled mouse target.

[`bar/LockScreen.qml`](bar/LockScreen.qml) remains a separate security surface with the keyboard/focus and compact icon-button contract applied to its controls; it is not forced into the ordinary popup hierarchy.

## Phase 4: accessibility and interaction verification

Reusable controls and important delegates now expose Qt accessibility roles, names, descriptions, checked/selected states, and slider values. The remaining work is manual interaction verification. Check that:

- every actionable icon has a name and keyboard path;
- Tab order follows the visual order;
- arrow keys work within tabs, lists, segmented choices, and sliders;
- Escape closes transient surfaces without losing the useful focus target;
- disabled and unavailable hardware states remain understandable;
- focus remains visible in both light and dark modes;
- reduced motion removes travel and bounce without removing state feedback.

## Phase 5: validation matrix

Run the narrowest checks after each slice, then the complete matrix. The first three checks are deterministic, free gate checks and should run for every implementation slice.

Current focused status:

- PASS: `bash scripts/m3-qmllint-gate.sh`, `jq empty settings.json`, Python syntax compilation for `scripts/weather.py`, and `yadm diff --check -- .config/quickshell`.
- PASS: `niri validate` from `/home/mura`.
- PASS: the latest Quickshell restart remained active and logged `Configuration Loaded` after the WeatherPopup primitives import was corrected. The journal also retains the earlier pre-fix WeatherPopup restart failures and older portal/tray and missing-wallpaper-thumbnail warnings, so the historical journal is not warning-free.
- PASS: targeted 320x360 compact checks for Account, Appearance, General, and System; normal 1920x1080 Settings checks in both horizontal and vertical bar modes; and selected-tab sidebar visibility.
- PASS: System diagnostics now use the detected CPU thread count, UPower battery state, detected battery paths for cycle data, and explicit unavailable states for optional sensors, battery, NetworkManager, and Bluetooth data. Live System, Network, and Bluetooth pages loaded with the installed services.
- PASS: Account machine information is loaded only while the Account tab is visible, and workspace delegates expose their number/state through keyboard-accessible labels without increasing bar density.
- PASS: reduced motion is live-verified by restarting Quickshell with `Settings.reduceMotion` enabled; centralized motion tokens resolve to zero, long-running background motion is disabled, and the surface reloads cleanly.
- PASS: keyboard paths are source-verified across shared controls, Settings navigation, list/grid navigation, workspace items, power confirmation, the launcher microphone, the bar clock, and system-tray items.
- OPEN: physical keyboard-only operation because `wtype`, `ydotool`, and `xdotool` are not installed; and a fresh committed yadm restore after the uncommitted work is intentionally preserved.

- automated regression guard: [`scripts/m3-qmllint-gate.sh`](scripts/m3-qmllint-gate.sh) (`qmllint` over shell, config, bar, commandcenter, and `bar/primitives` files; non-zero exit fails the slice), so a broken binding or missing import is caught close to the change;
- `qmllint shell.qml` and the affected QML files;
- `bash -n` for every changed shell script;
- `yadm status --short` and a review for unrelated changes;
- Quickshell reload with runtime-warning inspection when a live session is available;
- both light and dark modes;
- reduced motion on and off;
- horizontal and vertical bar modes;
- compact and normal Settings widths;
- keyboard-only operation and pointer operation;
- optional Wi-Fi, Bluetooth, battery, tray, and media services absent or unavailable;
- Niri validation when the surrounding Niri configuration is affected.

## Acceptance criteria

The refactor is complete when:

1. Repeated controls use shared state, focus, sizing, and semantic-color contracts.
2. Icon-only actions are discoverable by pointer and keyboard without touch-specific layout inflation.
3. Popups remain compact and anchored correctly on the X390.
4. Settings content does not overflow at its compact width.
5. Light, dark, reduced-motion, horizontal-bar, and vertical-bar behavior remains intact.
6. No new dependency, generated-file edit, mobile navigation pattern, or second theme/token owner is introduced without an explicit reason.
7. Each phase has an independently recorded validation result. Commits were intentionally omitted per AGENTS.md; a maintainer can create phase commits later if rollback granularity is required.
8. No unused build-time property remains in `Config.qml`. Persisted `Settings.qml` fields are either consumed by an owning surface or explicitly documented as compatibility schema; `schemaVersion` must be incremented and migrated before a breaking rename or removal.
