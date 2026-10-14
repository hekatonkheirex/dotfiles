# Elena alarms window (R5 of the SwayFX + eww replication)

Date: 2026-10-14. Status: approved 2026-10-14; implemented.

## Outcome
The bottom bar's alarm button opens her alarms window. A user can set a quick
("ring in") or standard ("ring at") alarm, browse and delete pending alarms, and
the alarm rings (sound plus a persistent notification) at the right time. The
bar pill shows the real pending count. Measured by: node gates for the
scheduling model pass; a render check shows every window state; a fake-clock
integration check proves ring and cancel; live: set a 1 minute alarm, see the
count go 0 to 1, hear and see it ring, count returns to 0.

## Reference
`config/eww/windows/alarms.{yuck,scss}`, `scripts/{alarm.sh,alarm-set-minutes.sh,
do-alarms-action,input-sink-alarms.sh}`, `scripts/daemons/alarms.sh` in
github.com/elenapan/dotfiles (master). Scale `Config.elenaScale`, sizes through
`Config.dp()`, accents through `Colors.elenaAccent(n)`. Org-file Agenda feed
stays excluded.

## Her behavior (what we replicate)
- Window: right and bottom anchored overlay above the bar, width dp(300), left
  corners dp(20), middle click closes. Left column: top "quick" button, an
  expandable cancel/confirm row, bottom "standard" button. Right: side buttons
  and an info block (top label, HH:MM preview, bottom label).
- States: `select-type` (browse: prev, delete, next; label "next up" or "no
  alarms"; time and label of the alarm at `index`), `select-time-quick` (label
  "ring in", +1 +5 +10 +60 minutes, preview `HHh MM`), `select-time-standard`
  (label "ring at", -h +h -m +m).
- Wheel over hours or minutes: up steps back, as her script does.
- Entry: digit keys fill the selected field (hours max 23, minutes max 59, label
  max 16 chars); Tab/Shift+Tab cycle hours, minutes, label; Backspace,
  Ctrl+Backspace, Return confirms, Esc cancels. Wheel over hours or minutes steps
  by 60 or 1 minute. Minutes wrap at 1440. Quick with 0 minutes does nothing.
- Quick = now + N minutes. Standard = next occurrence of HH:MM (tomorrow if
  already past). Label default "beep beep" (her default; kept).
- Confirm shows a 2 s notice "Will ring at HH:MM". Ring plays a sound once and
  posts a notification that does not time out, titled "Alarm", body the label.
- Delete removes the alarm at `index` and cancels its scheduling. Alarms sort
  chronologically; the list returns to index 0 after any change.

## Decisions I am making (change any of them)
1. **Persistence: file, not `/tmp`.** Alarms live in
   `~/.local/state/quickshell/alarms.json` as `[{id, at (epoch s), label}]`.
   Her daemon keeps them in `/tmp` as sleeping processes, so a reboot or
   restart loses them. Ours survive a shell restart. An alarm whose time passed
   while the shell was not running rings on start once, with "missed" in the
   notification body.
2. **Scheduling: one QML timer, not sleeping processes.** A single `Timer`
   re-armed to the earliest alarm, capped at 30 s intervals and compared against
   `Date.now()` each tick, so a suspend/resume rings the alarm within 30 s of
   wake (her `safe-sleep` solves the same problem). Pure logic in
   `config/Alarms.js`; `config/AlarmService.qml` owns the file, timer, sound and
   notification.
3. **Sound: freedesktop `alarm-clock-elapsed.oga` through `pw-play`** (installed;
   no mpv or her `alarm.mp3` dependency). Played once, as hers. Path is a
   `Settings`-free constant; `commandFor` seam like `NetworkListService` for
   tests.
4. **Notification: `notify-send -u critical -t 0 -a quickshell-alarm`.** Goes
   through our existing NotificationServer, so toast, history and DND rules
   apply, and critical bypasses DND/quiet hours (decision to confirm: an alarm
   that DND can silence is useless).
5. **Input: native QML.** Her `_eww_input` sway mode and key sink scripts are
   replaced by the window holding keyboard focus (`OnDemand`), keys handled in
   QML; buttons remain clickable.

## Files
| File | Role |
|---|---|
| `config/Alarms.js` (pure) | `nextOccurrence(now, hh, mm)`, `inMinutes(now, n)`, `addMinutes(total, delta)` (wrap 1440), `applyKey(state, key)` (field entry rules), `sortAlarms`, `due(alarms, now)`, `parse/serialize` (tolerates corrupt file), `previewParts` |
| `config/AlarmService.qml` | singleton: `alarms`, `count`, `add(at, label)`, `remove(id)`, file load/save, timer, `ring()` via `commandFor` seam |
| `bar/AlarmsWindow.qml` | window, dismiss paths as NetworksWindow (Esc, middle click, shield, bar button, FocusDismiss) |
| `bar/alarms/{AlarmsContent,AlarmButton,TimeStepButtons}.qml` | window-less, render-checkable pieces |
| `shell.qml` | instance, `onAlarmsRequested` toggles route `"alarms"`, IPC `alarmState` (JSON) and `alarmAdd`/`alarmRemove` for tests |
| `bar/BottomBar.qml` | `alarmCount: AlarmService.count`, forward `alarmsClicked` |
| `README.md`, this spec, plan | docs |

## Verification
- Node (`tests/alarms/alarms.test.mjs`): nextOccurrence across midnight, past
  time rolls to tomorrow, DST day safe via epoch math, wrap at 1440 both ways,
  field limits (24 to 23, 60 to 59, 17th label char dropped), key map,
  `due` ordering and boundary (equal timestamp rings), corrupt/empty/non-array
  file parse to `[]`, duplicate timestamps keep both.
- Service integration (scratch HOME, fake clock seam and fake `pw-play` /
  `notify-send` that log argv): add, count 1, tick past due, one sound and one
  notification, file updated, count 0; cancel before due never rings; restart
  with a past alarm rings once as missed; restart with a future alarm keeps it.
  Mutation-proven.
- Render check: the three states, disabled buttons, expanded confirm row,
  empty and populated browse, active field color, placeholder "e.g. gym".
- Existing gates: m3-qmllint, config-dump, bottom-bar and networks renders,
  style-refs, popup-ipc-check, all Node suites.
- Live (after the user's cold restart): 1 minute alarm rings with sound and
  notification, count updates, delete works, window dismisses by every path,
  journal clean.

## Risks
- Audible check needs the user's ears; sound proof is argv plus `pw-play`
  exit status, not hearing it.
- The 30 s tick means ring latency up to 30 s only after a suspend; normal
  operation re-arms to the exact deadline.
- Critical notifications interplay with lock screen: rings still play while
  locked (intended).

## Out of scope
Recurring alarms, snooze, custom sounds, multi monitor, Org Agenda feed, the
Agenda page's own tasks.
