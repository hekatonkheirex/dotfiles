// Gate test: node tests/settings-tabs/test.mjs
// Tab numbers are hardcoded in several places; they must all agree.
import assert from "node:assert/strict"
import { existsSync, readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"

const path = p => fileURLToPath(new URL(p, import.meta.url))
const read = p => readFileSync(path(p), "utf8")
const panel = read("../../bar/SettingsPanel.qml")

const defs = panel.slice(panel.indexOf("tabDefinitions: ["), panel.indexOf("readonly property int tabCount"))
const labels = [...defs.matchAll(/label: "([^"]+)"/g)].map(m => m[1])
assert.ok(labels.length >= 10, "tab definitions parsed: " + labels)
assert.ok(!labels.includes("Wallpaper"), "the Wallpaper tab is gone")

// switch (root.currentTab): case N -> <name>TabComponent -> bar/settings/<Name>Tab.qml shows itself for N.
const cases = [...panel.matchAll(/case (\d+): return (\w+)TabComponent/g)].map(m => [+m[1], m[2]])
assert.equal(cases.length, labels.length, "one case per tab")
assert.deepEqual(cases.map(c => c[0]), labels.map((_, i) => i), "cases are 0..n-1 in order")
for (const [index, name] of cases) {
  const file = `../../bar/settings/${name[0].toUpperCase() + name.slice(1)}Tab.qml`
  assert.ok(existsSync(path(file)), "tab file exists: " + file)
  assert.ok(new RegExp(`visible: root\\.currentTab === ${index}\\b`).test(read(file)), `${file} shows itself for tab ${index}`)
}
assert.ok(!existsSync(path("../../bar/settings/WallpaperTab.qml")), "WallpaperTab.qml is removed")
assert.ok(!/WallpaperTab/.test(panel), "SettingsPanel no longer references it")

// Labels line up with the files in order (sidebar order == switch order).
// Network left Settings in R4 (bar/NetworksWindow.qml is the only network UI).
const order = ["Account", "General", "Appearance", "Display & Input", "Bluetooth", "Media", "Lock & Power", "Notifications", "System", "Shortcuts"]
assert.deepEqual(labels, order, "sidebar order")
const fileFor = { "Display & Input": "displayInput", "Lock & Power": "lockMedia" }
labels.forEach((label, i) => {
  const want = (fileFor[label] || label.toLowerCase()) + "Tab"
  assert.equal(cases[i][1].toLowerCase() + "tab", want.toLowerCase().replace(/^(.*)tab$/, "$1tab") , `case ${i} is ${label}`)
})

// Search entries point at real tabs, and the wallpaper entry lands on Appearance.
const entries = [...panel.matchAll(/\{ tab: (\d+), category: "([^"]*)"[^}]*?title: "([^"]*)"/g)].map(m => ({ tab: +m[1], category: m[2], title: m[3] }))
assert.ok(entries.length > 60)
for (const e of entries) assert.ok(e.tab >= 0 && e.tab < labels.length, `search entry "${e.title}" points at tab ${e.tab}`)
const wp = entries.find(e => e.category === "Wallpaper")
assert.equal(wp.tab, labels.indexOf("Appearance"), "wallpaper search entry lands on Appearance")
const byTitle = t => entries.find(e => e.title === t).tab
assert.ok(!entries.some(e => e.title === "Wi-Fi"), "no Wi-Fi search entry")
assert.equal(byTitle("Bluetooth"), labels.indexOf("Bluetooth"))
assert.equal(byTitle("Show album art"), labels.indexOf("Media"))
assert.equal(byTitle("Lock after inactivity"), labels.indexOf("Lock & Power"))
assert.equal(byTitle("Do Not Disturb"), labels.indexOf("Notifications"))
assert.equal(byTitle("CPU Usage"), labels.indexOf("System"))
assert.equal(byTitle("App shortcuts"), labels.indexOf("Shortcuts"))
assert.equal(byTitle("Display mode"), labels.indexOf("Display & Input"))
assert.ok(new RegExp(`running: root\\.visible && root\\.currentTab === ${labels.indexOf("System")}\\b`).test(panel), "system polling follows the System tab")
console.log("PASS settings-tabs")

// The Appearance page owns the wallpaper entry point, and the shell exposes both actions.
const appearance = read("../../bar/settings/AppearanceTab.qml")
assert.ok(/text: "Wallpaper"/.test(appearance), "search anchor text exists")
assert.ok(/"call", "shell", "wallpapers"/.test(appearance) && /"call", "shell", "randomWallpaper"/.test(appearance), "Choose and Random buttons")
const shell = read("../../shell.qml")
assert.ok(/function randomWallpaper\(\)/.test(shell) && /random-wallpaper\.sh/.test(shell), "randomWallpaper IPC")
const film = read("../../bar/WallpaperFilmstrip.qml")
assert.ok(/generate-thumbnails\.sh/.test(film) && /thumbScript/.test(film), "the filmstrip now generates thumbnails")
assert.ok(/Qt\.Key_R && \(event\.modifiers & Qt\.ControlModifier\)/.test(film), "Ctrl+R applies a random wallpaper")
console.log("PASS wallpaper-entry-points")
