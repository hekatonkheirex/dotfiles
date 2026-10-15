// Gate test: node tests/settings-tabs/test.mjs
// Settings lives in the right sidebar (bar/SettingsSidebar.qml): six pages,
// each page file shows itself for its own index, and the retired pages and
// sections stay removed.
import assert from "node:assert/strict"
import { existsSync, readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"

const path = p => fileURLToPath(new URL(p, import.meta.url))
const read = p => readFileSync(path(p), "utf8")
const content = read("../../bar/settingsbar/SettingsSidebarContent.qml")

// Page order: switch case N -> component -> bar/settings/<Name>.qml shows itself for N.
const order = ["GeneralTab", "AppearanceTab", "DisplayInputTab", "BluetoothTab", "LockMediaTab", "NotificationsTab"]
assert.match(content, /readonly property int pageCount: 6\b/)
const comps = Object.fromEntries([...content.matchAll(/Component \{ id: (\w+); (\w+) \{ root: host \} \}/g)].map(m => [m[1], m[2]]))
const cases = [...content.matchAll(/case (\d+): return (\w+)/g)].map(m => [+m[1], comps[m[2]]])
const byIndex = [comps.generalPage, ...cases.sort((a, b) => a[0] - b[0]).map(c => c[1])]
assert.deepEqual(byIndex, order, "pages in order (default case is General)")
order.forEach((name, i) => {
  const src = read(`../../bar/settings/${name}.qml`)
  assert.ok(new RegExp(`visible: root\\.currentTab === ${i}\\b`).test(src), `${name} shows itself for page ${i}`)
})

// Retired pages and sections are gone.
for (const f of ["AccountTab", "MediaTab", "SystemTab", "ShortcutsTab", "AccentSwatch"])
  assert.ok(!existsSync(path(`../../bar/settings/${f}.qml`)), f + ".qml removed")
assert.ok(!existsSync(path("../../bar/SettingsPanel.qml")), "floating SettingsPanel removed")
const general = read("../../bar/settings/GeneralTab.qml")
assert.doesNotMatch(general, /text: "Behavior"|Show uptime|Reduced motion/, "General has no Behavior section")
const appearance = read("../../bar/settings/AppearanceTab.qml")
assert.doesNotMatch(appearance, /AccentSwatch|AccentPalette|Interface sizing|sizingCard|Active accent/, "Appearance has no accent or scaling cards")

// Sidebar wiring: right and bottom anchored, same single-open-popup route model.
const side = read("../../bar/SettingsSidebar.qml")
assert.match(side, /anchors\.right: true/)
assert.match(side, /anchors\.bottom: true/)
assert.match(side, /anchors\.left: false/)
const shell = read("../../shell.qml")
assert.match(shell, /SettingsSidebar \{\n\s+id: settingsSidebar\n/)
assert.match(shell, /visible: bar\.openPopup === "settings" && !lockScreen\.locked && !lockScreen\.compositorLocked/)
assert.match(shell, /SidebarActivator \{\n\s+rightEdge: true/)
assert.match(read("../../bar/Bar.qml"), /"settings"/)
const act = read("../../bar/SidebarActivator.qml")
assert.match(act, /anchors \{ left: !root\.rightEdge; right: root\.rightEdge;/)

// The appearance page still owns the wallpaper entry point and the shell exposes both actions.
assert.ok(/text: "Wallpaper"/.test(appearance), "wallpaper row exists")
assert.ok(/"call", "shell", "wallpapers"/.test(appearance) && /"call", "shell", "randomWallpaper"/.test(appearance), "Choose and Random buttons")
assert.ok(/function randomWallpaper\(\)/.test(shell) && /random-wallpaper\.sh/.test(shell), "randomWallpaper IPC")
const film = read("../../bar/WallpaperFilmstrip.qml")
assert.ok(/generate-thumbnails\.sh/.test(film) && /thumbScript/.test(film), "the filmstrip generates thumbnails")
assert.ok(/Qt\.Key_R && \(event\.modifiers & Qt\.ControlModifier\)/.test(film), "Ctrl+R applies a random wallpaper")
console.log("PASS settings-tabs")

// Regression: the palette synchronizer (~30s) must outlive the Appearance tab.
// The page Loader destroys the tab when the sidebar closes or the page changes;
// a Process owned by the tab was killed before Niri/kitty colors refreshed.
assert.doesNotMatch(appearance, /sync-active-palette\.sh|reloadThemeProc|\bProcess \{/, "Appearance tab owns no sync process")
const colors = read("../../config/Colors.qml")
assert.match(colors, /property var paletteSyncProc: Process \{/, "Colors owns the palette sync process")
assert.match(colors, /sync-active-palette\.sh/, "Colors runs sync-active-palette.sh")
assert.match(appearance, /Colors\.runPaletteSync\(/, "Appearance tab delegates to Colors.runPaletteSync")
