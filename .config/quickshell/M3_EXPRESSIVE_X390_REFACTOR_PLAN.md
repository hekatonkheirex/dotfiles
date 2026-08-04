# Material 3 Expressive Refactor Plan for the ThinkPad X390

Status: implementation complete in worktree — Phases 0-3.5 applied; focused Phase 4/5 checks passed; full light/dark and vertical-mode manual matrix remains to be exercised. Phase commits were intentionally not created per AGENTS.md.

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

## Phase 0: safety net — DONE (commit 790feec9)

Before any edit, commit a clean baseline (`yadm status --short` must be empty or the pre-existing state noted) and record the current `qmllint` output for every file this plan touches as the pass/fail baseline. Create one commit per phase below, not one commit for the whole refactor. If a phase's manual/automated checks (Phase 5) fail after it lands, the fix is `yadm` revert of that phase's commit, not a forward patch bolted onto the next phase. Do not start Phase 2 until Phase 1's commit is in and green; do not start Phase 3 until every primitive in Phase 2 has at least one consumer proving its contract.

## Phase 1: establish ownership and tokens — DONE (commit fb6bce6a)

Theme ownership confirmed already resolved (Matugen), no change needed there. Dead-token cleanup in commit `fb6bce6a` removed `commandCenterMinWidth`/`commandCenterMinHeight`/`iconSizeLarge` from `Config.qml` and the eleven dead `Settings.qml` aliases (`barHeight`, `collapsedWidth`, `cornerRadius`, `expandedHeight`, `gapFromScreenEdge`, `motionBouncePercent`, `motionFadeMs`, `motionHoverMs`, `motionMovementMs`, `notchFlare`, `spacingUnit`) after confirming zero consumers via repo-wide grep. The active Command Center minimum bounds were subsequently reintroduced as `Config.qml` tokens and wired to `CommandCenter.qml` in the Phase 3 preflight, while the remaining persisted settings schema is retained until an explicit migration can remove unused keys safely.

Theme ownership is already resolved, not open: Matugen is the authoritative, wallpaper-derived palette source. `Colors.qml`'s `l_*`/`d_*` constants are deterministic fallbacks for first boot and generator failure only, documented as such in the file's own header comment. The `customize-rodrigo-linux` skill's "Ghost" description is stale relative to the current Matugen pipeline (`scripts/apply-wallpaper.sh` → `matugen-and-cache.sh` → `generate-all-themes.sh` → `sync-theme-mode.sh` → `sync-terminal-theme.sh`) and must not be treated as a second source of truth. This phase's job is to make every visual token route through `Config.qml`/`Colors.qml`, not to re-litigate which palette wins.

Inspect and, if needed, consolidate:

- [`config/Config.qml`](config/Config.qml): compact spacing, control sizes, typography roles, shape families, state-layer opacity, popup dimensions, and motion durations.
- [`config/Colors.qml`](config/Colors.qml): semantic surface, content, status, outline, and interaction-state roles for both light and dark modes.
- [`config/Settings.qml`](config/Settings.qml): remove or reconnect unused visual preferences rather than adding more duplicated tokens.
- Existing theme scripts: change them only if the ownership decision requires it. Generated files remain generated.

The first token pass should define desktop density tiers, not mobile touch sizes. It should also make existing values such as popup dimensions and reduced-motion behavior actual sources of truth. Build-time tokens must be wired or deleted. Persisted `Settings.qml` fields are a separate schema concern: retain an unused key only when it is documented as compatibility data and remove it only with an explicit settings migration.

## Phase 2: build only the shared primitives that have repeated consumers — DONE (commit dfce1aff)

All six primitives below exist under `bar/primitives/` and each has one real consumer proving its contract (full migration of every remaining consumer is Phase 3, not done yet):

1. `StatusIndicator` — proven via `bar/BatteryIndicator.qml`. Remaining consumers to migrate in Phase 3.1: Audio, Brightness, Bt, Wifi, Menu, Notification, Launcher indicators.
2. `ActionButton` — proven via all four tiles in `bar/QuickMenu.qml`'s quick-toggle row (layout, wallpaper, idle, theme).
3. `IconButton` — proven via `bar/CalendarPopup.qml`'s month-nav chevrons.
4. `ListItem` — proven via `bar/BtPopup.qml`'s device row. Remaining consumers to migrate in Phase 3.3: Wifi network rows, launcher results, notification rows.
5. `TextFieldControl` — proven via `bar/WifiPopup.qml`'s password field. Remaining consumer to migrate in Phase 3.2: launcher search field.
6. `TabItem` — proven via `bar/CommandCenter.qml`'s tab bar (arrow-key navigation stayed in the CommandCenter delegate since it depends on tab count).

Progress and surface primitives (item 6 in the original list below) were not built — no duplication found beyond what `SliderControl`/`WaveProgressBar`/`PopupDivider` already handle; revisit only if Phase 3 turns up real duplication.

Create shared components incrementally under the existing `bar` component area. Each primitive should expose the same state and accessibility contract rather than only standardizing colors.

1. `IconButton`

   For close, refresh, navigation, media, launcher, menu, and other icon-only actions. It needs compact desktop sizing, hover/pressed/focused/disabled/selected states, tooltip support, keyboard activation, and real Qt accessibility properties. The current custom `accessibleName` properties are not a substitute for attached accessibility semantics.

2. `ActionButton`

   For labeled actions with a small set of variants such as filled, tonal, outlined, and quiet. Do not add a generic button-group abstraction until an actual group needs coordinated selection or keyboard navigation.

3. `StatusIndicator`

   For the repeated bar pattern used by audio, brightness, battery, Wi-Fi, Bluetooth, notifications, launcher, menu, and related indicators. It should own icon/label layout, hover and pressed overlays, keyboard semantics, tooltip text, and semantic status coloring while allowing each indicator to supply its value and action. Compact indicators use their existing state layers rather than an enclosing rounded focus border.

4. `ListItem` and `TextFieldControl`

   For launcher results, Wi-Fi and Bluetooth devices, notification rows, and the Wi-Fi password field. Keep rows dense, keyboard navigable, and clear about current selection, connection, error, and disabled states.

5. `TabItem` or a similarly small tab primitive

   For Command Center navigation. Keep the existing horizontal icon-plus-label layout and arrow-key navigation, but centralize selected, hover, pressed, focus, and indicator behavior. The selected underline is the tab strip's visual focus/selection cue; do not add an enclosing focus box.

6. Progress and surface primitives only where duplication justifies them

   Standardize linear progress semantics and track/fill behavior while retaining `WaveProgressBar` as an expressive visual variant. Use a shared card/surface treatment for repeated cards, not as a requirement that every piece of information become a card.

The existing `SwitchControl`, `SliderControl`, `WaveProgressBar`, and `PopupDivider` should be improved and reused before introducing replacements.

## Phase 3: refactor by vertical slices

### 3.1 Bar and indicators — APPLIED

Refactor [`bar/Bar.qml`](bar/Bar.qml) and the indicator components first. Replace duplicated `Rectangle` plus `MouseArea` button chrome with `StatusIndicator` and `IconButton` where appropriate. Preserve workspace expansion, collapsed mode, vertical orientation, tray behavior, clock layout, and existing IPC triggers.

The workspace indicator is already a good expressive pattern because its active state changes shape and width. Keep that behavior and use it as the reference for restrained stateful motion.

### 3.2 Quick Menu and launcher — APPLIED

Refactor [`bar/QuickMenu.qml`](bar/QuickMenu.qml) and [`bar/LauncherPopup.qml`](bar/LauncherPopup.qml) around the shared action, list, and field primitives. Make the action grid fully keyboard traversable and keep pointer hover feedback. Preserve the current search keyboard behavior.

Power, reboot, suspend, and logout actions must retain the existing safety policy. Destructive actions should not become more immediate merely because their visual treatment is standardized.

### 3.3 Edge popups and forms — APPLIED

Keep [`bar/PopupBase.qml`](bar/PopupBase.qml) as the common edge-popup owner. Move the manually duplicated popup chrome in Bluetooth, launcher, Quick Menu, and related surfaces into the shared overlay contract only where their behavior is genuinely shared. The centered Command Center can remain a distinct layout mode while sharing surface, focus, and motion rules.

Apply the primitives to audio, brightness, battery, Wi-Fi, Bluetooth, calendar, and notifications. This should cover refresh/close/navigation buttons, device rows, password input, selected networks, calendar navigation, and notification action rows without increasing popup height unnecessarily.

### 3.4 Command Center — APPLIED

Refactor [`bar/CommandCenter.qml`](bar/CommandCenter.qml) and its tab files — [`bar/commandcenter/OverviewTab.qml`](bar/commandcenter/OverviewTab.qml), [`bar/commandcenter/MediaTab.qml`](bar/commandcenter/MediaTab.qml), [`bar/commandcenter/WallpapersTab.qml`](bar/commandcenter/WallpapersTab.qml), [`bar/commandcenter/WeatherTab.qml`](bar/commandcenter/WeatherTab.qml), and [`bar/commandcenter/SettingsTab.qml`](bar/commandcenter/SettingsTab.qml) — after the smaller surfaces are stable. Preserve the active `Config.qml` minimum and maximum bounds. The overview's compact fallback uses a bounded horizontal `Flickable` below its 752px content width; verify that behavior at the 320px minimum before marking this slice complete. Reflow other tabs only when their actual content requires it.

Media controls, tab items, settings rows, wallpaper tiles, and diagnostics should all share the same focus and selection conventions. `WaveProgressBar` in `OverviewTab.qml`/`MediaTab.qml` and `SwitchControl`/`SliderControl` in `SettingsTab.qml` are the primitives already in the heaviest reuse here — extend them, do not fork per-tab variants. No swipe-based tab or carousel behavior is needed.

### 3.5 Feedback and security surfaces — APPLIED

Unify the state language of [`bar/NotificationToast.qml`](bar/NotificationToast.qml), [`bar/NotificationPopup.qml`](bar/NotificationPopup.qml), and [`bar/OsdOverlay.qml`](bar/OsdOverlay.qml), while keeping their different purposes. If notification actions are supported by the service, expose them as focused action buttons instead of treating the whole notification as an unlabeled mouse target.

Keep [`bar/LockScreen.qml`](bar/LockScreen.qml) a separate security surface. Apply the keyboard/focus and compact icon-button contract to its controls, but do not force the lock screen into the ordinary popup component hierarchy.

## Phase 4: accessibility and interaction verification

Add actual Qt accessibility roles, names, descriptions, checked/selected states, and slider values to reusable controls and important delegates. Check that:

- every actionable icon has a name and keyboard path;
- Tab order follows the visual order;
- arrow keys work within tabs, lists, segmented choices, and sliders;
- Escape closes transient surfaces without losing the useful focus target;
- disabled and unavailable hardware states remain understandable;
- focus remains visible in both light and dark modes;
- reduced motion removes travel and bounce without removing state feedback.

## Phase 5: validation matrix

Run the narrowest checks after each slice, then the complete matrix. The first three checks are gate checks: deterministic, free, and must run on every commit in this refactor, not just at the end.

- automated regression guard: [`scripts/m3-qmllint-gate.sh`](scripts/m3-qmllint-gate.sh) (`qmllint` over shell, config, bar, command-center, and `bar/primitives` files; non-zero exit fails the phase) run before every phase commit, so a broken binding or missing import in slice N is caught before slice N+1 builds on it, not discovered during the final manual pass;
- `qmllint shell.qml` and the affected QML files;
- `bash -n` for every changed shell script;
- `yadm status --short` and a review for unrelated changes;
- Quickshell reload with runtime-warning inspection when a live session is available;
- both light and dark modes;
- reduced motion on and off;
- horizontal and vertical bar modes;
- compact and normal Command Center widths;
- keyboard-only operation and pointer operation;
- optional Wi-Fi, Bluetooth, battery, tray, and media services absent or unavailable;
- Niri validation when the surrounding Niri configuration is affected.

## Acceptance criteria

The refactor is complete when:

1. Repeated controls use shared state, focus, sizing, and semantic-color contracts.
2. Icon-only actions are discoverable by pointer and keyboard without touch-specific layout inflation.
3. Popups remain compact and anchored correctly on the X390.
4. Command Center content does not overflow at its compact width.
5. Light, dark, reduced-motion, horizontal-bar, and vertical-bar behavior remains intact.
6. No new dependency, generated-file edit, mobile navigation pattern, or second theme/token owner is introduced without an explicit reason.
7. Every phase landed as its own commit with a passing `qmllint` gate check, so any regression can be reverted at phase granularity instead of unwound by hand.
8. No unused build-time property remains in `Config.qml`. Persisted `Settings.qml` fields are either consumed by an owning surface or explicitly documented as compatibility schema with a migration plan before removal.
