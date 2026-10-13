# Elena sidebar pages (S2)

## Objective
Replace the deferred dashboard grid with two pages inside the existing 320px sidebar. Status retains clock, battery, weather, media and level controls. Dashboard shows the current user/session, safe quick links, a browsable calendar, uptime, memory usage and one-minute CPU load average. The center music window remains excluded.

## Decisions and boundaries
- Default to Status; remember the selected page in memory, not settings.json.
- Keep page buttons and search outside scrolling content. Both pages scroll on short outputs.
- Page buttons support Tab/Enter/Space; Ctrl+PageUp/PageDown switches pages without consuming ordinary search cursor keys. Escape and click-away retain the existing dismissal path.
- Search remains available on either page and preserves its query while switching. Closing clears the query, as before. Existing launcher and @ wallpaper routing remain unchanged.
- Status service sidebarActive gates are true only while Status is visible. Dashboard statistics refresh every five seconds only while Dashboard is visible. No hidden background polling.
- Reuse CalendarLogic.js and calendarWeekStartsMonday. Month changes anchor to day 1, including December/January and leap years. Refresh today's date while the dashboard is active.
- Profile uses USER and XDG_CURRENT_DESKTOP; an initial badge avoids another masked Image allocation while the existing Image leak is unresolved.
- Quick links are Settings (Account), Appearance and System diagnostics, routed through the existing SettingsPanel owner. Do not spawn applications or introduce new IPC.
- Linux /proc uptime, meminfo and loadavg are the statistics sources. CPU load is explicitly labeled as load, not utilization. Missing data shows Unavailable, never fabricated zeroes.
- Preserve Niri bindings, authentication, existing palette/control grammar, external themes and the single-open-popup model. Launcher, power and notification redesign remain separate.

## Ownership and conventions
bar/sidebar/SidebarContent.qml owns page selection, scrolling, focus and shared search. Sidebar.qml owns service activation and forwards quick-link requests. Dashboard cards live beside the existing sidebar cards. System metric parsing is a small pure JS helper; the statistics card owns visibility-gated FileViews, not a global new service. shell.qml routes quick links to SettingsPanel.

Use existing Card, ActionButton, IconButton and semantic Config/Colors tokens. Signals use the existing QML pattern: `signal settingsRequested(int tab)`; the shell checks the locked guard before opening Settings. No style branches or new dependency.

## Acceptance and verification
1. Status retains all existing controls; Dashboard renders real profile, calendar and statistics.
2. Switching pages preserves search text; closing clears it. Hidden pages are disabled for keyboard navigation.
3. Page selection, keyboard switching, short-height scrolling and Settings links work through the real QML components.
4. Stats stop refreshing when closed or on Status; invalid/missing values render Unavailable.
5. Existing calendar week-start preference and month-boundary behavior hold.
6. Isolated Quickshell captures show both pages at normal and short height without new QML errors. Existing sidebar and controls gates remain green.

Commands (from ~/.config/quickshell):
- `bash scripts/m3-qmllint-gate.sh`
- `node tests/sidebar/test.mjs`
- `node tests/sidebar/stats.test.mjs`
- `bash scripts/sidebar-render.sh`
- `bash scripts/controls-behavior.sh`
- `bash scripts/style-refs.sh --elena`

Use the existing scratch-HOME rendering convention; do not exercise destructive actions or send keystrokes into the live desktop. Live checks follow a user-authorized cold restart. No commits or pushes without a separate request.
