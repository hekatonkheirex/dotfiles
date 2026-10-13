// Gate test: node tests/dock/item.test.mjs
// Structural: DockItem.qml source keeps the wheel guard/accumulator and the
// desktop-entry database dependency.
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = process.env.DOCK_ITEM_QML ??
  fileURLToPath(new URL("../../bar/dock/DockItem.qml", import.meta.url))
const qml = readFileSync(src, "utf8")
const wheel = qml.slice(qml.indexOf("onWheel"))

assert.match(wheel, /angleDelta\.y/, "wheel handler reads angleDelta.y")
assert.match(wheel, /===\s*0\)\s*return/, "zero-delta events are ignored")
assert.match(wheel, /wheelAccum\s*\+=/, "deltas accumulate")
assert.match(wheel, />=\s*120/, "emits per full 120 notch")
assert.match(wheel, /wheelAccum\s*-=/, "accumulator drains by notch")
assert.match(wheel, /wheelAccum\s*=\s*0/, "accumulator resets on direction flip")
assert.match(qml, /entry:[^]*?DesktopEntries\.applications/, "entry binding depends on the entry database")
console.log("dock item structural: ok")
