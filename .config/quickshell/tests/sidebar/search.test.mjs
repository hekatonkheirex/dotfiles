// Gate test: node tests/sidebar/search.test.mjs
// Structural: the launcher hook exists and is applied after the reset on show,
// and the shell helper sets it before the launcher opens.
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const read = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const launcher = read("../../bar/LauncherPopup.qml")
const shell = read("../../shell.qml")

assert.match(launcher, /property string initialQuery: ""/, "initialQuery property")

const start = launcher.indexOf("onVisibleChanged: {")
assert.ok(start > 0, "launcher onVisibleChanged")
const body = launcher.slice(start, start + 4000)
const reset = body.indexOf("filteredModel.clear()")
const apply = body.indexOf("root.initialQuery")
const done = body.indexOf("root.voiceRecording = false")
assert.ok(reset > 0 && apply > reset, "initialQuery is applied after the reset")
assert.ok(done > apply, "initialQuery is applied before the visible branch ends")
assert.match(body, /root\.initialQuery = ""/, "initialQuery is consumed")
assert.match(body, /searchInputControl\.text = q/, "text goes through the input")
assert.match(body, /root\.filterApps\(\)/, "results are filtered")

const helper = shell.slice(shell.indexOf("function openLauncherWith"))
const set = helper.indexOf("launcherPopup.initialQuery = query")
const open = helper.indexOf('bar.openPopup = "launcher"')
assert.ok(set > 0 && open > set, "helper sets initialQuery before opening the launcher")
assert.match(shell, /function sidebarSearch\(text: string\): bool/, "sidebarSearch IPC")
assert.match(shell, /function launcherQuery\(\): string/, "launcherQuery IPC")
console.log("sidebar search: ok")
