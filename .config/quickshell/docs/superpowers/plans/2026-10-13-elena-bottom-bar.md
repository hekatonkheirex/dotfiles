# Elena bottom bar (R1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the auto-hide dock with eww-style bottom bar (left cluster, centre dock, right cluster) that reserves space and drives the sidebar pages.

**Architecture:** Pure JS modules hold every decision that can be tested without a display (symbol table, battery and signal parts, nmcli parsing, sidebar toggle). A window-less `BottomBarContent.qml` renders fixed inputs (render-checkable); `BottomBar.qml` is the layer-shell window that feeds it from the existing services and emits actions to `shell.qml`.

**Tech Stack:** QML (Quickshell, Qt 6), node `.mjs` gate tests (load `.pragma library` JS through `new Function`), bash render check with python3 + PIL.

**Spec:** `docs/superpowers/specs/2026-10-13-elena-bottom-bar-design.md`

## Global Constraints

- VCS is yadm only: `cd ~ && yadm add <paths> && yadm commit -m ... && yadm push origin main`. Never stage `.config/quickshell/settings.json`, Kvantum, kitty, niri, btop or starship files. No `--no-verify`, no force-push.
- Never edit `~/.config/quickshell/settings.json` or any niri file. No wtype or keystroke injection in tests. Do not restart the shell service or run live `qs ipc` checks before Task 5 (QML saves hot-reload the live shell; that is expected).
- Delete any `.claude/` directory under `~/.config/quickshell` before running gates.
- No em dashes in code comments or docs; match the surrounding comment density.
- Scale: `Config.elenaScale = 1.5`; `Config.dp(n)` = `Math.round(n * 1.5)`. Bar height `dp(43)` = 65 px. Cluster width `dp(300)` = 450. Button min width `dp(67)` = 101. Value pill `dp(23)` = 35. Ring thickness `dp(5)` = 8.
- Accent ramp (`Colors.elenaAccent(n)`): 1 `error`, 2 `secondary`, 3 `tertiary`, 4 `primary`, 5 `inversePrimary`, 6 `fgTertiaryContainer`, 8 `outline`; any other n returns `primary`. Her per-app color index c in 1..10 maps to slot `((c - 1) % 6) + 1`.
- Glyph font: family `icomoon` (`~/.local/share/fonts/icomoon/remix.ttf`; four files in that folder share the family name, so the shell loads the file explicitly through `FontLoader`). Material Symbols (`Config.iconFont`) is the fallback for glyphs missing from remix.
- Button glyphs (codepoints verified present in remix.ttf): clock ``, calendar ``, speaker ``, vpn on ``, vpn off ``, alarm ``, charger ``, battery ``.
- Behavior contract carried over from the dock: click focuses or launches (`shell.dockActivate`), middle click closes (`shell.dockClose`), wheel cycles one window per 120-unit notch (`shell.dockCycle`).
- Every task ends with all gates in the Gate set green, then commit and push.

## Gate set

From `~/.config/quickshell`:

```bash
rm -rf .claude
bash scripts/m3-qmllint-gate.sh
bash scripts/tests/test_niri_shape.sh
for t in scripts/tests/test_*.py; do python3 -I "$t"; done
for t in tests/*/*.mjs; do node "$t"; done
bash scripts/controls-behavior.sh && bash scripts/controls-render.sh
bash scripts/sidebar-render.sh && bash scripts/tag-strip-render.sh
bash scripts/bottom-bar-render.sh        # from Task 3 on
bash scripts/config-dump.sh check
bash scripts/style-refs.sh --elena
bash scripts/controls-golden-baseline.sh check
```

## File Structure

| Path | Role |
|---|---|
| `config/DockSymbols.js` | the ported symbol table + `symbolFor(appId)` (Task 1) |
| `config/BottomBarModel.js` | `batteryParts`, `signalParts`, `clockText`, `dateText`, `parseWifi`, `parseVpn`, `sidebarToggle` (Task 1) |
| `tests/bottom-bar/{dock-symbols,model}.test.mjs` | gates for the two modules (Task 1) |
| `config/Config.qml`, `config/Colors.qml`, `config/BatteryService.qml`, `config/AudioService.qml`, `config/BottomBarFonts.qml`, `config/NetworkStatusService.qml`, `config/qmldir` | scale, accent ramp, flags, font loader, network service (Task 2) |
| `bar/bottombar/{BarButton,ValuePill,VolumeRing,BatteryStack,SignalBars,DockGlyph,BottomBarContent}.qml`, `tests/bottom-bar/shell.qml`, `scripts/bottom-bar-render.sh` | rendering and the render check (Task 3) |
| `bar/BottomBar.qml`, `bar/Sidebar.qml`, `shell.qml`, `tests/bottom-bar/wiring.test.mjs` | window, sidebar page request, IPC, shell wiring (Task 4) |
| deleted: `bar/Dock.qml`, `bar/dock/*`, `scripts/dock-render.sh`, `tests/dock/{item,window}.test.mjs`, `tests/dock/shell.qml` | removal (Task 4) |
| `README.md`, memory notes | docs (Task 5) |

---

### Task 1: Pure modules and gates

**Files:**
- Create: `config/DockSymbols.js`, `config/BottomBarModel.js`
- Create: `tests/bottom-bar/dock-symbols.test.mjs`, `tests/bottom-bar/model.test.mjs`

**Interfaces:**
- Produces:
  - `DockSymbols.symbolFor(appId: string) -> { symbol: string, font: "icomoon"|"material", slot: 1..6 }` (case-insensitive key match; unknown ids and empty strings return the default entry).
  - `BottomBarModel.batteryParts(pct: number) -> ["full"|"half"|"empty", x3]` top to bottom (index 0 is the highest threshold); `pct < 0` (no battery) returns three `"empty"`.
  - `BottomBarModel.signalParts(signal: 0..4, connected: bool) -> 4 x "active"|"inactive"|"disconnected"`.
  - `BottomBarModel.clockText(d: Date) -> "HHmm"`, `dateText(d: Date) -> "dd"`.
  - `BottomBarModel.parseWifi(text: string) -> { connected: bool, signal: 0..4 }` for `nmcli -t -f ACTIVE,SIGNAL dev wifi` output.
  - `BottomBarModel.parseVpn(text: string) -> bool` for `nmcli -t -f TYPE,STATE con show --active` output.
  - `BottomBarModel.sidebarToggle(openPopup: string, currentPage: int, requested: int, pages: int) -> { page: int, open: bool }`.

- [ ] **Step 1: Write the failing tests**

`tests/bottom-bar/dock-symbols.test.mjs`:

```js
// Gate test: node tests/bottom-bar/dock-symbols.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/DockSymbols.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src + "; return { symbolFor, table }")()

// Ported entries resolve to their glyphs.
assert.equal(M.symbolFor("kitty").symbol, "")
assert.equal(M.symbolFor("firefox").symbol, "")
assert.equal(M.symbolFor("org.telegram.desktop").symbol, "")
// Case-insensitive, like DockModel.
assert.equal(M.symbolFor("Kitty").symbol, "")
assert.equal(M.symbolFor("GIMP").symbol, M.symbolFor("Gimp").symbol)
// Color index 1..10 maps onto slots 1..6 (7 to 10 wrap onto 1 to 4).
assert.equal(M.symbolFor("kitty").slot, 5)      // her color "5"
assert.equal(M.symbolFor("lutris").slot, 6)     // her color "6"
assert.equal(M.symbolFor("unknown-app").slot, 4) // default color "10" wraps to 4
// Unknown and empty ids give the default (Material Symbols fallback glyph).
for (const id of ["unknown-app", "", undefined, null]) {
  const s = M.symbolFor(id)
  assert.equal(s.font, "material")
  assert.equal(s.symbol, "web_asset")
}
// Every ported key resolves to a non-empty symbol and a slot in 1..6.
let n = 0
for (const k of Object.keys(M.table)) {
  const s = M.symbolFor(k)
  assert.ok(s.symbol.length > 0, k)
  assert.ok(s.slot >= 1 && s.slot <= 6, k)
  n++
}
assert.equal(n, 35, "34 ported apps + default")
console.log("dock symbols: ok")
```

`tests/bottom-bar/model.test.mjs`:

```js
// Gate test: node tests/bottom-bar/model.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/BottomBarModel.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src +
  "; return { batteryParts, signalParts, clockText, dateText, parseWifi, parseVpn, sidebarToggle }")()

// batteryParts: top part full above 83, half above 66; middle full above 49,
// half above 33; bottom full above 16, half above 0 (strict greater-than).
const bp = p => M.batteryParts(p).join(",")
assert.equal(bp(100), "full,full,full")
assert.equal(bp(84), "full,full,full")
assert.equal(bp(83), "half,full,full")
assert.equal(bp(67), "half,full,full")
assert.equal(bp(66), "empty,full,full")
assert.equal(bp(50), "empty,full,full")
assert.equal(bp(49), "empty,half,full")
assert.equal(bp(34), "empty,half,full")
assert.equal(bp(33), "empty,empty,full")
assert.equal(bp(17), "empty,empty,full")
assert.equal(bp(16), "empty,empty,half")
assert.equal(bp(1), "empty,empty,half")
assert.equal(bp(0), "empty,empty,empty")
assert.equal(bp(-1), "empty,empty,empty")   // no battery

// signalParts
const sp = (s, c) => M.signalParts(s, c).join(",")
assert.equal(sp(4, true), "active,active,active,active")
assert.equal(sp(2, true), "active,active,inactive,inactive")
assert.equal(sp(1, true), "active,inactive,inactive,inactive")
assert.equal(sp(0, true), "inactive,inactive,inactive,inactive")
assert.equal(sp(3, false), "disconnected,disconnected,disconnected,disconnected")

// clock and date
const d = new Date(2026, 9, 7, 9, 5)
assert.equal(M.clockText(d), "0905")
assert.equal(M.dateText(d), "07")

// parseWifi: nmcli -t output "yes:78" for the active network.
assert.deepEqual(M.parseWifi("no:90\nyes:78\nno:40\n"), { connected: true, signal: 4 })
assert.deepEqual(M.parseWifi("yes:55\n"), { connected: true, signal: 3 })
assert.deepEqual(M.parseWifi("yes:30\n"), { connected: true, signal: 2 })
assert.deepEqual(M.parseWifi("yes:10\n"), { connected: true, signal: 1 })
assert.deepEqual(M.parseWifi("no:90\n"), { connected: false, signal: 0 })
assert.deepEqual(M.parseWifi(""), { connected: false, signal: 0 })
assert.deepEqual(M.parseWifi("yes:oops\n"), { connected: true, signal: 1 })
// bucket edges: 1..25 -> 1, 26..50 -> 2, 51..75 -> 3, 76..100 -> 4
assert.equal(M.parseWifi("yes:25").signal, 1)
assert.equal(M.parseWifi("yes:26").signal, 2)
assert.equal(M.parseWifi("yes:75").signal, 3)
assert.equal(M.parseWifi("yes:76").signal, 4)

// parseVpn: any activated vpn or wireguard connection
assert.equal(M.parseVpn("802-11-wireless:activated\nvpn:activated\n"), true)
assert.equal(M.parseVpn("wireguard:activated\n"), true)
assert.equal(M.parseVpn("802-11-wireless:activated\n"), false)
assert.equal(M.parseVpn("vpn:activating\n"), false)
assert.equal(M.parseVpn(""), false)

// sidebarToggle: closed opens at page; same page closes; other page switches.
assert.deepEqual(M.sidebarToggle("", 0, 1, 2), { page: 1, open: true })
assert.deepEqual(M.sidebarToggle("sidebar", 1, 1, 2), { page: 1, open: false })
assert.deepEqual(M.sidebarToggle("sidebar", 0, 1, 2), { page: 1, open: true })
assert.deepEqual(M.sidebarToggle("launcher", 0, 0, 2), { page: 0, open: true })
// clamp: pages = 2 means 0 and 1 exist; 2 and -1 clamp.
assert.deepEqual(M.sidebarToggle("", 0, 2, 2), { page: 1, open: true })
assert.deepEqual(M.sidebarToggle("", 0, -1, 2), { page: 0, open: true })
console.log("bottom bar model: ok")
```

- [ ] **Step 2: Run them, expect failure**

Run: `node tests/bottom-bar/dock-symbols.test.mjs; node tests/bottom-bar/model.test.mjs`
Expected: both fail with `ENOENT` (modules missing).

- [ ] **Step 3: Write `config/DockSymbols.js`**

```js
.pragma library

// Verbatim port of window_information in
// config/eww/scripts/daemons/sway-dock.py (github.com/elenapan/dotfiles,
// master 2025-09-07): app id -> icomoon glyph + her color index (1..10).
// Keys are matched case-insensitively (niri app_id spelling varies).
var table = {
  "firefox": { symbol: "", color: 3 },
  "kitty": { symbol: "", color: 5 },
  "htop": { symbol: "", color: 2 },
  "btop": { symbol: "", color: 2 },
  "Sxiv": { symbol: "", color: 1 },
  "Nsxiv": { symbol: "", color: 1 },
  "nemo": { symbol: "", color: 3 },
  "chrome-discordapp.com__channels_@me-Default": { symbol: "", color: 4 },
  "chrome-chatgpt.com__-Default": { symbol: "", color: 2 },
  "lutris": { symbol: "", color: 6 },
  "net.lutris.Lutris": { symbol: "", color: 6 },
  "editor": { symbol: "", color: 5 },
  "scratchpad": { symbol: "", color: 1 },
  "scratchpad_input": { symbol: "", color: 3 },
  "gucharmap": { symbol: "", color: 2 },
  "steam": { symbol: "", color: 2 },
  "mpv": { symbol: "", color: 6 },
  "chromium-browser": { symbol: "", color: 4 },
  "org.chromium.Chromium": { symbol: "", color: 4 },
  "org.pwmt.zathura": { symbol: "", color: 3 },
  "Emacs": { symbol: "", color: 2 },
  "org": { symbol: "", color: 2 },
  "explorer.exe": { symbol: "", color: 4 },
  "appimagekit_3a48058ef277d45ae2228089429c0259-Telegram_Desktop": { symbol: "", color: 4 },
  "org.telegram.desktop": { symbol: "", color: 4 },
  "pavucontrol": { symbol: "", color: 4 },
  "org.pulseaudio.pavucontrol": { symbol: "", color: 4 },
  "chrome-open.spotify.com__-Default": { symbol: "", color: 2 },
  "Wine": { symbol: "", color: 1 },
  "chrome-mail.proton.me__-Default": { symbol: "", color: 6 },
  "Gimp": { symbol: "", color: 4 },
  "gimp": { symbol: "", color: 4 },
  "org.inkscape.Inkscape": { symbol: "", color: 2 },
  "deluge": { symbol: "", color: 1 },
  // her ___default___ glyph (U+E421) is not in remix.ttf: Material Symbols
  // supplies an equivalent window glyph instead.
  "___default___": { symbol: "web_asset", color: 10, material: true }
}

var lower = {}
for (var k in table) lower[k.toLowerCase()] = table[k]

// Her color index 1..10 onto the six accent slots (7..10 wrap onto 1..4).
function slotOf(color) { return ((color - 1) % 6) + 1 }

function symbolFor(appId) {
  var key = appId === undefined || appId === null ? "" : String(appId).toLowerCase()
  var entry = lower[key] || lower["___default___"]
  return { symbol: entry.symbol, font: entry.material ? "material" : "icomoon", slot: slotOf(entry.color) }
}
```

- [ ] **Step 4: Write `config/BottomBarModel.js`**

```js
.pragma library

// Pure decisions for the bottom bar. No QML types, no I/O.

function pad2(n) { return (n < 10 ? "0" : "") + n }

function clockText(d) { return pad2(d.getHours()) + pad2(d.getMinutes()) }
function dateText(d) { return pad2(d.getDate()) }

// One battery part: "full" above `half`, "half" above `min` (both strict),
// else "empty". Thresholds are the eww battery-progress-bar-part values.
function part(pct, min, half) {
  if (pct > half) return "full"
  if (pct > min) return "half"
  return "empty"
}

// Top to bottom: the top part has the highest threshold.
function batteryParts(pct) {
  var p = typeof pct === "number" && pct >= 0 ? pct : -1
  if (p < 0) return ["empty", "empty", "empty"]
  return [part(p, 66, 83), part(p, 33, 49), part(p, 0, 16)]
}

function signalParts(signal, connected) {
  var out = []
  for (var i = 1; i <= 4; i++) {
    if (!connected) out.push("disconnected")
    else out.push(signal >= i ? "active" : "inactive")
  }
  return out
}

// nmcli -t -f ACTIVE,SIGNAL dev wifi -> active network and 1..4 bucket.
function parseWifi(text) {
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = lines[i].split(":")
    if (f[0] !== "yes") continue
    var pct = parseInt(f[1], 10)
    var bucket = isNaN(pct) ? 1 : Math.max(1, Math.min(4, Math.ceil(pct / 25)))
    return { connected: true, signal: bucket }
  }
  return { connected: false, signal: 0 }
}

// nmcli -t -f TYPE,STATE con show --active -> any activated vpn/wireguard.
function parseVpn(text) {
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = lines[i].split(":")
    if ((f[0] === "vpn" || f[0] === "wireguard") && f[1] === "activated") return true
  }
  return false
}

// Sidebar page buttons: closed opens at the page, the open page closes it,
// another page switches. `pages` is the number of pages that exist.
function sidebarToggle(openPopup, currentPage, requested, pages) {
  var page = Math.max(0, Math.min(pages - 1, Math.floor(requested)))
  if (openPopup === "sidebar" && currentPage === page) return { page: page, open: false }
  return { page: page, open: true }
}
```

- [ ] **Step 5: Run the tests, expect pass**

Run: `node tests/bottom-bar/dock-symbols.test.mjs && node tests/bottom-bar/model.test.mjs`
Expected: `dock symbols: ok` and `bottom bar model: ok`.

- [ ] **Step 6: Commit**

```bash
cd ~ && yadm add .config/quickshell/config/DockSymbols.js .config/quickshell/config/BottomBarModel.js .config/quickshell/tests/bottom-bar
yadm commit -m "bottom bar: pure symbol table and bar model with gate tests" && yadm push origin main
```

---

### Task 2: Tokens, flags, font loader, network service

**Files:**
- Modify: `config/Config.qml`, `config/Colors.qml`, `config/BatteryService.qml`, `config/AudioService.qml`, `config/qmldir`
- Create: `config/BottomBarFonts.qml`, `config/NetworkStatusService.qml`
- Modify: `tests/elena/config-dump.baseline.json` (additive keys: recapture), `tests/bottom-bar/wiring.test.mjs` (create)

**Interfaces:**
- Consumes: Task 1 `parseWifi`, `parseVpn`.
- Produces:
  - `Config.elenaScale: real = 1.5`, `Config.dp(n: real): int`, `Config.bottomBarHeight: int = dp(43)`.
  - `Colors.elenaAccent(n: int): color`.
  - `BatteryService.charging: bool` (true while Charging or PendingCharge).
  - `AudioService.barActive: bool` (own writer flag, included in `sinkActive`).
  - `BottomBarFonts.family: string`, `BottomBarFonts.materialFamily: string`.
  - `NetworkStatusService { active: bool; connected: bool; signal: int; vpn: bool }` (singleton, polls only while `active`).

- [ ] **Step 1: Failing structural test `tests/bottom-bar/wiring.test.mjs` (part 1)**

```js
// Gate test: node tests/bottom-bar/wiring.test.mjs (structural)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")

const cfg = rd("../../config/Config.qml")
assert.match(cfg, /readonly property real elenaScale: 1\.5/)
assert.match(cfg, /function dp\(n\) \{ return Math\.round\(n \* elenaScale\) \}/)
assert.match(cfg, /readonly property int bottomBarHeight: dp\(43\)/)

const colors = rd("../../config/Colors.qml")
assert.match(colors, /function elenaAccent\(n\)/)
for (const role of ["error", "secondary", "tertiary", "primary", "inversePrimary", "fgTertiaryContainer", "outline"])
  assert.match(colors.slice(colors.indexOf("function elenaAccent")), new RegExp("return " + role + "\\b"), role)

assert.match(rd("../../config/BatteryService.qml"), /readonly property bool charging:/)
const audio = rd("../../config/AudioService.qml")
assert.match(audio, /property bool barActive: false/)
assert.match(audio, /sinkActive: indicatorActive \|\| popupActive \|\| sidebarActive \|\| barActive/)

const net = rd("../../config/NetworkStatusService.qml")
assert.match(net, /pragma Singleton/)
assert.match(net, /nmcli -t -f ACTIVE,SIGNAL dev wifi/)
assert.match(net, /nmcli -t -f TYPE,STATE con show --active/)
assert.match(net, /running: root\.active/, "polls only while a consumer is active")
assert.match(net, /BottomBarModel\.parseWifi/)
const qmldir = rd("../../config/qmldir")
assert.match(qmldir, /singleton NetworkStatusService 1\.0 NetworkStatusService\.qml/)
assert.match(qmldir, /singleton BottomBarFonts 1\.0 BottomBarFonts\.qml/)
console.log("bottom bar wiring (config): ok")
```

Run: `node tests/bottom-bar/wiring.test.mjs` Expected: FAIL (assertions missing).

- [ ] **Step 2: `Config.qml`**

Next to `tagStripHeight`, add:

```qml
  // The bottom bar follows the reference rice's dpi() scale (1.5 on 1080p).
  readonly property real elenaScale: 1.5
  function dp(n) { return Math.round(n * elenaScale) }
  readonly property int bottomBarHeight: dp(43)
```

- [ ] **Step 3: `Colors.qml`**

Add near the other helper functions:

```qml
  // Reference-rice accent slots mapped onto this palette. The bottom bar and
  // the dock cycle this ramp; change the table here, not in the bar.
  function elenaAccent(n) {
    switch (n) {
    case 1: return error
    case 2: return secondary
    case 3: return tertiary
    case 4: return primary
    case 5: return inversePrimary
    case 6: return fgTertiaryContainer
    case 8: return outline
    default: return primary
    }
  }
```

- [ ] **Step 4: `BatteryService.qml`**

Add:

```qml
  readonly property bool charging: batteryDevice
    && (batteryDevice.state === UPowerDeviceState.Charging
      || batteryDevice.state === UPowerDeviceState.PendingCharge)
```

(Import of `UPowerDeviceState` is already present: the service uses `PendingCharge`.)

- [ ] **Step 5: `AudioService.qml`**

Add `property bool barActive: false` next to `sidebarActive`, and change `sinkActive` to
`indicatorActive || popupActive || sidebarActive || barActive`.

- [ ] **Step 6: `config/BottomBarFonts.qml`**

```qml
pragma Singleton
import QtQml
import QtQuick
import Quickshell

// Four font files in ~/.local/share/fonts/icomoon share the family "icomoon",
// so the bar loads the remix set explicitly to get a unique family name. When
// the file is missing the plain family name is used (and may resolve to a
// different icon set; glyphs then show as tofu, which is the failure signal).
QtObject {
  id: root

  readonly property string path: Quickshell.env("HOME") + "/.local/share/fonts/icomoon/remix.ttf"
  readonly property FontLoader loader: FontLoader { source: "file://" + root.path }
  readonly property string family: root.loader.status === FontLoader.Ready ? root.loader.name : "icomoon"
  readonly property string materialFamily: Config.iconFont
}
```

- [ ] **Step 7: `config/NetworkStatusService.qml`**

```qml
pragma Singleton
import QtQml
import Quickshell.Io
import "BottomBarModel.js" as BottomBarModel

// Wi-Fi signal bucket and VPN state for the bottom bar. nmcli monitor wakes a
// refresh on any NetworkManager change; a 10 s timer is the fallback. Nothing
// runs while no consumer sets `active`.
QtObject {
  id: root

  property bool active: false
  property bool connected: false
  property int signal: 0
  property bool vpn: false

  function refresh() {
    if (!root.active) return
    if (!wifiQuery.running) wifiQuery.running = true
    if (!vpnQuery.running) vpnQuery.running = true
  }

  property Process wifiQuery: Process {
    command: ["sh", "-c", "nmcli -t -f ACTIVE,SIGNAL dev wifi"]
    stdout: StdioCollector {
      onStreamFinished: {
        var r = BottomBarModel.parseWifi(text)
        root.connected = r.connected
        root.signal = r.signal
      }
    }
  }

  property Process vpnQuery: Process {
    command: ["sh", "-c", "nmcli -t -f TYPE,STATE con show --active"]
    stdout: StdioCollector {
      onStreamFinished: root.vpn = BottomBarModel.parseVpn(text)
    }
  }

  property Process monitor: Process {
    running: root.active
    command: ["nmcli", "monitor"]
    stdout: SplitParser {
      onRead: root.refresh()
    }
    onRunningChanged: if (!running && root.active) restart.start()
  }

  property Timer restart: Timer {
    interval: 2000
    onTriggered: if (root.active) root.monitor.running = true
  }

  property Timer fallback: Timer {
    interval: 10000
    repeat: true
    running: root.active
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
```

- [ ] **Step 8: `config/qmldir`**

Append:

```
singleton BottomBarFonts 1.0 BottomBarFonts.qml
singleton NetworkStatusService 1.0 NetworkStatusService.qml
```

- [ ] **Step 9: Run the test, recapture the dump baseline, gates**

```bash
node tests/bottom-bar/wiring.test.mjs                  # Expected: "bottom bar wiring (config): ok"
bash scripts/config-dump.sh check                       # Expected: "added Config.elenaScale / Config.bottomBarHeight ..." (additive)
bash scripts/config-dump.sh capture                     # additive keys only: review the diff of the baseline file
git -C ~ diff --stat -- .config/quickshell/tests/elena/config-dump.baseline.json
```

The recapture is legitimate only because the diff adds exactly `Config.elenaScale`, `Config.bottomBarHeight` and `Config.tagStripHeight`-style keys and the `Colors`/service additions listed above; any changed value is a bug. Then run the Gate set (skip `bottom-bar-render.sh`, which does not exist yet).

- [ ] **Step 10: Commit**

```bash
cd ~ && yadm add .config/quickshell/config .config/quickshell/tests/bottom-bar/wiring.test.mjs .config/quickshell/tests/elena/config-dump.baseline.json
yadm commit -m "bottom bar: scale tokens, accent ramp, font loader, network status service" && yadm push origin main
```

---

### Task 3: Rendering components and render check

**Files:**
- Create: `bar/bottombar/{BarButton,ValuePill,VolumeRing,BatteryStack,SignalBars,DockGlyph,BottomBarContent}.qml`
- Create: `tests/bottom-bar/shell.qml`, `scripts/bottom-bar-render.sh`

**Interfaces:**
- Consumes: Task 1 modules, Task 2 `Config.dp`, `Config.bottomBarHeight`, `Colors.elenaAccent`, `BottomBarFonts`.
- Produces: `BottomBarContent` with these properties and signals (all other pieces are internal):
  - properties: `items: var` (array of `DockModel.dockItems` entries), `clockText: string`, `dateText: string`, `volume: real` (0..100), `muted: bool`, `batteryPct: real`, `charging: bool`, `signal: int`, `connected: bool`, `vpn: bool`, `alarmCount: int`, `forceHover: string` (test hook: `"glance"|"tasks"|"media"|"network"|"alarms"|"logout"|""`).
  - signals: `glanceClicked()`, `glanceRightClicked()`, `tasksClicked()`, `mediaClicked()`, `mediaRightClicked()`, `mediaMiddleClicked()`, `mediaScrolled(int delta)`, `networkClicked()`, `alarmsClicked()`, `logoutClicked()`, `itemActivated(string appId)`, `itemClosed(string appId)`, `itemCycled(string appId, int direction)`.

- [ ] **Step 1: `bar/bottombar/ValuePill.qml`**

```qml
import QtQuick
import "../../config"

// Circle (or pill) holding a short value: the clock, the date, the alarm count.
Rectangle {
  id: root
  property string text: ""
  property int minWidth: Config.dp(23)

  implicitHeight: Config.dp(23)
  implicitWidth: Math.max(root.minWidth, label.implicitWidth + Config.dp(8))
  radius: height / 2
  color: Colors.surfaceContainerHighest

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text
    color: Colors.fgSurface
    font.family: Config.fontFamily
    font.pixelSize: Math.round(8 * 4 / 3 * Config.elenaScale)   // 8pt * scale
  }
}
```

- [ ] **Step 2: `bar/bottombar/BarButton.qml`**

```qml
import QtQuick
import "../../config"

// One bottom-bar button: accent glyph, optional content to its right, and a
// 3 S bottom border in the accent while hovered.
Item {
  id: root

  property string symbol: ""
  property color accent: Colors.primary
  property bool forceHover: false
  default property alias content: contentRow.data
  readonly property bool hovered: mouse.containsMouse || root.forceHover

  signal clicked()
  signal rightClicked()
  signal middleClicked()
  signal wheel(int delta)

  implicitWidth: Config.dp(67)
  implicitHeight: Config.bottomBarHeight

  Row {
    anchors.centerIn: parent
    spacing: Config.dp(10)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.symbol
      color: root.accent
      font.family: BottomBarFonts.family
      font.pixelSize: Math.round(12 * 4 / 3 * Config.elenaScale)   // 12pt * scale
    }
    Row {
      id: contentRow
      anchors.verticalCenter: parent.verticalCenter
      spacing: Config.dp(10)
    }
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: Config.dp(3)
    color: root.hovered ? root.accent : "transparent"
    Behavior on color {
      enabled: !Config.reducedMotion
      ColorAnimation { duration: 300 }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(m) {
      if (m.button === Qt.RightButton) root.rightClicked()
      else if (m.button === Qt.MiddleButton) root.middleClicked()
      else root.clicked()
    }
    onWheel: function(w) { root.wheel(w.angleDelta.y) }
  }
}
```

- [ ] **Step 3: `bar/bottombar/VolumeRing.qml`**

```qml
import QtQuick
import "../../config"

// Circular volume indicator: backdrop ring plus an arc that starts at 12
// o'clock and grows counter-clockwise (eww circular-progress :start-at 75,
// :clockwise false).
Item {
  id: root
  property real value: 0          // 0..100
  property bool muted: false
  property color fillColor: root.muted ? Colors.elenaAccent(8) : Colors.fgSurface

  implicitWidth: Config.dp(23)
  implicitHeight: Config.dp(23)

  onValueChanged: canvas.requestPaint()
  onMutedChanged: canvas.requestPaint()
  onFillColorChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var t = Config.dp(5)
      var r = Math.min(width, height) / 2 - t / 2
      var cx = width / 2, cy = height / 2
      ctx.lineWidth = t
      ctx.lineCap = "butt"
      ctx.strokeStyle = Colors.surfaceContainerHighest
      ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2, false); ctx.stroke()
      var v = Math.max(0, Math.min(100, root.value)) / 100
      if (v <= 0) return
      ctx.strokeStyle = root.fillColor
      ctx.beginPath()
      ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 - Math.PI * 2 * v, true)
      ctx.stroke()
    }
  }
}
```

- [ ] **Step 4: `bar/bottombar/BatteryStack.qml`**

```qml
import QtQuick
import "../../config"
import "../../config/BottomBarModel.js" as BottomBarModel

// Three stacked bars: full above half-threshold, half-opacity above the
// lower threshold, empty otherwise (BottomBarModel.batteryParts).
Column {
  id: root
  property real pct: -1
  property color fillColor: Colors.elenaAccent(6)

  spacing: 4
  readonly property var parts: BottomBarModel.batteryParts(root.pct)

  Repeater {
    model: root.parts
    Rectangle {
      required property string modelData
      width: Config.dp(14)
      height: (Config.dp(23) - root.spacing * 2) / 3
      radius: height / 2
      color: modelData === "empty" ? Colors.surfaceContainerHighest : root.fillColor
      opacity: modelData === "half" ? 0.5 : 1
    }
  }
}
```

- [ ] **Step 5: `bar/bottombar/SignalBars.qml`**

```qml
import QtQuick
import "../../config"
import "../../config/BottomBarModel.js" as BottomBarModel

// Four vertical bars growing left to right; all four collapse to short muted
// bars when there is no active Wi-Fi network.
Row {
  id: root
  property int signal: 0
  property bool connected: false
  property color activeColor: Colors.elenaAccent(4)

  spacing: 4
  readonly property var parts: BottomBarModel.signalParts(root.signal, root.connected)
  // Heights: 23-16, 23-10.5, 23-5.5, 23 (scaled); disconnected: 23-17.
  readonly property var heights: [Config.dp(7), Config.dp(12.5), Config.dp(17.5), Config.dp(23)]

  Repeater {
    model: root.parts
    Item {
      required property string modelData
      required property int index
      width: Config.dp(5)
      height: Config.dp(23)
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: modelData === "disconnected" ? Config.dp(6) : root.heights[index]
        radius: width / 2
        color: modelData === "active" ? root.activeColor
          : (modelData === "disconnected" ? Colors.elenaAccent(8) : Colors.surfaceContainerHighest)
      }
    }
  }
}
```

- [ ] **Step 6: `bar/bottombar/DockGlyph.qml`**

```qml
import QtQuick
import "../../config"
import "../../config/DockSymbols.js" as DockSymbols

// One dock item: app glyph in its accent, a 6x3 S indicator under it while the
// app is focused, muted glyph while pinned with no window. Click focuses or
// launches, middle click closes, wheel cycles one window per 120 notch.
Item {
  id: root

  property string appId: ""
  property bool running: false
  property bool focused: false
  property real wheelAccum: 0

  readonly property var sym: DockSymbols.symbolFor(root.appId)
  readonly property color accent: Colors.elenaAccent(root.sym.slot)
  readonly property color glyphColor: root.running ? root.accent : Colors.elenaAccent(8)

  signal activated()
  signal closeRequested()
  signal cycled(int direction)

  implicitWidth: Config.dp(35)
  implicitHeight: Config.dp(26) + Config.dp(6) + Config.dp(3)

  Text {
    id: glyph
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    text: root.sym.symbol
    color: root.glyphColor
    font.family: root.sym.font === "material" ? BottomBarFonts.materialFamily : BottomBarFonts.family
    font.pixelSize: Math.round(16 * 4 / 3 * Config.elenaScale)   // 16pt * scale
    Behavior on color {
      enabled: !Config.reducedMotion
      ColorAnimation { duration: 200 }
    }
  }

  Rectangle {
    objectName: "focusIndicator"
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    width: Config.dp(6)
    height: Config.dp(3)
    radius: height / 2
    color: root.accent
    opacity: root.focused ? 1 : 0
    Behavior on opacity {
      enabled: !Config.reducedMotion
      NumberAnimation { duration: 200 }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) root.closeRequested()
      else root.activated()
    }
    onWheel: function(wheel) {
      const dy = wheel.angleDelta.y
      if (dy === 0) return
      // Reset on direction flip; one cycle per full 120 notch so a touchpad
      // swipe of many small deltas does not skip through every window.
      if ((dy > 0) !== (root.wheelAccum > 0)) root.wheelAccum = 0
      root.wheelAccum += dy
      while (Math.abs(root.wheelAccum) >= 120) {
        const dir = root.wheelAccum > 0 ? -1 : 1
        root.wheelAccum -= root.wheelAccum > 0 ? 120 : -120
        root.cycled(dir)
      }
    }
  }
}
```

- [ ] **Step 7: `bar/bottombar/BottomBarContent.qml`**

```qml
import QtQuick
import "../../config"

// The whole bar surface without a window (the render check loads it directly).
Item {
  id: root

  property var items: []
  property string clockText: "0000"
  property string dateText: "00"
  property real volume: 0
  property bool muted: false
  property real batteryPct: -1
  property bool charging: false
  property int signal: 0
  property bool connected: false
  property bool vpn: false
  property int alarmCount: 0
  property string forceHover: ""

  signal glanceClicked()
  signal glanceRightClicked()
  signal tasksClicked()
  signal mediaClicked()
  signal mediaRightClicked()
  signal mediaMiddleClicked()
  signal mediaScrolled(int delta)
  signal networkClicked()
  signal alarmsClicked()
  signal logoutClicked()
  signal itemActivated(string appId)
  signal itemClosed(string appId)
  signal itemCycled(string appId, int direction)

  implicitHeight: Config.bottomBarHeight

  readonly property int outerRadius: Config.dp(20)

  // Left cluster
  Rectangle {
    id: left
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    width: Config.dp(300)
    height: parent.height
    color: Colors.surface
    topRightRadius: root.outerRadius

    Row {
      anchors.fill: parent
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: ""
        accent: Colors.elenaAccent(1)
        forceHover: root.forceHover === "glance"
        onClicked: root.glanceClicked()
        onRightClicked: root.glanceRightClicked()
        ValuePill { text: root.clockText; minWidth: Config.dp(34) }
      }
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: ""
        accent: Colors.elenaAccent(2)
        forceHover: root.forceHover === "tasks"
        onClicked: root.tasksClicked()
        ValuePill { text: root.dateText }
      }
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: ""
        accent: Colors.elenaAccent(5)
        forceHover: root.forceHover === "media"
        onClicked: root.mediaClicked()
        onRightClicked: root.mediaRightClicked()
        onMiddleClicked: root.mediaMiddleClicked()
        onWheel: function(delta) { root.mediaScrolled(delta) }
        VolumeRing { value: root.volume; muted: root.muted }
      }
    }
  }

  // Centre dock
  Row {
    id: dock
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Config.dp(6)
    spacing: Config.dp(4)

    Repeater {
      model: root.items
      DockGlyph {
        required property var modelData
        appId: modelData.appId
        running: modelData.count > 0
        focused: modelData.focused
        onActivated: root.itemActivated(modelData.appId)
        onCloseRequested: root.itemClosed(modelData.appId)
        onCycled: function(direction) { root.itemCycled(modelData.appId, direction) }
      }
    }
  }

  // Right cluster
  Rectangle {
    id: right
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    width: Config.dp(300)
    height: parent.height
    color: Colors.surface
    topLeftRadius: root.outerRadius

    Row {
      anchors.fill: parent
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: root.vpn ? "" : ""
        accent: Colors.elenaAccent(4)
        forceHover: root.forceHover === "network"
        onClicked: root.networkClicked()
        SignalBars { signal: root.signal; connected: root.connected }
      }
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: ""
        accent: Colors.elenaAccent(3)
        forceHover: root.forceHover === "alarms"
        onClicked: root.alarmsClicked()
        Item {
          width: Config.dp(23)
          height: Config.dp(23)
          ValuePill {
            anchors.centerIn: parent
            visible: root.alarmCount > 0
            text: String(root.alarmCount)
          }
          Rectangle {   // no alarms: the slashed line
            anchors.centerIn: parent
            visible: root.alarmCount === 0
            width: Config.dp(23)
            height: Config.dp(4)
            radius: height / 2
            rotation: 38
            color: Colors.elenaAccent(3)
          }
        }
      }
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: root.charging ? "" : ""
        accent: Colors.elenaAccent(6)
        forceHover: root.forceHover === "logout"
        onClicked: root.logoutClicked()
        BatteryStack { pct: root.batteryPct }
      }
    }
  }
}
```

- [ ] **Step 8: `tests/bottom-bar/shell.qml` and `scripts/bottom-bar-render.sh`**

`tests/bottom-bar/shell.qml` (copied to the root of a config copy; stage 1000x65 so the clusters and dock do not overlap; two renders are needed because hover is a forced property, so the stage holds two `BottomBarContent` instances stacked vertically: `forceHover: ""` on top with 100 % battery, 4-bar signal, 100 % volume; `forceHover: "glance"` below with 50 % battery, 2-bar signal, muted, 0 alarms vs 3 alarms respectively):

```qml
// Copied to the root of a config copy by scripts/bottom-bar-render.sh.
import QtQuick
import Quickshell
import "config"
import "bar/bottombar"

ShellRoot {
  FloatingWindow {
    implicitWidth: 1000
    implicitHeight: 170
    color: Colors.surface

    Item {
      id: stage
      width: 1000
      height: 170
      Rectangle { anchors.fill: parent; color: "#101216" }

      BottomBarContent {          // A: idle, full battery, 4 bars, volume 100
        x: 0; y: 0; width: 1000
        items: [
          { appId: "kitty",  pinned: true,  count: 1, windowIds: [3], focused: true,  urgent: false },
          { appId: "firefox", pinned: true, count: 0, windowIds: [],  focused: false, urgent: false },
          { appId: "mpv",    pinned: false, count: 1, windowIds: [7], focused: false, urgent: false }
        ]
        clockText: "0905"; dateText: "07"
        volume: 100; muted: false
        batteryPct: 100; charging: true
        signal: 4; connected: true; vpn: true
        alarmCount: 3
      }
      BottomBarContent {          // B: hover on glance, half battery, 2 bars, muted
        x: 0; y: 85; width: 1000
        items: []
        clockText: "2359"; dateText: "31"
        volume: 40; muted: true
        batteryPct: 50; charging: false
        signal: 2; connected: true; vpn: false
        alarmCount: 0
        forceHover: "glance"
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

`scripts/bottom-bar-render.sh` (same scaffold as `scripts/dock-render.sh`: scratch HOME, copy `config bar resources`, elenapan fixed palette, `GOLDEN_OUT`, the same error pattern filter; then a python3/PIL block). Palette values (elenapan): surface `#1a1f2b`, surfaceContainerHighest `#343c4d`, error `#ff6b6b`, secondary `#f06292`, tertiary `#5bb8d4`, primary `#c77dc8`, inversePrimary `#8e4f90`, fgTertiaryContainer `#cfeefa`, outline `#5b6578`. Required assertions (sample rectangles relative to the stage; `S = 1.5`, bar height 65):
1. Image size is 1000x170; no QML error lines in the log.
2. **Cluster surface:** a 6x6 patch at (20, 30) and at (980, 30) equals `#1a1f2b` (top 85 px bar A), and the pixel at (449, 0) (left cluster's top-right corner, radius 30) equals the stage background `#101216` (corner is rounded away).
3. **Hover border:** in bar B the bottom 4 px strip under the first button (x 20..80, y 85+61..85+65) is the glance accent `#ff6b6b`; in bar A the same strip is not.
4. **Focused indicator:** in bar A a 9x4 patch at the bottom-centre of the first dock item (kitty, slot 5) equals `#8e4f90` (inversePrimary); the second item (firefox, pinned with no window) has no indicator-colored pixels and its glyph pixels are `#5b6578` (muted outline); the third (mpv, slot 6, running, unfocused) shows its glyph in `#cfeefa` and no indicator.
5. **Battery stack:** in bar A (100 %) all three parts are `#cfeefa`; in bar B (50 %) top part is `#343c4d`, middle is half-opacity `#cfeefa` over the surface (blend within tolerance 8), bottom is `#cfeefa`.
6. **Signal bars:** bar A has four columns, all `#c77dc8`; bar B has two `#c77dc8` and two `#343c4d`.
7. **Ring:** in bar A (volume 100) the whole ring is `#f2f4f8` (fgSurface); in bar B (volume 40, muted) the arc from 12 o'clock counter-clockwise to about 144 degrees is `#5b6578` and the remaining arc is the backdrop `#343c4d`.
8. **Alarm count:** bar A shows a pill (pixels `#343c4d` inside the button area); bar B shows the slashed line in `#5bb8d4`.

Use a tolerance of 8/255 per channel; print each measured count like the dock script, assert thresholds, end with `bottom bar render: ok`. Mutation-prove: (a) set `ValuePill` color to red and confirm assertion 8 fails; (b) change the battery thresholds in `BottomBarModel.js` and confirm assertion 5 fails; revert both.

- [ ] **Step 9: Gates, commit**

```bash
bash scripts/bottom-bar-render.sh        # Expected: bottom bar render: ok
<Gate set>
cd ~ && yadm add .config/quickshell/bar/bottombar .config/quickshell/tests/bottom-bar .config/quickshell/scripts/bottom-bar-render.sh
yadm commit -m "bottom bar: content components and render check" && yadm push origin main
```

---

### Task 4: Window, shell wiring, sidebar page request, removal of the dock

**Files:**
- Create: `bar/BottomBar.qml`
- Modify: `bar/Sidebar.qml`, `shell.qml`
- Modify: `tests/bottom-bar/wiring.test.mjs` (part 2), `scripts/popup-ipc-check.sh` (add `openSidebarPage` sequence)
- Delete: `bar/Dock.qml`, `bar/dock/DockContent.qml`, `bar/dock/DockItem.qml`, `scripts/dock-render.sh`, `tests/dock/item.test.mjs`, `tests/dock/window.test.mjs`, `tests/dock/shell.qml`

**Interfaces:**
- Consumes: Task 1 to 3.
- Produces: `shell.openSidebarPage(n)` (IPC `openSidebarPage(n: int): bool`), IPC `bottomBarState(): string` (JSON `{ items, clockText, dateText, volume, muted, batteryPct, charging, signal, connected, vpn, alarmCount, height }`), `Sidebar.showPage(n)` and `Sidebar.currentPage`.

- [ ] **Step 1: Failing structural tests (part 2) appended to `tests/bottom-bar/wiring.test.mjs`**

```js
const bar = rd("../../bar/BottomBar.qml")
assert.match(bar, /WlrLayershell\.layer: WlrLayer\.Bottom/, "below normal windows")
assert.match(bar, /exclusionMode: ExclusionMode\.Normal/)
assert.match(bar, /exclusiveZone: root\.implicitHeight/, "reserves the bar height")
assert.match(bar, /anchors\s*\{[\s\S]*?left: true[\s\S]*?right: true[\s\S]*?bottom: true/)
assert.match(bar, /Config\.layerNamespace\("bottombar"\)/)
assert.match(bar, /BottomBarContent \{/)
assert.match(bar, /AudioService.*barActive|Binding \{[^}]*property: "barActive"/s, "volume polling flag")
assert.match(bar, /NetworkStatusService.*active|Binding \{[^}]*target: NetworkStatusService/s)
assert.doesNotMatch(bar, /HoverHandler|revealed|holdTimer/, "no auto-hide logic")

const shell = rd("../../shell.qml")
assert.match(shell, /BottomBar \{/)
assert.doesNotMatch(shell, /\n  Dock \{/, "old dock instance removed")
assert.doesNotMatch(shell, /function dockReveal\(/)
assert.match(shell, /function dockState\(\): string/, "dockState kept")
assert.match(shell, /function bottomBarState\(\): string/)
assert.match(shell, /function openSidebarPage\(n: int\): bool/)
assert.match(shell, /BottomBarModel\.sidebarToggle\(/)
const sb = rd("../../bar/Sidebar.qml")
assert.match(sb, /function showPage\(n\)/)
assert.match(sb, /readonly property int currentPage: content\.currentPage/)
// Button to action table (spec): which signal calls what.
const wire = bar.slice(bar.indexOf("BottomBarContent {"))
assert.match(wire, /onGlanceClicked:[^\n]*openSidebarPage\(0\)/)
assert.match(wire, /onTasksClicked:[^\n]*openSidebarPage\(1\)/)
assert.match(wire, /onMediaClicked:[^\n]*openSidebarPage\(2\)/)
assert.match(wire, /onMediaMiddleClicked:[^\n]*toggleMute\(\)/)
assert.match(wire, /onMediaRightClicked:[^\n]*pavucontrol/)
assert.match(wire, /onGlanceRightClicked:[^\n]*launcher/)
console.log("bottom bar wiring: ok")
```

Run: expected FAIL.

- [ ] **Step 2: `bar/Sidebar.qml`**

Add inside the root `PopupBase`:

```qml
  readonly property int currentPage: content.currentPage
  readonly property int pageCount: 2
  // Pages are 0 (Status) and 1 (Dashboard); R2 adds the media page.
  function showPage(n) { content.currentPage = Math.max(0, Math.min(root.pageCount - 1, Math.floor(n))) }
```

- [ ] **Step 3: `bar/BottomBar.qml`**

```qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "../config/BottomBarModel.js" as BottomBarModel
import "bottombar"

// Elena's bottom bar: a full-width layer-shell window below normal windows
// that reserves its height. Data comes from the existing services; actions
// leave through signals that shell.qml wires.
PanelWindow {
  id: root

  property var items: []
  property alias content: content

  signal sidebarPageRequested(int page)
  signal launcherRequested()
  signal networkRequested()
  signal logoutRequested()
  signal itemActivated(string appId)
  signal itemClosed(string appId)
  signal itemCycled(string appId, int direction)

  anchors {
    left: true
    right: true
    bottom: true
  }
  implicitHeight: Config.bottomBarHeight
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: root.implicitHeight
  WlrLayershell.namespace: Config.layerNamespace("bottombar")
  WlrLayershell.layer: WlrLayer.Bottom

  // Own writer flags: the bar is the only consumer of these services' slow
  // paths while it is visible.
  Binding { target: AudioService; property: "barActive"; value: root.visible }
  Binding { target: NetworkStatusService; property: "active"; value: root.visible }

  SystemClock { id: clock; precision: SystemClock.Minutes }

  BottomBarContent {
    id: content
    anchors.fill: parent
    items: root.items
    clockText: BottomBarModel.clockText(clock.date)
    dateText: BottomBarModel.dateText(clock.date)
    volume: Math.round(AudioService.volume * 100)
    muted: AudioService.muted
    batteryPct: BatteryService.pct
    charging: BatteryService.charging
    signal: NetworkStatusService.signal
    connected: NetworkStatusService.connected
    vpn: NetworkStatusService.vpn
    alarmCount: 0   // R5 supplies the alarm list

    onGlanceClicked: root.sidebarPageRequested(0)
    onGlanceRightClicked: root.launcherRequested()
    onTasksClicked: root.sidebarPageRequested(1)
    onMediaClicked: root.sidebarPageRequested(2)
    onMediaScrolled: function(delta) {
      AudioService.setVolume(Math.max(0, Math.min(1, AudioService.volume + (delta > 0 ? 0.05 : -0.05))))
    }
    onMediaMiddleClicked: AudioService.toggleMute()
    onMediaRightClicked: Quickshell.execDetached(["sh", "-c",
      "niri msg action focus-window --id $(niri msg -j windows | jq -r '[.[] | select(.app_id==\"org.pulseaudio.pavucontrol\")][0].id // empty') 2>/dev/null || pavucontrol"])
    onNetworkClicked: root.networkRequested()
    onLogoutClicked: root.logoutRequested()
    onItemActivated: function(appId) { root.itemActivated(appId) }
    onItemClosed: function(appId) { root.itemClosed(appId) }
    onItemCycled: function(appId, direction) { root.itemCycled(appId, direction) }
  }
}
```

(The pavucontrol one-liner must not leave a failed `focus-window` swallowing the launch: the implementer validates `niri msg -j windows | jq` is installed with `which jq`; if `jq` is missing use a python3 one-liner with the same selection. `AudioService.volume` is 0..1.)

- [ ] **Step 4: `shell.qml`**

1. Replace the `Dock { ... }` instance with:

```qml
  BottomBar {
    id: bottomBar
    visible: bar.visible && !lockScreen.locked
    screen: bar.screen
    items: DockModel.dockItems(DockModel.normalizePinned(Settings.dockPinned), WindowService.windows)
    onSidebarPageRequested: function(page) { shell.openSidebarPage(page) }
    onLauncherRequested: {
      if (lockScreen.locked) return
      shell.anchorLauncher()
      bar.openPopup = bar.openPopup === "launcher" ? "" : "launcher"
    }
    onNetworkRequested: {
      if (lockScreen.locked) return
      settingsPanel.currentTab = 4      // Network tab until R4
      bar.openPopup = "settings"
    }
    onLogoutRequested: {
      if (lockScreen.locked) return
      bar.togglePopupByName("quickmenu")   // until R3
    }
    onItemActivated: function(appId) { shell.dockActivate(appId) }
    onItemClosed: function(appId) { shell.dockClose(appId) }
    onItemCycled: function(appId, direction) { shell.dockCycle(appId, direction) }
  }
```

   Give the existing `Sidebar {` instance `id: sidebar`.

2. Add near `openLauncherWith`:

```qml
  // Bottom-bar page buttons: closed opens at the page, the open page closes
  // it, another page switches (BottomBarModel.sidebarToggle).
  function openSidebarPage(n) {
    if (lockScreen.locked) return false
    var r = BottomBarModel.sidebarToggle(bar.openPopup, sidebar.currentPage, n, sidebar.pageCount)
    if (r.open) {
      sidebar.showPage(r.page)
      bar.openPopup = "sidebar"
    } else {
      bar.openPopup = ""
    }
    return true
  }
```

   plus `import "config/BottomBarModel.js" as BottomBarModel` next to the other JS imports. If `anchorLauncher` is not a function name in this tree, use the helper `openLauncherWith` already contains (look at lines 235 to 250 of shell.qml and call the same anchoring statement).

3. IPC (inside the `IpcHandler`): remove `dockReveal`; update `dockState` to `JSON.stringify({ workspaceEmpty: WindowService.workspaceEmpty, windows: WindowService.windows.length, items: bottomBar.items })`; add

```qml
    function openSidebarPage(n: int): bool { return shell.openSidebarPage(n) }

    // Dev/testing: bottom bar inputs as JSON.
    function bottomBarState(): string {
      var c = bottomBar.content
      return JSON.stringify({ items: bottomBar.items, clockText: c.clockText, dateText: c.dateText,
        volume: c.volume, muted: c.muted, batteryPct: c.batteryPct, charging: c.charging,
        signal: c.signal, connected: c.connected, vpn: c.vpn, alarmCount: c.alarmCount,
        height: bottomBar.implicitHeight })
    }
```

- [ ] **Step 5: Delete the old dock files and fix tests**

```bash
cd ~ && yadm rm -q .config/quickshell/bar/Dock.qml .config/quickshell/bar/dock/DockContent.qml \
  .config/quickshell/bar/dock/DockItem.qml .config/quickshell/scripts/dock-render.sh \
  .config/quickshell/tests/dock/item.test.mjs .config/quickshell/tests/dock/window.test.mjs \
  .config/quickshell/tests/dock/shell.qml
```

`tests/dock/section.test.mjs`, `settings.test.mjs`, `service.test.mjs`, `dock-model.test.mjs`, `window-state.test.mjs` stay. Add the wheel and activation assertions that `item.test.mjs` carried to `tests/bottom-bar/wiring.test.mjs` for `bar/bottombar/DockGlyph.qml`:

```js
const glyph = rd("../../bar/bottombar/DockGlyph.qml")
const wheel = glyph.slice(glyph.indexOf("onWheel"))
assert.match(wheel, /angleDelta\.y/)
assert.match(wheel, /===\s*0\)\s*return/)
assert.match(wheel, /wheelAccum\s*\+=/)
assert.match(wheel, />=\s*120/)
assert.match(wheel, /wheelAccum\s*-=/)
assert.match(wheel, /wheelAccum\s*=\s*0/)
```

Also: `scripts/popup-ipc-check.sh`: add a sequence `qs ipc call shell openSidebarPage 1` -> `currentPopup` is `sidebar`; again `openSidebarPage 1` -> `currentPopup` is empty; `openSidebarPage 0` then `openSidebarPage 1` -> still `sidebar`; finally `dismissPopups`.

- [ ] **Step 6: Gate set, commit**

Run the full Gate set (the dock render script is gone; `tests/dock/*.mjs` loop covers what remains). Then:

```bash
cd ~ && yadm add -A .config/quickshell/bar .config/quickshell/shell.qml .config/quickshell/scripts .config/quickshell/tests
yadm status --short | grep -E "settings.json|Kvantum|kitty|niri|btop|starship" | grep -v '^ M' || true
yadm commit -m "bottom bar: window, shell wiring, sidebar page request; remove the auto-hide dock" && yadm push origin main
```

---

### Task 5: Docs, notes, live verification (user cold restart)

- [ ] **Step 1: README**

Replace the dock paragraph and keybinding notes: describe the bottom bar (clusters, buttons, dock behavior), the font prerequisite (her zip: Kyok, Baro, BattleAndy into `~/.local/share/fonts`, then `fc-cache -f`; icons from `remix.ttf` already in `~/.local/share/fonts/icomoon`), the interim button targets (network to Settings > Network, alarms no-op, logout to the quick menu) and the dev IPC (`dockState`, `bottomBarState`, `openSidebarPage`). Remove `dockReveal` from the IPC table.

- [ ] **Step 2: Memory notes**

Update `quickshell-elena-theme.md` with: R1 shipped, spec/plan paths, the accent ramp function name, interim buttons, the font-loader reason (four `icomoon` files), and that `bar/Dock.qml` no longer exists.

- [ ] **Step 3: Ask the user to cold restart**

The user runs `! systemctl --user restart quickshell.service`. Do not run it.

- [ ] **Step 4: Live checks (after the restart)**

```bash
cd ~/.config/quickshell
qs ipc call shell bottomBarState | head -c 400
qs ipc call shell dockState | head -c 300
niri msg layers | grep -i -A6 bottombar        # bottom layer, exclusive zone == height
niri msg -j windows | head -c 300              # tiled windows end above the bar
for p in 1 1 0 1; do qs ipc call shell openSidebarPage $p; qs ipc call shell currentPopup; done
qs ipc call shell dismissPopups
journalctl --user -u quickshell.service -n 80 --no-pager | grep -i -E "error|TypeError|is not a type" | tail
```

Expected: JSON with the bar inputs and `height` 65; the layer line shows the exclusive zone; popup sequence `sidebar`, ``, `sidebar`, `sidebar`; no new QML errors. Then sample RSS with `~/.cache/qs-rss` twice 10 minutes apart and record the delta in the report.

- [ ] **Step 5: Final whole-branch review (opus) over the R1 commits, fix wave if needed, final report (DONE or DONE_WITH_CONCERNS, restart note, open follow-ups: R2 to R7, the Settings panel question)**

---

## Self-review

- **Spec coverage:** layout and sizes (Task 3 + Global Constraints), buttons table (Tasks 3 and 4: signals and wiring, with the network/alarms/logout interim targets), dock behavior (Tasks 3 and 4), accent ramp (Task 2 `elenaAccent`, Task 1 slot wrap), data and files (Tasks 1 to 4), `openSidebarPage` clamp and toggle (Task 1 `sidebarToggle`, Task 4), verification (node gates in Tasks 1, 2, 4; render check in Task 3; live in Task 5). Deleted files listed in Task 4.
- **Spec correction:** the spec says disconnected shows "one short x8 bar"; her SCSS applies `.disconnected` to all four parts, so all four collapse to short x8 bars. The plan follows her code (Task 1 `signalParts`, Task 3 `SignalBars`); the spec text is amended in the same commit as this plan.
- **Known soft spots:** the render-check coordinates in Task 3 Step 8 are specified as rectangles and expected colors, not pixel-exact; the implementer computes them from the stage geometry (`dp()` values at S = 1.5) and mutation-proves the assertions. The pavucontrol one-liner depends on `jq`; the plan names the fallback.
