# Task 6 Report: BtSurface

## What was done

Created `pill/surfaces/BtSurface.qml`, transcribed verbatim from the brief. Content ported from `bar/BtPopup.qml`: chrome (the inline `PanelWindow`) stripped, everything inside `contentColumn` plus its supporting `Process`es (`statusQuery`, `listQuery`) and the `btItemDelegate` `Component` carried over unchanged. `onVisibleChanged` drives the initial `bluetoothctl show` query in place of the source's `Qt.application.activeChanged`/`entryAnimation` wiring, per the brief.

No other files were touched.

## Verification

- Cross-checked every property/signal referenced against the actual component source before writing:
  - `IconButton.qml`: `iconLabel`, `size`, `iconSize`, `enabled`, `iconColor`, `accessibleName`, `tooltipText`, `onClicked` all present.
  - `SwitchControl.qml`: `checked`, `activeColor`, `surfaceContainerHighest`, `outline`, `motionDuration`, `reducedMotion`, `accessibleName`, `onToggled` all present.
  - `PopupDivider.qml`: no props used beyond default instantiation — fine.
  - `ListItem.qml`: `leadingIcon`, `leadingIconColor`, `title`, `subtitle`, `accessibleName`, `hovered` (readonly, used as `itemRow.hovered`), default `trailingContent` alias (the `Row` and `IconButton` children land there) — all present.
  - `pill/config/Config.qml`: `motionMedium` (readonly int) and `reducedMotion` (bool) confirmed at lines 38/40.
  - `pill/config/Colors.qml`: `error` color property confirmed at line 195.
- Ran `qmllint pill/surfaces/BtSurface.qml` — clean, no output, exit 0. Compared against `qmllint pill/surfaces/WifiSurface.qml` (an already-shipped sibling surface) to confirm the tool isn't silently suppressing cross-module import warnings across the board — also exit 0, so BtSurface's clean result is consistent with the established pattern, not a fluke.
- No syntax errors, no unresolved local references.

## Commit

`505db84f` — "Port the bluetooth popup content into a pill-hosted BtSurface"
1 file changed, 247 insertions(+), `pill/surfaces/BtSurface.qml` created.

## Notes

Task 7 wires this surface into `Pill.qml` as the `surface === "bluetooth"` content — not in scope here. Cannot visually verify end-to-end until that wiring exists (per task brief).
