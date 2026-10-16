// Gate test: node tests/bottom-bar/model.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/BottomBarModel.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src +
  "; return { batteryParts, signalParts, clockText, dateText, parseWifi, parseVpn, sidebarToggle, notchSteps, iconFit }")()

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

// notchSteps: one signed step per full 120, remainder kept, flip resets.
const run = deltas => deltas.reduce((st, d) => {
  const r = M.notchSteps(st.accum, d)
  return { accum: r.accum, steps: st.steps.concat(r.steps) }
}, { accum: 0, steps: [] })
assert.deepEqual(M.notchSteps(0, 120), { accum: 0, steps: 1 }, "single notch")
assert.deepEqual(run([40, 40, 40]), { accum: 0, steps: [0, 0, 1] }, "three touchpad deltas make one notch")
assert.deepEqual(M.notchSteps(0, 240), { accum: 0, steps: 2 }, "two notches in one event")
assert.deepEqual(run([130, 10]), { accum: 20, steps: [1, 0] }, "remainder kept")
assert.deepEqual(run([60, -120]), { accum: 0, steps: [0, -1] }, "flip drops the old remainder")
assert.deepEqual(M.notchSteps(50, 0), { accum: 50, steps: 0 }, "zero delta ignored")
assert.deepEqual(M.notchSteps(0, -120), { accum: 0, steps: -1 }, "negative notch")
assert.deepEqual(run([-100, -50]), { accum: -30, steps: [0, -1] }, "negative remainder kept")
console.log("bottom bar model: ok")

// iconFit: scale the opaque bbox's longer side up to the slot, clamped to
// [1, 1.4], and report the bbox center's offset.
const sq = (n, x0, y0, x1, y1) => Array.from({ length: n * n }, (_, i) =>
  (i % n >= x0 && i % n <= x1 && Math.floor(i / n) >= y0 && Math.floor(i / n) <= y1) ? 255 : 0)
assert.deepEqual(M.iconFit(sq(10, 0, 0, 9, 9), 10), { scale: 1, dx: 0, dy: 0 }, "full-bleed icon is untouched")
assert.deepEqual(M.iconFit(sq(10, 1, 1, 8, 8), 10), { scale: 1.25, dx: 0, dy: 0 }, "8 of 10 px grows 1.25x")
assert.equal(M.iconFit(sq(10, 4, 4, 5, 5), 10).scale, 1.4, "tiny artwork is capped")
const off = M.iconFit(sq(10, 0, 2, 5, 7), 10)
assert.equal(off.scale, 1.4, "6 of 10 px wants 1.67x, capped")
assert.ok(Math.abs(off.dx - -0.2) < 1e-9 && Math.abs(off.dy - 0) < 1e-9, "off-center bbox reports its offset")
assert.deepEqual(M.iconFit(sq(10, 3, 0, 6, 9), 10).scale, 1, "tall icon is limited by its longer side")
assert.deepEqual(M.iconFit(new Array(100).fill(0), 10), { scale: 1, dx: 0, dy: 0 }, "blank raster is the identity")
assert.deepEqual(M.iconFit(null, 10), { scale: 1, dx: 0, dy: 0 }, "missing data is the identity")
assert.deepEqual(M.iconFit(new Array(100).fill(10), 10), { scale: 1, dx: 0, dy: 0 }, "alpha at or below 16 is ignored")
console.log("model: iconFit ok")
