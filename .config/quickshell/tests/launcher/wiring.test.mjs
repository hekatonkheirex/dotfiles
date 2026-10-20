// Gate test: node tests/launcher/wiring.test.mjs
// Static wiring between bar/LauncherPopup.qml and config/launcher/*.js.
import assert from "node:assert/strict"
import { readFileSync, readdirSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { load } from "./load.mjs"

const rd = (rel) => readFileSync(fileURLToPath(new URL(rel, import.meta.url)), "utf8")
const qml = rd("../../bar/LauncherPopup.qml")
const { actionsFor } = load("ActionPanel.js", ["actionsFor"])

// every module is imported
for (const f of readdirSync(fileURLToPath(new URL("../../config/launcher/", import.meta.url))).filter(n => n.endsWith(".js"))) {
  assert.ok(qml.includes(`config/launcher/${f}"`), `LauncherPopup does not import ${f}`)
  assert.match(rd("../../config/launcher/" + f), /^\.pragma library$/m, `${f} must be a pragma library`)
}

// every action id the panel can emit has a handler
const kinds = ["app", "calc", "quicklink", "snippet", "emoji", "window", "clipboard", "clipboard-action", "command", "action"]
const ids = new Set()
for (const kind of kinds) for (const terminal of [false, true]) for (const canType of [false, true]) {
  for (const a of actionsFor({ kind, terminal, name: "x" }, { canType })) ids.add(a.id)
}
const body = qml.slice(qml.indexOf("function runPanelAction"), qml.indexOf("function launchCommandText"))
for (const id of ids) assert.ok(body.includes(`case "${id}":`), `runPanelAction has no case for "${id}"`)

// keys and surfaces
assert.match(qml, /sequences: \["Ctrl\+K", "Shift\+F10", "Menu"\]/)
assert.match(qml, /Instantiator \{\s*model: root\.panelActions/)
assert.doesNotMatch(qml, /selectionActionLabel/)
assert.doesNotMatch(qml, /appModel/, "the old app ListModel is gone")
assert.match(qml, /path: Quickshell\.env\("HOME"\) \+ "\/\.config\/quickshell\/launcher\.json"/)
assert.match(qml, /launcher-history\.json/)
assert.match(qml, /LauncherRoot\.build\(/)
assert.match(qml, /LauncherRoot\.shouldRemember\(id\)/)

// no shell string built from user text: URLs and clipboard go through argv
assert.match(qml, /execDetached\(\["xdg-open", data\.url \|\| ""\]\)/)
assert.match(qml, /execDetached\(\["wl-copy", "--", text\]\)/)
assert.match(qml, /exec wtype -- \\"\$1\\"", "launcher-type", text/, "typeText passes text as $1, never interpolated")
assert.doesNotMatch(qml, /execDetached\(\[\s*"(sh|bash)",\s*"-c",\s*[^\]]*\+\s*(text|data|result|query)/, "no shell command built by concatenating user text")

// kept from before
for (const seq of ["Ctrl+F", "Escape", "Ctrl+N", "Ctrl+P", "Ctrl+M"]) assert.ok(qml.includes(`"${seq}"`), seq)
assert.match(qml, /wallpapersRequested/)
console.log("launcher wiring: ok")
