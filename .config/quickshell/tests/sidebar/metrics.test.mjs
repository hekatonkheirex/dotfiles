// Gate test: node tests/sidebar/metrics.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/SystemMetrics.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src +
  "; return { parseCpu, cpuPercent, memoryPercent, swapPercent, tempC, diskPercent, parseNet, netRate, netTile, uptimeParts }")()

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

// network tile: megabits, fill against the ceiling
assert.deepEqual(M.netTile(0, 100), { percent: 0, label: "0.0" })
assert.deepEqual(M.netTile(625000, 100), { percent: 5, label: "5.0" })      // 5 Mb/s
assert.deepEqual(M.netTile(12500000, 100), { percent: 100, label: "100" })
assert.deepEqual(M.netTile(125000000, 100), { percent: 100, label: "1000" })

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
