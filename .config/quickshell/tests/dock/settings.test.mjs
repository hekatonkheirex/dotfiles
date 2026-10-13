// Gate test: node tests/dock/settings.test.mjs  (structural: Settings.qml wiring)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const s = readFileSync(fileURLToPath(new URL("../../config/Settings.qml", import.meta.url)), "utf8")
assert.match(s, /dockPinned: "brave-origin,kitty",/, "default pinned apps")
assert.match(s, /property alias dockPinned: adapter\.dockPinned/, "alias")
assert.match(s, /property string dockPinned: root\.defaults\.dockPinned/, "adapter property")
assert.match(s, /dockPinned = root\.defaults\.dockPinned/, "reset to default")
assert.match(s, /DockModel\.pinnedToCsv\(dockPinned\)/, "normalized on load")
assert.match(s, /import "DockModel\.js" as DockModel/, "imports the model")

// normalization must live in the same load handler as the palette migration
const mig = s.indexOf("migratePaletteId(")
const norm = s.indexOf("DockModel.pinnedToCsv(dockPinned)")
const save = s.indexOf("if (needsSave) root.save()")
assert.ok(mig >= 0 && norm > mig && save > norm, "normalization sits between palette migration and save")
console.log("dock settings: ok")
