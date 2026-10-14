# Settings as a right sidebar

Date: 2026-10-14. Status: implemented.

## Outcome
Settings opens as a right-edge sidebar with pages, the mirror of the left sidebar, replacing the floating, resizable Settings window. Measured by `tests/settings-tabs/test.mjs` (page order, retired pages and sections stay gone, wiring), `scripts/popup-ipc-check.sh` (route `settings`), and live screenshots of all six pages.

## Decisions
- Window: `bar/SettingsSidebar.qml`, a `PopupBase` anchored right and bottom, `dp(300)` wide, the left sidebar width, above the bottom bar, square right corners. Route `settings` joins the single-open-popup model. Opens from a 1 px right-edge hover strip (`SidebarActivator { rightEdge: true }`, same `sidebarEdgeHover` toggle and 120 ms dwell), the launcher action, the `settings` file trigger and `qs ipc call shell popup settings`.
- Pages (order): General, Appearance, Display & Input, Bluetooth, Lock & Power, Notifications. Reuses the existing page files, renumbered 0-5; `bar/settingsbar/SettingsSidebarContent.qml` loads one at a time (only while open) and shares the left sidebar's `PageIndicators`.
- Removed by request: Account, Media, System and Shortcuts pages; General "Behavior" section (reduced motion, uptime); Appearance "Accent Colors" and "Interface sizing"; `AccentSwatch.qml`.
- Removed with the window: search, rail, drag and resize handle, `Settings.settingsPanelWidth/Height` remain as unused saved keys.
- Saved keys are kept (`accentPalette`, `reduceMotion`, `systemShowUptime`, font/icon/spacing scales); only their UI is gone.

## Risks
- Page files were built for a wide panel; at `dp(380)` they render single column. Display & Input's transform list is tall and scrolls.
- The right edge is a common scrollbar location; the edge toggle gates both strips.
