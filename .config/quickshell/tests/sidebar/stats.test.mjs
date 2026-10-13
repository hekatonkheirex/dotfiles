import { readFileSync } from "node:fs"
import assert from "node:assert/strict"

const source = readFileSync(new URL("../../bar/sidebar/SidebarStats.js", import.meta.url), "utf8")
  .replace(/^\.pragma library$/m, "")
const { firstNumber, memory, uptimeLabel, memoryLabel } = new Function(source + "; return { firstNumber, memory, uptimeLabel, memoryLabel }")()

assert.equal(firstNumber("0.00 1.23 2.34 1/100 42"), 0, "zero load is a valid observation")
assert.equal(firstNumber("1234.56 789.01\n"), 1234.56, "uptime uses the first value, not accumulated idle time")
for (const input of ["", " \n", "-1 0", "Infinity", "NaN", "12oops", null, undefined]) {
  assert.equal(firstNumber(input), null, `unavailable numeric input: ${input}`)
}
const observed = memory("MemTotal: 8388608 kB\nMemFree: 1 kB\nMemAvailable: 6291456 kB\n")
assert.deepEqual(observed, { used: 2097152, total: 8388608 }, "available memory includes reclaimable cache")
assert.equal(memoryLabel(observed), "2.0 / 8.0 GiB", "proc kB values convert to binary GiB")
assert.deepEqual(memory("MemTotal: 1024 kB\nMemAvailable: 1024 kB"), { used: 0, total: 1024 })
assert.deepEqual(memory("MemTotal: 1024 kB\nMemAvailable: 0 kB"), { used: 1024, total: 1024 })
for (const input of ["", "MemTotal: 0 kB\nMemAvailable: 0 kB", "MemTotal: 100 kB\nMemFree: 50 kB", "MemTotal: 100 kB\nMemAvailable: 101 kB", "MemTotal: 100 kB\nMemAvailable: -1 kB", "MemTotal: 100 bytes\nMemAvailable: 10 kB"]) {
  assert.equal(memory(input), null, "missing or inconsistent memory cannot masquerade as a percentage")
}
assert.equal(memoryLabel(null), "Unavailable")
assert.equal(uptimeLabel(0), "0m")
assert.equal(uptimeLabel(3599), "59m")
assert.equal(uptimeLabel(3600), "1h 0m")
assert.equal(uptimeLabel(86399), "23h 59m")
assert.equal(uptimeLabel(86400), "1d 0h 0m")
for (const value of [null, -1, Infinity, NaN]) assert.equal(uptimeLabel(value), "Unavailable")
console.log("sidebar statistics: ok")
