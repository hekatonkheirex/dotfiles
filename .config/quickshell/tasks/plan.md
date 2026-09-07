# Implementation Plan: Settings Window

## Overview

Add a centered, searchable settings window with persistent local appearance preferences. Unsupported integrations will render as explicit placeholders.

## Architecture Decisions

- Use one full-screen `PanelWindow` overlay with a centered settings card so the page behaves consistently under Hyprland and remains independent of the bar layout.
- Keep settings state in a small `SettingsStore.qml` backed by `Quickshell.Io` `FileView` and `JsonAdapter`.
- Use reusable QML controls for sidebar entries, setting rows, segmented choices, toggles, sliders, and placeholder cards.
- Keep unsupported categories visible for navigation, but mark their controls as placeholders and do not invent system integrations.
- Add a settings gear to the bar and a Quickshell IPC entry point.

## Task List

### Phase 1: Foundation

- [x] Task 1: Add persistent settings store and shared settings controls.
- [x] Task 2: Add the overlay window shell, card layout, sidebar, search, and dismissal behavior.

### Phase 2: Settings Surface

- [x] Task 3: Implement the functional Appearance page.
- [x] Task 4: Add all supported-category navigation pages and explicit placeholders for unavailable features.

### Phase 3: Integration and Validation

- [x] Task 5: Add bar and IPC entry points, layer-rule support, and documentation.
- [x] Task 6: Validate QML syntax, live reload, geometry, and visual output.

### Checkpoint: Complete

- [x] Settings opens from the bar and IPC.
- [x] Search filters the sidebar.
- [x] Appearance preferences persist locally.
- [x] Import and Community are absent.
- [x] All remaining categories have visible placeholder content.
- [x] QML lint and live Quickshell reload pass.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| A full-screen layer can steal input from normal windows | High | Keep it hidden by default, use an explicit namespace, and close it from the card close button or outside click. |
| Some integrations are unavailable to this shell | Medium | Keep those rows as disabled, clearly labeled placeholders. |
| QML reload can lose transient page state | Low | Persist only user settings; keep navigation state local to the window. |

## Open Questions

- None. Import and Community features are intentionally excluded per request.

---

# Implementation Plan: Quickshell Notifications

## Overview

Provide a Quickshell-owned desktop notification server, a bar entry point, an anchored notification history popup, and a small top-right toast surface. Keep unsupported features as explicit placeholders.

## Architecture Decisions

- Use Quickshell 0.3.1's native `Quickshell.Services.Notifications.NotificationServer` instead of adding a second notification daemon or package.
- Keep one notification service in `shell.qml`; expose its tracked `ObjectModel` to each bar instance and render the automatic toast once on the primary screen to avoid duplicate toasts on multi-monitor setups.
- Retain notifications in the in-memory tracked model, support notification actions and dismissal, and persist only user preferences such as Do Not Disturb. Disk-backed notification history is out of scope for this pass.
- Keep notification popups anchored through the existing `PopupPanel` path so they inherit the bar's dismissal and layer behavior.

## Task List

### Phase 1: Notification ownership

- [x] Task 1: Add the shared notification service and persistent notification preferences.
- [x] Task 2: Handle incoming notifications, unread state, expiry, actions, and clear-all behavior.

### Phase 2: User surfaces

- [x] Task 3: Add the anchored notification history popup and bar indicator.
- [x] Task 4: Add the primary-screen toast surface with timeout and dismissal.

### Phase 3: Settings and validation

- [x] Task 5: Replace the Notifications placeholder page with functional Do Not Disturb and supported-feature controls.
- [x] Task 6: Validate QML, live reload, current DBus ownership, and `notify-send` delivery.

### Checkpoint: Complete

- [x] A notification is accepted from `notify-send` and appears as a toast.
- [x] The bar indicator opens history, supports dismissal/actions, and clears notifications.
- [x] Do Not Disturb suppresses toasts while retaining history.
- [x] No extra package or user service is installed.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Another process owns `org.freedesktop.Notifications` | High | Verify that Quickshell is the only notification owner before enabling delivery. |
| Notification objects expire or are destroyed during UI interaction | High | Use the tracked ObjectModel, clear stale unread references on removal, and guard toast targets before invoking methods. |
| Multiple monitors duplicate automatic toasts | Medium | Instantiate one toast on the primary screen; keep history popups local to the bar that opened them. |
| Notification bodies may contain markup or untrusted text | Medium | Advertise plain-text bodies and render them with `Text.PlainText`. |

## Open Questions

- No disk-backed history or notification sound integration in this pass; both remain future settings placeholders.

# Implementation Plan: Quickshell Lockscreen Migration

## Overview

Use a native Quickshell session lock with PAM password authentication as the active session lock owner.

## Architecture Decisions

- Use Quickshell's `WlSessionLock` and `WlSessionLockSurface` instead of a normal layer-shell window so the compositor enforces lock coverage.
- Use `PamContext` with the existing password-only `login` PAM service.
- Expose only a lock IPC action; never expose an IPC unlock action.
- Render one lock surface per monitor and share the PAM/authentication state from the shell root.
- Keep keybind, power-button, and idle-timeout actions routed through the verified Quickshell and hypridle paths.

## Task List

### Phase 1: Manual lock

- [x] Add the native session-lock controller and PAM conversation.
- [x] Add the centered lock UI with clock, username, password input, and error state.
- [x] Add `session lock` IPC and document the manual test path.

### Phase 2: Handoff after verification

- [x] Verify manual lock and password unlock on the active Hyprland session.
- [x] Move the power-menu lock action to Quickshell IPC.
- [x] Move the Hyprland lock keybind to Quickshell IPC.
- [x] Make Quickshell and hypridle the sole lock, idle, and power owners.
- [x] Verify idle lock, DPMS off, and suspend/resume behavior.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Lock surface destruction while locked | High | Do not reload or terminate Quickshell while the lock is active; validate manual unlock before handoff. |
| PAM conversation mismatch | High | Use the current password-only `login` PAM stack and only unlock on `PamResult.Success`. |
| Two lock owners race | High | Keep one verified Quickshell lockscreen and one hypridle scheduler. |
