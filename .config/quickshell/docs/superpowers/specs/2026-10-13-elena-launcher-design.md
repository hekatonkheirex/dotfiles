# Elena launcher presentation redesign

## Objective and reference
Apply the next agreed Elenapan presentation layer to the existing launcher: rounded dark card, dashed outline and tracked monospace uppercase status labels. The local Aphelion showcase at 35 seconds demonstrates that framing/typography grammar, not a launcher layout; preserve the current screen-bounded 460px single-column interaction rather than inventing a reference launcher.

## Ownership and changes
- bar/LauncherPopup.qml owns the surface, search, provider chips, result list and context menu. Keep non-voice provider/model/process functions unchanged.
- Add a compact provider heading and result count, a dashed rounded frame and contextual keyboard hints. Use semantic Colors and Config sizing/motion tokens; monospace metadata resolves through the installed generic monospace family (currently JetBrains Mono).
- Keep application names/descriptions in normal case and the existing body font. Use existing ListItem input/accessibility and native TextFieldControl/ActionButton/IconButton controls. Selected rows gain a small accent marker and use the existing shape scale.
- Remove the obsolete dmenu-only search reparenting slot; the same search control becomes a direct layout child. Its id, signals and focus behavior remain.
- Frame repaints only on geometry/color/visibility changes; no decorative animation or new background polling.
- User amendment: remove speech recognition entirely from Quickshell. Delete recording/transcription state and processes, microphone UI, voice-only runtime paths, the helper script and active dependency/documentation references. Installed system packages and models outside the repo are not removed.

## Preserved behavior and boundaries
App discovery/fuzzy ranking, argv handling, terminal launch, > actions, ; clipboard preview/delete/confirmed wipe, @ wallpaper handoff, Ctrl+F, arrow selection, Enter, Escape, right-click/Shift+F10/Menu, selection descriptions, screen sizing/placement and reduced motion remain. No new providers, IPC, persisted preferences, dependencies, bindings, system-theme changes or authentication changes. Power menu and notifications remain separate.

## Acceptance and verification
1. Apps/actions/clipboard render distinct contextual headings, counts and keyboard hints. Speech recognition has no remaining executable path or launcher control.
2. Normal and empty-query results, long names and short viewport content stay bounded without obscuring search or hints.
3. Real QML keyboard navigation and context menu still work; application activation is exercised only with an isolated harmless desktop-entry fixture. No power, lock, clipboard wipe or microphone capture on the live desktop.
4. Capture and visually inspect the actual launcher content under the Elenapan palette; no new QML errors. Confirm the outline contains dashes and gaps through the captured frame, not source text.
5. Run `bash scripts/m3-qmllint-gate.sh`, existing Node regressions, `python3 -m pytest scripts/tests/test_claude_usage.py scripts/tests/test_codex_usage.py`, existing desktop-parser checks and `bash scripts/controls-behavior.sh`. Use throwaway native Quickshell scenarios for launcher-specific UI checks.
6. Update README and handoff after runtime proof. Live validation follows the user's cold restart; do not restart the desktop implicitly.

Qt drawing authority: https://doc.qt.io/qt-6/qml-qtquick-context2d.html#setLineDash-method and https://doc.qt.io/qt-6/qml-qtquick-context2d.html#roundedRect-method (Qt 6.12).
