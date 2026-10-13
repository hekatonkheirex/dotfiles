# Elena power-menu presentation redesign

## Objective
Continue the reference-derived dashed-card/monospace grammar from the launcher. QuickMenu gets a 3×2 session grid: the existing Log Out, Shut Down, Restart and Sleep actions, Lock, and the existing Settings shortcut. No Hibernate command is introduced. DND, Bluetooth, airplane mode and caffeine stay in the controls row above the grid.

## Ownership and changes
- bar/QuickMenu.qml: presentation, hover/focus labels and grid-aware keyboard traversal. Move Settings into the sixth tile rather than duplicating it. Preserve powerOptions commands, requestPower/pending/cancel/confirm flow, lockRequested and settingsRequested.
- bar/PowerConfirmation.qml: matching frame, monospace confirmation context/hints, existing action title/description, safe initial Cancel focus, and 48px button hit height. Preserve signals, keyboard activation, outside-click cancellation and customization used by both lock-screen callsites.
- bar/primitives/DashedFrame.qml: small shared drawing primitive, extracted from the launcher now that there are three consumers. Semantic stroke color, caller-provided radius and visibility; repaint only on geometry/color/show changes. Launcher retains its existing appearance.
- shell.qml, lock execution helpers, systemd/Niri commands, PAM/fingerprint, bindings and external themes remain unchanged.

## Interaction contract
Grid traversal follows its visible left-to-right three-column geometry: Left/Right moves one tile with wrapping; Up/Down moves between corresponding columns in the two rows. Tab/Enter/Space remain native button interactions. Keyboard entry starts on a tile only when requested; opening the menu does not choose or execute a power action. Power selection closes QuickMenu while the existing overlay owns confirmation. Cancel, Escape or outside click clears pending state. Opening confirmation focuses Cancel so unmodified Enter cancels. Lock continues through the shell's existing secure lock request, without passing through power commands.

## Acceptance and safe verification
1. Capture and inspect QuickMenu, standard confirmation and lock-customized confirmation colors using isolated native QML surfaces.
2. Real keyboard/pointer selection of all four power actions sets the corresponding pending action and closes QuickMenu; cancellation clears it. No real power command is executed.
3. Verify grid traversal and Settings routing without invoking lock or toggles on the live desktop.
4. Verify confirmation initial Cancel focus, Enter/Escape/outside cancellation, navigation to the action button and its confirmed signal in a standalone confirmation-only scenario not connected to an executor. Verify the real QuickMenu executor separately with isolated harmless command fixtures.
5. Run `bash scripts/m3-qmllint-gate.sh`, existing Node commands, `python3 -m pytest -q scripts/tests/test_safe_logout.py` and `bash scripts/controls-behavior.sh`. Smoke-render the extracted launcher frame too.
6. Update README/handoff after proof; live display-only checks require the user's cold restart. No commits, pushes or system modifications.
