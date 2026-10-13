# elena sidebar core (phase 2a) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Under the elena style, `qs ipc call shell popup sidebar` opens a left-edge overlay panel with clock + weekday row, battery pill, weather, media controls and three level bars.

**Architecture:** `bar/Sidebar.qml` extends the existing `PopupBase` (layer-shell window with Esc/click-away dismissal) and joins the single-open-popup model (`bar.openPopup === "sidebar"`). Its content, `bar/sidebar/SidebarContent.qml`, is a column of small card components fed by the existing singleton services. Services get one extra `sidebarActive` flag so they poll while the sidebar is open without fighting other popups' `popupActive` bindings.

**Tech Stack:** Quickshell/QML, `.pragma library` JS, node tests, bash + Python PIL render check.

## Global Constraints

- VCS is yadm (no `.git`): `yadm add <paths>`, `yadm commit`. Never `--no-verify`. Never stage `settings.json` (already modified, unrelated).
- Spec: `docs/superpowers/specs/2026-10-12-elena-sidebar-design.md`.
- Sidebar only works under `Config.elenaTheme`; in every other style `togglePopupByName("sidebar")` returns false and nothing changes.
- Panel width 320 px; top margin `Config.barWidth + Config.spacingMedium` (barWidth is 8 under elena); left and bottom margins `Config.spacingMedium`; `ExclusionMode.Ignore` (overlay, no reserved space).
- Weekday row: Monday first, letters `M T W T F S S`, today circled in `Colors.secondary`.
- Cards use `Colors.surfaceContainer`, radius `Config.shapeLarge`, text `Colors.fgSurface`, accents `primary` / `secondary` / `tertiary` and their `fg*` on-colors.
- Reuse `IconButton` / `IconGlyph` from `bar/primitives`; do not write new icon code. Clock honors `Settings.clock24h`.
- Live testing hazards (see `quickshell-testing-gotchas`, `quickshell-elena-theme` memory): QML saves reload the running shell and can wedge `qs ipc`; cold-restart with `systemctl --user restart quickshell.service` (the user runs it) before live measurement; switch style in memory only (`qs ipc call shell style elena ""`) and restore `material3` + `dismissPopups` right after; send no keystrokes with `wtype`; check `jq -r .themeStyle settings.json` afterward.

## File Structure

| File | Responsibility |
|---|---|
| `config/Weekdays.js` (new) | `weekRow(date)`: pure Monday-first week row |
| `tests/sidebar/test.mjs` (new) | Gate test for `weekRow` |
| `bar/sidebar/Card.qml` (new) | Rounded surface shared by cards |
| `bar/sidebar/ClockCard.qml` (new) | Time, stacked-dot separator, weekday row |
| `bar/sidebar/BatteryPill.qml` (new) | Battery percent pill (hidden without a battery) |
| `bar/sidebar/WeatherCard.qml` (new) | Description + temperature |
| `bar/sidebar/MediaCard.qml` (new) | Title, artist, prev/play/next |
| `bar/sidebar/LevelBar.qml` (new) | One vertical level bar with mute icon |
| `bar/sidebar/LevelBars.qml` (new) | Volume, mic, brightness bars |
| `bar/sidebar/SidebarContent.qml` (new) | Column of the five cards |
| `tests/sidebar/shell.qml`, `scripts/sidebar-render.sh` (new) | Render check |
| `bar/Sidebar.qml` (new) | `PopupBase` window around the content |
| `bar/Bar.qml` (mod) | `togglePopupByName("sidebar")` special case |
| `shell.qml` (mod) | Instantiate `Sidebar` |
| `config/{Media,Weather,Audio,Brightness}Service.qml` (mod) | `sidebarActive` flag |

---

### Task 1: weekRow (gate-tested)

**Files:**
- Create: `config/Weekdays.js`, `tests/sidebar/test.mjs`

**Interfaces:**
- Produces: `Weekdays.weekRow(date) -> [{letter: string, isToday: bool}]` (7 entries, Monday first).

- [ ] **Step 1: Write the failing test** `tests/sidebar/test.mjs`

```js
// Gate test: node tests/sidebar/test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/Weekdays.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const { weekRow } = new Function(src + "; return { weekRow }")()

const letters = row => row.map(d => d.letter).join("")
const todayIdx = row => row.map(d => d.isToday)
  .reduce((acc, t, i) => t ? acc.concat(i) : acc, [])

// Local-time constructors (month is 0-based) keep this timezone independent.
const cases = [
  [new Date(2026, 9, 12, 12, 0), 0, "Monday"],
  [new Date(2026, 9, 11, 23, 59), 6, "Sunday"],
  [new Date(2026, 9, 31, 12, 0), 5, "Saturday, month end"],
  [new Date(2026, 10, 1, 0, 0), 6, "Sunday, month start"],
  [new Date(2026, 11, 31, 12, 0), 3, "Thursday, year end"],
  [new Date(2027, 0, 1, 0, 0), 4, "Friday, year start"],
  [new Date(2026, 2, 8, 2, 30), 6, "Sunday, US DST start"],
  [new Date(2026, 9, 14, 12, 0), 2, "Wednesday"],
]
for (const [date, idx, name] of cases) {
  const row = weekRow(date)
  assert.equal(row.length, 7, name)
  assert.equal(letters(row), "MTWTFSS", name)
  assert.deepEqual(todayIdx(row), [idx], name)
}
// An invalid or missing date marks nothing and still returns 7 letters.
for (const bad of [new Date(NaN), undefined, null, "2026-10-12", 5]) {
  const row = weekRow(bad)
  assert.equal(letters(row), "MTWTFSS")
  assert.deepEqual(todayIdx(row), [])
}
console.log("sidebar: ok")
```

- [ ] **Step 2: Run, expect FAIL**

Run: `node tests/sidebar/test.mjs`
Expected: throws ENOENT for `config/Weekdays.js`.

- [ ] **Step 3: Create `config/Weekdays.js`**

```js
.pragma library

var LETTERS = ["M", "T", "W", "T", "F", "S", "S"]

// Monday-first week row for the sidebar clock. `date` marks today; anything
// that is not a valid Date marks nothing.
function weekRow(date) {
  var today = (date instanceof Date && !isNaN(date.getTime()))
    ? (date.getDay() + 6) % 7
    : -1
  return LETTERS.map(function(letter, i) {
    return { letter: letter, isToday: i === today }
  })
}
```

- [ ] **Step 4: Run, expect PASS**

Run: `node tests/sidebar/test.mjs`
Expected: `sidebar: ok`.

- [ ] **Step 5: Commit**

```bash
yadm add config/Weekdays.js tests/sidebar/test.mjs
yadm commit -m "elena sidebar: weekRow with gate test"
```

---

### Task 2: Display cards (Card, ClockCard, BatteryPill, WeatherCard)

**Files:**
- Create: `bar/sidebar/Card.qml`, `bar/sidebar/ClockCard.qml`, `bar/sidebar/BatteryPill.qml`, `bar/sidebar/WeatherCard.qml`

**Interfaces:**
- Consumes: `Weekdays.weekRow` (Task 1), `ClockTiming.nextInterval(now, showSeconds)` (`config/ClockTiming.js`), `BatteryService.pct/.batteryDevice`, `WeatherService.desc/.temp/.statusMessage`, `IconGlyph` (`iconLabel`, `iconColor`, `iconSize`).
- Produces: `Card` (a `Rectangle`: `color: Colors.surfaceContainer`, `radius: Config.shapeLarge`); the three cards each report `implicitHeight` so a `ColumnLayout` can size them.

- [ ] **Step 1: Create `bar/sidebar/Card.qml`**

```qml
import QtQuick
import "../../config"

// Rounded surface shared by the sidebar cards.
Rectangle {
  color: Colors.surfaceContainer
  radius: Config.shapeLarge
}
```

- [ ] **Step 2: Create `bar/sidebar/ClockCard.qml`**

```qml
import QtQuick
import "../../config"
import "../../config/ClockTiming.js" as ClockTiming
import "../../config/Weekdays.js" as Weekdays

Card {
  id: root

  property date now: new Date()

  implicitHeight: col.implicitHeight + Config.spacingLarge * 2

  Timer {
    interval: ClockTiming.nextInterval(root.now, false)
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  Column {
    id: col
    anchors.centerIn: parent
    spacing: Config.spacingMedium

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.spacingMedium

      Text {
        text: Qt.formatTime(root.now, Settings.clock24h ? "HH" : "h")
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: 56
        font.weight: Font.Medium
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Repeater {
          model: [Colors.secondary, Colors.tertiary, Colors.primary]
          Rectangle { width: 8; height: 8; radius: 2; color: modelData }
        }
      }

      Text {
        text: Qt.formatTime(root.now, "mm")
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: 56
        font.weight: Font.Medium
      }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.spacingSmall

      Repeater {
        model: Weekdays.weekRow(root.now)

        Item {
          width: 30
          height: 30

          Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.secondary
            visible: modelData.isToday
          }
          Text {
            anchors.centerIn: parent
            text: modelData.letter
            color: modelData.isToday ? Colors.fgSecondary : Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.weight: Font.Medium
          }
        }
      }
    }
  }
}
```

- [ ] **Step 3: Create `bar/sidebar/BatteryPill.qml`**

```qml
import QtQuick
import Quickshell.Services.UPower
import "../../config"
import "../primitives"

Rectangle {
  id: root

  readonly property bool present: BatteryService.pct >= 0
  readonly property bool charging: BatteryService.batteryDevice !== null
    && BatteryService.batteryDevice.state === UPowerDeviceState.Charging

  visible: root.present
  implicitHeight: 52
  radius: height / 2
  color: Colors.tertiary

  Row {
    anchors.centerIn: parent
    spacing: Config.spacingSmall

    IconGlyph {
      anchors.verticalCenter: parent.verticalCenter
      iconLabel: root.charging ? "bolt" : "battery_full"
      iconColor: Colors.fgTertiary
      iconSize: 20
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Math.round(BatteryService.pct) + "%"
      color: Colors.fgTertiary
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
      font.weight: Font.Medium
    }
  }
}
```

- [ ] **Step 4: Create `bar/sidebar/WeatherCard.qml`**

```qml
import QtQuick
import "../../config"

Card {
  id: root

  implicitHeight: col.implicitHeight + Config.spacingLarge * 2

  Column {
    id: col
    anchors.centerIn: parent
    spacing: 4

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: WeatherService.desc !== "" ? WeatherService.desc : WeatherService.statusMessage
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: WeatherService.temp
      color: Colors.tertiary
      font.family: Config.fontFamily
      font.pixelSize: 28
      font.weight: Font.Medium
    }
  }
}
```

- [ ] **Step 5: Lint and commit**

Run: `bash scripts/m3-qmllint-gate.sh` (it lints `bar/*.qml`; also run `qmllint bar/sidebar/*.qml` directly and fix any import-path errors).
Expected: exit 0 / no errors.

```bash
yadm add bar/sidebar/Card.qml bar/sidebar/ClockCard.qml bar/sidebar/BatteryPill.qml bar/sidebar/WeatherCard.qml
yadm commit -m "elena sidebar: clock, battery and weather cards"
```

---

### Task 3: Interactive cards (MediaCard, LevelBar, LevelBars)

**Files:**
- Create: `bar/sidebar/MediaCard.qml`, `bar/sidebar/LevelBar.qml`, `bar/sidebar/LevelBars.qml`

**Interfaces:**
- Consumes: `Card` (Task 2), `MediaService.status/.title/.artist`, `AudioService.volume/.muted/.micVolume/.micMuted/.setVolume(v)/.toggleMute()/.setMicVolume(v)/.toggleMicMute()` (v is 0..1), `BrightnessService.pct` (0..100) and `.setBrightness(pct)`, `IconButton` (`size`, `iconSize`, `iconLabel`, `accessibleName`, `tooltipText`, signal `clicked`).
- Produces: `LevelBar { value: real 0..1; accent: color; iconLabel: string; muted: bool; accessibleName: string; signal moved(real value); signal iconClicked() }`.

- [ ] **Step 1: Create `bar/sidebar/MediaCard.qml`**

```qml
import QtQuick
import Quickshell
import "../../config"
import "../primitives"

Card {
  id: root

  readonly property bool hasPlayer: MediaService.status !== "NoPlayer"
  readonly property string control: Quickshell.env("HOME")
    + "/.config/quickshell/scripts/mpris_control.py"

  implicitHeight: col.implicitHeight + Config.spacingLarge * 2

  Column {
    id: col
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Config.spacingLarge
    anchors.verticalCenter: parent.verticalCenter
    spacing: Config.spacingSmall

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      text: root.hasPlayer
        ? (MediaService.title !== "" ? MediaService.title : "Unknown title")
        : "Nothing playing"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
      font.weight: Font.Medium
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      visible: root.hasPlayer && MediaService.artist !== ""
      text: MediaService.artist
      color: Colors.tertiary
      font.family: Config.fontFamily
      font.pixelSize: Config.typeBodyMediumSize
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.spacingSmall

      IconButton {
        size: 40
        iconSize: 20
        iconLabel: "skip_previous"
        accessibleName: "Previous track"
        tooltipText: "Previous track"
        onClicked: Quickshell.execDetached([root.control, "prev"])
      }
      IconButton {
        size: 48
        iconSize: 22
        iconLabel: MediaService.status === "Playing" ? "pause" : "play_arrow"
        accessibleName: MediaService.status === "Playing" ? "Pause" : "Play"
        tooltipText: MediaService.status === "Playing" ? "Pause" : "Play"
        onClicked: Quickshell.execDetached([root.control, "play"])
      }
      IconButton {
        size: 40
        iconSize: 20
        iconLabel: "skip_next"
        accessibleName: "Next track"
        tooltipText: "Next track"
        onClicked: Quickshell.execDetached([root.control, "next"])
      }
    }
  }
}
```

- [ ] **Step 2: Create `bar/sidebar/LevelBar.qml`**

```qml
import QtQuick
import "../../config"
import "../primitives"

// Vertical level bar: click or drag the track to set the level; the icon
// underneath is a button (mute toggle for audio, inert for brightness).
Item {
  id: root

  property real value: 0
  property color accent: Colors.primary
  property string iconLabel: ""
  property bool muted: false
  property string accessibleName: ""

  signal moved(real value)
  signal iconClicked()

  implicitWidth: 40
  implicitHeight: 160

  Rectangle {
    id: track
    anchors.top: parent.top
    anchors.bottom: icon.top
    anchors.bottomMargin: Config.spacingSmall
    anchors.horizontalCenter: parent.horizontalCenter
    width: 18
    radius: width / 2
    color: Colors.surfaceContainerHighest

    Rectangle {
      anchors.bottom: parent.bottom
      width: parent.width
      height: Math.max(parent.width, parent.height * Math.max(0, Math.min(1, root.value)))
      radius: width / 2
      color: root.muted ? Colors.outline : root.accent
    }

    MouseArea {
      anchors.fill: parent
      anchors.leftMargin: -10
      anchors.rightMargin: -10
      function setFrom(mouse) {
        var p = mapToItem(track, mouse.x, mouse.y)
        var v = Math.max(0, Math.min(1, 1 - p.y / track.height))
        // Skip sub-1% jitter so a drag does not spawn a process per pixel.
        if (Math.abs(v - root.value) >= 0.01) root.moved(v)
      }
      onPressed: function(mouse) { setFrom(mouse) }
      onPositionChanged: function(mouse) { if (pressed) setFrom(mouse) }
    }
  }

  IconButton {
    id: icon
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    size: 32
    iconSize: 18
    iconLabel: root.iconLabel
    accessibleName: root.accessibleName
    tooltipText: root.accessibleName
    onClicked: root.iconClicked()
  }
}
```

- [ ] **Step 3: Create `bar/sidebar/LevelBars.qml`**

```qml
import QtQuick
import "../../config"

Card {
  id: root

  implicitHeight: 200

  Row {
    anchors.centerIn: parent
    spacing: Config.spacingLarge * 1.5

    LevelBar {
      height: root.height - Config.spacingLarge * 2
      value: AudioService.volume
      muted: AudioService.muted
      accent: Colors.primary
      iconLabel: AudioService.muted ? "volume_off" : "volume_up"
      accessibleName: "Volume"
      onMoved: function(v) { AudioService.setVolume(v) }
      onIconClicked: AudioService.toggleMute()
    }
    LevelBar {
      height: root.height - Config.spacingLarge * 2
      value: AudioService.micVolume
      muted: AudioService.micMuted
      accent: Colors.secondary
      iconLabel: AudioService.micMuted ? "mic_off" : "mic"
      accessibleName: "Microphone"
      onMoved: function(v) { AudioService.setMicVolume(v) }
      onIconClicked: AudioService.toggleMicMute()
    }
    LevelBar {
      height: root.height - Config.spacingLarge * 2
      value: BrightnessService.pct / 100
      accent: Colors.tertiary
      iconLabel: "brightness_medium"
      accessibleName: "Brightness"
      onMoved: function(v) { BrightnessService.setBrightness(v * 100) }
    }
  }
}
```

- [ ] **Step 4: Lint and commit**

Run: `qmllint bar/sidebar/*.qml` then `bash scripts/m3-qmllint-gate.sh`
Expected: no errors.

```bash
yadm add bar/sidebar/MediaCard.qml bar/sidebar/LevelBar.qml bar/sidebar/LevelBars.qml
yadm commit -m "elena sidebar: media card and level bars"
```

---

### Task 4: Content column + render check

**Files:**
- Create: `bar/sidebar/SidebarContent.qml`, `tests/sidebar/shell.qml`, `scripts/sidebar-render.sh`

**Interfaces:**
- Consumes: the five cards (Tasks 2-3).
- Produces: `SidebarContent` (`ColumnLayout`, no window; used by `Sidebar.qml` in Task 5 and by the render check).

- [ ] **Step 1: Write the failing render check** `scripts/sidebar-render.sh`

```bash
#!/usr/bin/env bash
# Usage: sidebar-render.sh [quickshell-root]
# Renders SidebarContent under the elenapam palette in a scratch HOME, fails on
# any QML error in the log, and pixel-checks the card surface and today's circle.
set -euo pipefail
root=$(realpath "${1:-$(dirname "$0")/..}")
home=$(mktemp -d); trap 'rm -rf "$home"' EXIT
mkdir -p "$home/.config/quickshell" "$home/cfg"
cp -r "$root/config" "$root/bar" "$root/resources" "$home/cfg/"
cp "$root/tests/sidebar/shell.qml" "$home/cfg/shell.qml"
printf '{"themeStyle":"elena","colorSource":"fixed","colorPalette":"elenapam","colorVariant":"auto","themePreference":2}\n' \
  > "$home/.config/quickshell/settings.json"
HOME="$home" GOLDEN_OUT="$home/sidebar.png" QS_NO_RELOAD_POPUP=1 \
  timeout 30 qs -p "$home/cfg/shell.qml" >"$home/qs.log" 2>&1 || true
[ -s "$home/sidebar.png" ] || { echo "FAIL: no render"; tail -8 "$home/qs.log"; exit 1; }
if grep -E "(TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR)" "$home/qs.log" \
   | grep -v "Cannot find the mpris\|dbus" | head -5 | grep -q .; then
  echo "FAIL: QML errors"; grep -E "(TypeError|ReferenceError|is not a type|is not installed|Cannot assign|Unable to assign|ERROR)" "$home/qs.log" | head -8; exit 1
fi
python3 -I - "$home/sidebar.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
w, h = im.size
assert (w, h) == (320, 640), f"size {w}x{h}"
card = (0x23, 0x2a, 0x37)       # elenapam surface_container
secondary = (0xf0, 0x62, 0x92)  # today's circle
def near(a, b, t=3): return all(abs(a[i] - b[i]) <= t for i in range(3))
px = list(im.getdata())
n_card = sum(near(p, card) for p in px)
n_sec = sum(near(p, secondary) for p in px)
print(f"card px {n_card}, secondary px {n_sec}")
assert n_card >= 10000, "card surfaces missing"
assert 300 <= n_sec <= 4000, "today's circle missing or wrong color"
print("sidebar render: ok")
PY
```

`tests/sidebar/shell.qml`:

```qml
// Copied to the root of a config copy by scripts/sidebar-render.sh.
// Renders SidebarContent on the panel surface and saves $GOLDEN_OUT.
import QtQuick
import Quickshell
import "config"
import "bar/sidebar"

ShellRoot {
  FloatingWindow {
    implicitWidth: 320
    implicitHeight: 640
    color: Colors.surface

    Item {
      id: stage
      width: 320
      height: 640

      Rectangle { anchors.fill: parent; color: Colors.surface }
      SidebarContent {
        anchors.fill: parent
        anchors.margins: Config.spacingMedium
      }
    }

    Timer {
      interval: 2500
      running: true
      onTriggered: stage.grabToImage(function(r) {
        r.saveToFile(Quickshell.env("GOLDEN_OUT"))
        Qt.quit()
      })
    }
  }
}
```

- [ ] **Step 2: Run, expect FAIL**

Run: `bash scripts/sidebar-render.sh`
Expected: FAIL (SidebarContent is not a type).

- [ ] **Step 3: Create `bar/sidebar/SidebarContent.qml`**

```qml
import QtQuick
import QtQuick.Layouts
import "../../config"

// The sidebar's cards in one column. No window: Sidebar.qml hosts it, and the
// render check loads it directly.
ColumnLayout {
  spacing: Config.spacingMedium

  ClockCard { Layout.fillWidth: true }
  BatteryPill { Layout.fillWidth: true }
  WeatherCard { Layout.fillWidth: true }
  MediaCard { Layout.fillWidth: true }
  LevelBars {
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 160
  }
}
```

- [ ] **Step 4: Run, expect PASS**

Run: `bash scripts/sidebar-render.sh`
Expected: `card px N, secondary px M` then `sidebar render: ok`. If the size assertion fails because niri tiled the FloatingWindow (as in the tag-strip check), the stage is already a fixed 320x640 `Item` and `grabToImage` captures only it; if a pixel count is off, copy the PNG to the scratchpad directory, Read it, and adjust the thresholds only with evidence. The `FAIL: QML errors` filter excludes only mpris/dbus noise from a headless session; any other error is a real defect to fix.

- [ ] **Step 5: Lint and commit**

```bash
bash scripts/m3-qmllint-gate.sh
yadm add bar/sidebar/SidebarContent.qml tests/sidebar/shell.qml scripts/sidebar-render.sh
yadm commit -m "elena sidebar: content column and render check"
```

---

### Task 5: Window, toggle, service flags, live check

**Files:**
- Create: `bar/Sidebar.qml`
- Modify: `bar/Bar.qml` (`togglePopupByName`, ~line 237), `shell.qml` (next to `WeatherPopup { }`, ~line 558), `config/MediaService.qml:17-22`, `config/WeatherService.qml:24-27,31,126`, `config/AudioService.qml:18-23`, `config/BrightnessService.qml:12-16`

**Interfaces:**
- Consumes: `SidebarContent` (Task 4), `PopupBase` (`surfaceWidth`, `dismissed`, margins), services.
- Produces: `bar.togglePopupByName("sidebar") -> bool`; `qs ipc call shell popup sidebar`.

- [ ] **Step 1: `sidebarActive` on the four services.** Read each file's region first. In each service add `property bool sidebarActive: false` next to `popupActive`, and include it wherever `popupActive` gates polling or refresh:
  - `MediaService.qml:22`: `readonly property bool active: indicatorActive || popupActive || sidebarActive || waveActive`
  - `WeatherService.qml:27`: `readonly property bool active: indicatorActive || popupActive || sidebarActive`; lines ~31 and ~126, `if (root.popupActive) root.refresh()` becomes `if (root.popupActive || root.sidebarActive) root.refresh()` (read both handlers: they are the on-open refresh paths).
  - `AudioService.qml:22-23`: `sinkActive: indicatorActive || popupActive || sidebarActive`, `micActive: popupActive || sidebarActive`.
  - `BrightnessService.qml:16`: `active: indicatorActive || popupActive || sidebarActive`.
  Then `grep -n popupActive config/*Service.qml` and confirm no remaining condition that should also accept `sidebarActive`.

- [ ] **Step 2: Create `bar/Sidebar.qml`**

```qml
import QtQuick
import Quickshell
import "../config"
import "sidebar"

// Elena's left-edge status panel: an overlay (no reserved space) that joins
// the bar's single-open-popup model through shell.qml.
PopupBase {
  id: root

  surfaceWidth: 320
  anchors.bottom: true
  margins.left: Config.spacingMedium
  margins.top: Config.barWidth + Config.spacingMedium
  margins.bottom: Config.spacingMedium

  // Own flag, not popupActive: the Media/Weather/Audio/Brightness popups bind
  // popupActive to their own visibility and would fight a second writer.
  Binding { target: MediaService; property: "sidebarActive"; value: root.visible }
  Binding { target: WeatherService; property: "sidebarActive"; value: root.visible }
  Binding { target: AudioService; property: "sidebarActive"; value: root.visible }
  Binding { target: BrightnessService; property: "sidebarActive"; value: root.visible }

  SidebarContent {
    anchors.fill: parent
    anchors.margins: Config.spacingMedium
  }
}
```

- [ ] **Step 3: Toggle in `bar/Bar.qml`.** At the top of `togglePopupByName(name)`, before `var widgets = {`:

```qml
    // The sidebar has no anchor widget and only exists under elena.
    if (name === "sidebar") {
      if (!Config.elenaTheme) return false
      openPopup = openPopup === "sidebar" ? "" : "sidebar"
      return true
    }
```

- [ ] **Step 4: Instance in `shell.qml`**, after the `WeatherPopup { }` block:

```qml
  Sidebar {
    visible: bar.openPopup === "sidebar" && Config.elenaTheme && !lockScreen.locked
    screen: bar.screen
    onDismissed: bar.openPopup = ""
  }
```

- [ ] **Step 5: Static checks**

Run: `bash scripts/m3-qmllint-gate.sh && bash scripts/sidebar-render.sh && node tests/sidebar/test.mjs && node tests/elena/test.mjs && scripts/controls-behavior.sh .`
Expected: all pass. (`controls-behavior.sh` runs about 4 minutes.)

- [ ] **Step 6: Commit**

```bash
yadm add bar/Sidebar.qml bar/Bar.qml shell.qml config/MediaService.qml config/WeatherService.qml config/AudioService.qml config/BrightnessService.qml
yadm commit -m "elena sidebar: window, toggle, service flags"
```

- [ ] **Step 7: Live check (controller and user; subagents must not restart services).** The user cold-restarts the shell. Then, with the live-testing hazards from Global Constraints:
  1. `qs ipc call shell style elena ""`
  2. `qs ipc call shell popup sidebar` returns true; screenshot with `grim -o eDP-1 <scratchpad>/sidebar-live.png`; Read it: five cards at the left edge below the block row, windows not moved.
  3. `qs ipc call shell popup sidebar` again closes it (toggle); `qs ipc call shell style material3 ""` then `qs ipc call shell popup sidebar` returns false (no effect outside elena).
  4. Restore: `qs ipc call shell style material3 ""`, `qs ipc call shell dismissPopups`, `jq -r .themeStyle ~/.config/quickshell/settings.json` is `material3`.

---

### Task 6: Gates, docs, ship

- [ ] **Step 1:** Run the full gate set: `node tests/sidebar/test.mjs && node tests/elena/test.mjs && node tests/bar-form/test.mjs && node tests/settings-tabs/test.mjs`, `bash scripts/tag-strip-render.sh`, `bash scripts/sidebar-render.sh`, `bash scripts/m3-qmllint-gate.sh`, `scripts/controls-behavior.sh .`, `scripts/controls-golden-baseline.sh check` (run `check` right after any `update`; the golden capture is occasionally nondeterministic).
- [ ] **Step 2:** Append a "Usage" paragraph to the spec: the toggle command `qs ipc call shell popup sidebar` and the niri bind line to add to `~/.config/niri/config.kdl` (given to the user, not edited): `Mod+Shift+S { spawn "qs" "ipc" "call" "shell" "popup" "sidebar"; }` (confirm the key is free in their config before suggesting it).
- [ ] **Step 3:** Update memory `quickshell-elena-theme.md` with the sidebar (files, `sidebarActive` rationale, roadmap status). Push with `yadm push origin main` (user rule: commit and push after a task).
- [ ] **Step 4:** Report: what to restart (nothing; QML hot-reloads; if `qs ipc` answers "Not ready" after saves, `systemctl --user restart quickshell.service`).

---

## Self-review

- **Spec coverage:** surface (T5), single-open-popup + elena gating (T5 Steps 3-4), five cards (T2, T3), `weekRow` (T1), service activation (T5 Step 1), gate test (T1), render check (T4), live check (T5 Step 7), niri bind line (T6 Step 2). Spec said cards "set popupActive"; the plan uses a separate `sidebarActive` to avoid two writers on one property, and the spec gets that correction in T6 Step 2's docs edit (add one line under Cards).
- **Placeholders:** none; the only read-first steps (service handler lines, popup insertion points) name the exact patterns to edit.
- **Types:** `weekRow` item shape `{letter, isToday}` matches `ClockCard` use; `LevelBar.moved(real)` receives 0..1 and `LevelBars` scales brightness by 100 for `setBrightness(pct)`; `Card` is referenced by name inside `bar/sidebar/` only (same directory, no import needed).
- **Risks:** `PopupBase` margin overrides on a derived type (same technique shell.qml uses on instances); `FloatingWindow` tiling in the render harness (stage is fixed-size, as in the tag-strip check); `mpris_control.py` behavior is reused unchanged.
