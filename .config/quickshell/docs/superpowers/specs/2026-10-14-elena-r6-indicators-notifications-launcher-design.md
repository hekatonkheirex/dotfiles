# Elena R6: mic indicator, notification toasts, launcher (SwayFX + eww replication)

Date: 2026-10-14. Status: approved and implemented. Corrections found while building: the toast frame is x0 (her urgency sections override the global x8 frame color) and Quickshell reports `expireTimeout` in milliseconds. The mic setting sits next to the sidebar edge toggle in Appearance, not Display & Input (that tab holds only remote CLI rows).

## Outcome
Three of her surfaces appear in our shell with her look and behavior, on our
palette: the microphone tab at the top center, her dunst notification card, and
her rofi launcher layout for Mod+D. Measured by: pure-model node gates, one
render check per surface (pixels for her colors, borders, glyphs, row counts),
interaction checks (clicks, keys), existing gates unchanged, then live checks on
the hot-reloaded shell (mic toggle, a real notification of each urgency, the
launcher opened and dismissed).

## Reference (github.com/elenapan/dotfiles, master)
- `config/eww/windows/microphone-indicator.{yuck,scss}`, `scripts/daemons/microphone.sh`
- `config/dunst/dunstrc` (her notifications are dunst, not eww)
- `config/rofi/config.rasi`, `colors.rasi` (her launcher is rofi, combi of window and run)
Mode and split indicators stay dropped (sway-only). Sizes through `Config.dp()`
(`elenaScale` 1.5), accents through `Colors.elenaAccent(n)`. Kyok falls back to
our font as in earlier phases.

## R6a Microphone indicator
- A tab at the top center, `dp(18)` by `dp(10)`, square top and `round_max`
  bottom corners (her `0 0 max max`). Live mic: fill x1 at full opacity.
  Muted: fill x8 at opacity 0.4. Fade 200 ms (reduced motion: instant).
- Click: toggle default-source mute (`pactl set-source-mute @DEFAULT_SOURCE@
  toggle`). Middle click: hide until the mute state next changes.
- State from `pactl subscribe` filtered to `source #` (her daemon), always on,
  not gated by popups. A change of default source posts a low-urgency
  "Recording device" notification with the device description.
- Layer Overlay, anchored top center, no exclusive zone, input only on the tab.
  Namespace `quickshell-popup-mic` (existing no-blur rule). Sits over the 8 px
  tag strip as hers sits under the sway bar gap (y offset `-dp(4.5)` clipped at
  the screen top).
- New `Settings.micIndicator` (default true) and a Settings toggle under
  Display & Input. When false the window and the subscriber never start.
- Files: `config/MicService.qml` (singleton, `muted`, `ready`, `deviceName`,
  command seam), `bar/MicIndicator.qml`, pure `config/MicState.js`
  (`parseMute(text)`, `parseSourceEvent(line)`, `parseDescription`).

## R6b Notification toast
Restyle `NotificationToast.qml` and the stacking behavior to her dunstrc;
delivery, history, DND, quiet hours and actions are untouched.
- Position: top right, `dp(20)` offsets, clear of the top strip.
  `Settings.notificationToastPosition` keeps working (bottom-right sits above
  the bottom bar). Width up to `dp(700)` content-driven, min `dp(280)`.
- Card: background `xbg` (surface), frame `dp(8)` in x8 (`#3A435A` analog, our
  `elenaAccent(8)`), radius `dp(18)`, padding `dp(22)`.
- Content: summary row with the glyph U+E944 (accent) then summary text, body row
  with U+E90D (x8) then body, tracked as hers: `"<glyph>  summary\n<glyph>  body"`.
- Urgency colors: text/glyph low x6, normal x2, critical x1. Timeouts when the
  app gives none: low 3 s, normal 8 s, critical never (sticky). An app timeout
  wins. (Our current setting `notificationToastDurationMs` remains and becomes
  the normal-urgency default, 8000 by default, migrated only if still 5000.)
- Mouse: left click closes the card; middle click runs the default action then
  closes; right click closes every card. Existing action buttons stay.
- Limit and duplicates: at most 5 stacked cards (oldest beyond that go to
  history only); an identical summary and body within the stack increments a
  count badge `(N)` instead of a new card (`stack_duplicates`).
- History popup keeps the dashed card style from the earlier redesign.
- Pure `config/ToastModel.js`: `urgencySlot`, `timeoutMs`, `stack(list, n, limit)`.

## R6c Launcher (Mod+D)
Presentation and layout only; providers, ranking, `>`, `;`, `@` and keyboard
structure remain.
- Centered on screen, width 50 percent (min `dp(560)`), no top-bar anchoring.
- Frame: solid `dp(6)` border x0 (`surfaceContainer`), radius `dp(12)`,
  background `xbg`. Replaces the dashed frame here only.
- Input bar: padding `dp(25) dp(25) dp(15) dp(25)`; prompt glyph U+ECA7 in x1,
  then a colon cell, then the entry in fg. No mic or extra controls.
- List: 8 visible lines, rows `dp(10)` by `dp(25)` padding, spacing `dp(2)`;
  selected row background x0 with text x4; urgent/active tints x1/x5 map to our
  provider tags. Scroll without a scrollbar. Mouse: click accepts, hover moves
  selection (her `me-accept-entry: MousePrimary`).
- Keys added to the existing set: Ctrl+N/P and Alt+J/K move, Alt+H/L (and
  Ctrl+PageUp/Down) row left/right is unused (one column), Tab/Shift+Tab step.
  Esc and click outside dismiss as today.
- Pure `config/LauncherLayout.js`: `visibleLines(heightPx, rowPx)`,
  `windowWidth(screenW)`, `clampSelection`.

## Decisions I am making (change any)
1. Mic tab is always shown when `Settings.micIndicator` is on (her intent: a
   permanent "mic is live" warning), muted state shown dim instead of hidden.
2. Her notification limit 5 and duplicate stacking are applied; her 18pt Kyok
   size is mapped by scale, not copied literally.
3. Launcher keeps our provider list instead of her combi of window and run;
   only the rofi look, geometry and extra keys are replicated.
4. Toast default timeouts follow her 3 s / 8 s / sticky, replacing our flat 5 s
   unless the user has customized `notificationToastDurationMs`.

## Verification
- Node: `tests/r6/mic-state.test.mjs`, `toast-model.test.mjs`,
  `launcher-layout.test.mjs` (edges: empty/garbled pactl lines, urgency map,
  app timeout precedence, stack limit 5 and duplicate counting, widths at
  1366/1920/2560).
- Render checks (scratch HOME, fake `pactl`, private D-Bus for notifications):
  `scripts/r6-render.sh` with per-surface pixel checks and click/key checks;
  mutation-proven like R5.
- Existing gates: m3-qmllint, config-dump, style-refs, notification D-Bus
  suite, launcher tests, bottom-bar/networks/sidebar/alarms renders.
- Live on the hot-reloaded shell: toggle the mic by click and by `pactl`, send
  one low, one normal and one critical notification, open and dismiss Mod+D.

## Risks
- The always-on `pactl subscribe` is a new long-lived process (like
  AudioService's, shared parse); one reader only, no duplicates.
- Launcher resizing touches a 1085-line file; changes limited to the frame,
  input bar and row styling, protected by the existing launcher tests.
- Notification stacking changes the number of toast windows; history must still
  receive every notification (tested through private D-Bus).

## Out of scope
Mode and split indicators, her Org agenda, per-monitor placement, a window
switcher mode in the launcher, changing notification persistence or DND.
