// Gate test: node tests/bottom-bar/wiring.test.mjs (structural)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")

const cfg = rd("../../config/Config.qml")
assert.match(cfg, /readonly property real elenaScale: 1\.5/)
assert.match(cfg, /function dp\(n\) \{ return Math\.round\(n \* elenaScale\) \}/)
assert.match(cfg, /readonly property int bottomBarHeight: dp\(43\)/)

const colors = rd("../../config/Colors.qml")
assert.match(colors, /function elenaAccent\(n\)/)
for (const role of ["error", "secondary", "tertiary", "primary", "inversePrimary", "fgTertiaryContainer", "outline"])
  assert.match(colors.slice(colors.indexOf("function elenaAccent")), new RegExp("return " + role + "\\b"), role)

assert.match(rd("../../config/BatteryService.qml"), /readonly property bool charging:/)
const audio = rd("../../config/AudioService.qml")
assert.match(audio, /property bool barActive: false/)
assert.match(audio, /sinkActive: indicatorActive \|\| popupActive \|\| sidebarActive \|\| barActive/)

const net = rd("../../config/NetworkStatusService.qml")
assert.match(net, /pragma Singleton/)
assert.match(net, /nmcli -t -f ACTIVE,SIGNAL dev wifi/)
assert.match(net, /nmcli -t -f TYPE,STATE con show --active/)
assert.match(net, /running: root\.active/, "polls only while a consumer is active")
assert.match(net, /BottomBarModel\.parseWifi/)
const qmldir = rd("../../config/qmldir")
assert.match(qmldir, /singleton NetworkStatusService 1\.0 NetworkStatusService\.qml/)
assert.match(qmldir, /singleton BottomBarFonts 1\.0 BottomBarFonts\.qml/)
assert.match(net, /root\.monitor\.running = Qt\.binding\(/, "restart must re-bind, not assign true")
assert.doesNotMatch(net, /monitor\.running = true/, "plain true drops the active gate")
assert.match(rd("../../config/BatteryService.qml"), /charging: !!batteryDevice/)
assert.match(rd("../../scripts/bar-font-check.sh"), /remix\.ttf/)
assert.match(rd("../../scripts/bar-font-check.sh"), /icomoon-feather\.ttf/)
const fonts = rd("../../config/BottomBarFonts.qml")
assert.match(fonts, /readonly property string family: "ElenaIcons1"/)
assert.match(fonts, /readonly property var families: \["ElenaIcons1", "ElenaIcons2", "ElenaIcons3"\]/)
// Qt 6.12 Text has no font.families (config load fails); the fallback chain
// comes from the fontconfig rule on ElenaIcons1, so Text sets font.family only.
for (const f of ["BarButton", "DockGlyph"]) {
  const q = rd(`../../bar/bottombar/${f}.qml`)
  assert.match(q, /font\.family: .*BottomBarFonts\.family\b/, f)
  assert.doesNotMatch(q, /font\.families/, f)
}
assert.doesNotMatch(fonts, /FontLoader/)
const content = rd("../../bar/bottombar/BottomBarContent.qml")
assert.match(content, /root\.width - 2 \* Config\.dp\(300\) - 2 \* Config\.dp\(8\)/, "dock width")
assert.match(content, /id: dockClip[\s\S]*clip: true/, "dock clipped to the free width")
assert.match(rd("../../bar/bottombar/VolumeRing.qml"), /onBackdropChanged: canvas\.requestPaint\(\)/)
console.log("bottom bar wiring (config): ok")
