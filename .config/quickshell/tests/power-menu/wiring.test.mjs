// Gate test: node tests/power-menu/wiring.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const settings = rd("../../config/Settings.qml")
const tab = rd("../../bar/settings/AppearanceTab.qml")
const panel = rd("../../bar/SettingsPanel.qml")

assert.match(settings, /powerMenuQuote: "Take a breath\."/)
assert.match(settings, /powerMenuQuoteAuthor: ""/)
for (const k of ["powerMenuQuote", "powerMenuQuoteAuthor"]) {
  assert.match(settings, new RegExp(`property alias ${k}: adapter\\.${k}`))
  assert.match(settings, new RegExp(`property string ${k}: root\\.defaults\\.${k}`))
  assert.match(settings, new RegExp(`${k} = root\\.defaults\\.${k}`))
  assert.match(tab, new RegExp(`Settings\\.${k}\\b`))
}
assert.match(tab, /accessibleName: "Power menu quote"/)
assert.match(tab, /accessibleName: "Power menu quote author"/)
assert.match(panel, /anchor: "Power menu quote"/)
assert.match(panel, /anchor: "Power menu quote author"/)
console.log("power-menu wiring ok")
