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

// Task 3: the overlay replaces the QuickMenu; route name stays "quickmenu".
import { existsSync } from "node:fs"
const shell = rd("../../shell.qml")
const menu = rd("../../bar/PowerMenu.qml")
assert.ok(!existsSync(fileURLToPath(new URL("../../bar/QuickMenu.qml", import.meta.url))), "bar/QuickMenu.qml is gone")
assert.doesNotMatch(shell, /\bQuickMenu\s*\{|quickMenu\./, "shell.qml no longer uses QuickMenu")
assert.match(shell, /PowerMenu \{\s*id: powerMenu/)
assert.match(shell, /visible: bar\.openPopup === "quickmenu" && !lockScreen\.locked/)
const logout = shell.match(/onLogoutRequested: \{[^}]*\}/)[0]
assert.match(logout, /bar\.togglePopupByName\("quickmenu"\)/)
assert.doesNotMatch(logout, /until R3/)
assert.match(shell, /"qsquickmenu-trigger": "quickmenu"/)
assert.match(shell, /function quickmenu\(\) \{\s*bar\.openPopup = bar\.openPopup === "quickmenu" \? "" : "quickmenu"/)
const confirm = shell.match(/id: powerConfirmationWindow[\s\S]*?\n  \}\n/)[0]
assert.match(confirm, /visible: powerMenu\.pendingIndex >= 0 && !lockScreen\.locked/)
for (const k of ["actionLabel", "actionDescription", "actionIcon"])
  assert.match(confirm, new RegExp(`${k}: powerMenu\\.`), `${k} reads the PowerMenu pending button`)
assert.match(confirm, /onConfirmed: powerMenu\.confirmPending\(\)/)
assert.match(confirm, /onCancelled: powerMenu\.cancelPending\(\)/)
// Window contract.
assert.match(menu, /WlrLayershell\.layer: WlrLayer\.Overlay/)
assert.match(menu, /exclusionMode: ExclusionMode\.Ignore/)
assert.match(menu, /keyboardFocus: root\.visible \? WlrKeyboardFocus\.Exclusive : WlrKeyboardFocus\.None/)
assert.match(menu, /Config\.layerNamespace\("powermenu"\)/)
for (const e of ["top", "bottom", "left", "right"]) assert.match(menu, new RegExp(`anchors\\.${e}: true`))
assert.match(menu, /PowerMenuContent \{[\s\S]*locked: false/)
assert.match(menu, /property int pendingIndex: -1/)
assert.match(menu, /signal dismissed\(\)/)
assert.match(menu, /signal lockRequested\(\)/)
// Commands: exit via safe-logout, hibernate/suspend via systemctl.
assert.match(menu, /scripts\/safe-logout\.sh/)
for (const c of ["poweroff", "reboot", "hibernate", "suspend"]) assert.match(menu, new RegExp(`\\["systemctl", "${c}"\\]`))
// Backdrop click outside the panel dismisses (window-level MouseArea).
assert.match(menu, /MouseArea \{\s*anchors\.fill: parent[\s\S]*?onClicked: root\.dismissed\(\)/)
console.log("power-menu task 3 wiring ok")

// Task 2 review fixes.
assert.match(rd("../../bar/powermenu/TerminalLine.qml"), /running: root\.visible && !Config\.reducedMotion/, "cursor stays solid under reduced motion")
assert.match(rd("../../bar/powermenu/PaletteRow.qml"), /leftPadding: Config\.dp\(16\) - Config\.dp\(15\)/, "first circle takes her -15 S margin too")
assert.match(rd("../../bar/powermenu/PowerMenuContent.qml"), /objectName: "heart"[\s\S]*?bottomPadding: Config\.dp\(8\)/, "heart keeps her margin-bottom 8 S")
console.log("power-menu review fixes ok")
