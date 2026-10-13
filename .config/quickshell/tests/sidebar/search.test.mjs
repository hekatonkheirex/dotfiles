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

// Hook block: from `if (root.initialQuery !== "")` to its matching closing brace.
const hookStart = body.indexOf('if (root.initialQuery !== "")')
assert.ok(hookStart > reset, "initialQuery is applied after the reset")
let depth = 0, hookEnd = -1
for (let i = body.indexOf("{", hookStart); i < body.length; i++) {
  if (body[i] === "{") depth++
  else if (body[i] === "}" && --depth === 0) { hookEnd = i; break }
}
assert.ok(hookEnd > hookStart, "hook block is closed")
const hook = body.slice(hookStart, hookEnd + 1)
const anim = body.indexOf("Config.reducedMotion || root.dmenu")
assert.ok(anim > hookEnd, "initialQuery is applied before the entry animation block")
assert.ok(body.indexOf("appendFilteredResult(appModel.get(i)") < hookStart, "applied after the app refill")
assert.ok(hook.includes('root.initialQuery = ""'), "initialQuery is consumed")
assert.ok(hook.includes("searchInputControl.text = q"), "text goes through the input")
assert.ok(hook.includes("root.searchText = q"), "searchText is set")
assert.ok(hook.includes("root.filterApps()"), "results are filtered")

// Hidden branch (the else holding resultMenu.close(), after the hook) clears a stale query.
const closeAt = body.indexOf("resultMenu.close()")
assert.ok(closeAt > hookEnd, "hidden branch follows the hook")
const hidden = body.slice(body.lastIndexOf("} else {", closeAt), closeAt)
assert.ok(hidden.includes('root.initialQuery = ""'), "hidden branch clears a stale initialQuery")

const helper = shell.slice(shell.indexOf("function openLauncherWith"))
const set = helper.indexOf("launcherPopup.initialQuery = query")
const open = helper.indexOf('bar.openPopup = "launcher"')
assert.ok(set > 0 && open > set, "helper sets initialQuery before opening the launcher")
assert.match(shell, /function sidebarSearch\(text: string\): bool/, "sidebarSearch IPC")
assert.match(shell, /function launcherQuery\(\): string/, "launcherQuery IPC")
assert.match(shell, /onSearchSubmitted: function\(text\) \{ shell\.openLauncherWith\(text\) \}/, "sidebar hand-off")
console.log("sidebar search: ok")
