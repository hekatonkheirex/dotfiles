# Elena sidebar, her three pages (R2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current two-page sidebar with her Home / Agenda / Media pages, page indicators and a left-edge hover activator.

**Architecture:** Pure JS modules hold every decision that needs no display (metric parsing, page stepping, calendar grid, media math). `SystemMetricsService` and the extended `MediaService` feed them; `bar/sidebar/*Page.qml` render fixed inputs and are render-checkable without a window; `Sidebar.qml` stays the layer-shell window and `SidebarActivator.qml` is the 1 px hover strip.

**Tech Stack:** QML (Quickshell, Qt 6), node `.mjs` gates (`.pragma library` JS loaded through `new Function`), bash + python3/PIL render checks, python3 dbus for MPRIS.

**Spec:** `docs/superpowers/specs/2026-10-13-elena-sidebar-pages-r2-design.md`

## Global Constraints

- VCS is yadm only: `cd ~ && yadm add <paths> && yadm commit -m ... && yadm push origin main`. Never stage `.config/quickshell/settings.json`, Kvantum, kitty, niri, btop or starship files. No `--no-verify`, no force-push. Do not edit `~/.config/niri/*` or `settings.json`.
- QML saves hot-reload the live shell. Keep `shell.qml` and every instantiated file valid at each saved state: create new files first, switch the wiring in one edit, delete old files last. No live `qs ipc` mutations before Task 5.
- Delete any `.claude/` under `~/.config/quickshell` before gates. No em dashes in comments or docs.
- Scale: `Config.dp(n)` = `Math.round(n * 1.5)`. Sidebar width `dp(300)` (450), page area `dp(554)`, indicator section `dp(106)`, bottom margin `Config.bottomBarHeight + dp(7)`, right corners `dp(20)`.
- Accent slots: `Colors.elenaAccent(n)`: 1 error, 2 secondary, 3 tertiary, 4 primary, 5 inversePrimary, 6 fgTertiaryContainer, 8 outline (muted). Tile fills: volume x5 (muted x8), battery x6, cpu x2, brightness x1, temperature x1, ram x3, swap x4, disk x5, network x4. Indicator colors per page: x1, x2, x5.
- Pages: 0 Home, 1 Agenda, 2 Media; `Sidebar.pageCount` = 3. Weekday strip Sunday-first; month grid follows `Settings.calendarWeekStartsMonday`.
- Glyph font for icomoon glyphs: `BottomBarFonts.family` (`ElenaIcons1`, fallback stack by fontconfig). Render-check scratch HOMEs must symlink `~/.config/fontconfig/conf.d` and `~/.local/share/fonts/icomoon` and set `XDG_RUNTIME_DIR` inside the scratch HOME (see `scripts/bottom-bar-render.sh`).
- Every task ends with the Gate set green, then commit and push.

## Gate set

From `~/.config/quickshell`:

```bash
rm -rf .claude
bash scripts/m3-qmllint-gate.sh
bash scripts/tests/test_niri_shape.sh
for t in scripts/tests/test_*.py; do python3 -I "$t"; done
for t in tests/*/*.mjs; do node "$t"; done
bash scripts/controls-behavior.sh && bash scripts/controls-render.sh
bash scripts/tag-strip-render.sh && bash scripts/bottom-bar-render.sh && bash scripts/bar-font-check.sh
bash scripts/sidebar-render.sh            # rewritten in Task 3
bash scripts/config-dump.sh check
bash scripts/style-refs.sh --elena
bash scripts/controls-golden-baseline.sh check
```

`bash scripts/popup-ipc-check.sh` joins the set in Task 5 only (it drives the live shell).

## File Structure

| Path | Role |
|---|---|
| `config/SystemMetrics.js`, `config/SidebarPages.js`, `config/MediaMath.js`, `bar/CalendarLogic.js` (+`buildMonthGrid`) | pure logic (Task 1) |
| `tests/sidebar/{metrics,pages,calendar,media}.test.mjs` | gates for the above (Task 1) |
| `config/SystemMetricsService.qml`, `config/MediaService.qml`, `scripts/mpris_monitor.py`, `scripts/mpris_control.py`, `config/BottomBarFonts.qml`, `config/Settings.qml`, `config/qmldir`, `bar/settings/AppearanceTab.qml` | services, settings (Task 2) |
| `bar/sidebar/{SliderTile,PageIndicators,SeekLine,HomePage,AgendaPage,MediaPage,SidebarContent}.qml`, `tests/sidebar/shell.qml`, `scripts/sidebar-render.sh` | rendering and render check (Task 3) |
| `bar/Sidebar.qml`, `bar/SidebarActivator.qml`, `shell.qml`, `scripts/popup-ipc-check.sh`, old files deleted (Task 4) |
| `README.md`, memory notes, live checks (Task 5) |

---

### Task 1: Pure modules and gates

**Files:**
- Create: `config/SystemMetrics.js`, `config/SidebarPages.js`, `config/MediaMath.js`
- Modify: `bar/CalendarLogic.js`
- Create: `tests/sidebar/metrics.test.mjs`, `tests/sidebar/pages.test.mjs`, `tests/sidebar/calendar.test.mjs`, `tests/sidebar/media.test.mjs`

**Interfaces (all produced here, consumed by Tasks 2 and 3):**
- `SystemMetrics.cpuPercent(prev, cur) -> 0..100|null` where each argument is `parseCpu(text)` output `{ idle, total }`; `SystemMetrics.parseCpu(statText) -> {idle,total}|null` (first `cpu ` line, idle = idle + iowait).
- `SystemMetrics.memoryPercent(meminfoText) -> 0..100|null`; `SystemMetrics.swapPercent(meminfoText) -> 0..100|null` (null when `SwapTotal` is 0).
- `SystemMetrics.tempC(texts: string[]) -> number|null` (max of the millidegree values, in deg C; non-numeric ignored).
- `SystemMetrics.diskPercent(dfText) -> 0..100|null` (`df -P /` second line, Use% column).
- `SystemMetrics.parseNet(procNetDevText) -> {rx, tx}|null` (sum of all non-`lo` interfaces); `SystemMetrics.netRate(prev, cur, dtSec) -> {down, up}|null` in bytes per second, negative deltas (counter reset) give 0.
- `SystemMetrics.uptimeParts(seconds) -> string` (two largest non-zero units of w d h m, e.g. `"1w 1d"`, `"3h 5m"`, `"59s"` under a minute, `"0m"` never; `null` or negative gives `"--"`).
- `SidebarPages.stepPage(current, delta, count) -> int` (clamped, no wrap), `SidebarPages.indicatorWidth(selected) -> 14|27`, `SidebarPages.wheelPage(current, deltaY, count) -> int` (positive deltaY steps to the previous page).
- `MediaMath.fraction(positionSec, lengthSec) -> 0..1`, `MediaMath.seekTarget(positionSec, deltaSec, lengthSec) -> number` (clamped 0..length), `MediaMath.timeText(sec) -> "m:ss"`, `MediaMath.lineIndex(fraction, lines) -> 0..lines-1`, `MediaMath.fractionOfLine(index, lines) -> fraction in (0,1]`.
- `CalendarLogic.buildMonthGrid(date, startsMonday) -> [{ day:int, other:bool }] x42`.

- [ ] **Step 1: Write the failing tests**

`tests/sidebar/metrics.test.mjs`:

```js
// Gate test: node tests/sidebar/metrics.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/SystemMetrics.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src +
  "; return { parseCpu, cpuPercent, memoryPercent, swapPercent, tempC, diskPercent, parseNet, netRate, uptimeParts }")()

// cpu: idle + iowait counts as idle; delta over two samples.
const a = M.parseCpu("cpu  100 0 100 700 100 0 0 0 0 0\ncpu0 1 1 1 1 1 0 0 0 0 0\n")
assert.deepEqual(a, { idle: 800, total: 1000 })
const b = M.parseCpu("cpu  200 0 200 750 100 0 0 0 0 0\n")
assert.deepEqual(b, { idle: 850, total: 1250 })
assert.equal(M.cpuPercent(a, b), 80)             // 50 idle of 250 total
assert.equal(M.cpuPercent(a, a), null)           // zero elapsed
assert.equal(M.cpuPercent({ idle: 900, total: 1000 }, { idle: 100, total: 200 }), null) // counter reset
assert.equal(M.parseCpu("garbage"), null)
assert.equal(M.cpuPercent(null, a), null)

// memory and swap
const mi = "MemTotal: 16000000 kB\nMemFree: 1000000 kB\nMemAvailable: 4000000 kB\nSwapTotal: 8000000 kB\nSwapFree: 6000000 kB\n"
assert.equal(M.memoryPercent(mi), 75)
assert.equal(M.swapPercent(mi), 25)
assert.equal(M.swapPercent("MemTotal: 1 kB\nMemAvailable: 1 kB\nSwapTotal: 0 kB\nSwapFree: 0 kB\n"), null)
assert.equal(M.memoryPercent("nothing"), null)
assert.equal(M.memoryPercent("MemTotal: 100 kB\nMemAvailable: 200 kB\n"), null)

// temperature: max of millidegrees, ignores junk
assert.equal(M.tempC(["45000\n", "61500\n", "n/a"]), 61.5)
assert.equal(M.tempC([]), null)
assert.equal(M.tempC(["x", ""]), null)

// disk: df -P / second line
const df = "Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/nvme0n1p2 500000000 171000000 305000000 36% /\n"
assert.equal(M.diskPercent(df), 36)
assert.equal(M.diskPercent("Filesystem\n"), null)

// network: sum non-lo interfaces; rates; counter reset gives 0
const nd = "Inter-|   Receive\n face |bytes packets\n    lo: 500 5 0 0 0 0 0 0 600 6 0 0 0 0 0 0\n wlan0: 1000 10 0 0 0 0 0 0 2000 20 0 0 0 0 0 0\n  eth0: 300 3 0 0 0 0 0 0 100 1 0 0 0 0 0 0\n"
assert.deepEqual(M.parseNet(nd), { rx: 1300, tx: 2100 })
assert.deepEqual(M.netRate({ rx: 1000, tx: 1000 }, { rx: 3000, tx: 1500 }, 2), { down: 1000, up: 250 })
assert.deepEqual(M.netRate({ rx: 5000, tx: 5000 }, { rx: 100, tx: 100 }, 2), { down: 0, up: 0 })
assert.equal(M.netRate(null, { rx: 1, tx: 1 }, 2), null)
assert.equal(M.netRate({ rx: 1, tx: 1 }, { rx: 2, tx: 2 }, 0), null)
assert.equal(M.parseNet(""), null)

// uptime parts
assert.equal(M.uptimeParts(59), "59s")
assert.equal(M.uptimeParts(60), "1m")
assert.equal(M.uptimeParts(3600 + 5 * 60), "1h 5m")
assert.equal(M.uptimeParts(86400 + 3600), "1d 1h")
assert.equal(M.uptimeParts(8 * 86400 + 2 * 3600), "1w 1d")
assert.equal(M.uptimeParts(7 * 86400), "1w")
assert.equal(M.uptimeParts(null), "--")
assert.equal(M.uptimeParts(-5), "--")
console.log("sidebar metrics: ok")
```

`tests/sidebar/pages.test.mjs`:

```js
// Gate test: node tests/sidebar/pages.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/SidebarPages.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src + "; return { stepPage, indicatorWidth, wheelPage }")()

assert.equal(M.stepPage(0, 1, 3), 1)
assert.equal(M.stepPage(2, 1, 3), 2)      // clamped, no wrap
assert.equal(M.stepPage(0, -1, 3), 0)
assert.equal(M.stepPage(1, -1, 3), 0)
assert.equal(M.stepPage(1, 5, 3), 2)
assert.equal(M.stepPage(NaN, 1, 3), 1)    // NaN treated as page 0
assert.equal(M.indicatorWidth(true), 27)
assert.equal(M.indicatorWidth(false), 14)
// wheel: positive deltaY (scroll up) goes to the previous page
assert.equal(M.wheelPage(1, 120, 3), 0)
assert.equal(M.wheelPage(1, -120, 3), 2)
assert.equal(M.wheelPage(0, 120, 3), 0)
assert.equal(M.wheelPage(1, 0, 3), 1)
console.log("sidebar pages: ok")
```

`tests/sidebar/calendar.test.mjs`:

```js
// Gate test: node tests/sidebar/calendar.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../bar/CalendarLogic.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src + "; return { buildMonthGrid }")()

const days = g => g.map(c => c.day).join(",")
// October 2026: starts on Thursday (4), 31 days.
const oct = M.buildMonthGrid(new Date(2026, 9, 15), false)
assert.equal(oct.length, 42)
assert.equal(days(oct.slice(0, 5)), "27,28,29,30,1")     // Sunday-first: Sep 27..30 then Oct 1
assert.deepEqual(oct.slice(0, 4).map(c => c.other), [true, true, true, true])
assert.equal(oct[4].other, false)
assert.equal(oct[4 + 30].day, 31)
assert.equal(oct[4 + 31].day, 1)                          // Nov 1
assert.equal(oct[4 + 31].other, true)
// Monday-first: Thursday is index 3.
const octM = M.buildMonthGrid(new Date(2026, 9, 15), true)
assert.equal(days(octM.slice(0, 4)), "28,29,30,1")
// February 2028 (leap): 29 days, starts Tuesday.
const feb = M.buildMonthGrid(new Date(2028, 1, 10), false)
assert.equal(feb.filter(c => !c.other).length, 29)
assert.equal(feb[2].day, 1)
// December: trailing cells are January (other).
const dec = M.buildMonthGrid(new Date(2026, 11, 1), false)
assert.equal(dec.filter(c => !c.other).length, 31)
assert.equal(dec[41].other === true || dec.filter(c => !c.other).length === 31, true)
// January: leading cells are December of the previous year.
const jan = M.buildMonthGrid(new Date(2027, 0, 1), false)
assert.equal(jan[0].other, jan[0].day > 7)
// Invalid date gives 42 empty cells.
assert.equal(M.buildMonthGrid(new Date(NaN), false).length, 42)
console.log("sidebar calendar: ok")
```

`tests/sidebar/media.test.mjs`:

```js
// Gate test: node tests/sidebar/media.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/MediaMath.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src +
  "; return { fraction, seekTarget, timeText, lineIndex, fractionOfLine }")()

assert.equal(M.fraction(30, 120), 0.25)
assert.equal(M.fraction(200, 120), 1)
assert.equal(M.fraction(-5, 120), 0)
assert.equal(M.fraction(10, 0), 0)          // unknown length
assert.equal(M.fraction(NaN, 100), 0)

assert.equal(M.seekTarget(50, 10, 120), 60)
assert.equal(M.seekTarget(115, 10, 120), 120)
assert.equal(M.seekTarget(4, -10, 120), 0)
assert.equal(M.seekTarget(10, 10, 0), 10)   // unknown length: no upper clamp beyond position

assert.equal(M.timeText(0), "0:00")
assert.equal(M.timeText(65), "1:05")
assert.equal(M.timeText(3600 + 61), "61:01")
assert.equal(M.timeText(-3), "0:00")
assert.equal(M.timeText(NaN), "0:00")

// 20 seek lines
assert.equal(M.lineIndex(0, 20), 0)
assert.equal(M.lineIndex(0.049, 20), 0)
assert.equal(M.lineIndex(0.05, 20), 1)
assert.equal(M.lineIndex(1, 20), 19)
assert.equal(M.lineIndex(-1, 20), 0)
assert.equal(M.fractionOfLine(0, 20), 0.05)
assert.equal(M.fractionOfLine(19, 20), 1)
console.log("sidebar media: ok")
```

- [ ] **Step 2: Run, expect failure**

Run: `for t in metrics pages calendar media; do node tests/sidebar/$t.test.mjs; done`
Expected: every one fails with `ENOENT` or a missing function.

- [ ] **Step 3: Write `config/SystemMetrics.js`**

```js
.pragma library

// Pure parsers for the Home page tiles. No QML types, no I/O.

function num(text) {
  var v = Number(String(text).trim())
  return isFinite(v) ? v : null
}

function parseCpu(text) {
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    if (!/^cpu\s/.test(lines[i])) continue
    var f = lines[i].trim().split(/\s+/).slice(1).map(Number)
    if (f.length < 5 || f.some(function(v) { return !isFinite(v) })) return null
    var total = 0
    for (var j = 0; j < f.length; j++) total += f[j]
    return { idle: f[3] + f[4], total: total }
  }
  return null
}

function cpuPercent(prev, cur) {
  if (!prev || !cur) return null
  var dt = cur.total - prev.total
  var di = cur.idle - prev.idle
  if (dt <= 0 || di < 0 || di > dt) return null
  return Math.round(100 * (dt - di) / dt)
}

function meminfo(text) {
  var out = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var m = /^(MemTotal|MemAvailable|SwapTotal|SwapFree):\s+(\d+)\s+kB/.exec(lines[i])
    if (m) out[m[1]] = Number(m[2])
  }
  return out
}

function memoryPercent(text) {
  var m = meminfo(text)
  if (!(m.MemTotal > 0) || m.MemAvailable === undefined || m.MemAvailable > m.MemTotal) return null
  return Math.round(100 * (m.MemTotal - m.MemAvailable) / m.MemTotal)
}

function swapPercent(text) {
  var m = meminfo(text)
  if (!(m.SwapTotal > 0) || m.SwapFree === undefined || m.SwapFree > m.SwapTotal) return null
  return Math.round(100 * (m.SwapTotal - m.SwapFree) / m.SwapTotal)
}

// thermal zone files hold millidegrees Celsius.
function tempC(texts) {
  var best = null
  for (var i = 0; i < (texts || []).length; i++) {
    var s = String(texts[i]).trim()
    if (s === "") continue
    var v = Number(s)
    if (!isFinite(v)) continue
    var c = v / 1000
    if (best === null || c > best) best = c
  }
  return best
}

function diskPercent(text) {
  var lines = String(text || "").trim().split("\n")
  if (lines.length < 2) return null
  var f = lines[1].trim().split(/\s+/)
  var m = /^(\d+)%$/.exec(f[4] || "")
  return m ? Number(m[1]) : null
}

function parseNet(text) {
  var rx = 0, tx = 0, seen = false
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var m = /^\s*([^:\s]+):\s*(.*)$/.exec(lines[i])
    if (!m || m[1] === "lo") continue
    var f = m[2].trim().split(/\s+/).map(Number)
    if (f.length < 9 || !isFinite(f[0]) || !isFinite(f[8])) continue
    rx += f[0]
    tx += f[8]
    seen = true
  }
  return seen ? { rx: rx, tx: tx } : null
}

function netRate(prev, cur, dtSec) {
  if (!prev || !cur || !(dtSec > 0)) return null
  var down = cur.rx - prev.rx
  var up = cur.tx - prev.tx
  return { down: down > 0 ? down / dtSec : 0, up: up > 0 ? up / dtSec : 0 }
}

function uptimeParts(seconds) {
  if (seconds === null || seconds === undefined || !isFinite(seconds) || seconds < 0) return "--"
  var s = Math.floor(seconds)
  if (s < 60) return s + "s"
  var minutes = Math.floor(s / 60)
  var units = [
    ["w", Math.floor(minutes / (7 * 1440))],
    ["d", Math.floor(minutes / 1440) % 7],
    ["h", Math.floor(minutes / 60) % 24],
    ["m", minutes % 60]
  ]
  var out = []
  for (var i = 0; i < units.length && out.length < 2; i++) {
    if (units[i][1] > 0) out.push(units[i][1] + units[i][0])
  }
  return out.join(" ")
}
```

- [ ] **Step 4: Write `config/SidebarPages.js` and `config/MediaMath.js`**

```js
.pragma library

// config/SidebarPages.js: page stepping for the sidebar and its indicators.
function stepPage(current, delta, count) {
  var c = isFinite(current) ? current : 0
  return Math.max(0, Math.min(count - 1, c + delta))
}

function indicatorWidth(selected) { return selected ? 27 : 14 }

// Scrolling up goes to the previous page, down to the next (her scripts).
function wheelPage(current, deltaY, count) {
  if (!deltaY) return current
  return stepPage(current, deltaY > 0 ? -1 : 1, count)
}
```

```js
.pragma library

// config/MediaMath.js: position and seek arithmetic for the Media page.
function fraction(positionSec, lengthSec) {
  if (!(lengthSec > 0) || !isFinite(positionSec)) return 0
  return Math.max(0, Math.min(1, positionSec / lengthSec))
}

function seekTarget(positionSec, deltaSec, lengthSec) {
  var t = positionSec + deltaSec
  if (lengthSec > 0) t = Math.min(t, lengthSec)
  return Math.max(0, t)
}

function timeText(sec) {
  if (!isFinite(sec) || sec < 0) sec = 0
  var s = Math.floor(sec)
  return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60)
}

function lineIndex(fraction, lines) {
  var f = Math.max(0, Math.min(1, fraction))
  return Math.min(lines - 1, Math.floor(f * lines))
}

function fractionOfLine(index, lines) { return (index + 1) / lines }
```

(Write the two modules as two files; the first comment line of each names the file.)

- [ ] **Step 5: Add `buildMonthGrid` to `bar/CalendarLogic.js`**

Append (keep every existing function):

```js
// 42 cells (six rows) with leading and trailing days of the neighbouring
// months marked `other`. An invalid date gives 42 empty cells.
function buildMonthGrid(date, startsMonday) {
  var cells = []
  if (!date || isNaN(date.getTime())) {
    for (var e = 0; e < 42; e++) cells.push({ day: 0, other: true })
    return cells
  }
  var first = new Date(date.getFullYear(), date.getMonth(), 1)
  var lead = first.getDay()
  if (startsMonday) lead = (lead + 6) % 7
  var start = new Date(first.getFullYear(), first.getMonth(), 1 - lead)
  for (var i = 0; i < 42; i++) {
    var d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
    cells.push({ day: d.getDate(), other: d.getMonth() !== date.getMonth() })
  }
  return cells
}
```

- [ ] **Step 6: Run the tests, expect pass**

Run: `for t in metrics pages calendar media; do node tests/sidebar/$t.test.mjs || break; done`
Expected: `sidebar metrics: ok`, `sidebar pages: ok`, `sidebar calendar: ok`, `sidebar media: ok`. If a case in the test disagrees with the implementation, the test encodes the spec: fix the implementation (thresholds, rounding, `other` flag), and report the change.

- [ ] **Step 7: Gates and commit**

```bash
for t in tests/*/*.mjs; do node "$t" || break; done; bash scripts/m3-qmllint-gate.sh
cd ~ && yadm add .config/quickshell/config/SystemMetrics.js .config/quickshell/config/SidebarPages.js \
  .config/quickshell/config/MediaMath.js .config/quickshell/bar/CalendarLogic.js .config/quickshell/tests/sidebar
yadm commit -m "sidebar R2: pure metrics, page, media and calendar-grid modules with gates" && yadm push origin main
```

---

### Task 2: Services, MPRIS extensions, clock fonts, setting

**Files:**
- Create: `config/SystemMetricsService.qml`
- Modify: `config/MediaService.qml`, `scripts/mpris_monitor.py`, `scripts/mpris_control.py`, `config/BottomBarFonts.qml`, `config/Settings.qml`, `config/qmldir`, `bar/settings/AppearanceTab.qml`, `tests/bottom-bar/wiring.test.mjs` or a new `tests/sidebar/wiring.test.mjs`, `tests/elena/config-dump.baseline.json`

**Interfaces:**
- Consumes: Task 1 modules.
- Produces:
  - `SystemMetricsService { active: bool; cpu, ram, swap, disk, temp, netPercent: real (-1 when unavailable); netLabel: string; hostname: string; uptime: string }` (singleton; refresh every 2 s while `active`).
  - `MediaService { positionSec: real; function seekBy(delta), seekTo(sec), stop(), playPause(), next(), previous(), playerVolumeBy(delta) }`.
  - `BottomBarFonts { clockFamily, clockMinutesFamily: string }`.
  - `Settings.sidebarEdgeHover: bool` (default true).

- [ ] **Step 1: Failing structural test `tests/sidebar/wiring.test.mjs` (part 1)**

```js
// Gate test: node tests/sidebar/wiring.test.mjs (structural)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")

const svc = rd("../../config/SystemMetricsService.qml")
assert.match(svc, /pragma Singleton/)
assert.match(svc, /import "SystemMetrics\.js" as SystemMetrics/)
assert.match(svc, /running: root\.active/, "polls only while active")
for (const p of ["/proc/stat", "/proc/meminfo", "/proc/net/dev", "/proc/uptime", "/sys/class/thermal"])
  assert.ok(svc.includes(p), p)
const qmldir = rd("../../config/qmldir")
assert.match(qmldir, /singleton SystemMetricsService 1\.0 SystemMetricsService\.qml/)

const media = rd("../../config/MediaService.qml")
for (const f of ["positionSec", "function seekBy(", "function seekTo(", "function stop(", "function playerVolumeBy("])
  assert.ok(media.includes(f), f)
const ctl = rd("../../scripts/mpris_control.py")
for (const a of ["'seek'", "'position'", "'volume'"]) assert.ok(ctl.includes(a), a)
assert.match(rd("../../scripts/mpris_monitor.py"), /position_sec/)

const fonts = rd("../../config/BottomBarFonts.qml")
assert.match(fonts, /clockFamily/)
assert.match(fonts, /clockMinutesFamily/)
assert.match(fonts, /Baro Plain/)
assert.match(fonts, /Baro LineThree/)

const settings = rd("../../config/Settings.qml")
assert.match(settings, /sidebarEdgeHover: true/)
assert.match(settings, /property alias sidebarEdgeHover: adapter\.sidebarEdgeHover/)
assert.match(rd("../../bar/settings/AppearanceTab.qml"), /sidebarEdgeHover/)
console.log("sidebar wiring (services): ok")
```

Run: expect FAIL.

- [ ] **Step 2: `config/SystemMetricsService.qml`**

```qml
pragma Singleton
import QtQml
import Quickshell
import Quickshell.Io
import "SystemMetrics.js" as SystemMetrics

// Home-page tile values. Reads procfs/sysfs once per tick; runs only while a
// consumer sets `active`. -1 means unavailable (the tile dims).
QtObject {
  id: root

  property bool active: false
  property real cpu: -1
  property real ram: -1
  property real swap: -1
  property real disk: -1
  property real temp: -1
  property real netPercent: -1
  property string netLabel: "--"
  property string hostname: ""
  property string uptime: "--"

  property var prevCpu: null
  property var prevNet: null
  property real prevNetAt: 0
  property real netCeilingBytes: 100 * 1000 * 1000     // 100 MB/s = 100 %

  property var thermalTexts: []

  function tick() {
    if (!root.active) return
    statFile.reload(); meminfoFile.reload(); netFile.reload(); uptimeFile.reload()
    if (!dfProc.running) dfProc.running = true
    if (!thermalProc.running) thermalProc.running = true
  }

  FileView {
    id: statFile
    path: root.active ? "/proc/stat" : ""
    onLoaded: {
      var cur = SystemMetrics.parseCpu(text())
      var pct = SystemMetrics.cpuPercent(root.prevCpu, cur)
      if (cur) root.prevCpu = cur
      root.cpu = pct === null ? root.cpu : pct
    }
  }
  FileView {
    id: meminfoFile
    path: root.active ? "/proc/meminfo" : ""
    onLoaded: {
      var m = SystemMetrics.memoryPercent(text())
      var s = SystemMetrics.swapPercent(text())
      root.ram = m === null ? -1 : m
      root.swap = s === null ? -1 : s
    }
  }
  FileView {
    id: netFile
    path: root.active ? "/proc/net/dev" : ""
    onLoaded: {
      var cur = SystemMetrics.parseNet(text())
      var now = Date.now() / 1000
      var rate = SystemMetrics.netRate(root.prevNet, cur, now - root.prevNetAt)
      if (cur) { root.prevNet = cur; root.prevNetAt = now }
      if (rate === null) return
      var top = Math.max(rate.down, rate.up)
      root.netPercent = Math.max(0, Math.min(100, 100 * top / root.netCeilingBytes))
      root.netLabel = (top / 1000000).toFixed(top >= 10000000 ? 0 : 1)
    }
  }
  FileView {
    id: uptimeFile
    path: root.active ? "/proc/uptime" : ""
    onLoaded: {
      var v = Number(String(text()).trim().split(/\s+/)[0])
      root.uptime = SystemMetrics.uptimeParts(isFinite(v) ? v : null)
    }
  }
  FileView {
    id: hostFile
    path: "/etc/hostname"
    onLoaded: root.hostname = String(text()).trim()
  }

  property Process dfProc: Process {
    command: ["df", "-P", "/"]
    stdout: StdioCollector {
      onStreamFinished: {
        var d = SystemMetrics.diskPercent(text)
        root.disk = d === null ? -1 : d
      }
    }
  }
  property Process thermalProc: Process {
    command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        var t = SystemMetrics.tempC(String(text).split("\n"))
        root.temp = t === null ? -1 : t
      }
    }
  }

  property Timer timer: Timer {
    interval: 2000
    repeat: true
    running: root.active
    triggeredOnStart: true
    onTriggered: root.tick()
  }
}
```

(`root.temp` is in deg C; the tile maps it to 0..100 directly, so a 100 C ceiling. Confirm `Quickshell.Io` exports `FileView` and `StdioCollector` the way `config/NetworkStatusService.qml` and `bar/sidebar/StatsCard.qml` use them; follow those files if the syntax differs. `/etc/hostname` may be missing: leave hostname empty and let the chip hide the name.)

- [ ] **Step 3: `config/qmldir`**: add `singleton SystemMetricsService 1.0 SystemMetricsService.qml`.

- [ ] **Step 4: MPRIS extensions**

`scripts/mpris_control.py`: extend the action chain inside the existing `try` with

```python
        elif action == 'position':
            props = dbus.Interface(player_obj, 'org.freedesktop.DBus.Properties')
            print(int(props.Get('org.mpris.MediaPlayer2.Player', 'Position')) / 1000000.0)
        elif action == 'seek' and len(sys.argv) > 2:
            player_iface.Seek(dbus.Int64(int(float(sys.argv[2]) * 1000000)))
        elif action == 'seekto' and len(sys.argv) > 2:
            meta = dbus.Interface(player_obj, 'org.freedesktop.DBus.Properties').Get(
                'org.mpris.MediaPlayer2.Player', 'Metadata')
            track = meta.get('mpris:trackid')
            if track is not None:
                player_iface.SetPosition(track, dbus.Int64(int(float(sys.argv[2]) * 1000000)))
        elif action == 'volume' and len(sys.argv) > 2:
            props = dbus.Interface(player_obj, 'org.freedesktop.DBus.Properties')
            cur = float(props.Get('org.mpris.MediaPlayer2.Player', 'Volume'))
            props.Set('org.mpris.MediaPlayer2.Player', 'Volume',
                      dbus.Double(max(0.0, min(1.0, cur + float(sys.argv[2])))))
```

(`play` in the existing chain is the PlayPause toggle; keep it.)

`scripts/mpris_monitor.py`: add `position_sec` (int seconds, 0 when unknown) to the dict `get_player_info` returns and to the NoPlayer dict (`'position_sec': 0`), read from `Position` in the same `try`; add a `GLib.timeout_add_seconds(1, tick)` whose callback re-runs `get_player_info` for the active sender while its status is `Playing` and calls `update_and_print()`; it must not print when nothing changed (compare the position to the last emitted).

`config/MediaService.qml`: add `property real positionSec: 0` (set from `info.position_sec`) and

```qml
  readonly property string control: Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py"
  function playPause() { Quickshell.execDetached(["python3", root.control, "play"]) }
  function stop() { Quickshell.execDetached(["python3", root.control, "stop"]) }
  function next() { Quickshell.execDetached(["python3", root.control, "next"]) }
  function previous() { Quickshell.execDetached(["python3", root.control, "prev"]) }
  function seekBy(delta) { Quickshell.execDetached(["python3", root.control, "seek", String(delta)]) }
  function seekTo(sec) { Quickshell.execDetached(["python3", root.control, "seekto", String(sec)]) }
  function playerVolumeBy(delta) { Quickshell.execDetached(["python3", root.control, "volume", String(delta)]) }
```

(If the file already defines some of these names, reuse and only add the missing ones.)

- [ ] **Step 5: Fonts and setting**

`config/BottomBarFonts.qml`: add

```qml
  function pick(name) {
    var want = name.toLowerCase()
    var all = Qt.fontFamilies()
    for (var i = 0; i < all.length; i++) if (all[i].toLowerCase() === want) return all[i]
    return Config.fontFamily
  }
  readonly property string clockFamily: pick("Baro Plain")
  readonly property string clockMinutesFamily: pick("Baro LineThree")
```

`config/Settings.qml`: `sidebarEdgeHover: true` in `defaults`, `property alias sidebarEdgeHover: adapter.sidebarEdgeHover`, `property bool sidebarEdgeHover: root.defaults.sidebarEdgeHover` in the adapter and in the reset block (follow how `dockPinned` is declared at lines 31, 147, 237, 292). `bar/settings/AppearanceTab.qml`: a switch row "Open sidebar at the left screen edge" next to the Dock section (copy the pattern of an existing boolean row in that file; add a search entry in `SettingsPanel.searchEntries` if rows are indexed there).

- [ ] **Step 6: Gates, baseline, commit**

```bash
node tests/sidebar/wiring.test.mjs                 # "sidebar wiring (services): ok"
bash scripts/config-dump.sh check                  # added keys only: Settings.sidebarEdgeHover? (Settings is not in the dump; expect ok)
python3 -I -c "import ast,sys; [ast.parse(open(f).read()) for f in ('scripts/mpris_control.py','scripts/mpris_monitor.py')]"
<Gate set minus sidebar-render.sh>
cd ~ && yadm add .config/quickshell/config .config/quickshell/scripts/mpris_control.py \
  .config/quickshell/scripts/mpris_monitor.py .config/quickshell/bar/settings/AppearanceTab.qml \
  .config/quickshell/bar/SettingsPanel.qml .config/quickshell/tests/sidebar
yadm commit -m "sidebar R2: metrics service, MPRIS position and controls, clock fonts, edge-hover setting" && yadm push origin main
```

If the recapture of `tests/elena/config-dump.baseline.json` is needed (new `Config` or `Colors` keys), add only the new keys by hand; never run a plain `capture` (it drops the pre-elena reference).

---

### Task 3: Pages, tiles, indicators, render check

**Files:**
- Create: `bar/sidebar/{SliderTile,PageIndicators,SeekLine,HomePage,AgendaPage,MediaPage}.qml`
- Modify: `bar/sidebar/SidebarContent.qml` (rewrite), `tests/sidebar/shell.qml` (rewrite), `scripts/sidebar-render.sh` (rewrite)

**Interfaces:**
- Consumes: Tasks 1 and 2; `AudioService`, `BrightnessService`, `BatteryService`, `WeatherService`, `MediaService`, `Colors.elenaAccent`, `BottomBarFonts`.
- Produces: `SidebarContent { active: bool; currentPage: int (0..2); signal escaped() }` (no search, no settings link); each page exposes read-only inputs as properties so the render check can drive them (`HomePage { now: date; ...tile values }`, `AgendaPage { today: date; weekStartsMonday: bool }`, `MediaPage { status, title, artist, artUrl, positionSec, lengthSec }`).

- [ ] **Step 1: `SliderTile.qml`**

```qml
import QtQuick
import "../../config"

// Her slider tile: 64 S square, fill rising from the bottom, a round label
// glyph at the bottom-right that shows the value on hover.
Item {
  id: root

  property real value: 0            // 0..100, -1 = unavailable
  property color accent: Colors.primary
  property string glyph: ""
  property string valueText: ""
  property bool interactive: false
  property bool muted: false

  signal moved(real value)

  readonly property real level: root.value < 0 ? 0 : Math.max(0, Math.min(100, root.value))
  implicitWidth: Config.dp(64) + Config.dp(12)
  implicitHeight: Config.dp(64) + Config.dp(12)
  opacity: root.value < 0 ? 0.45 : 1

  Rectangle {
    id: trough
    anchors.centerIn: parent
    width: Config.dp(64)
    height: Config.dp(64)
    radius: Config.dp(23)
    color: Colors.surfaceContainerHighest
    clip: true

    Rectangle {
      anchors.bottom: parent.bottom
      width: parent.width
      height: parent.height * root.level / 100
      color: root.muted ? Colors.elenaAccent(8) : root.accent
      // Square top corners under 70 %, rounded (her no-round class) above.
      radius: root.level >= 70 ? Config.dp(3) : 0
      Behavior on height {
        enabled: !Config.reducedMotion
        NumberAnimation { duration: 300 }
      }
    }

    MouseArea {
      anchors.fill: parent
      enabled: root.interactive && root.value >= 0
      function setFrom(mouse) {
        var v = Math.max(0, Math.min(100, 100 * (1 - mouse.y / height)))
        root.moved(v)
      }
      onPressed: function(m) { setFrom(m) }
      onPositionChanged: function(m) { if (pressed) setFrom(m) }
    }
  }

  Rectangle {
    id: label
    x: trough.x + trough.width - width - Config.dp(5)
    y: trough.y + trough.height - height - Config.dp(5)
    width: Config.dp(26)
    height: width
    radius: width / 2
    color: Colors.surface
    border.width: 1
    border.color: Colors.surfaceContainerHighest

    Text {
      anchors.centerIn: parent
      visible: !hover.hovered
      text: root.glyph
      color: Colors.fgSurface
      font.family: BottomBarFonts.family
      font.pixelSize: Config.dp(11)
    }
    Text {
      anchors.centerIn: parent
      visible: hover.hovered
      text: root.valueText
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.dp(7)
    }
    HoverHandler { id: hover }
  }
}
```

- [ ] **Step 2: `PageIndicators.qml` and `SeekLine.qml`**

```qml
// PageIndicators.qml
import QtQuick
import "../../config"
import "../../config/SidebarPages.js" as SidebarPages

Column {
  id: root
  property int currentPage: 0
  property int count: 3
  signal pageSelected(int page)
  signal pageScrolled(int deltaY)
  spacing: Config.dp(20)

  Rectangle {   // separator
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width - 2 * Config.dp(34)
    height: Config.dp(8)
    radius: height / 2
    color: Colors.surfaceContainerHighest
  }
  Row {
    id: dots
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Config.dp(12)
    Repeater {
      model: root.count
      Rectangle {
        required property int index
        readonly property bool selected: index === root.currentPage
        width: Config.dp(SidebarPages.indicatorWidth(selected))
        height: Config.dp(14)
        radius: height / 2
        color: Colors.elenaAccent(index === 0 ? 1 : (index === 1 ? 2 : 5))
        opacity: selected ? 1 : 0.3
        Behavior on width { enabled: !Config.reducedMotion; NumberAnimation { duration: 150 } }
        MouseArea {
          anchors.fill: parent
          anchors.margins: -Config.dp(6)
          cursorShape: Qt.PointingHandCursor
          onClicked: root.pageSelected(index)
        }
      }
    }
  }
  MouseArea {   // wheel anywhere over the section
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    onWheel: function(w) { root.pageScrolled(w.angleDelta.y) }
  }
}
```

```qml
// SeekLine.qml
import QtQuick
import "../../config"
import "../../config/MediaMath.js" as MediaMath

// 20 vertical lines; those left of the progress fraction are colored.
Row {
  id: root
  property real fraction: 0
  property int lines: 20
  signal seekRequested(real fraction)
  spacing: Config.dp(5)

  Repeater {
    model: root.lines
    Item {
      required property int index
      width: Config.dp(7)
      height: Config.dp(26)
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: Config.dp(3)
        height: parent.height * (0.45 + 0.55 * Math.abs(Math.sin(index * 0.9)))
        radius: width / 2
        color: MediaMath.fractionOfLine(index, root.lines) <= root.fraction + 1e-9
          ? Colors.elenaAccent(5) : Colors.surfaceContainerHighest
      }
      MouseArea {
        anchors.fill: parent
        anchors.leftMargin: -Config.dp(2)
        anchors.rightMargin: -Config.dp(2)
        cursorShape: Qt.PointingHandCursor
        onClicked: root.seekRequested(MediaMath.fractionOfLine(index, root.lines))
      }
    }
  }
}
```

- [ ] **Step 3: `HomePage.qml`** (time, weekday strip, weather pill, 3x3 tiles, hostname chip)

Structure (write the file in this shape; `now` is a property so the render check can fix the date):

```qml
import QtQuick
import "../../config"

Item {
  id: root
  property bool active: false
  property date now: new Date()

  SystemClock { id: clock; precision: SystemClock.Minutes; enabled: root.active }
  Binding { target: root; property: "now"; value: clock.date; when: root.active }
  Binding { target: SystemMetricsService; property: "active"; value: root.active }
  Binding { target: WeatherService; property: "sidebarActive"; value: root.active }
  Binding { target: AudioService; property: "sidebarActive"; value: root.active }
  Binding { target: BrightnessService; property: "sidebarActive"; value: root.active }

  readonly property var days: {
    var out = []
    var start = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate() - root.now.getDay())
    var letters = ["S", "M", "T", "W", "T", "F", "S"]
    for (var i = 0; i < 7; i++) {
      var d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
      out.push({ letter: letters[i], number: d.getDate(), today: i === root.now.getDay() })
    }
    return out
  }

  Column {
    anchors.top: parent.top
    anchors.topMargin: Config.dp(40)
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Config.dp(10)

    Row {   // time: HH + mm
      anchors.horizontalCenter: parent.horizontalCenter
      Text {
        text: ("0" + root.now.getHours()).slice(-2)
        color: Colors.fgSurface
        font.family: BottomBarFonts.clockFamily
        font.pixelSize: Math.round(44 * 4 / 3 * Config.elenaScale)
      }
      Text {
        text: ("0" + root.now.getMinutes()).slice(-2)
        color: Colors.elenaAccent(1)
        font.family: BottomBarFonts.clockMinutesFamily
        font.pixelSize: Math.round(44 * 4 / 3 * Config.elenaScale)
      }
    }
    Row {   // weekday strip
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.dp(8)
      Repeater {
        model: root.days
        Column {
          required property var modelData
          width: Config.dp(36)
          Rectangle {
            width: parent.width
            height: Config.dp(52)
            radius: Config.dp(14)
            color: modelData.today ? Colors.surfaceContainerHighest : "transparent"
            Column {
              anchors.centerIn: parent
              spacing: Config.dp(4)
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.letter
                color: modelData.today ? Colors.elenaAccent(1) : Colors.fgSurfaceVariant
                font.family: Config.fontFamily
                font.pixelSize: Config.dp(11)
                font.weight: Font.Bold
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.number
                color: modelData.today ? Colors.fgSurface : Colors.outline
                font.family: Config.fontFamily
                font.pixelSize: Config.dp(10)
              }
            }
          }
        }
      }
    }
    // weather pill, then three rows of three SliderTile, then hostname chip
  }
}
```

Fill in the three remaining blocks in the same file:
- **Weather pill:** a `Rectangle` pill (`radius height/2`, `Colors.surfaceContainerHighest`) with a round icon glyph (the condition glyph the WeatherService/indicator already maps: reuse `bar/WeatherIndicator.qml`'s icon mapping if it has one, else the Material Symbols name from `WeatherService.desc`), `WeatherService.temp`, a separator dot and `WeatherService.desc`; when `WeatherService.status === "loading"` show "Loading weather".
- **Tiles:** `Grid { columns: 3 }` of nine `SliderTile`s with values, accents, glyphs (use these icomoon codepoints, verified in `remix.ttf`/feather via bar-font-check: volume ``, battery ``, cpu ``, brightness ``, temperature ``, ram ``, swap ``, disk ``, network ``; the implementer renders them once, looks at the PNG and swaps any codepoint that does not read as that icon for the nearest remix glyph, listing the final table in the report). Values: `AudioService.volume * 100` (muted flag `AudioService.muted`, `interactive: true`, `onMoved: AudioService.setVolume(v / 100)`), `BatteryService.pct`, `SystemMetricsService.cpu`, `BrightnessService.pct` (`interactive: true`, `onMoved: BrightnessService.setBrightness(v)`), `SystemMetricsService.temp`, `.ram`, `.swap`, `.disk`, `.netPercent` (valueText `SystemMetricsService.netLabel`). Battery glyph switches to the charger `` while `BatteryService.charging`. `valueText` is `Math.round(value)` for the others.
- **Hostname chip:** pill with a computer glyph, `SystemMetricsService.hostname`, a separator dot and `SystemMetricsService.uptime`; hide the hostname text when empty.

- [ ] **Step 4: `AgendaPage.qml`**

Properties `today: date`, `weekStartsMonday: bool`, `shownMonth: date` (starts as today, reset when `active` goes false). Header row: a ring (`Canvas`, backdrop `surfaceContainerHighest`, `0` and `tasks` caption centered; stroke x2-accent only when tasks exist: never, no source) and a month/year block with up/down arrow buttons (`IconButton`-style `MouseArea`s) that shift `shownMonth` by month and by year. Weekday letter row (order per `weekStartsMonday`, today's letter in `Colors.elenaAccent(1)`), then a `Grid { columns: 7 }` of 42 cells from `CalendarLogic.buildMonthGrid(shownMonth, weekStartsMonday)`: other-month numbers `Colors.outline` at 0.5 opacity, in-month numbers `Colors.fgSurface`, weekend columns `Colors.elenaAccent(2)`, today a filled round (`Colors.fgSurface` fill, `Colors.surface` text). Below, the empty state: a note glyph and "You have no tasks" in `Colors.fgSurfaceVariant`.

- [ ] **Step 5: `MediaPage.qml`**

Properties `status`, `title`, `artist`, `artUrl`, `positionSec`, `lengthSec` (bound to `MediaService` by `SidebarContent`; plain properties here so the render check feeds fixed values); signals `playPause()`, `previous()`, `next()`, `seekBy(real delta)`, `seekFraction(real f)`, `stop()`, `favorite()`, `volumeStep(real delta)` (system), `playerVolumeStep(real delta)`.
- Art: a 160 S circle (`Image` with a circular `layer` mask or a `Rectangle { radius }` clip around an `Image`; neutral disc plus note glyph while `artUrl === ""`); `sourceSize` capped at `Qt.size(320, 320)` (the Image leak is unresolved: keep the cap).
- Ring: `Canvas` half circle along the bottom (angles from pi/2 clockwise ... draw an arc from 90 degrees to 270 degrees counter-clockwise for the backdrop, and the same arc scaled by `MediaMath.fraction(positionSec, lengthSec)` for the fill in `Colors.elenaAccent(5)`), 8 S thick; `MediaMath.timeText(positionSec)` at the left end and `timeText(lengthSec)` at the right end (hidden when `lengthSec` is 0).
- Hover: `HoverHandler` on the art hides the ring and shows a play or pause glyph over a dimmed cover; click calls `playPause()`.
- Title and artist: two pill `Row`s with glyph and text inside a horizontal `Flickable` (`clip`, `contentWidth` of the text, no scrollbar).
- `SeekLine { fraction: MediaMath.fraction(...) ; onSeekRequested: seekFraction(f) }`.
- Buttons row: prev, next (`MouseArea`s accepting left and right: right click emits `seekBy(-10)` / `seekBy(10)`), a larger play/pause (glyph per `status`), then volume up/down (left: `volumeStep(±5)`, right: `playerVolumeStep(±0.1)`), stop, favorite (a flash `Timer` of 600 ms toggles the accent). The play/pause `MouseArea` handles `onWheel`: `playerVolumeStep(±0.02)` per 120 notch via `SidebarPages`-style accumulation (reuse `BottomBarModel.notchSteps`).

- [ ] **Step 6: `SidebarContent.qml` (rewrite)**

```qml
import QtQuick
import "../../config"
import "../../config/SidebarPages.js" as SidebarPages
import "../../config/MediaMath.js" as MediaMath

Item {
  id: root
  property bool active: false
  property int currentPage: 0
  readonly property int pageCount: 3
  signal escaped()

  Keys.onPressed: function(event) {
    if ((event.modifiers & Qt.ControlModifier)
        && (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown)) {
      root.currentPage = SidebarPages.stepPage(root.currentPage, event.key === Qt.Key_PageUp ? -1 : 1, root.pageCount)
      event.accepted = true
    } else if (event.key === Qt.Key_Escape) {
      root.escaped(); event.accepted = true
    }
  }

  Item {
    id: pages
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: Config.dp(554)

    HomePage { anchors.fill: parent; visible: root.currentPage === 0; active: root.active && root.currentPage === 0 }
    AgendaPage {
      anchors.fill: parent
      visible: root.currentPage === 1
      active: root.active && root.currentPage === 1
      weekStartsMonday: Settings.calendarWeekStartsMonday
    }
    MediaPage {
      anchors.fill: parent
      visible: root.currentPage === 2
      status: MediaService.status
      title: MediaService.title
      artist: MediaService.artist
      artUrl: MediaService.artUrl
      positionSec: MediaService.positionSec
      lengthSec: MediaService.lengthSec
      onPlayPause: MediaService.playPause()
      onPrevious: MediaService.previous()
      onNext: MediaService.next()
      onStop: MediaService.stop()
      onSeekBy: function(d) { MediaService.seekBy(d) }
      onSeekFraction: function(f) { MediaService.seekTo(f * MediaService.lengthSec) }
      onVolumeStep: function(d) { AudioService.setVolume(Math.max(0, Math.min(1, AudioService.volume + d / 100))) }
      onPlayerVolumeStep: function(d) { MediaService.playerVolumeBy(d) }
      onFavorite: favoriteProc.running = true
    }
  }

  Binding { target: MediaService; property: "sidebarActive"; value: root.active && root.currentPage === 2 }

  PageIndicators {
    anchors.top: pages.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    currentPage: root.currentPage
    count: root.pageCount
    onPageSelected: function(p) { root.currentPage = p }
    onPageScrolled: function(dy) { root.currentPage = SidebarPages.wheelPage(root.currentPage, dy, root.pageCount) }
  }
}
```

`favoriteProc`: a `Process` with `command: ["sh", "-c", 'f="$HOME/Music/playlists/songs"; mkdir -p "$(dirname "$f")"; [ -n "$T" ] && printf "%s - %s\n" "$A" "$T" >> "$f"']` and `environment: ({ A: MediaService.artist, T: MediaService.title })`; guard against an empty title (the shell test does `[ -n "$T" ]`). Ensure every `Quickshell.Io` import is present.

- [ ] **Step 7: Render check**

Rewrite `tests/sidebar/shell.qml` and `scripts/sidebar-render.sh` on the `scripts/bottom-bar-render.sh` scaffold (scratch HOME with the fontconfig and icomoon symlinks, `XDG_RUNTIME_DIR` inside the scratch HOME, error-pattern filter, `GOLDEN_OUT`, timeout 30). Stage a 450x700 `Item` per page: `HomePage` with `now: new Date(2026, 9, 7, 9, 5)` and fixed tile inputs (set the tile value properties through a small `Item` that overrides the service bindings, or give HomePage `testValues` property that, when set, bypasses services), `AgendaPage` with `today` 2026-10-07 `weekStartsMonday: false`, `MediaPage` with fixed title/artist/position 30/120, and `PageIndicators` at page 1. Assertions (palette values from the elenapan fixed palette, tolerance 8/255; measure and print counts like the other render scripts):
1. Home: a tile with value 50 has trough pixels above the fill line and accent pixels below (sample the left edge strip at 25 % and 75 % of the tile height); the volume tile with `muted` uses `#5b6578`; the weekday strip highlights exactly one day (October 7, a Wednesday: third column from the right of S M T W: index 3).
2. Agenda: today's number sits in a filled round (count `fgSurface`-colored pixels in the cell), the first row's leading days are dimmed (`outline` at 0.5 opacity), "You have no tasks" region has ink.
3. Media: ring arc fill pixels at about 25 % along the bottom half (30 s of 120 s) are `#8e4f90`, the seek line has exactly 5 colored lines (fraction 0.25 of 20), the play glyph region has ink.
4. Indicators: selected pill is 27 S wide (41 px) and colored x2 (`#f06292`), the other two 21 px wide at 0.3 opacity.
Mutation-prove four of them (tile fill color, indicator width, seek-line count by changing `fractionOfLine`, calendar `other` dimming).

- [ ] **Step 8: Gates and commit**

Run the Gate set (the dock-era `tests/sidebar/{test,search,stats}.test.mjs` are deleted in Task 4; until then they must keep passing against the files they test, which are untouched in this task: the old `bar/sidebar/*` components are not deleted yet and `SidebarContent` is rewritten, so move any assertion in them that reads `SidebarContent.qml` text to the new file or delete it with a note). Commit:

```bash
cd ~ && yadm add .config/quickshell/bar/sidebar .config/quickshell/tests/sidebar .config/quickshell/scripts/sidebar-render.sh
yadm commit -m "sidebar R2: Home, Agenda and Media pages, slider tiles, indicators, render check" && yadm push origin main
```

---

### Task 4: Window, activator, shell wiring, removal of the old pages

**Files:**
- Modify: `bar/Sidebar.qml`, `shell.qml`, `scripts/popup-ipc-check.sh`, `bar/BottomBar.qml` (media button stays page 2), `config/BottomBarModel.js` test unaffected, `README.md`
- Create: `bar/SidebarActivator.qml`
- Delete: `bar/sidebar/{BatteryPill,CalendarCard,ClockCard,DashboardPage,LevelBar,LevelBars,MediaCard,SearchField,StatsCard,WeatherCard}.qml`, `tests/sidebar/{test,search,stats}.test.mjs`, `config/Weekdays.js`, `bar/sidebar/SidebarStats.js` if unreferenced

**Interfaces:**
- Consumes: Task 3 `SidebarContent`.
- Produces: `Sidebar.pageCount` = 3, `Sidebar.showPage(n)`, `Sidebar.currentPage`; IPC `openSidebarPage(n)` unchanged; removed IPC `sidebarSearch`.

- [ ] **Step 1: `bar/Sidebar.qml` (rewrite as her surface)**

```qml
import QtQuick
import Quickshell
import "../config"
import "sidebar"

// Elena's sidebar: left and bottom anchored overlay above the bottom bar.
PopupBase {
  id: root

  surfaceWidth: Config.dp(300)
  surfaceHeight: Math.min(Config.dp(554) + Config.dp(106),
    Screen.desktopAvailableHeight - Config.bottomBarHeight - Config.dp(7) - Config.barWidth)

  readonly property int currentPage: content.currentPage
  readonly property int pageCount: content.pageCount
  function showPage(n) {
    content.currentPage = Math.max(0, Math.min(root.pageCount - 1, Math.floor(n)))
  }

  anchors.top: false
  anchors.bottom: true
  margins.left: 0
  margins.top: 0
  margins.bottom: Config.bottomBarHeight + Config.dp(7)
  surfaceColor: Colors.surface

  // Square left corners (the panel touches the screen edge), no outline.
  Binding { target: root.bg; property: "topLeftRadius"; value: 0 }
  Binding { target: root.bg; property: "bottomLeftRadius"; value: 0 }
  Binding { target: root.bg; property: "topRightRadius"; value: Config.dp(20) }
  Binding { target: root.bg; property: "bottomRightRadius"; value: Config.dp(20) }
  Binding { target: root.bg; property: "border.width"; value: 0 }

  SidebarContent {
    id: content
    anchors.fill: parent
    active: root.visible
    onEscaped: root.dismissed()
  }

  // Middle click anywhere hides it (her eventbox onmiddleclick).
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.MiddleButton
    onClicked: root.dismissed()
  }
}
```

(PopupBase draws its own `bg`; if setting per-corner radii through `Binding` on `bg` is rejected, expose `topLeftRadius`... through a small `property real leftRadius` on PopupBase instead; read `bar/PopupBase.qml` first. The slide-in uses PopupBase's existing entry animation; add `Behavior` on `margins.left` from `-surfaceWidth` only if the implementer verifies it hot-reloads cleanly, otherwise keep PopupBase's entry and note the deviation in the report.)

- [ ] **Step 2: `bar/SidebarActivator.qml`**

```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"

// 1 px strip at the left screen edge: hovering it opens the sidebar.
PanelWindow {
  id: root

  property bool enabledByState: true     // false while locked or fullscreen
  signal activated()

  anchors { left: true; top: true; bottom: true }
  implicitWidth: 1
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("sidebar-activator")
  WlrLayershell.layer: WlrLayer.Top
  visible: Settings.sidebarEdgeHover && root.enabledByState

  Timer {
    id: dwell
    interval: 120
    onTriggered: root.activated()
  }
  HoverHandler {
    onHoveredChanged: hovered ? dwell.restart() : dwell.stop()
  }
}
```

- [ ] **Step 3: `shell.qml` (one atomic edit)**

1. Add `SidebarActivator { id: sidebarActivator; screen: bar.screen; enabledByState: !lockScreen.locked && !WindowService.focusedFullscreen; onActivated: shell.openSidebarPage(sidebar.currentPage) }` next to `Sidebar`. If `WindowService` has no fullscreen flag, add `focusedFullscreen` to `config/WindowState.js` reducer output (niri windows carry `is_fullscreen`? check `WindowState.js`; if the event stream does not expose it, drop the fullscreen condition and document it).
2. `openSidebarPage` is unchanged except it must not close on activator hover when already open on that page: the activator only calls it when `bar.openPopup !== "sidebar"`.
3. Remove the `Sidebar` handlers `onSearchSubmitted`/`onSettingsRequested`, the IPC `sidebarSearch`, and the sidebar-specific comment on `openLauncherWith` (keep the function: `launcherQuery` and other callers use it; grep first).
4. IPC `bottomBarState` unchanged.

- [ ] **Step 4: Delete old files and fix the tests that referenced them**

```bash
cd ~ && yadm rm -q .config/quickshell/bar/sidebar/{BatteryPill,CalendarCard,ClockCard,DashboardPage,LevelBar,LevelBars,MediaCard,SearchField,StatsCard,WeatherCard}.qml \
  .config/quickshell/tests/sidebar/test.mjs .config/quickshell/tests/sidebar/search.test.mjs \
  .config/quickshell/tests/sidebar/stats.test.mjs .config/quickshell/config/Weekdays.js
grep -rn "Weekdays\|LevelBar\|SidebarStats\|BatteryPill\|SearchField" bar shell.qml config scripts tests README.md | grep -v "^docs"
```

Every remaining hit is fixed or deleted (if `SidebarStats.js` is unreferenced delete it; `LevelTile.qml` in `bar/controls` stays). `tests/controls/shell.qml` may reference `LevelBar`: the LevelTile check stays, drop only the `LevelBar` wrapper assertion if present and note it.

- [ ] **Step 5: Wiring test part 2 (append to `tests/sidebar/wiring.test.mjs`)**

```js
const side = rd("../../bar/Sidebar.qml")
assert.match(side, /anchors\.top: false/)
assert.match(side, /anchors\.bottom: true/)
assert.match(side, /margins\.bottom: Config\.bottomBarHeight \+ Config\.dp\(7\)/)
assert.match(side, /readonly property int pageCount: content\.pageCount/)
assert.match(side, /acceptedButtons: Qt\.MiddleButton/)
const act = rd("../../bar/SidebarActivator.qml")
assert.match(act, /implicitWidth: 1/)
assert.match(act, /left: true; top: true; bottom: true/)
assert.match(act, /interval: 120/)
assert.match(act, /Settings\.sidebarEdgeHover/)
const sh = rd("../../shell.qml")
assert.match(sh, /SidebarActivator \{/)
assert.match(sh, /!lockScreen\.locked/)
assert.doesNotMatch(sh, /function sidebarSearch\(/)
assert.doesNotMatch(sh, /onSearchSubmitted/)
const content = rd("../../bar/sidebar/SidebarContent.qml")
assert.match(content, /readonly property int pageCount: 3/)
assert.match(content, /Qt\.Key_PageUp/)
for (const gone of ["SearchField", "StatsCard", "DashboardPage", "LevelBars"])
  assert.doesNotMatch(content, new RegExp(gone), gone + " removed")
console.log("sidebar wiring: ok")
```

- [ ] **Step 6: `scripts/popup-ipc-check.sh`**: update the sidebar sequence to `openSidebarPage 2` (opens), again (closes), `openSidebarPage 0` then `1` (switches, `bottomBarState.page` is 1) and `2` (page 2); remove any `sidebarSearch` lines. Do not run it in this task.

- [ ] **Step 7: README**: replace the sidebar feature text and IPC rows (no `sidebarSearch`), document the three pages, the edge activator and its setting, the favorites file, and the metric sources; fix the Project Structure tree.

- [ ] **Step 8: Gates, commit**

Run the Gate set (without popup-ipc-check). Then:

```bash
cd ~ && yadm add -A .config/quickshell/bar .config/quickshell/shell.qml .config/quickshell/config \
  .config/quickshell/scripts .config/quickshell/tests .config/quickshell/README.md
yadm status --short | grep -E "settings.json|Kvantum|kitty|niri|btop|starship" | grep -v '^ M' || true
yadm commit -m "sidebar R2: her sidebar window, edge activator, shell wiring; remove old pages" && yadm push origin main
```

---

### Task 5: Live verification (after the user's cold restart)

- [ ] **Step 1:** Ask the user to run `! systemctl --user restart quickshell.service` (their command). Wait.
- [ ] **Step 2: Live checks**

```bash
cd ~/.config/quickshell
for p in 0 1 2 2 0; do qs ipc call shell openSidebarPage $p; qs ipc call shell currentPopup; qs ipc call shell bottomBarState | python3 -c "import json,sys; print('page', json.load(sys.stdin)['page'])"; done
qs ipc call shell dismissPopups
bash scripts/popup-ipc-check.sh
journalctl --user -u quickshell.service --since "5 min ago" --no-pager | grep -i -E "error|TypeError|is not a type|ReferenceError" | tail
export NIRI_SOCKET=$(ls /run/user/$(id -u)/niri*.sock | head -1); niri msg layers | grep -i -A3 -E "sidebar|bottombar"
```

Expected: pages 0, 1, 2 (then closed), popup-ipc-check all ok, no new QML errors, the activator surface listed.
- [ ] **Step 3:** Sample RSS before and after opening each page ten times through IPC (`~/.cache/qs-rss` sampler or `/proc/PID/status` VmRSS); record the delta (Image leak baseline).
- [ ] **Step 4:** Final whole-branch review (opus), one fix wave, scoped re-review; final report (DONE or DONE_WITH_CONCERNS, restart note, follow-ups R3 to R7).

---

## Self-review

- **Spec coverage:** surface/dismiss/indicators (Tasks 3, 4), Home tiles table and chip (Task 3 with Task 2 service), Agenda (Tasks 1, 3), Media (Tasks 1, 2, 3), activator and setting (Tasks 2, 4), removals (Task 4), verification (Tasks 1 to 5).
- **Known soft spots:** the tile glyph codepoints in Task 3 Step 3 are provisional and verified visually by the implementer; the slide-in animation and per-corner radii depend on `PopupBase`; the fullscreen condition for the activator depends on whether niri's event stream exposes it (documented fallback); render-check coordinates are measured.
