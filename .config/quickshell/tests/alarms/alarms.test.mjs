// Gate test: node tests/alarms/alarms.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/Alarms.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const A = new Function('"use strict";\n' + src +
  "; return { emptyState, addMinutes, stepMinutes, applyKey, previewHours, previewMinutes, nextOccurrence, inMinutes, fromInput, sortAlarms, due, nextId, formatHM, parse, serialize, nextDelay, totalMinutes }")()

const at = (h, m, s = 0, day = 14) => new Date(2026, 9, day, h, m, s, 0).getTime()

// addMinutes wraps both ways
assert.equal(A.addMinutes(0, -1), 1439)
assert.equal(A.addMinutes(1439, 1), 0)
assert.equal(A.addMinutes(0, 60), 60)
assert.equal(A.addMinutes(30, -60), 1410)

// stepMinutes keeps field and label, normalizes strings
let s = { field: "label", hours: "", minutes: "", label: "gym" }
s = A.stepMinutes(s, 75)
assert.deepEqual(s, { field: "label", hours: "1", minutes: "15", label: "gym" })
assert.equal(A.previewHours(s), "01")
assert.equal(A.previewMinutes(s), "15")
assert.equal(A.stepMinutes(A.emptyState(), -1).hours, "23")

// applyKey: field limits and clamps
let k = A.emptyState()
k = A.applyKey(k, "2"); k = A.applyKey(k, "9")
assert.equal(k.hours, "23", "29 clamps to 23")
k = A.applyKey(k, "1")
assert.equal(k.hours, "23", "third hour digit dropped")
k = A.applyKey(k, "tab")
assert.equal(k.field, "minutes")
k = A.applyKey(k, "7"); k = A.applyKey(k, "5")
assert.equal(k.minutes, "59", "75 clamps to 59")
k = A.applyKey(k, "x")
assert.equal(k.minutes, "59", "non digit rejected in minutes")
k = A.applyKey(k, "backspace")
assert.equal(k.minutes, "5")
k = A.applyKey(k, "c-backspace")
assert.equal(k.minutes, "")
k = A.applyKey(k, "backspace")
assert.equal(k.minutes, "", "backspace on empty is a no-op")
k = A.applyKey(k, "tab")
assert.equal(k.field, "label")
for (const c of "abcdefghijklmnopqrstuvwxyz") k = A.applyKey(k, c)
assert.equal(k.label, "abcdefghijklmnop", "label capped at 16")
k = A.applyKey(k, "tab")
assert.equal(k.field, "hours")
k = A.applyKey(k, "s-tab")
assert.equal(k.field, "label")
assert.equal(A.applyKey(k, "escape").label, k.label, "unknown key ignored")
let lbl = { field: "label", hours: "", minutes: "", label: "" }
assert.equal(A.applyKey(lbl, " ").label, " ", "space allowed in label")
assert.equal(A.applyKey(lbl, "\n").label, "", "control char rejected")

// nextOccurrence
assert.equal(A.nextOccurrence(at(10, 0), 18, 40), at(18, 40))
assert.equal(A.nextOccurrence(at(19, 0), 18, 40), at(18, 40, 0, 15), "past rolls to tomorrow")
assert.equal(A.nextOccurrence(at(18, 40), 18, 40), at(18, 40, 0, 15), "equal now rolls to tomorrow")
assert.equal(A.nextOccurrence(at(23, 59, 30), 0, 0), at(0, 0, 0, 15), "across midnight")
assert.equal(A.nextOccurrence(at(10, 0, 30), 10, 1), at(10, 1), "seconds are zeroed")

// fromInput
const q = { field: "hours", hours: "0", minutes: "5", label: "" }
assert.deepEqual(A.fromInput("quick", q, at(10, 0)), { at: at(10, 5), label: "beep beep" })
assert.equal(A.fromInput("quick", A.emptyState(), at(10, 0)), null, "0 minutes quick does nothing")
assert.deepEqual(A.fromInput("standard", { field: "hours", hours: "7", minutes: "30", label: "gym" }, at(8, 0)),
  { at: at(7, 30, 0, 15), label: "gym" })
assert.equal(A.fromInput("standard", A.emptyState(), at(0, 0, 30)).at, at(0, 0, 0, 15), "standard 00:00 at 00:00:30 is tomorrow")
assert.equal(A.fromInput("select-type", q, 0), null)

// due, sort, ids
const list = [{ id: 3, at: 300, label: "c" }, { id: 1, at: 100, label: "a" }, { id: 2, at: 100, label: "b" }]
assert.deepEqual(A.sortAlarms(list).map(a => a.id), [1, 2, 3], "stable by time then id")
assert.deepEqual(A.due(list, 100).map(a => a.id), [1, 2], "equal timestamp rings")
assert.deepEqual(A.due(list, 99), [])
assert.equal(A.nextId(list), 4)
assert.equal(A.nextId([]), 1)

// parse/serialize
assert.deepEqual(A.parse(""), [])
assert.deepEqual(A.parse("not json"), [])
assert.deepEqual(A.parse("{\"a\":1}"), [])
assert.deepEqual(A.parse("[null, 5, {\"at\":\"x\"}, {\"at\":10,\"label\":\"ok\",\"id\":7}]"), [{ id: 7, at: 10, label: "ok" }])
const dup = A.parse("[{\"id\":1,\"at\":5},{\"id\":1,\"at\":6}]")
assert.deepEqual(dup.map(a => a.id).sort(), [1, 2], "duplicate ids repaired")
assert.deepEqual(A.parse(A.serialize(list)), A.sortAlarms(list), "round trip")
assert.equal(A.parse("[{\"at\":9}]")[0].label, "beep beep")

// formatHM, nextDelay
assert.equal(A.formatHM(at(7, 5)), "07:05")
assert.equal(A.nextDelay([], 0), 0)
assert.equal(A.nextDelay([{ id: 1, at: 1000, label: "" }], 0), 1000)
assert.equal(A.nextDelay([{ id: 1, at: 10 * 60000, label: "" }], 0), 30000, "capped at 30 s")
assert.equal(A.nextDelay([{ id: 1, at: 5, label: "" }], 100), 250, "overdue re-arms soon, not 0")

console.log("alarms: ok")
