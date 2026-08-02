# Notch, Settings App, and Lock Screen Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the horizontal top bar with a hover-expanding "notch" (clock idle,
media player + mini calendar on hover, click opens Control Center), add a 10-tab
Settings window that actually controls it, and restyle the lock screen — all matching
the reference video (DankMaterialShell), while leaving vertical-mode `Bar.qml` and the
existing Ghost theme system completely untouched.

**Architecture:** New `Notch.qml` (horizontal mode) sits alongside the existing
`Bar.qml` (vertical mode); `shell.qml` picks one based on the existing layout
preference. Popup-anchor state (`openPopup`/`popupAnchorX/Y`) moves from `Bar.qml` up
to `shell.qml` so both components can share it. MPRIS state moves from
`CommandCenter.qml` up to `shell.qml` for the same reason. A new `Settings.qml`
(`FileView` + `JsonAdapter`, Quickshell's native structured-persistence pattern) holds
every user-tunable value, written to `~/.config/quickshell/settings.json`. All new
visual components (`Notch.qml`, `Settings/*`, restyled `LockScreen.qml`) use a fixed
hardcoded Rosé Pine palette (`config/NotchPalette.qml`) instead of `colors_`.

**Tech Stack:** QML/Qt6.11 (Quickshell), existing `SwitchControl.qml`/`SliderControl.qml`
reused for Settings controls, `mpris_monitor.py`/`mpris_control.py` (existing, unchanged)
for media, PAM/fprintd (existing, unchanged) for lock screen auth.

## Global Constraints

- Every new/edited `.qml` file must pass `qmllint <file>` (run from
  `/home/mura/.config/quickshell`) with no errors before being considered done.
- After each edit, hot-reload is verified via the running Quickshell instance's log at
  `/run/user/1000/quickshell/by-id/<id>/log.log` — look for a fresh `Configuration
  Loaded` line with no `WARN`/error lines after it. If no new line appears within ~2s,
  `touch` the edited file once (the watcher has been observed to miss a write) before
  concluding something is broken.
- No vertical-mode regressions: `Bar.qml` itself is not edited except for the
  `openPopup` state lift (Task 2) — verify vertical mode still works after that task
  specifically, via `echo vertical > ~/.config/quickshell/layout` + IPC `layout` call
  or toggling via `QuickMenu`.
- Never use `colors_`/Ghost tokens in new files (`Notch.qml`, anything under
  `Settings/`, `config/NotchPalette.qml`) — use `NotchPalette` instead. Existing files
  keep using `colors_` exactly as they do today.
- Reuse `bar/SwitchControl.qml` and `bar/SliderControl.qml` for every toggle/slider in
  the Settings window — do not reimplement them.
- `mpris_monitor.py` / `mpris_control.py` / PAM / fprintd logic is not modified, only
  relocated (state ownership) or called from a new location.

---

## Task 1: Extract shared calendar day-grid logic

**Files:**
- Create: `bar/CalendarLogic.js`
- Modify: `bar/CalendarPopup.qml`

**Interfaces:**
- Produces: `CalendarLogic.daysInMonth(date)`, `CalendarLogic.monthStartDay(date)`,
  `CalendarLogic.isToday(dayNum, displayMonth, currentDate)`,
  `CalendarLogic.buildDayModel(date)`, `CalendarLogic.weekDays` (array),
  `CalendarLogic.monthNames` (array) — consumed by Task 8 (`CalendarMini.qml`).

`CalendarPopup.qml` currently duplicates this logic inline (lines 40–65 as read
earlier). Extracting it now means Task 8 doesn't reimplement it, and this is the only
touch `CalendarPopup.qml` gets in this whole plan — it keeps serving vertical-mode
`Bar.qml` exactly as before, just backed by shared code.

- [ ] **Step 1: Create the JS module**

```javascript
// bar/CalendarLogic.js
.pragma library

var weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
var monthNames = ["January", "February", "March", "April", "May", "June", "July",
  "August", "September", "October", "November", "December"]

function daysInMonth(d) {
  return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
}

function monthStartDay(d) {
  return new Date(d.getFullYear(), d.getMonth(), 1).getDay()
}

function isToday(dayNum, displayMonth, currentDate) {
  return dayNum === currentDate.getDate()
    && displayMonth.getMonth() === currentDate.getMonth()
    && displayMonth.getFullYear() === currentDate.getFullYear()
}

function buildDayModel(date) {
  if (!date || isNaN(date.getTime())) return []
  var list = []
  var startDay = monthStartDay(date)
  var days = daysInMonth(date)
  for (var i = 0; i < startDay; i++) list.push(-1)
  for (var d = 1; d <= days; d++) list.push(d)
  return list
}
```

- [ ] **Step 2: Point `CalendarPopup.qml` at the shared module**

In `bar/CalendarPopup.qml`, add the import at the top (after the existing imports,
before the `PanelWindow` block):

```qml
import "CalendarLogic.js" as CalendarLogic
```

Replace the inline `weekDays`/`monthNames` properties and `daysInMonth`/
`monthStartDay`/`isToday`/`buildDayModel` functions (originally at lines 36–65 of the
file, per the earlier read) with:

```qml
  readonly property var weekDays: CalendarLogic.weekDays
  readonly property var monthNames: CalendarLogic.monthNames

  function daysInMonth(d) { return CalendarLogic.daysInMonth(d) }
  function monthStartDay(d) { return CalendarLogic.monthStartDay(d) }
  function isToday(dayNum) {
    return CalendarLogic.isToday(dayNum, root.displayMonth, root.currentDate)
  }
  function buildDayModel(date) { return CalendarLogic.buildDayModel(date) }
```

Keep every other line of `CalendarPopup.qml` (the `currentDate`/`displayMonth`
properties, `cellWidth`, the rest of the file) exactly as-is — this is a pure
extraction, no behavior change.

- [ ] **Step 3: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint bar/CalendarLogic.js bar/CalendarPopup.qml
touch bar/CalendarPopup.qml
```

Expected: no lint errors; `log.log` shows a fresh `Configuration Loaded` with no
warnings after the touch.

- [ ] **Step 4: Manual verification**

With the layout preference set to `vertical` (`echo vertical >
~/.config/quickshell/layout`, then reload), click the clock in `Bar.qml` to open the
calendar popup — confirm today's date is still highlighted and the month grid renders
identically to before. Set the preference back to `horizontal` afterward
(`echo horizontal > ~/.config/quickshell/layout`).

- [ ] **Step 5: Commit**

```bash
yadm add bar/CalendarLogic.js bar/CalendarPopup.qml
yadm commit -m "Extract calendar day-grid logic into shared CalendarLogic.js"
```

---

## Task 2: Lift popup-anchor state from Bar.qml to shell.qml

**Files:**
- Modify: `bar/Bar.qml`
- Modify: `shell.qml`

**Interfaces:**
- Produces: `shell.openPopup` (string), `shell.popupAnchorX`/`shell.popupAnchorY`
  (int), `shell.togglePopup(name, widget)` (function) — consumed by Task 9 (`Notch`
  click → `commandcenter`), Task 11 (power-menu button), and every existing popup
  instantiation in `shell.qml`.
- Consumes: nothing new.

Today `Bar.qml` owns `openPopup`/`popupAnchorX`/`popupAnchorY` and every popup in
`shell.qml` reads `bar.openPopup` etc. Once `Notch.qml` exists (Task 6+) there will be
two different top-level components that both need to drive the same popups, so this
state has to live one level up, in `shell.qml`, with both `Bar.qml` and `Notch.qml`
writing to it.

- [ ] **Step 1: Add the state and helper to `shell.qml`**

Add near the top of `shell.qml`, after the `isHorizontal` property block (after line
102 in the current file, before the `popupMarginLeft` function):

```qml
  property string openPopup: ""
  property int popupAnchorX: 0
  property int popupAnchorY: 0

  function togglePopup(name, widget) {
    var x = widget ? widget.mapToItem(null, 0, 0).x : 0
    var y = widget ? widget.mapToItem(null, 0, 0).y : 0
    var w = widget ? widget.width : 0
    if (shell.openPopup === name) {
      shell.openPopup = ""
    } else {
      if (shell.isHorizontal) {
        shell.popupAnchorX = x + w / 2
        shell.popupAnchorY = (bar.horizontal ? bar.height : 0) - 16
      } else {
        shell.popupAnchorY = y
      }
      shell.openPopup = name
    }
  }
```

This is a straight copy of `Bar.qml`'s current `togglePopup` (lines 61–76), with
`root.` replaced by `shell.` and the popup-anchor-Y-at-bottom-of-bar calculation
referencing `bar.height` directly (still valid — `bar` keeps existing in vertical
mode; in horizontal mode after Task 10 this branch won't be hit by `Notch.qml`, which
computes its own anchor separately in Task 9).

- [ ] **Step 2: Update every popup instantiation in `shell.qml` to use `shell.*`**

Replace every occurrence of `bar.openPopup`, `bar.popupAnchorX`, `bar.popupAnchorY` in
`shell.qml` with `shell.openPopup`, `shell.popupAnchorX`, `shell.popupAnchorY`. This
touches: `PopupShield.visible`, `AudioPopup`, `WifiPopup`, `BtPopup`,
`BrightnessPopup`, `BatteryPopup`, `CalendarPopup`, `NotificationPopup`, `QuickMenu`,
`CommandCenter`'s `visible` binding, `LauncherPopup` — each currently has a line like
`visible: bar.openPopup === "audio" && !lockScreen.locked` and
`onDismissed: bar.openPopup = ""`. Change to `shell.openPopup === "audio"` and
`shell.openPopup = ""` respectively. Also update `popupMarginLeft`/`popupMarginTop`
(lines 107–117) to read `shell.popupAnchorX`/`shell.popupAnchorY` instead of
`bar.popupAnchorX`/`bar.popupAnchorY` (keep the `bar.horizontal ? ... : ...` branching
as-is — `bar.horizontal` still exists and still matters for margin calc in vertical
mode).

Update the `IpcHandler` functions (`launcher`, `quickmenu`, `commandcenter`) to call
`shell.togglePopup(...)` / set `shell.openPopup` directly instead of `bar.openPopup =
...`:

```qml
    function launcher() {
      if (bar.horizontal) {
        shell.popupAnchorX = bar.getLauncherX()
      } else {
        shell.popupAnchorY = 0
      }
      shell.openPopup = shell.openPopup === "launcher" ? "" : "launcher"
    }

    function lock() {
      lockScreen.lockScreen()
    }

    function quickmenu() {
      if (bar.horizontal) {
        shell.popupAnchorX = bar.getMenuIndicatorX()
      } else {
        shell.popupAnchorY = bar.getMenuIndicatorY()
      }
      shell.openPopup = shell.openPopup === "quickmenu" ? "" : "quickmenu"
    }

    function commandcenter() {
      shell.openPopup = shell.openPopup === "commandcenter" ? "" : "commandcenter"
    }
```

Note: `bar.getLauncherX()`/`bar.getMenuIndicatorX()`/`bar.horizontal` calls here still
work in vertical mode (calling into the still-alive `Bar` instance); Task 10 updates
these three functions again once `Notch` exists, so they work in horizontal mode too.

- [ ] **Step 3: Update `Bar.qml` to delegate to `shell`**

In `bar/Bar.qml`, remove the local `property string openPopup: ""`, `property int
popupAnchorX/popupAnchorY: 0`, and the `togglePopup` function body (lines 43–76 of the
current file) and replace with properties that read from the parent shell:

```qml
  property string openPopup: shell.openPopup
  property int popupAnchorX: shell.popupAnchorX
  property int popupAnchorY: shell.popupAnchorY

  function togglePopup(name, widget) {
    shell.togglePopup(name, widget)
  }
```

This requires `Bar.qml` to be able to see `shell` — since `Bar` is instantiated as a
direct child of the `ShellRoot` in `shell.qml`, `shell` is reachable as the enclosing
context property already (QML resolves ids from enclosing scopes automatically for
components instantiated inline in the same file tree); no explicit property-passing
needed. Every other reference to `root.openPopup`/`root.togglePopup(...)` inside
`Bar.qml` (the `barMouseArea`, `onOpenPopupChanged`, the individual indicator
`onClicked` handlers) stays unchanged — they now transparently read/write through to
`shell`.

- [ ] **Step 4: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint shell.qml bar/Bar.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 5: Manual verification (vertical mode)**

`echo vertical > ~/.config/quickshell/layout`, reload, then click through every
indicator in the left-docked bar (wifi, bluetooth, audio, brightness, battery, clock →
calendar, notification, menu) and confirm each popup still opens/closes/positions
correctly. Set back to `horizontal` afterward.

- [ ] **Step 6: Commit**

```bash
yadm add bar/Bar.qml shell.qml
yadm commit -m "Lift popup-anchor state from Bar.qml to shell.qml"
```

---

## Task 3: Lift MPRIS state from CommandCenter.qml to shell.qml

**Files:**
- Modify: `bar/CommandCenter.qml`
- Modify: `bar/commandcenter/MediaTab.qml`
- Modify: `shell.qml`

**Interfaces:**
- Produces: `shell.mprisStatus`/`mprisTitle`/`mprisArtist`/`mprisAlbum`/`mprisArtUrl`/
  `mprisLengthSec`/`mprisLengthStr`/`elapsedSeconds` (properties), `shell.formatTime(sec)`
  (function) — consumed by Task 7 (`MediaPlayerWidget.qml`) and `CommandCenter.qml`
  (updated in this task to read from `shell` instead of owning the state).
- Consumes: nothing new.

The MPRIS `Process` currently only runs while `root.visible` (i.e. only while Control
Center is open — see `bar/CommandCenter.qml:396`). Once the notch's hover media player
(Task 7) needs this data with Control Center closed, the process has to run
persistently. This is an intentional behavior change: MPRIS polling goes from
"only while Control Center is open" to "always on" — acceptable, `mpris_monitor.py` is
event-driven (dbus-subscribed), not a busy-poll.

- [ ] **Step 1: Add MPRIS state and process to `shell.qml`**

Add after the `Config { id: cfg }` block in `shell.qml`:

```qml
  // MPRIS media state — shared by Notch.qml's hover media player and
  // CommandCenter's Media tab. Runs persistently (not gated on any popup's
  // visibility) since the notch needs fresh data even when Control Center
  // is closed.
  property string mprisStatus: "NoPlayer"
  property string mprisTitle: ""
  property string mprisArtist: ""
  property string mprisAlbum: ""
  property string mprisArtUrl: ""
  property int mprisLengthSec: 0
  property string mprisLengthStr: "0:00"
  property int elapsedSeconds: 0

  onMprisTitleChanged: shell.elapsedSeconds = 0

  function formatTime(sec) {
    var m = Math.floor(sec / 60)
    var s = sec % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }

  Timer {
    id: playbackTimer
    interval: 1000
    running: shell.mprisStatus === "Playing"
    repeat: true
    onTriggered: {
      if (shell.elapsedSeconds < shell.mprisLengthSec) {
        shell.elapsedSeconds += 1
      }
    }
  }

  Process {
    id: mprisProcess
    command: ["python3", "-u", Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_monitor.py"]
    running: true
    stdout: SplitParser {
      onRead: function(data) {
        try {
          var info = JSON.parse(data.trim());
          shell.mprisStatus = info.status;
          shell.mprisTitle = info.title;
          shell.mprisArtist = info.artist;
          shell.mprisAlbum = info.album;
          shell.mprisArtUrl = info.artUrl;
          shell.mprisLengthSec = info.length_sec;
          shell.mprisLengthStr = info.length_str;
        } catch (e) {
          // Parse error, ignore this line
        }
      }
    }
    onRunningChanged: {
      if (!running) mprisProcessRetry.start()
    }
  }

  Timer {
    id: mprisProcessRetry
    interval: 3000
    onTriggered: mprisProcess.running = true
  }
```

`shell.qml` already has `import Quickshell.Io` (line 7) so `Process`/`SplitParser`/
`Timer` are already available — no new imports needed.

- [ ] **Step 2: Remove the now-duplicated state from `CommandCenter.qml`**

In `bar/CommandCenter.qml`, delete: the `mprisStatus`/`mprisTitle`/`mprisArtist`/
`mprisAlbum`/`mprisArtUrl`/`mprisLengthSec`/`mprisLengthStr` properties (lines 68–74),
`elapsedSeconds`/`cavaBarValues` — **keep `cavaBarValues`**, that stays local to
`CommandCenter.qml` (the visualizer is Control-Center-only, not needed by the compact
notch widget) — the `onMprisTitleChanged` handler (lines 81–83), `playbackTimer` (lines
86–96), `formatTime` (lines 98–102), and the `mprisProcess`/`mprisProcessRetry` blocks
(lines 393–427).

Add local alias properties in their place so every existing reference inside
`CommandCenter.qml` and its tab files (which use `root.mprisTitle`, `root.formatTime`,
etc.) keeps working unchanged:

```qml
  readonly property string mprisStatus: shell.mprisStatus
  readonly property string mprisTitle: shell.mprisTitle
  readonly property string mprisArtist: shell.mprisArtist
  readonly property string mprisAlbum: shell.mprisAlbum
  readonly property string mprisArtUrl: shell.mprisArtUrl
  readonly property int mprisLengthSec: shell.mprisLengthSec
  readonly property string mprisLengthStr: shell.mprisLengthStr
  readonly property int elapsedSeconds: shell.elapsedSeconds
  property var cavaBarValues: []

  function formatTime(sec) { return shell.formatTime(sec) }
```

`CommandCenter.qml` is instantiated inline inside `shell.qml` (line 397), so `shell` is
reachable the same way `Bar.qml` reaches it in Task 2.

- [ ] **Step 3: `MediaTab.qml` needs no changes**

`bar/commandcenter/MediaTab.qml` only ever reads `root.mprisTitle` etc. (`root` being
the `CommandCenter` instance passed in as a property, per its own `property QtObject
root: null` declaration) — since Step 2 kept those as read-through aliases with the
same names, this file is untouched.

- [ ] **Step 4: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint shell.qml bar/CommandCenter.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 5: Manual verification**

Play something with an MPRIS-compatible player (or use whatever fake-player tooling
exists per prior MPRIS soak-testing in this project). Open Control Center → Media tab,
confirm title/artist/art/progress bar/transport controls still work exactly as before.
Close Control Center, confirm (via a temporary `Text { text: shell.mprisTitle }` probe,
removed after checking, or just proceeding to Task 7 which will make this visible for
real) that `shell.mprisTitle` keeps updating while Control Center is closed.

- [ ] **Step 6: Commit**

```bash
yadm add bar/CommandCenter.qml shell.qml
yadm commit -m "Lift MPRIS state from CommandCenter to shell.qml"
```

---

## Task 4: Fixed video palette

**Files:**
- Create: `config/NotchPalette.qml`

**Interfaces:**
- Produces: `NotchPalette.base`, `.surface`, `.overlay`, `.text`, `.muted`, `.love`,
  `.gold`, `.pine`, `.foam` (all `color`) — consumed by every task from here on that
  builds a new visual component (`Notch.qml`, `Settings/*`, restyled `LockScreen.qml`).

- [ ] **Step 1: Create the file**

```qml
// config/NotchPalette.qml
// Fixed Rosé Pine-derived palette for the notch, Settings window, and lock
// screen ONLY — matches the theme selected in the reference video's own
// screenshots. Deliberately independent of colors_/the Ghost theme system:
// this is a scoped exception (see docs/superpowers/specs/2026-08-02-notch-
// redesign-design.md), not a precedent for replacing Ghost elsewhere.
import QtQml

QtObject {
  readonly property color base: "#191724"
  readonly property color surface: "#1f1d2e"
  readonly property color overlay: "#26233a"
  readonly property color text: "#e0def4"
  readonly property color muted: "#6e6a86"
  readonly property color love: "#eb6f92"
  readonly property color gold: "#f6c177"
  readonly property color pine: "#31748f"
  readonly property color foam: "#9ccfd8"
}
```

- [ ] **Step 2: Lint**

```bash
cd /home/mura/.config/quickshell
qmllint config/NotchPalette.qml
```

Expected: no errors. (Not wired into `shell.qml` yet — that happens naturally when
Task 6 instantiates it inside `Notch.qml`; a standalone `QtObject` file has nothing to
hot-reload-check on its own.)

- [ ] **Step 3: Commit**

```bash
yadm add config/NotchPalette.qml
yadm commit -m "Add fixed Rosé Pine palette for notch/settings/lockscreen"
```

---

## Task 5: Settings persistence (`config/Settings.qml` + `settings.json`)

**Files:**
- Create: `config/Settings.qml`

**Interfaces:**
- Produces: a `Settings` component whose default property is a `JsonAdapter` exposing
  every tunable value as a plain QML property (see full list below), plus a
  `save()` function — consumed by every Settings tab (Tasks 14–23) and by `Notch.qml`
  (Task 6) for sizing.

Uses Quickshell's native `FileView` + `JsonAdapter` (`Quickshell.Io`, confirmed present
in this Quickshell build at `/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes`) —
the correct native tool for structured persisted state, instead of extending the
existing shell-`echo`-to-file pattern (fine for the single-word `layout`/`colorscheme`
prefs, risky for a JSON blob due to shell-quoting).

- [ ] **Step 1: Create the file**

```qml
// config/Settings.qml
// Persisted, user-tunable settings for the notch/Settings-window/lockscreen
// project. Backed by ~/.config/quickshell/settings.json via Quickshell's
// native FileView+JsonAdapter. Config.qml stays separate and holds only
// build-time constants that are never user-editable.
import QtQml
import Quickshell.Io

FileView {
  id: root
  path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
  watchChanges: true

  onLoadFailed: (error) => {
    // First run: no settings.json yet. Write current (default) values so
    // the file exists from here on.
    if (error === FileViewError.FileNotFound) {
      root.writeAdapter()
    }
  }

  property alias notchFlare: adapter.notchFlare
  property alias barHeight: adapter.barHeight
  property alias collapsedWidth: adapter.collapsedWidth
  property alias expandedHeight: adapter.expandedHeight
  property alias gapFromScreenEdge: adapter.gapFromScreenEdge

  property alias mediaShowAlbumArt: adapter.mediaShowAlbumArt
  property alias mediaShowProgressBar: adapter.mediaShowProgressBar
  property alias mediaControlsAlwaysVisible: adapter.mediaControlsAlwaysVisible

  property alias clock24h: adapter.clock24h
  property alias clockShowSeconds: adapter.clockShowSeconds
  property alias calendarWeekStartsMonday: adapter.calendarWeekStartsMonday

  property alias fontFamily: adapter.fontFamily
  property alias fontPixelSize: adapter.fontPixelSize
  property alias spacingUnit: adapter.spacingUnit
  property alias cornerRadius: adapter.cornerRadius

  property alias reduceMotion: adapter.reduceMotion
  property alias motionMovementMs: adapter.motionMovementMs
  property alias motionFadeMs: adapter.motionFadeMs
  property alias motionHoverMs: adapter.motionHoverMs
  property alias motionBouncePercent: adapter.motionBouncePercent

  property alias notificationToastDurationMs: adapter.notificationToastDurationMs
  property alias doNotDisturb: adapter.doNotDisturb

  property alias ccShowWifi: adapter.ccShowWifi
  property alias ccShowBluetooth: adapter.ccShowBluetooth
  property alias ccShowAudio: adapter.ccShowAudio
  property alias ccShowDisplay: adapter.ccShowDisplay
  property alias ccShowNightLight: adapter.ccShowNightLight

  property alias lockShowMedia: adapter.lockShowMedia
  property alias lockClockSize: adapter.lockClockSize

  property alias weatherCity: adapter.weatherCity
  property alias systemShowUptime: adapter.systemShowUptime

  function save() { root.writeAdapter() }

  JsonAdapter {
    id: adapter

    property real notchFlare: 14
    property real barHeight: 34
    property real collapsedWidth: 150
    property real expandedHeight: 135
    property real gapFromScreenEdge: 11

    property bool mediaShowAlbumArt: true
    property bool mediaShowProgressBar: true
    property bool mediaControlsAlwaysVisible: false

    property bool clock24h: true
    property bool clockShowSeconds: false
    property bool calendarWeekStartsMonday: false

    property string fontFamily: "Roboto"
    property real fontPixelSize: 15
    property real spacingUnit: 4
    property real cornerRadius: 10

    property bool reduceMotion: false
    property real motionMovementMs: 400
    property real motionFadeMs: 200
    property real motionHoverMs: 150
    property real motionBouncePercent: 40

    property real notificationToastDurationMs: 5000
    property bool doNotDisturb: false

    property bool ccShowWifi: true
    property bool ccShowBluetooth: true
    property bool ccShowAudio: true
    property bool ccShowDisplay: true
    property bool ccShowNightLight: true

    property bool lockShowMedia: true
    property real lockClockSize: 72

    property string weatherCity: "Asunción"
    property bool systemShowUptime: true
  }
}
```

Defaults for the Bar & Island group come directly from the video's reference numbers
(confirmed earlier). `notificationToastDurationMs` default matches the current
hardcoded `Config.qml` value (`5000`) so behavior doesn't change until a user actually
touches the new setting.

- [ ] **Step 2: Instantiate it in `shell.qml`**

Add after `Config { id: cfg }`:

```qml
  Settings {
    id: settings
  }
```

- [ ] **Step 3: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint config/Settings.qml shell.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 4: Manual verification (first-run + persistence)**

```bash
rm -f ~/.config/quickshell/settings.json
touch shell.qml   # force reload so Settings{} re-instantiates and hits onLoadFailed
sleep 1
cat ~/.config/quickshell/settings.json
```

Expected: the file now exists and contains the default values listed above as JSON.
Edit one value directly in the file (e.g. `"barHeight": 40`), touch `shell.qml` again,
and confirm no errors — full read/write round-trip works before anything visual
depends on it.

- [ ] **Step 5: Commit**

```bash
yadm add config/Settings.qml shell.qml
yadm commit -m "Add persisted Settings.qml backed by settings.json"
```

---

## Task 6: Notch skeleton — idle clock pill

**Files:**
- Create: `bar/Notch.qml`
- Modify: `shell.qml`

**Interfaces:**
- Produces: `Notch` component with properties `colors_` (unused, kept only for
  signature symmetry with `Bar` — actually omit, see note below), `config`,
  `settings`, `notificationServer`, `horizontal` (always `true`, kept for symmetry),
  `visible`. Exposes `getLauncherX()` returning the notch's own center-X (for Task 10's
  IPC wiring).
- Consumes: `shell.togglePopup`, `shell.openPopup`, `settings.notchFlare` /
  `.barHeight` / `.collapsedWidth` / `.gapFromScreenEdge`, `NotchPalette`.

This task builds only the idle state — a centered pill showing the clock, flush with
a gap from the top edge, sized from `Settings`. Hover/media/calendar come in Tasks 7–8;
Control-Center-on-click comes in Task 9. Not wired into `shell.qml`'s live layout yet
(Task 10) — verified standalone first by temporarily setting it `visible: true`
alongside the existing `Bar`.

- [ ] **Step 1: Create the skeleton**

```qml
// bar/Notch.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"

PanelWindow {
  id: root

  property QtObject config: null
  property QtObject settings: null
  property QtObject notificationServer: null
  readonly property bool horizontal: true

  NotchPalette { id: palette }

  anchors { top: true }
  implicitWidth: (config ? config.barWidth : 50) + 16
  implicitHeight: (settings ? settings.expandedHeight : 135) + (settings ? settings.gapFromScreenEdge : 11) + 16
  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: (settings ? settings.barHeight : 34) + (settings ? settings.gapFromScreenEdge : 11)
  WlrLayershell.namespace: "quickshell-notch"
  WlrLayershell.layer: WlrLayer.Top

  property date now: new Date()
  Timer {
    interval: 1000
    running: root.visible
    repeat: true
    onTriggered: root.now = new Date()
  }

  property bool expanded: false
  property real expandProgress: expanded ? 1.0 : 0.0
  Behavior on expandProgress {
    NumberAnimation {
      duration: settings ? settings.motionMovementMs : 400
      easing.type: Easing.OutBack
      easing.amplitude: (settings ? settings.motionBouncePercent : 40) / 100.0
    }
  }

  Timer {
    id: collapseTimer
    interval: 800
    running: false
    repeat: false
    onTriggered: {
      if (!pillMouse.containsMouse) root.expanded = false
    }
  }

  function getLauncherX() {
    return pill ? pill.mapToItem(null, 0, 0).x + pill.width / 2 : 0
  }

  mask: Region { item: pill }

  Rectangle {
    id: pill
    x: (root.width - width) / 2
    y: settings ? settings.gapFromScreenEdge : 11
    width: layout.implicitWidth + 24
    height: (settings ? settings.barHeight : 34) + ((settings ? settings.expandedHeight : 135) - (settings ? settings.barHeight : 34)) * root.expandProgress
    radius: settings ? settings.notchFlare : 14
    color: palette.base

    MouseArea {
      id: pillMouse
      anchors.fill: parent
      hoverEnabled: true
      onContainsMouseChanged: {
        if (containsMouse) {
          collapseTimer.stop()
          root.expanded = true
        } else if (root.openPopup === "") {
          collapseTimer.start()
        }
      }
      onClicked: shell.togglePopup("commandcenter", pill)
    }

    RowLayout {
      id: layout
      anchors.centerIn: parent
      spacing: 12

      Text {
        text: {
          var h = root.now.getHours()
          var m = root.now.getMinutes().toString().padStart(2, "0")
          return h.toString().padStart(2, "0") + ":" + m
        }
        color: palette.text
        font.family: config ? config.fontFamily : "Roboto"
        font.pixelSize: (config ? config.fontPixelSize : 10) + 2
        font.weight: Font.Bold
      }
    }
  }
}
```

Note on `root.openPopup` referenced inside `pillMouse.onContainsMouseChanged`: `Notch`
doesn't own popup state (Task 2 moved it to `shell`), so this should read
`shell.openPopup` — `shell` is reachable the same way it is from `Bar.qml` (Task 2,
Step 3) once `Notch` is instantiated inline in `shell.qml`. Fix the line to:

```qml
        } else if (shell.openPopup === "") {
```

(Included as a fix-up here rather than a separate step since it's a one-line
correction to the block just written above.)

- [ ] **Step 2: Temporarily wire it in for standalone testing**

In `shell.qml`, add (temporarily — this instantiation gets replaced properly in Task
10):

```qml
  Notch {
    id: notchTest
    config: cfg
    settings: settings
    notificationServer: notifServer
    visible: true
  }
```

- [ ] **Step 3: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint bar/Notch.qml shell.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 4: Visual verification**

```bash
grim /tmp/claude-1000/-home-mura--config-quickshell/*/scratchpad/notch-idle.png 2>/dev/null || grim /tmp/notch-idle.png
```

Confirm: a small dark pill, centered horizontally, `11px` gap from the top edge,
showing only the current time, `14px` corner radius, `34px` tall.

- [ ] **Step 5: Remove the temporary test instantiation**

Delete the `Notch { id: notchTest ... }` block added in Step 2 — Task 10 replaces it
with the real conditional wiring.

- [ ] **Step 6: Commit**

```bash
yadm add bar/Notch.qml
yadm commit -m "Add Notch.qml skeleton: idle clock pill"
```

---

## Task 7: Media player widget (hover, left side)

**Files:**
- Create: `bar/notch/MediaPlayerWidget.qml`
- Modify: `bar/Notch.qml`

**Interfaces:**
- Produces: `MediaPlayerWidget` component, properties `settings`, `palette`
  (`NotchPalette` instance), reads MPRIS data directly off `shell` (reachable the same
  way as `Bar.qml`/`CommandCenter.qml` reach it, being instantiated inline inside
  `Notch.qml` which is itself inline inside `shell.qml`).
- Consumes: `shell.mprisTitle`/`mprisArtist`/`mprisArtUrl`/`mprisStatus`/
  `elapsedSeconds`/`mprisLengthSec`/`mprisLengthStr`, `shell.formatTime()` (Task 3),
  `settings.mediaShowAlbumArt`/`.mediaShowProgressBar`.

Compact version of `bar/commandcenter/MediaTab.qml`'s player — art, title/artist,
transport controls, no visualizer canvas (that's Control-Center-only eye candy, not
needed at notch scale).

- [ ] **Step 1: Create the widget**

```qml
// bar/notch/MediaPlayerWidget.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"

RowLayout {
  id: root
  property QtObject settings: null
  property QtObject palette: null
  spacing: 10

  Rectangle {
    Layout.preferredWidth: 40
    Layout.preferredHeight: 40
    radius: 8
    clip: true
    color: palette ? palette.overlay : "#26233a"
    visible: !settings || settings.mediaShowAlbumArt

    Image {
      source: shell.mprisArtUrl ? shell.mprisArtUrl : ""
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      visible: shell.mprisArtUrl !== ""
    }

    Text {
      anchors.centerIn: parent
      text: "♪"
      color: palette ? palette.muted : "#6e6a86"
      font.pixelSize: 18
      visible: shell.mprisArtUrl === ""
    }
  }

  ColumnLayout {
    spacing: 2
    Layout.preferredWidth: 140

    Text {
      text: shell.mprisTitle ? shell.mprisTitle : "No Media Playing"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 12
      font.weight: Font.Bold
      elide: Text.ElideRight
      Layout.fillWidth: true
    }

    Text {
      text: shell.mprisArtist ? shell.mprisArtist : ""
      color: palette ? palette.muted : "#6e6a86"
      font.pixelSize: 10
      elide: Text.ElideRight
      Layout.fillWidth: true
      visible: shell.mprisArtist !== ""
    }

    RowLayout {
      spacing: 6
      visible: !settings || settings.mediaShowProgressBar

      Text {
        text: shell.formatTime(shell.elapsedSeconds)
        color: palette ? palette.muted : "#6e6a86"
        font.pixelSize: 9
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 3
        radius: 1.5
        color: palette ? palette.overlay : "#26233a"

        Rectangle {
          width: parent.width * (shell.mprisLengthSec > 0 ? shell.elapsedSeconds / shell.mprisLengthSec : 0)
          height: parent.height
          radius: parent.radius
          color: palette ? palette.love : "#eb6f92"
        }
      }

      Text {
        text: shell.mprisLengthStr
        color: palette ? palette.muted : "#6e6a86"
        font.pixelSize: 9
      }
    }
  }

  Row {
    spacing: 4

    Repeater {
      model: [
        { icon: "◀", cmd: "prev" },
        { icon: shell.mprisStatus === "Playing" ? "⏸" : "▶", cmd: "play" },
        { icon: "▶▶", cmd: "next" }
      ]

      delegate: Rectangle {
        required property var modelData
        width: 22
        height: 22
        radius: 11
        color: "transparent"

        Text {
          anchors.centerIn: parent
          text: modelData.icon
          color: palette ? palette.text : "#e0def4"
          font.pixelSize: 10
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached([
            Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py",
            modelData.cmd
          ])
        }
      }
    }
  }
}
```

- [ ] **Step 2: Wire it into `Notch.qml`'s hover state**

In `bar/Notch.qml`, replace the `RowLayout { id: layout ... }` block (which currently
holds just the clock `Text`) with a three-slot layout: media (left, fades in on
hover), clock (center, always visible), calendar (right, fades in on hover — added in
Task 8, stubbed here as an empty `Item` until then):

```qml
    RowLayout {
      id: layout
      anchors.centerIn: parent
      spacing: 16

      MediaPlayerWidget {
        settings: root.settings
        palette: palette
        opacity: root.expandProgress
        visible: opacity > 0
        Layout.preferredWidth: implicitWidth * root.expandProgress
        clip: true
      }

      Text {
        text: {
          var h = root.now.getHours()
          var m = root.now.getMinutes().toString().padStart(2, "0")
          return h.toString().padStart(2, "0") + ":" + m
        }
        color: palette.text
        font.family: config ? config.fontFamily : "Roboto"
        font.pixelSize: (config ? config.fontPixelSize : 10) + 2
        font.weight: Font.Bold
      }

      // Calendar mini-view slot — filled in Task 8
      Item {
        id: calendarSlot
        opacity: root.expandProgress
        visible: opacity > 0
      }
    }
```

Add the import at the top of `Notch.qml`:

```qml
import "notch"
```

- [ ] **Step 3: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint bar/notch/MediaPlayerWidget.qml bar/Notch.qml
touch bar/Notch.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 4: Visual verification**

Re-add the temporary `Notch { visible: true }` block from Task 6 Step 2 (or, if Task
10 has already landed by the time this is executed, the real wiring already covers
it). Play media via an MPRIS-compatible player, hover the notch (manual — no pointer
automation tool is installed on this machine, per the design doc's testing-gap note;
this step is Rodrigo's to perform, not scriptable here), confirm the media widget
fades in on the left with correct title/artist/art/transport controls, and that
clicking prev/play/next actually controls playback.

- [ ] **Step 5: Commit**

```bash
yadm add bar/notch/MediaPlayerWidget.qml bar/Notch.qml
yadm commit -m "Add hover media player widget to notch"
```

---

## Task 8: Calendar mini-view (hover, right side)

**Files:**
- Create: `bar/notch/CalendarMini.qml`
- Modify: `bar/Notch.qml`

**Interfaces:**
- Produces: `CalendarMini` component, properties `palette`, `settings`.
- Consumes: `CalendarLogic.js` (Task 1).

Compact month grid, no navigation arrows (matches the video's inline calendar — just
shows the current month, today highlighted). Full navigable calendar is still
available in vertical mode via the untouched `CalendarPopup.qml`.

- [ ] **Step 1: Create the widget**

```qml
// bar/notch/CalendarMini.qml
import QtQuick
import QtQuick.Layouts
import "../CalendarLogic.js" as CalendarLogic

ColumnLayout {
  id: root
  property QtObject palette: null
  property QtObject settings: null
  spacing: 4

  readonly property date currentDate: new Date()
  readonly property var dayModel: CalendarLogic.buildDayModel(currentDate)
  readonly property var weekDays: settings && settings.calendarWeekStartsMonday
    ? CalendarLogic.weekDays.slice(1).concat(CalendarLogic.weekDays.slice(0, 1))
    : CalendarLogic.weekDays

  Text {
    text: CalendarLogic.monthNames[root.currentDate.getMonth()] + " " + root.currentDate.getFullYear()
    color: palette ? palette.text : "#e0def4"
    font.pixelSize: 10
    font.weight: Font.Bold
    Layout.alignment: Qt.AlignHCenter
  }

  GridLayout {
    columns: 7
    rowSpacing: 2
    columnSpacing: 2
    Layout.alignment: Qt.AlignHCenter

    Repeater {
      model: root.weekDays
      delegate: Text {
        required property string modelData
        text: modelData.charAt(0)
        color: palette ? palette.muted : "#6e6a86"
        font.pixelSize: 8
        Layout.preferredWidth: 14
        horizontalAlignment: Text.AlignHCenter
      }
    }

    Repeater {
      model: root.dayModel
      delegate: Text {
        required property int modelData
        readonly property bool isToday: modelData > 0 && CalendarLogic.isToday(modelData, root.currentDate, root.currentDate)
        text: modelData > 0 ? modelData.toString() : ""
        color: isToday ? (palette ? palette.base : "#191724") : (palette ? palette.text : "#e0def4")
        font.pixelSize: 8
        font.weight: isToday ? Font.Bold : Font.Normal
        Layout.preferredWidth: 14
        horizontalAlignment: Text.AlignHCenter

        Rectangle {
          visible: parent.isToday
          anchors.centerIn: parent
          width: 14
          height: 14
          radius: 7
          color: palette ? palette.love : "#eb6f92"
          z: -1
        }
      }
    }
  }
}
```

- [ ] **Step 2: Wire it into `Notch.qml`'s `calendarSlot`**

Replace the stub `Item { id: calendarSlot ... }` added in Task 7 Step 2 with:

```qml
      CalendarMini {
        id: calendarSlot
        palette: palette
        settings: root.settings
        opacity: root.expandProgress
        visible: opacity > 0
        Layout.preferredWidth: implicitWidth * root.expandProgress
        clip: true
      }
```

- [ ] **Step 3: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint bar/notch/CalendarMini.qml bar/Notch.qml
touch bar/Notch.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 4: Visual verification**

Hover the notch (manual, per the same note as Task 7 Step 4), confirm the mini
calendar fades in on the right with today's date circled in the accent color and the
correct month/year header.

- [ ] **Step 5: Commit**

```bash
yadm add bar/notch/CalendarMini.qml bar/Notch.qml
yadm commit -m "Add hover mini-calendar to notch"
```

---

## Task 9: Click-to-open Control Center from the notch

**Files:**
- Modify: `bar/Notch.qml` (already wired in Task 6, Step 1: `onClicked:
  shell.togglePopup("commandcenter", pill)`)

**Interfaces:**
- Consumes: `shell.togglePopup` (Task 2), the existing `CommandCenter` instantiation
  in `shell.qml` (already conditioned on `shell.openPopup === "commandcenter"` — no
  changes needed there once Task 2 lands, since `CommandCenter`'s `visible:` binding
  was already updated to read `shell.openPopup` in Task 2 Step 2).

This task is verification-only — the click handler was already written in Task 6. No
new code.

- [ ] **Step 1: Manual verification**

Click the notch (idle or hover state). Confirm Control Center opens as a dropdown.
Click the notch again (or click elsewhere, per `PopupShield`'s existing dismiss
behavior), confirm it closes. Confirm this works whether the notch is idle or
currently hover-expanded.

- [ ] **Step 2: Commit**

Nothing to commit — this task validates prior work. If Step 1 surfaces a bug, fix it
in `bar/Notch.qml` and commit:

```bash
yadm add bar/Notch.qml
yadm commit -m "Fix notch click-to-open-Control-Center wiring"
```

(Only run this commit if a fix was actually needed.)

---

## Task 10: Swap Notch in for Bar in horizontal mode

**Files:**
- Modify: `shell.qml`

**Interfaces:**
- Consumes: `Notch` (Task 6), `Bar` (untouched vertical-mode component).

- [ ] **Step 1: Replace the single `Bar` instantiation with a conditional pair**

In `shell.qml`, replace:

```qml
  Bar {
    id: bar
    horizontal: shell.isHorizontal
    colors_: colors
    config: cfg
    notificationServer: notifServer
    visible: !lockScreen.locked
  }
```

with:

```qml
  Bar {
    id: bar
    horizontal: false
    colors_: colors
    config: cfg
    notificationServer: notifServer
    visible: !shell.isHorizontal && !lockScreen.locked
  }

  Notch {
    id: notch
    config: cfg
    settings: settings
    notificationServer: notifServer
    visible: shell.isHorizontal && !lockScreen.locked
  }
```

`bar.horizontal` is now hardcoded `false` since `Bar` only ever renders in vertical
mode from here on — `Notch` is always the horizontal-mode component.

- [ ] **Step 2: Fix the IPC handlers to work in both modes**

The `launcher`/`quickmenu` IPC handlers (updated in Task 2 Step 2) call
`bar.getLauncherX()`/`bar.getMenuIndicatorX()` unconditionally — these only make sense
when `Bar` is the visible one. Update both functions in `shell.qml`'s `IpcHandler`:

```qml
    function launcher() {
      if (shell.isHorizontal) {
        shell.popupAnchorX = notch.getLauncherX()
        shell.popupAnchorY = notch.height
      } else {
        shell.popupAnchorY = 0
      }
      shell.openPopup = shell.openPopup === "launcher" ? "" : "launcher"
    }

    function quickmenu() {
      if (shell.isHorizontal) {
        shell.popupAnchorX = notch.getLauncherX()
        shell.popupAnchorY = notch.height
      } else {
        shell.popupAnchorY = bar.getMenuIndicatorY()
      }
      shell.openPopup = shell.openPopup === "quickmenu" ? "" : "quickmenu"
    }
```

(Both anchor to the notch's own center in horizontal mode, since there's no
dedicated launcher/menu icon anymore — `LauncherPopup` still works via the Niri
keybind per the design's "keybind only" decision, it just opens centered under the
notch instead of anchored to a since-removed icon.)

- [ ] **Step 3: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint shell.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 4: Full regression check, both orientations**

Horizontal (default): confirm the notch renders, idle/hover/click all work as verified
in Tasks 6–9.

```bash
echo vertical > ~/.config/quickshell/layout
touch shell.qml
```

Vertical: confirm `Bar.qml` renders exactly as it did before this entire plan started
— all indicators, all popups, calendar popup via clock click.

```bash
echo horizontal > ~/.config/quickshell/layout
touch shell.qml
```

Back to horizontal for the rest of the plan.

- [ ] **Step 5: Commit**

```bash
yadm add shell.qml
yadm commit -m "Swap Notch in for Bar in horizontal mode"
```

---

## Task 11: Power-menu trigger inside Control Center

**Files:**
- Modify: `bar/CommandCenter.qml`

**Interfaces:**
- Consumes: `shell.togglePopup("quickmenu", widget)` (Task 2), the existing `QuickMenu`
  popup (untouched).

The old gear icon (`MenuIndicator`, removed from the notch per the design) was the
only trigger for `QuickMenu` (Sleep/Restart/Shut Down/Log Out — confirmed by reading
`bar/QuickMenu.qml`). Without a new trigger this becomes unreachable by mouse
(keybind-only would be a real regression, not something Rodrigo asked to drop). Add a
small power icon to Control Center's header.

- [ ] **Step 1: Find Control Center's header row**

```bash
grep -n "RowLayout\|header\|Header" bar/CommandCenter.qml | head -20
```

Locate the top header row of the panel (contains the tab-switching UI / close
button). Add the power button as a new item in that row — exact insertion point
depends on what Step 1's grep shows; add it as the last item before (or after) the
existing close/dismiss control, following whatever spacing pattern the surrounding
`RowLayout` already uses.

- [ ] **Step 2: Add the button**

```qml
      Rectangle {
        width: 32
        height: 32
        radius: 16
        color: colors_ ? colors_.surfaceContainer : "#25232A"
        border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "power_settings_new"
          font.family: config ? config.iconFont : "Material Symbols Outlined"
          font.pixelSize: 16
          color: colors_ ? colors_.fgSurface : "#FFFFFF"
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          hoverEnabled: true
          onClicked: shell.togglePopup("quickmenu", parent)
        }
      }
```

- [ ] **Step 3: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint bar/CommandCenter.qml
touch bar/CommandCenter.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 4: Manual verification**

Open Control Center, click the new power icon, confirm the `QuickMenu` popup
(Sleep/Restart/Shut Down/Log Out) opens with correct options and each action still
works.

- [ ] **Step 5: Commit**

```bash
yadm add bar/CommandCenter.qml
yadm commit -m "Add power-menu trigger to Control Center header"
```

---

## Task 12: Shared Settings UI controls

**Files:**
- Create: `Settings/SettingsControls.qml`

**Interfaces:**
- Produces: `SettingsRow` (label + trailing content row), `SettingsSlider` (label +
  `bar/SliderControl.qml` + numeric readout, maps a `min`..`max` px/ms/percent range
  onto the 0..1 `SliderControl` value), `SettingsToggle` (label + `bar/SwitchControl.qml`)
  — consumed by every tab in Tasks 14–23.

QML doesn't support multiple top-level component definitions in one file being
imported individually by name the way this needs (`SettingsRow { }`, `SettingsSlider {
}` used as distinct tags) — so this "file" is actually three sibling files sharing a
directory, described together here since they're trivial and always used as a set.

- [ ] **Step 1: Create `Settings/SettingsRow.qml`**

```qml
// Settings/SettingsRow.qml
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root
  property string label: ""
  property QtObject palette: null
  default property alias content: trailing.children

  Layout.fillWidth: true
  Layout.preferredHeight: 40

  Text {
    text: root.label
    color: palette ? palette.text : "#e0def4"
    font.pixelSize: 13
    Layout.fillWidth: true
  }

  Row {
    id: trailing
    spacing: 8
  }
}
```

- [ ] **Step 2: Create `Settings/SettingsToggle.qml`**

```qml
// Settings/SettingsToggle.qml
import QtQuick
import "../bar"

SettingsRow {
  id: root
  property bool checked: false
  property QtObject palette: null
  signal toggled(bool value)

  SwitchControl {
    checked: root.checked
    activeColor: root.palette ? root.palette.love : "#eb6f92"
    surfaceContainerHighest: root.palette ? root.palette.overlay : "#26233a"
    outline: root.palette ? root.palette.muted : "#6e6a86"
    onToggled: root.toggled(!root.checked)
  }
}
```

- [ ] **Step 3: Create `Settings/SettingsSlider.qml`**

```qml
// Settings/SettingsSlider.qml
import QtQuick
import QtQuick.Layouts
import "../bar"

ColumnLayout {
  id: root
  property string label: ""
  property QtObject palette: null
  property real value: 0
  property real min: 0
  property real max: 100
  property string unit: "px"
  signal changed(real value)

  Layout.fillWidth: true
  spacing: 4

  RowLayout {
    Layout.fillWidth: true
    Text {
      text: root.label
      color: root.palette ? root.palette.text : "#e0def4"
      font.pixelSize: 13
      Layout.fillWidth: true
    }
    Text {
      text: Math.round(root.value) + " " + root.unit
      color: root.palette ? root.palette.muted : "#6e6a86"
      font.pixelSize: 12
    }
  }

  SliderControl {
    Layout.fillWidth: true
    value: root.max > root.min ? (root.value - root.min) / (root.max - root.min) : 0
    activeColor: root.palette ? root.palette.love : "#eb6f92"
    surfaceContainerHighest: root.palette ? root.palette.overlay : "#26233a"
    outline: root.palette ? root.palette.muted : "#6e6a86"
    onChanged: function(ratio) {
      root.changed(root.min + ratio * (root.max - root.min))
    }
  }
}
```

Note: `SettingsToggle.qml` extends `SettingsRow.qml` by declaring itself as a
`SettingsRow { ... }`-shaped component (its root type is effectively `SettingsRow`,
achieved by importing the local directory and using `SettingsRow` as its root element
— i.e. the file's root item literally is a `SettingsRow`, not `Item`). Correct that
file's root line to explicitly read `SettingsRow {` (it already does, as written
above) — flagging here only because it's easy to misread as a typo; it's intentional
component-extension-by-composition, the standard QML idiom for this.

- [ ] **Step 4: Lint**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/SettingsRow.qml Settings/SettingsToggle.qml Settings/SettingsSlider.qml
```

Expected: no errors. (Nothing to hot-reload yet — not instantiated until Task 13+.)

- [ ] **Step 5: Commit**

```bash
yadm add Settings/SettingsRow.qml Settings/SettingsToggle.qml Settings/SettingsSlider.qml
yadm commit -m "Add shared Settings UI controls (row/toggle/slider)"
```

---

## Task 13: Settings window shell (sidebar + empty pages)

**Files:**
- Create: `Settings/SettingsWindow.qml`
- Modify: `shell.qml`
- Modify: `bar/CommandCenter.qml`

**Interfaces:**
- Produces: `SettingsWindow` component, `property bool visible`, `signal dismissed()`.
- Consumes: `NotchPalette`, `settings` — Tasks 14–23 each add one `Loader`-swapped tab
  page into the `pages` model this task defines.

Plain `Window` (not layer-shell) — matches the video's floating-window feel, unlike
every other panel in this shell which uses `PanelWindow`/layer-shell.

- [ ] **Step 1: Create the window shell**

```qml
// Settings/SettingsWindow.qml
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "../config"

Window {
  id: root
  property QtObject settings: null
  property QtObject config: null
  signal dismissed()

  NotchPalette { id: palette }

  width: 720
  height: 520
  color: palette.base
  title: "Quickshell Settings"

  readonly property var tabModel: [
    { name: "Bar & Island", icon: "🖥" },
    { name: "Media", icon: "🎵" },
    { name: "Clock & Date", icon: "🕐" },
    { name: "Appearance", icon: "🎨" },
    { name: "Motion", icon: "🌀" },
    { name: "Launcher", icon: "🔍" },
    { name: "Notifications", icon: "🔔" },
    { name: "Control Center", icon: "⚙" },
    { name: "Lock Screen", icon: "🔒" },
    { name: "System", icon: "🖴" }
  ]
  property int currentTab: 0
  property string searchText: ""

  RowLayout {
    anchors.fill: parent
    spacing: 0

    // Sidebar
    ColumnLayout {
      Layout.preferredWidth: 220
      Layout.fillHeight: true
      spacing: 0

      TextInput {
        Layout.fillWidth: true
        Layout.margins: 12
        Layout.preferredHeight: 32
        color: palette.text
        font.pixelSize: 12
        text: root.searchText
        onTextChanged: root.searchText = text

        Text {
          text: "Search Settings"
          color: palette.muted
          font.pixelSize: 12
          visible: parent.text.length === 0
        }
      }

      Repeater {
        model: root.tabModel
        delegate: Rectangle {
          required property var modelData
          required property int index
          Layout.fillWidth: true
          Layout.preferredHeight: 40
          color: root.currentTab === index ? palette.overlay : "transparent"
          radius: 8

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text { text: parent.parent.modelData.icon; font.pixelSize: 14 }
            Text {
              text: parent.parent.modelData.name
              color: palette.text
              font.pixelSize: 13
              Layout.fillWidth: true
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.currentTab = index
          }
        }
      }
    }

    // Page area
    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: palette.surface

      Loader {
        anchors.fill: parent
        anchors.margins: 24
        source: [
          "tabs/BarIslandTab.qml",
          "tabs/MediaSettingsTab.qml",
          "tabs/ClockDateTab.qml",
          "tabs/AppearanceSettingsTab.qml",
          "tabs/MotionSettingsTab.qml",
          "tabs/LauncherSettingsTab.qml",
          "tabs/NotificationsSettingsTab.qml",
          "tabs/ControlCenterSettingsTab.qml",
          "tabs/LockScreenSettingsTab.qml",
          "tabs/SystemSettingsTab.qml"
        ][root.currentTab]

        onLoaded: {
          item.settings = root.settings
          item.palette = palette
        }
      }
    }
  }

  onVisibleChanged: if (!visible) root.dismissed()
}
```

Each tab file (Tasks 14–23) must declare `property QtObject settings: null` and
`property QtObject palette: null` as its two root properties — the `Loader.onLoaded`
above assigns both by name, so any tab file missing either property silently fails to
receive it. This is called out explicitly in each tab task below.

- [ ] **Step 2: Wire the open trigger into `CommandCenter.qml`**

Add a settings-gear button next to the power button added in Task 11 (same header
row), following the same `Rectangle` + `MouseArea` pattern:

```qml
      Rectangle {
        width: 32
        height: 32
        radius: 16
        color: colors_ ? colors_.surfaceContainer : "#25232A"
        border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "settings"
          font.family: config ? config.iconFont : "Material Symbols Outlined"
          font.pixelSize: 16
          color: colors_ ? colors_.fgSurface : "#FFFFFF"
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: settingsWindow.visible = true
        }
      }
```

Add the `SettingsWindow` instance to `shell.qml` (near the `CommandCenter`
instantiation):

```qml
  SettingsWindow {
    id: settingsWindow
    settings: settings
    config: cfg
    visible: false
    onDismissed: visible = false
  }
```

`CommandCenter.qml`'s new button needs to reach `settingsWindow` — since both are
instantiated inline as siblings inside `shell.qml`, this resolves the same way `shell`
itself does from `Bar.qml`/`Notch.qml` (enclosing-scope id lookup).

- [ ] **Step 3: Stub out the ten tab files with the minimum that satisfies the Loader**

Each of Tasks 14–23 replaces one of these stubs with real content. Create all ten now
so Step 4's lint/reload check passes (the `Loader.source` array references all ten
paths immediately):

```bash
cd /home/mura/.config/quickshell/Settings
mkdir -p tabs
for f in BarIslandTab MediaSettingsTab ClockDateTab AppearanceSettingsTab \
         MotionSettingsTab LauncherSettingsTab NotificationsSettingsTab \
         ControlCenterSettingsTab LockScreenSettingsTab SystemSettingsTab; do
cat > "tabs/${f}.qml" <<'EOF'
import QtQuick
import QtQuick.Layouts

Item {
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 16
    Text { text: "Coming soon"; color: palette ? palette.muted : "#6e6a86" }
  }
}
EOF
done
```

- [ ] **Step 4: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/SettingsWindow.qml Settings/tabs/*.qml bar/CommandCenter.qml shell.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 5: Manual verification**

Open Control Center, click the new gear icon, confirm a `720×520` window opens with
the 10-tab sidebar, each tab switches the page area (showing "Coming soon" for now),
and the search field accepts text (filtering itself lands in a later task — not
required for this skeleton to be considered working).

- [ ] **Step 6: Commit**

```bash
yadm add Settings/SettingsWindow.qml Settings/tabs shell.qml bar/CommandCenter.qml
yadm commit -m "Add Settings window shell with 10-tab sidebar"
```

---

## Task 14: Bar & Island settings tab

**Files:**
- Modify: `Settings/tabs/BarIslandTab.qml`

**Interfaces:**
- Consumes: `settings.notchFlare`/`.barHeight`/`.collapsedWidth`/`.expandedHeight`/
  `.gapFromScreenEdge` (Task 5), `SettingsSlider` (Task 12).

- [ ] **Step 1: Replace the stub**

```qml
// Settings/tabs/BarIslandTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 20

    Text {
      text: "Bar & Island"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 20
      font.weight: Font.Bold
    }
    Text {
      text: "Shape and size of the notch."
      color: palette ? palette.muted : "#6e6a86"
      font.pixelSize: 12
      Layout.bottomMargin: 8
    }

    SettingsSlider {
      label: "Notch flare"; palette: root.palette; unit: "px"
      min: 0; max: 30
      value: settings ? settings.notchFlare : 14
      onChanged: function(v) { if (settings) { settings.notchFlare = v; settings.save() } }
    }
    SettingsSlider {
      label: "Bar height"; palette: root.palette; unit: "px"
      min: 20; max: 60
      value: settings ? settings.barHeight : 34
      onChanged: function(v) { if (settings) { settings.barHeight = v; settings.save() } }
    }
    SettingsSlider {
      label: "Collapsed width"; palette: root.palette; unit: "px"
      min: 80; max: 300
      value: settings ? settings.collapsedWidth : 150
      onChanged: function(v) { if (settings) { settings.collapsedWidth = v; settings.save() } }
    }
    SettingsSlider {
      label: "Expanded height"; palette: root.palette; unit: "px"
      min: 60; max: 220
      value: settings ? settings.expandedHeight : 135
      onChanged: function(v) { if (settings) { settings.expandedHeight = v; settings.save() } }
    }
    SettingsSlider {
      label: "Gap from screen edge"; palette: root.palette; unit: "px"
      min: 0; max: 30
      value: settings ? settings.gapFromScreenEdge : 11
      onChanged: function(v) { if (settings) { settings.gapFromScreenEdge = v; settings.save() } }
    }

    Item { Layout.fillHeight: true }
  }
}
```

Note: `SettingsSlider`'s `label`/`palette`/`min`/`max`/`unit`/`value` properties and
`onChanged` signal are exactly as defined in Task 12 Step 3 — this file is a pure
consumer, no new properties invented here.

Note on `root.palette`: this file's root `Item` has no `id: root` declared — QML
gives every root element an implicit default that isn't addressable as `root` unless
named. Add `id: root` to the root `Item` line (`Item { id: root ... }`) so
`root.palette` resolves; apply this same fix in every subsequent tab task (14–23) that
references `root.palette` inside a `SettingsSlider`/`SettingsToggle`.

- [ ] **Step 2: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/tabs/BarIslandTab.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 3: Manual verification**

Open Settings → Bar & Island. Drag the "Bar height" slider. Confirm: the numeric
readout updates live, and the notch's idle pill height changes in real time (no
restart) since `Notch.qml` binds directly to `settings.barHeight`. Quit and restart
Quickshell (or just reload), confirm the value persisted (re-open Settings, slider is
where you left it).

- [ ] **Step 4: Commit**

```bash
yadm add Settings/tabs/BarIslandTab.qml
yadm commit -m "Wire up Bar & Island settings tab"
```

---

## Task 15: Motion settings tab

**Files:**
- Modify: `Settings/tabs/MotionSettingsTab.qml`

**Interfaces:**
- Consumes: `settings.reduceMotion`/`.motionMovementMs`/`.motionFadeMs`/
  `.motionHoverMs`/`.motionBouncePercent`.

- [ ] **Step 1: Replace the stub**

```qml
// Settings/tabs/MotionSettingsTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 20

    Text {
      text: "Motion"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 20
      font.weight: Font.Bold
    }
    Text {
      text: "How fast the shell animates, or whether it animates at all."
      color: palette ? palette.muted : "#6e6a86"
      font.pixelSize: 12
      Layout.bottomMargin: 8
    }

    SettingsToggle {
      label: "Reduce motion"; palette: root.palette
      checked: settings ? settings.reduceMotion : false
      onToggled: function(v) { if (settings) { settings.reduceMotion = v; settings.save() } }
    }
    SettingsSlider {
      label: "Movement (size / position)"; palette: root.palette; unit: "ms"
      min: 100; max: 800
      value: settings ? settings.motionMovementMs : 400
      onChanged: function(v) { if (settings) { settings.motionMovementMs = v; settings.save() } }
    }
    SettingsSlider {
      label: "Fades & colour"; palette: root.palette; unit: "ms"
      min: 50; max: 500
      value: settings ? settings.motionFadeMs : 200
      onChanged: function(v) { if (settings) { settings.motionFadeMs = v; settings.save() } }
    }
    SettingsSlider {
      label: "Hover response"; palette: root.palette; unit: "ms"
      min: 50; max: 400
      value: settings ? settings.motionHoverMs : 150
      onChanged: function(v) { if (settings) { settings.motionHoverMs = v; settings.save() } }
    }
    SettingsSlider {
      label: "Bounce"; palette: root.palette; unit: "%"
      min: 0; max: 100
      value: settings ? settings.motionBouncePercent : 40
      onChanged: function(v) { if (settings) { settings.motionBouncePercent = v; settings.save() } }
    }

    Item { Layout.fillHeight: true }
  }
}
```

- [ ] **Step 2: Wire `reduceMotion` and the timing values into `Notch.qml`**

In `bar/Notch.qml`, update the `Behavior on expandProgress` block (written in Task 6)
to respect `reduceMotion`:

```qml
  Behavior on expandProgress {
    enabled: !(settings && settings.reduceMotion)
    NumberAnimation {
      duration: settings ? settings.motionMovementMs : 400
      easing.type: Easing.OutBack
      easing.amplitude: (settings ? settings.motionBouncePercent : 40) / 100.0
    }
  }
```

(The `duration`/`easing.amplitude` bindings already read from `settings` as written in
Task 6 — this step only adds the `reduceMotion` gate.)

- [ ] **Step 3: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/tabs/MotionSettingsTab.qml bar/Notch.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 4: Manual verification**

Toggle "Reduce motion" on, hover the notch, confirm it snaps open/closed instantly
with no animation. Toggle it back off, drag "Bounce" to `0`, confirm the expand
animation loses its overshoot.

- [ ] **Step 5: Commit**

```bash
yadm add Settings/tabs/MotionSettingsTab.qml bar/Notch.qml
yadm commit -m "Wire up Motion settings tab, apply to notch animation"
```

---

## Task 16: Media settings tab

**Files:**
- Modify: `Settings/tabs/MediaSettingsTab.qml`

**Interfaces:**
- Consumes: `settings.mediaShowAlbumArt`/`.mediaShowProgressBar`/
  `.mediaControlsAlwaysVisible`.

- [ ] **Step 1: Replace the stub**

```qml
// Settings/tabs/MediaSettingsTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 20

    Text {
      text: "Media"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 20
      font.weight: Font.Bold
    }

    SettingsToggle {
      label: "Show album art"; palette: root.palette
      checked: settings ? settings.mediaShowAlbumArt : true
      onToggled: function(v) { if (settings) { settings.mediaShowAlbumArt = v; settings.save() } }
    }
    SettingsToggle {
      label: "Show progress bar"; palette: root.palette
      checked: settings ? settings.mediaShowProgressBar : true
      onToggled: function(v) { if (settings) { settings.mediaShowProgressBar = v; settings.save() } }
    }
    SettingsToggle {
      label: "Controls always visible (not just on hover)"; palette: root.palette
      checked: settings ? settings.mediaControlsAlwaysVisible : false
      onToggled: function(v) { if (settings) { settings.mediaControlsAlwaysVisible = v; settings.save() } }
    }

    Item { Layout.fillHeight: true }
  }
}
```

`mediaShowAlbumArt`/`mediaShowProgressBar` are already consumed by
`MediaPlayerWidget.qml` (Task 7 — the `visible: !settings || settings.mediaShowAlbumArt`
and equivalent progress-bar binding). `mediaControlsAlwaysVisible` has no consumer yet
since `Notch.qml`'s current design only shows the media widget at all during hover
(Task 7) — implementing "always visible, even when idle" is a bigger structural change
to `Notch.qml`'s idle-state layout not covered by the approved design (idle state is
explicitly clock-only per the spec). This toggle is included because the video's
Settings app has it, but it's a no-op until/unless a future task changes the idle-state
layout — noted here rather than silently faked.

- [ ] **Step 2: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/tabs/MediaSettingsTab.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 3: Manual verification**

Toggle "Show album art" off, hover the notch, confirm the art square disappears but
title/artist/controls remain. Toggle "Show progress bar" off, confirm the
time/progress/time row disappears.

- [ ] **Step 4: Commit**

```bash
yadm add Settings/tabs/MediaSettingsTab.qml
yadm commit -m "Wire up Media settings tab"
```

---

## Task 17: Clock & Date settings tab

**Files:**
- Modify: `Settings/tabs/ClockDateTab.qml`
- Modify: `bar/Notch.qml`
- Modify: `bar/notch/CalendarMini.qml`

**Interfaces:**
- Consumes: `settings.clock24h`/`.clockShowSeconds`/`.calendarWeekStartsMonday`.

- [ ] **Step 1: Replace the stub**

```qml
// Settings/tabs/ClockDateTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 20

    Text {
      text: "Clock & Date"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 20
      font.weight: Font.Bold
    }

    SettingsToggle {
      label: "24-hour format"; palette: root.palette
      checked: settings ? settings.clock24h : true
      onToggled: function(v) { if (settings) { settings.clock24h = v; settings.save() } }
    }
    SettingsToggle {
      label: "Show seconds"; palette: root.palette
      checked: settings ? settings.clockShowSeconds : false
      onToggled: function(v) { if (settings) { settings.clockShowSeconds = v; settings.save() } }
    }
    SettingsToggle {
      label: "Week starts on Monday"; palette: root.palette
      checked: settings ? settings.calendarWeekStartsMonday : false
      onToggled: function(v) { if (settings) { settings.calendarWeekStartsMonday = v; settings.save() } }
    }

    Item { Layout.fillHeight: true }
  }
}
```

`calendarWeekStartsMonday` is already consumed by `CalendarMini.qml` (Task 8's
`weekDays` property). This task only needs to wire the clock format into `Notch.qml`.

- [ ] **Step 2: Wire `clock24h`/`clockShowSeconds` into `Notch.qml`**

Both `Text` blocks in `bar/Notch.qml` that render the clock (the idle pill's, and the
one inside `layout` from Task 7) currently hardcode 24h `HH:mm` formatting. Replace
both occurrences of:

```qml
        text: {
          var h = root.now.getHours()
          var m = root.now.getMinutes().toString().padStart(2, "0")
          return h.toString().padStart(2, "0") + ":" + m
        }
```

with:

```qml
        text: {
          var h = root.now.getHours()
          var m = root.now.getMinutes().toString().padStart(2, "0")
          var s = root.now.getSeconds().toString().padStart(2, "0")
          var use24h = !settings || settings.clock24h
          var hh = use24h ? h : ((h % 12) || 12)
          var suffix = use24h ? "" : (h < 12 ? " AM" : " PM")
          var base = hh.toString().padStart(2, "0") + ":" + m
          if (settings && settings.clockShowSeconds) base += ":" + s
          return base + suffix
        }
```

- [ ] **Step 3: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/tabs/ClockDateTab.qml bar/Notch.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 4: Manual verification**

Toggle "24-hour format" off, confirm the notch clock switches to `h:mm AM/PM`. Toggle
"Show seconds" on, confirm `:ss` appears. Toggle "Week starts on Monday", hover the
notch, confirm the mini calendar's weekday header row reorders.

- [ ] **Step 5: Commit**

```bash
yadm add Settings/tabs/ClockDateTab.qml bar/Notch.qml
yadm commit -m "Wire up Clock & Date settings tab"
```

---

## Task 18: Appearance settings tab

**Files:**
- Modify: `Settings/tabs/AppearanceSettingsTab.qml`
- Modify: `bar/Notch.qml`
- Modify: `Settings/SettingsWindow.qml`

**Interfaces:**
- Consumes: `settings.fontFamily`/`.fontPixelSize`/`.spacingUnit`/`.cornerRadius`.

Deliberately no color/theme picker — colors stay owned by `apply-desktop-theme`
(untouched, per the design doc's explicit boundary).

- [ ] **Step 1: Replace the stub**

```qml
// Settings/tabs/AppearanceSettingsTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 20

    Text {
      text: "Appearance"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 20
      font.weight: Font.Bold
    }
    Text {
      text: "Fonts and spacing for the notch and Settings window. Colors are\nmanaged separately via apply-desktop-theme."
      color: palette ? palette.muted : "#6e6a86"
      font.pixelSize: 12
      Layout.bottomMargin: 8
    }

    SettingsSlider {
      label: "Font size"; palette: root.palette; unit: "px"
      min: 10; max: 24
      value: settings ? settings.fontPixelSize : 15
      onChanged: function(v) { if (settings) { settings.fontPixelSize = v; settings.save() } }
    }
    SettingsSlider {
      label: "Spacing unit"; palette: root.palette; unit: "px"
      min: 2; max: 12
      value: settings ? settings.spacingUnit : 4
      onChanged: function(v) { if (settings) { settings.spacingUnit = v; settings.save() } }
    }
    SettingsSlider {
      label: "Corner radius"; palette: root.palette; unit: "px"
      min: 0; max: 24
      value: settings ? settings.cornerRadius : 10
      onChanged: function(v) { if (settings) { settings.cornerRadius = v; settings.save() } }
    }

    Item { Layout.fillHeight: true }
  }
}
```

`fontFamily` has no control here — the video's reference shows a text field for it,
but this codebase has one project font (`Roboto`, from `Config.qml`) with no
alternative fonts installed/verified available, so a font-family picker would be a
control with no real options behind it (exactly the kind of inert placeholder the
plan format forbids). Omitted; `fontFamily` stays in `Settings.qml`'s schema for
forward-compatibility but has no UI control in this task.

- [ ] **Step 2: Wire `fontPixelSize` into `Notch.qml`'s clock text**

Both clock `Text` blocks in `bar/Notch.qml`: change

```qml
        font.pixelSize: (config ? config.fontPixelSize : 10) + 2
```

to

```qml
        font.pixelSize: (settings ? settings.fontPixelSize : 15)
```

- [ ] **Step 3: Wire `cornerRadius` into `SettingsWindow.qml`'s sidebar tab-highlight**

In `Settings/SettingsWindow.qml`, the tab `Rectangle` delegate currently hardcodes
`radius: 8` — change to `radius: settings ? settings.cornerRadius : 10`.

- [ ] **Step 4: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/tabs/AppearanceSettingsTab.qml bar/Notch.qml Settings/SettingsWindow.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 5: Manual verification**

Drag "Font size" to its max, confirm the notch clock text visibly grows. Drag "Corner
radius" in Settings, confirm the Settings window's own sidebar tab-highlight corners
change.

- [ ] **Step 6: Commit**

```bash
yadm add Settings/tabs/AppearanceSettingsTab.qml bar/Notch.qml Settings/SettingsWindow.qml
yadm commit -m "Wire up Appearance settings tab (fonts/spacing, not colors)"
```

---

## Task 19: Notifications settings tab

**Files:**
- Modify: `Settings/tabs/NotificationsSettingsTab.qml`
- Modify: `bar/NotificationToast.qml`

**Interfaces:**
- Consumes: `settings.notificationToastDurationMs`/`.doNotDisturb`.

- [ ] **Step 1: Check `NotificationToast.qml`'s current duration source**

```bash
grep -n "notificationToastDurationMs\|config.notification" bar/NotificationToast.qml
```

Expected: a reference to `config.notificationToastDurationMs` (the existing
`Config.qml` constant, `5000`).

- [ ] **Step 2: Replace the stub tab**

```qml
// Settings/tabs/NotificationsSettingsTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 20

    Text {
      text: "Notifications"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 20
      font.weight: Font.Bold
    }

    SettingsSlider {
      label: "Toast duration"; palette: root.palette; unit: "ms"
      min: 1000; max: 15000
      value: settings ? settings.notificationToastDurationMs : 5000
      onChanged: function(v) { if (settings) { settings.notificationToastDurationMs = v; settings.save() } }
    }
    SettingsToggle {
      label: "Do not disturb"; palette: root.palette
      checked: settings ? settings.doNotDisturb : false
      onToggled: function(v) { if (settings) { settings.doNotDisturb = v; settings.save() } }
    }

    Item { Layout.fillHeight: true }
  }
}
```

- [ ] **Step 3: Wire `notificationToastDurationMs` into `NotificationToast.qml`**

Replace the `config.notificationToastDurationMs` reference found in Step 1 with a
fallback chain that prefers the new setting: change (wherever it appears, likely a
`Timer.interval:` binding) from `config.notificationToastDurationMs` to `(settings ?
settings.notificationToastDurationMs : config.notificationToastDurationMs)`. This
requires `NotificationToast.qml` to accept a new `property QtObject settings: null`
(add it alongside the existing `colors_`/`config` properties at the top of the file),
and `shell.qml`'s `NotificationToast { ... }` instantiation (line 259–264) to pass
`settings: settings`.

- [ ] **Step 4: Wire `doNotDisturb` into the notification server**

In `shell.qml`, the `NotificationServer.onNotification` handler (lines 244–256)
currently always calls `notificationToast.show(notif)`. Gate it:

```qml
    onNotification: function(notif) {
      notif.tracked = true
      if (notif.appName === batteryAlert.appName) {
        if (notif.summary === "Battery Alert") batteryAlert.alertNotif = notif
        else if (notif.summary === "Battery Warning") batteryAlert.warningNotif = notif
        notif.closed.connect(function() {
          if (batteryAlert.warningNotif === notif) batteryAlert.warningNotif = null
          if (batteryAlert.alertNotif === notif) batteryAlert.alertNotif = null
        })
      }
      if (!settings.doNotDisturb) notificationToast.show(notif)
      notificationPopup.onNotificationReceived(notif)
    }
```

Note: `notificationPopup.onNotificationReceived(notif)` still runs regardless of DND —
notifications still land in the notification list/popup, DND only suppresses the toast
pop-up, matching how DND behaves on every mainstream desktop (silence the interruption,
don't discard the record).

- [ ] **Step 5: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/tabs/NotificationsSettingsTab.qml bar/NotificationToast.qml shell.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 6: Manual verification**

Send a test notification (`notify-send "Test" "Hello"`), confirm the toast disappears
after the configured duration when changed in Settings. Toggle "Do not disturb" on,
send another test notification, confirm no toast appears but the notification still
shows up in the bell/notification popup.

- [ ] **Step 7: Commit**

```bash
yadm add Settings/tabs/NotificationsSettingsTab.qml bar/NotificationToast.qml shell.qml
yadm commit -m "Wire up Notifications settings tab (toast duration, DND)"
```

---

## Task 20: Control Center settings tab

**Files:**
- Modify: `Settings/tabs/ControlCenterSettingsTab.qml`
- Modify: `bar/commandcenter/OverviewTab.qml`

**Interfaces:**
- Consumes: `settings.ccShowWifi`/`.ccShowBluetooth`/`.ccShowAudio`/`.ccShowDisplay`/
  `.ccShowNightLight`.

- [ ] **Step 1: Find the toggle tiles in `OverviewTab.qml`**

```bash
grep -n "Wi-Fi\|Wifi\|Bluetooth\|Audio\|Display\|Night Light" bar/commandcenter/OverviewTab.qml
```

Locate each tile's root `Rectangle`/delegate.

- [ ] **Step 2: Replace the stub tab**

```qml
// Settings/tabs/ControlCenterSettingsTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 20

    Text {
      text: "Control Center"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 20
      font.weight: Font.Bold
    }
    Text {
      text: "Choose which quick-toggle tiles appear."
      color: palette ? palette.muted : "#6e6a86"
      font.pixelSize: 12
      Layout.bottomMargin: 8
    }

    SettingsToggle {
      label: "Wi-Fi tile"; palette: root.palette
      checked: settings ? settings.ccShowWifi : true
      onToggled: function(v) { if (settings) { settings.ccShowWifi = v; settings.save() } }
    }
    SettingsToggle {
      label: "Bluetooth tile"; palette: root.palette
      checked: settings ? settings.ccShowBluetooth : true
      onToggled: function(v) { if (settings) { settings.ccShowBluetooth = v; settings.save() } }
    }
    SettingsToggle {
      label: "Audio tile"; palette: root.palette
      checked: settings ? settings.ccShowAudio : true
      onToggled: function(v) { if (settings) { settings.ccShowAudio = v; settings.save() } }
    }
    SettingsToggle {
      label: "Display tile"; palette: root.palette
      checked: settings ? settings.ccShowDisplay : true
      onToggled: function(v) { if (settings) { settings.ccShowDisplay = v; settings.save() } }
    }
    SettingsToggle {
      label: "Night Light tile"; palette: root.palette
      checked: settings ? settings.ccShowNightLight : true
      onToggled: function(v) { if (settings) { settings.ccShowNightLight = v; settings.save() } }
    }

    Item { Layout.fillHeight: true }
  }
}
```

- [ ] **Step 3: Gate each tile's visibility in `OverviewTab.qml`**

For each tile `Rectangle` located in Step 1, add (or extend, if it already has a
`visible:` binding for other reasons) `visible: !root.settings || root.settings.ccShowWifi`
(and the matching property for each of the other four tiles). `OverviewTab.qml`'s root
`property QtObject root: null` refers to the `CommandCenter` instance, per the same
pattern as `MediaTab.qml` (Task 3) — so `CommandCenter.qml` needs a
`readonly property QtObject settings: shell.settings` alias added (mirroring the MPRIS
alias pattern from Task 3) for `OverviewTab.qml` to reach it as `root.settings`.

- [ ] **Step 4: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/tabs/ControlCenterSettingsTab.qml bar/commandcenter/OverviewTab.qml bar/CommandCenter.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 5: Manual verification**

Toggle "Wi-Fi tile" off in Settings, open Control Center's Overview tab, confirm the
Wi-Fi tile is gone and the remaining tiles reflow to fill the space.

- [ ] **Step 6: Commit**

```bash
yadm add Settings/tabs/ControlCenterSettingsTab.qml bar/commandcenter/OverviewTab.qml bar/CommandCenter.qml
yadm commit -m "Wire up Control Center settings tab (per-tile visibility)"
```

---

## Task 21: Lock Screen settings tab

**Files:**
- Modify: `Settings/tabs/LockScreenSettingsTab.qml`

**Interfaces:**
- Consumes: `settings.lockShowMedia`/`.lockClockSize`.
- Produces: nothing new — Task 22 (`LockScreen.qml` redesign) is the consumer; this
  task only builds the tab UI since Task 22 needs to already know the property names
  it'll bind to (it does, from `Settings.qml`, Task 5).

- [ ] **Step 1: Replace the stub**

```qml
// Settings/tabs/LockScreenSettingsTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 20

    Text {
      text: "Lock Screen"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 20
      font.weight: Font.Bold
    }

    SettingsToggle {
      label: "Show media widget"; palette: root.palette
      checked: settings ? settings.lockShowMedia : true
      onToggled: function(v) { if (settings) { settings.lockShowMedia = v; settings.save() } }
    }
    SettingsSlider {
      label: "Clock size"; palette: root.palette; unit: "px"
      min: 48; max: 120
      value: settings ? settings.lockClockSize : 72
      onChanged: function(v) { if (settings) { settings.lockClockSize = v; settings.save() } }
    }

    Item { Layout.fillHeight: true }
  }
}
```

- [ ] **Step 2: Lint**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/tabs/LockScreenSettingsTab.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 3: Manual verification**

Deferred to Task 22 (nothing visually observable from this tab alone until
`LockScreen.qml` consumes these two properties).

- [ ] **Step 4: Commit**

```bash
yadm add Settings/tabs/LockScreenSettingsTab.qml
yadm commit -m "Add Lock Screen settings tab"
```

---

## Task 22: System settings tab

**Files:**
- Modify: `Settings/tabs/SystemSettingsTab.qml`
- Modify: `bar/CommandCenter.qml`

**Interfaces:**
- Consumes: `settings.weatherCity`/`.systemShowUptime`.

- [ ] **Step 1: Replace the stub**

```qml
// Settings/tabs/SystemSettingsTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 20

    Text {
      text: "System"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 20
      font.weight: Font.Bold
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 8
      Text {
        text: "Weather city"
        color: palette ? palette.text : "#e0def4"
        font.pixelSize: 13
        Layout.fillWidth: true
      }
      TextInput {
        text: settings ? settings.weatherCity : "Asunción"
        color: palette ? palette.text : "#e0def4"
        font.pixelSize: 13
        Layout.preferredWidth: 160
        onEditingFinished: if (settings) { settings.weatherCity = text; settings.save() }
      }
    }

    SettingsToggle {
      label: "Show uptime"; palette: root.palette
      checked: settings ? settings.systemShowUptime : true
      onToggled: function(v) { if (settings) { settings.systemShowUptime = v; settings.save() } }
    }

    Item { Layout.fillHeight: true }
  }
}
```

- [ ] **Step 2: Wire `weatherCity` into `CommandCenter.qml`**

```bash
grep -n "weatherCity" bar/CommandCenter.qml
```

Change the hardcoded `property string weatherCity: "Asunción"` (line 27, per the
earlier read) to `readonly property string weatherCity: shell.settings.weatherCity`
(mirroring the alias pattern from Tasks 3/20). Confirm whatever weather-fetch `Process`
elsewhere in this file already uses `root.weatherCity`/`weatherCity` as a query
parameter continues to do so unchanged — only the property's source of truth changes,
not its name or type.

- [ ] **Step 3: Wire `systemShowUptime` into wherever `uptimeText` is displayed**

```bash
grep -rn "uptimeText" bar/
```

Wrap that display's `visible:` (or the containing row's) with `visible: !root.settings
|| root.settings.systemShowUptime` (`root` = `CommandCenter` instance, `settings`
alias already added in Task 20 Step 3).

- [ ] **Step 4: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/tabs/SystemSettingsTab.qml bar/CommandCenter.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 5: Manual verification**

Change "Weather city" to a different city, open Control Center's Weather tab, confirm
it now fetches/displays weather for the new city. Toggle "Show uptime" off, confirm the
uptime text disappears from wherever it's shown.

- [ ] **Step 6: Commit**

```bash
yadm add Settings/tabs/SystemSettingsTab.qml bar/CommandCenter.qml
yadm commit -m "Wire up System settings tab (weather city, uptime toggle)"
```

---

## Task 23: Launcher settings tab (read-only)

**Files:**
- Modify: `Settings/tabs/LauncherSettingsTab.qml`

**Interfaces:**
- Consumes: nothing from `Settings.qml` (no editable state, per the design's explicit
  decision that Niri keybind editing is out of scope).

- [ ] **Step 1: Find the actual configured keybind**

```bash
grep -n "launcher\|qslauncher" ~/.config/niri/config.kdl
```

- [ ] **Step 2: Replace the stub with a static display of whatever Step 1 found**

```qml
// Settings/tabs/LauncherSettingsTab.qml
import QtQuick
import QtQuick.Layouts
import ".."

Item {
  id: root
  property QtObject settings: null
  property QtObject palette: null

  ColumnLayout {
    anchors.fill: parent
    spacing: 20

    Text {
      text: "Launcher"
      color: palette ? palette.text : "#e0def4"
      font.pixelSize: 20
      font.weight: Font.Bold
    }
    Text {
      text: "The launcher has no on-screen trigger — it opens via a Niri keybind."
      color: palette ? palette.muted : "#6e6a86"
      font.pixelSize: 12
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 40
      radius: 8
      color: palette ? palette.overlay : "#26233a"

      Text {
        anchors.centerIn: parent
        text: "Configured in ~/.config/niri/config.kdl"
        color: palette ? palette.text : "#e0def4"
        font.pixelSize: 12
      }
    }

    Item { Layout.fillHeight: true }
  }
}
```

Left generic (pointing at the config file rather than echoing the exact keybind
string) since Step 1's grep result isn't known until this task actually runs —
whoever executes this task should replace the placeholder `Text` in Step 2 with the
literal keybind found in Step 1 if one exists, e.g. `"Mod+D → launcher (Niri
keybind)"`. This is the one spot in the whole plan where the exact final string can't
be hardcoded in advance, since it depends on reading Rodrigo's actual Niri config at
execution time — everything else in this file is real, final content.

- [ ] **Step 3: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint Settings/tabs/LauncherSettingsTab.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 4: Commit**

```bash
yadm add Settings/tabs/LauncherSettingsTab.qml
yadm commit -m "Add read-only Launcher settings tab"
```

---

## Task 24: Lock screen redesign

**Files:**
- Modify: `bar/LockScreen.qml`

**Interfaces:**
- Consumes: `NotchPalette` (Task 4), `settings.lockShowMedia`/`.lockClockSize` (Task
  5/21), `shell.mprisTitle`/`.mprisArtist` (Task 3).

- [ ] **Step 1: Delete the dead non-Niri fallback block**

Delete the entire `Loader { active: !config.isNiri && root.locked ... }` block — this
is lines 398–527 of the file as read earlier (everything from `Loader {` to its
closing `}` right before the file's final `}`). `config.isNiri` is hardcoded `true` in
`Config.qml`, so this branch never executes; confirmed dead code.

- [ ] **Step 2: Reorder date above clock, resize clock, restyle with `NotchPalette`**

Add the import at the top of `bar/LockScreen.qml`:

```qml
import "../config"
```

Add `property QtObject settings: null` alongside the existing `colors_`/`config`
properties (line 12–13), and instantiate the palette near the top of the file (after
the existing `readonly property color accentGreen: ...` block):

```qml
  NotchPalette { id: palette }
```

Inside the `WlSessionLock.surface`'s `Column` (currently starting at line 192), swap
the order of the two `Text` blocks — date first, then clock — and apply the new
sizing/coloring. Replace the existing clock `Text` (lines 244–256) and date `Text`
(lines 258–269) with:

```qml
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
              var d = root.now
              var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
              var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
              return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate()
            }
            color: palette.muted
            font.family: "Roboto"
            font.pixelSize: 18
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
              var d = root.now
              return d.getHours().toString().padStart(2, "0") + ":" + d.getMinutes().toString().padStart(2, "0")
            }
            color: palette.text
            font.family: "Roboto"
            font.pixelSize: root.settings ? root.settings.lockClockSize : 72
            font.weight: Font.Bold
          }
```

- [ ] **Step 3: Hide the password field until first keypress**

Wrap the existing password `Rectangle` (lines 273–314) in a `visible:` gate and add a
hint `Text` that shows instead when hidden. Add a new property near the top of the
file: `property bool passwordFieldRevealed: false`. Wrap the whole `Rectangle` block:

```qml
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: 48
            radius: 12
            color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.2)
            visible: root.passwordFieldRevealed

            TextInput {
              // unchanged from the existing file — same id, same bindings
              anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
              color: palette.text
              font.family: "Roboto"
              font.pixelSize: 18
              text: root.lockInputText
              echoMode: TextInput.Password
              passwordCharacter: "●"
              focus: root.locked && root.passwordFieldRevealed
              activeFocusOnPress: true
              cursorVisible: true
              verticalAlignment: Qt.AlignVCenter
              selectByMouse: true

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                acceptedButtons: Qt.NoButton
              }

              onTextChanged: {
                root.lockPassword = text
                root.lockInputText = text
                root.lockError = ""
              }

              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  root.tryLockAuth()
                }
              }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Press Any Key to Enter Password"
            color: palette.muted
            font.family: "Roboto"
            font.pixelSize: 14
            visible: !root.passwordFieldRevealed
          }
```

Add a screen-wide key catcher to flip `passwordFieldRevealed` on first keypress — in
the `WlSessionLockSurface { ... }` block, alongside the existing `MouseArea`
(lines 164–169), add:

```qml
        Item {
          anchors.fill: parent
          focus: true
          Keys.onPressed: function(event) {
            if (!root.passwordFieldRevealed) {
              root.passwordFieldRevealed = true
              event.accepted = false // let the keypress still reach the TextInput if it's a real character
            }
          }
        }
```

Reset `passwordFieldRevealed = false` wherever `lockScreen()` already resets other
per-session state (the existing `clearPassword()` function, lines 48–52, is the
natural place — add `root.passwordFieldRevealed = false` as its last line) so each new
lock starts hidden again.

- [ ] **Step 4: Add battery/wifi status pills, top-right**

Add near the top of the `WlSessionLockSurface` block (as a sibling to the existing
`Column`, not inside it — positioned independently in the corner):

```qml
        RowLayout {
          anchors.top: parent.top
          anchors.right: parent.right
          anchors.margins: 16
          spacing: 8

          Text {
            text: Math.round(UPower.displayDevice.percentage * 100) + "%"
            color: palette.text
            font.pixelSize: 12
            visible: UPower.displayDevice && UPower.displayDevice.ready
          }
        }
```

This requires `import Quickshell.Services.UPower` and `import QtQuick.Layouts` added
to the top of `bar/LockScreen.qml` (`Quickshell.Services.UPower` is already imported in
`shell.qml` for `batteryAlert`, confirming it's available in this Quickshell build).
Wifi status is intentionally omitted from this pill row — there's no existing wifi
Process/state accessible from `LockScreen.qml` the way `UPower` is globally available,
and wiring one up is a bigger addition (a new persistent `nmcli`/`iwctl` poller) than
this task's scope justifies for a lock-screen-only glance indicator; battery-only for
now, flagged rather than faked.

- [ ] **Step 5: Wire in the media widget (if `lockShowMedia`)**

Add near the top of the `Column`, before the date/clock text (so it appears above
them, matching the video's layout where a mini media bar sits at the very top):

```qml
          RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            visible: (!root.settings || root.settings.lockShowMedia) && shell.mprisTitle !== ""

            Text {
              text: shell.mprisTitle + " — " + shell.mprisArtist
              color: palette.muted
              font.pixelSize: 12
            }
          }
```

- [ ] **Step 6: Update `shell.qml`'s `LockScreen` instantiation**

```qml
  LockScreen {
    id: lockScreen
    colors_: colors
    config: cfg
    settings: settings
  }
```

- [ ] **Step 7: Lint and reload-check**

```bash
cd /home/mura/.config/quickshell
qmllint bar/LockScreen.qml shell.qml
touch shell.qml
```

Expected: no lint errors, fresh `Configuration Loaded`, no warnings.

- [ ] **Step 8: Manual verification**

```bash
loginctl lock-session
```

Confirm: date above clock, larger clock, no password field visible until a key is
pressed (then it appears and accepts input), battery percentage visible top-right,
media title/artist visible at top if something is playing, and — critically — PAM auth
still unlocks correctly, fprintd retry still fires (if a fingerprint reader is
present), and all three power buttons (suspend/reboot/poweroff) still work. Unlock to
confirm `passwordFieldRevealed` resets for next time.

- [ ] **Step 9: Commit**

```bash
yadm add bar/LockScreen.qml shell.qml
yadm commit -m "Redesign lock screen: date/clock reorder, press-any-key password, status pills"
```

---

## Task 25: Full regression pass

**Files:** none (verification only)

- [ ] **Step 1: Lint everything touched by this plan**

```bash
cd /home/mura/.config/quickshell
qmllint bar/*.qml bar/notch/*.qml bar/commandcenter/*.qml config/*.qml Settings/*.qml Settings/tabs/*.qml shell.qml
```

Expected: zero errors across every file.

- [ ] **Step 2: Horizontal mode — full walkthrough**

Idle notch (clock only) → hover (media + clock + calendar) → click (Control Center
opens, power button works, settings gear opens Settings window) → each of the 10
Settings tabs changes something observable → Niri keybind opens launcher, anchored
under the notch.

- [ ] **Step 3: Vertical mode — full walkthrough**

`echo vertical > ~/.config/quickshell/layout`, reload: every original `Bar.qml`
indicator and popup (wifi/bt/audio/brightness/battery/tray/menu/notification/calendar)
still works exactly as before this plan started. Set back to `horizontal` when done.

- [ ] **Step 4: Lock screen**

`loginctl lock-session`: full checklist from Task 24 Step 8.

- [ ] **Step 5: Settings persistence survives a real Quickshell restart**

```bash
pkill -f "quickshell -vv"
quickshell -vv &
```

(Or whatever the actual established restart command is for this environment — check
existing session memory/notes for the correct kill/relaunch sequence before running,
since a bare `pkill` may not match how Quickshell is normally supervised here.) After
restart, confirm every Settings value changed during this plan's execution is still in
effect (read from `settings.json`, not defaults).

- [ ] **Step 6: Final commit (if Step 1–5 surfaced any fixes)**

```bash
yadm add -A .config/quickshell
yadm commit -m "Fix regressions found in full verification pass"
```

(Only run if fixes were actually needed — if everything passed clean, there's nothing
to commit here.)
