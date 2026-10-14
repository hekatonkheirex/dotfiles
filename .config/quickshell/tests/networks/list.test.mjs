// Gate test: node tests/networks/list.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/NetworkList.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src +
  "; return { parseWifiList, parseSaved, merge, signalBucket, shortName, parsePingLine, formatRate }")()

// parseWifiList
const w = M.parseWifiList([
  "no:Home\\:5G:60:WPA2",
  "no:Cafe:80:--",
  "no::90:WPA2",                 // hidden, dropped
  "no:Dup:30:WPA2",
  "yes:Dup:20:WPA2",             // active duplicate, weaker
  "no:Dup:55:WPA2",              // strongest duplicate
  "no:Back\\\\slash:10:WPA3",
  "",
].join("\n"))
assert.deepEqual(w.map(r => r.name), ["Dup", "Cafe", "Home:5G", "Back\\slash"])
assert.deepEqual(w[0], { name: "Dup", signal: 55, secure: true, active: true })
assert.equal(w[1].secure, false)            // "--" means open
assert.equal(w[2].secure, true)
assert.deepEqual(M.parseWifiList(""), [])
assert.deepEqual(M.parseWifiList(null), [])

// parseSaved
const s = M.parseSaved([
  "Home\\:5G:802-11-wireless:yes:wlan0",
  "Cafe:wifi:no:--",
  "Wired:802-3-ethernet:yes:eth0",
  "lo:loopback:no:lo",
].join("\n"))
assert.deepEqual(s, ["Home:5G", "Cafe"])

// merge
const m = M.merge(w, s)
assert.equal(m.find(r => r.name === "Cafe").saved, true)
assert.equal(m.find(r => r.name === "Dup").saved, false)
assert.equal(m.length, w.length)

// signalBucket
for (const [v, b] of [[0, "bad"], [24, "bad"], [25, "ok"], [49, "ok"], [50, "good"], [74, "good"], [75, "excellent"], [100, "excellent"]])
  assert.equal(M.signalBucket(v), b, "bucket " + v)

// shortName
assert.equal(M.shortName("a".repeat(22)), "a".repeat(22))
assert.equal(M.shortName("a".repeat(23)), "a".repeat(19) + "...")

// parsePingLine
assert.deepEqual(M.parsePingLine("64 bytes from 1.1.1.1: icmp_seq=1 ttl=57 time=12.4 ms"), { kind: "time", ms: 12 })
assert.deepEqual(M.parsePingLine("rtt min/avg/max/mdev = 11.0/12.6/14.2/1.0 ms"), { kind: "avg", ms: 13 })
assert.deepEqual(M.parsePingLine("ping: connect: Network is unreachable"), { kind: "unreachable" })
assert.deepEqual(M.parsePingLine("junk"), { kind: "none" })
// formatRate: bytes/s -> her "N.NNMB/s"; unknown (-1, NaN) -> "--MB/s"
assert.equal(M.formatRate(1250000), "1.25MB/s")
assert.equal(M.formatRate(0), "0.00MB/s")
assert.equal(M.formatRate(4999), "0.00MB/s")
assert.equal(M.formatRate(5000), "0.01MB/s")
assert.equal(M.formatRate(-1), "--MB/s")
assert.equal(M.formatRate(NaN), "--MB/s")
console.log("network list: ok")
