// Gate test: node tests/dock/window.test.mjs (structural)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const dock = rd("../../bar/Dock.qml")
assert.match(dock, /ExclusionMode\.Ignore/, "reserves no space")
assert.match(dock, /WlrLayershell\.layer: WlrLayer\.Top/)
assert.match(dock, /Config\.layerNamespace\("dock"\)/)
assert.match(dock, /anchors\s*\{[\s\S]*bottom: true[\s\S]*left: true[\s\S]*right: true|anchors\s*\{[\s\S]*left: true[\s\S]*right: true[\s\S]*bottom: true/, "full-width bottom anchor")
assert.match(dock, /mask: Region \{ item: /, "input mask follows the visible part")
assert.match(dock, /HoverHandler/, "pointer detection that sees through children")
assert.match(dock, /interval: 400/, "400 ms hide delay")
assert.match(dock, /workspaceEmpty \|\| /, "empty workspace shows the dock")
assert.match(dock, /holdTimer\.running/, "revealed includes the linger")
assert.match(dock, /enabled: !Config\.reducedMotion/, "reduced motion disables the slide")

const shell = rd("../../shell.qml")
assert.match(shell, /import "config\/DockModel\.js" as DockModel/)
assert.match(shell, /function dockActivate\(/)
assert.match(shell, /function dockClose\(/)
assert.match(shell, /function dockCycle\(/)
assert.match(shell, /focus-window --id/)
assert.match(shell, /close-window --id/)
assert.match(shell, /function dockState\(\): string/)
assert.match(shell, /function dockReveal\(on: bool\)/)
assert.match(shell, /Dock \{[\s\S]*visible: Config\.elenaTheme/, "dock only under elena")
assert.match(shell, /ls -t \/run\/user\/\$\(id -u\)\/niri\.\*\.sock/, "niri socket discovery")
const fn = name => {
  const m = shell.match(new RegExp("function " + name + "\\([^)]*\\) \\{[\\s\\S]*?\\n  \\}"))
  assert.ok(m, name + " body")
  return m[0]
}
assert.match(fn("niriAction"), /niri msg action/)
const activate = fn("dockActivate")
assert.match(activate, /count === 0\)[\s\S]*dockLaunch/, "launches when no windows")
assert.match(activate, /focused[\s\S]*DockModel\.nextWindow/, "cycles when app is focused")
assert.match(shell, /return JSON\.stringify\(\{[\s\S]*revealed: dock\.revealed[\s\S]*workspaceEmpty[\s\S]*windows:[\s\S]*items:/, "dockState is JSON")
const gate = rd("../../scripts/m3-qmllint-gate.sh")
assert.match(gate, /bar\/dock\/\*\.qml/, "gate lints dock files")
console.log("dock window: ok")
