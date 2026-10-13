// Gate test: node tests/dock/section.test.mjs (structural)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const section = rd("../../bar/settings/DockSection.qml")
assert.match(section, /DockModel\.normalizePinned\(Settings\.dockPinned\)/, "reads the pinned list")
assert.match(section, /Settings\.dockPinned = DockModel\.pinnedToCsv\(/, "writes through the model")
assert.match(section, /Settings\.save\(\)/, "persists")
assert.match(section, /DesktopEntries\.applications/, "add-app source")
assert.match(section, /startupClass/, "app_id guess prefers startupClass")
assert.match(section, /Elena/, "tells the user the dock is Elena-only")
assert.match(section, /noDisplay/, "hidden entries are not offered")
assert.match(section, /maxResults: 6/, "results capped at 6")
assert.match(section, /out\.length < root\.maxResults/, "cap enforced")

// every write to Settings.dockPinned goes through pinnedToCsv, and only one site writes
const writes = section.match(/Settings\.dockPinned\s*=[^=]/g) || []
assert.equal(writes.length, 1, "single write site")
assert.doesNotMatch(section, /Settings\.dockPinned =(?! DockModel\.pinnedToCsv\()/, "no raw writes")

assert.match(rd("../../bar/settings/AppearanceTab.qml"), /DockSection \{/, "wired into Appearance")
const panel = rd("../../bar/SettingsPanel.qml")
assert.match(panel, /title: "Dock pinned apps"/, "search entry")
assert.match(panel, /tab: 2, category: "Dock"/, "search entry on Appearance tab")
// the search anchor must be findable: the section exposes it as objectName
const m = panel.match(/title: "Dock pinned apps", anchor: "([^"]+)"/)
assert.ok(m, "search entry has an anchor")
assert.ok(section.includes('objectName: "' + m[1] + '"'), "anchor matches DockSection objectName")
console.log("dock section: ok")
