# Task 5 report: WifiSurface

## What was done

Created `pill/surfaces/WifiSurface.qml` (434 lines) with the exact content specified in the brief — content ported from `bar/WifiPopup.qml`, chrome stripped, height clamp dropped, `onShown` replaced with `onVisibleChanged`. No other files were touched.

## Verification performed

1. **Component API check** — read all 6 imported components (`IconButton`, `SwitchControl`, `PopupDivider`, `ListItem`, `TextFieldControl`, `ActionButton`) in `pill/components/` and confirmed every property and signal referenced in `WifiSurface.qml` actually exists on each:
   - `IconButton`: `iconLabel`, `size`, `iconSize`, `enabled`, `accessibleName`, `tooltipText`, `clicked` — all present.
   - `SwitchControl`: `checked`, `activeColor`, `surfaceContainerHighest`, `outline`, `motionDuration`, `reducedMotion`, `accessibleName`, `toggled` — all present.
   - `PopupDivider`: used with no properties — fine.
   - `ListItem`: `leadingIcon`, `leadingIconColor`, `leadingIconOpacity`, `title`, `subtitle`, `selected`, `accessibleName`, `accessibleDescription`, `clicked`, plus default `trailingContent` alias (used implicitly via the two child `Text` elements nested inside `ListItem` in the delegate) — all present.
   - `TextFieldControl`: `text` (alias), `placeholder`, `accessibleName`, `echoMode` — all present.
   - `ActionButton`: `labelText`, `variant`, `accessibleName`, `activated`, `radius` (inherited from `Rectangle`), `enabled` (inherited `Item`/`Rectangle` property) — all present.
2. **Config/Colors check** — confirmed `Config.qml` exports `fontFamily`, `iconFont`, `fontPixelSize`, `motionMedium`, `reducedMotion`, and `Colors.qml` exports `fgSurface`, `fgSurfaceVariant`, `primary`, `outline`, `surfaceContainerHighest` (all referenced in the surface).
3. **qmllint** — `qmllint pill/surfaces/WifiSurface.qml` ran clean, exit 0, no warnings or errors (including no cross-module import warnings, since `../components` and `../config` resolve to real sibling directories in the pill tree).
4. **Line-count sanity check** — `bar/WifiPopup.qml` (source) and the new `WifiSurface.qml` are both 434 lines, consistent with a chrome-stripped 1:1 content port.

## Commit

```
99c261a7 Port the wifi popup content into a pill-hosted WifiSurface
1 file changed, 434 insertions(+)
create mode 100644 .config/quickshell/pill/surfaces/WifiSurface.qml
```

Committed via `yadm add` + `yadm commit` (yadm-managed dotfiles repo rooted at `$HOME`, not a plain git repo).

## Notes

- `bar/WifiPopup.qml` was read only for comparison, never modified.
- No `shell.qml` wiring exists yet for this surface (Task 7's job) — cannot visually verify end-to-end with `qs`, as expected per the task instructions.
