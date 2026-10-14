// Gate test: node tests/r6/mic-state.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const src = readFileSync(fileURLToPath(new URL("../../config/MicState.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = new Function('"use strict";\n' + src + "; return { parseMute, isSourceEvent, parseDescription, look }")()

assert.equal(M.parseMute("Mute: yes\n"), true)
assert.equal(M.parseMute("Mute: no\n"), false)
assert.equal(M.parseMute("mute: YES"), true)
assert.equal(M.parseMute(""), null)
assert.equal(M.parseMute("Failure: No such entity"), null)

assert.equal(M.isSourceEvent("Event 'change' on source #51"), true)
assert.equal(M.isSourceEvent("Event 'change' on source-output #7"), false)
assert.equal(M.isSourceEvent("Event 'change' on sink #2"), false)
assert.equal(M.isSourceEvent(""), false)

const list = [
  "Source #1", "\tName: alsa_output.pci.monitor", "\tDescription: Monitor of Built-in",
  "Source #2", "\tName: alsa_input.pci.analog-stereo", "\tDescription: Built-in Audio Analog Stereo",
  "\tName: other", "\tDescription: Other",
].join("\n")
assert.equal(M.parseDescription(list, "alsa_input.pci.analog-stereo"), "Built-in Audio Analog Stereo")
assert.equal(M.parseDescription(list, "other"), "Other")
assert.equal(M.parseDescription(list, "missing"), "")
assert.equal(M.parseDescription(list, ""), "")
assert.equal(M.parseDescription("", "x"), "")

assert.deepEqual(M.look(false), { slot: 1, opacity: 1.0 })
assert.deepEqual(M.look(true), { slot: 8, opacity: 0.4 })
console.log("mic-state: ok")
