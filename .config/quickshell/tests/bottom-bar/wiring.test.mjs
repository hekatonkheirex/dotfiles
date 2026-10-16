// Gate test: node tests/bottom-bar/wiring.test.mjs (structural)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")


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
assert.match(net, /"nmcli -t -f ACTIVE,SIGNAL dev wifi list --rescan no"/, "cached scan; default rescan auto rescans every ~30 s")
assert.match(net, /property int restartDelay: 2000/)
assert.match(net, /onRead: \{\s*root\.restartDelay = 2000/, "back-off resets once the monitor reads")
assert.match(net, /restart\.interval = root\.restartDelay\s*restart\.start\(\)\s*root\.restartDelay = Math\.min\(60000, root\.restartDelay \* 2\)/, "2 s doubling to 60 s")
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
assert.match(content, /id: dockClip[\s\S]*clip: true/, "dock clipped to the free width")
assert.match(rd("../../bar/bottombar/VolumeRing.qml"), /onBackdropChanged: canvas\.requestPaint\(\)/)
console.log("bottom bar wiring (config): ok")

const bar = rd("../../bar/BottomBar.qml")
assert.match(bar, /exclusionMode: ExclusionMode\.Normal/)
assert.match(bar, /exclusiveZone: root\.implicitHeight/, "reserves the bar height")
assert.match(bar, /anchors\s*\{[\s\S]*?left: true[\s\S]*?right: true[\s\S]*?bottom: true/)
assert.match(bar, /Config\.layerNamespace\("bottombar"\)/)
assert.match(bar, /BottomBarContent \{/)
assert.match(bar, /Binding \{[^}]*target: AudioService; property: "barActive"; value: root\.visible/, "volume polling flag")
assert.match(bar, /Binding \{[^}]*target: NetworkStatusService; property: "active"; value: root\.visible/)
assert.doesNotMatch(bar, /HoverHandler|revealed|holdTimer/, "no auto-hide logic")
// pavucontrol: focus the running window, else spawn; never both, never neither.
assert.match(bar, /ls -t \/run\/user\/\$\(id -u\)\/niri\.\*\.sock/, "socket discovery like shell.niriAction")
assert.match(bar, /org\.pulseaudio\.pavucontrol\\" or \.app_id==\\"pavucontrol/)
assert.match(bar, /if \[ -n \\"\$id\\" \]; then niri msg action focus-window --id \\"\$id\\"; else exec pavucontrol; fi/)
// Wheel volume step is Config.volumeStep %.
assert.match(bar, /onMediaScrolled:[\s\S]*?Config\.volumeStep \/ 100/)

const shell = rd("../../shell.qml")
assert.match(shell, /\n  BottomBar \{\n    id: bottomBar\n    visible: bar\.visible && !lockScreen\.locked/)
assert.doesNotMatch(shell, /\n  Dock \{/, "old dock instance removed")
assert.doesNotMatch(shell, /\bdock\.|dockReveal/, "no references to the old dock id")
assert.match(shell, /function bottomBarState\(\): string/)
assert.match(shell, /function openSidebarPage\(n: int\): bool \{ return shell\.openSidebarPage\(n\) \}/)
assert.match(shell, /BottomBarModel\.sidebarToggle\(bar\.openPopup, sidebar\.currentPage, n, sidebar\.pageCount\)/)
assert.match(shell, /import "config\/BottomBarModel\.js" as BottomBarModel/)
assert.match(shell, /Sidebar \{\n    id: sidebar\n/)
const inst = shell.slice(shell.indexOf("\n  BottomBar {"))
assert.match(inst, /onSidebarPageRequested: function\(page\) \{ shell\.openSidebarPage\(page\) \}/)
assert.match(inst, /onLauncherRequested: \{[^}]*ipc\.launcher\(\)/, "reuses the launcher() IPC path")
assert.match(inst, /onNetworkRequested: \{\s*if \(lockScreen\.locked\) return\s*bar\.togglePopupByName\("networks"\)\s*\}/, "network toggles the networks window")
// ipc.launcher() is the toggle the launcher button reuses.
assert.match(shell, /function launcher\(\) \{\s*bar\.openPopup = bar\.openPopup === "launcher" \? "" : "launcher"/)
assert.match(shell, /height: bottomBar\.implicitHeight, page: sidebar\.currentPage \}\)/, "bottomBarState reports the page")
assert.match(inst, /onLogoutRequested: \{[^}]*bar\.togglePopupByName\("quickmenu"\)/)
for (const h of ["onLauncherRequested", "onNetworkRequested", "onLogoutRequested"])
  assert.match(inst, new RegExp(h + ": \\{\\s*if \\(lockScreen\\.locked\\) return"), h + " locked guard")
// R4: the network button no longer opens Settings.
assert.doesNotMatch(inst, /settingsPanel\.currentTab/)

const sb = rd("../../bar/Sidebar.qml")
assert.match(sb, /function showPage\(n\)/)
assert.match(sb, /readonly property int currentPage: content\.currentPage/)
assert.match(sb, /readonly property int pageCount: content\.pageCount/)
assert.match(rd("../../bar/sidebar/SidebarContent.qml"), /readonly property int pageCount: 3/, "media button (page 2) reaches the media page")
// Button to action table (spec): which signal calls what.
const wire = bar.slice(bar.indexOf("BottomBarContent {"))
assert.match(wire, /onGlanceClicked: root\.sidebarPageRequested\(0\)/)
assert.match(wire, /onTasksClicked: root\.sidebarPageRequested\(1\)/)
assert.match(wire, /onMediaClicked: root\.sidebarPageRequested\(2\)/)
assert.match(wire, /onMediaMiddleClicked:[^\n]*AudioService\.toggleMute\(\)/)
assert.match(wire, /onMediaRightClicked:[^\n]*pavucontrol/)
assert.match(wire, /onGlanceRightClicked:[^\n]*launcher/)
assert.match(wire, /onNetworkClicked: root\.networkRequested\(\)/)
assert.match(wire, /onLogoutClicked: root\.logoutRequested\(\)/)

// Wheel cycling moved from the deleted dock item onto DockGlyph.
const glyph = rd("../../bar/bottombar/DockGlyph.qml")
// Notch logic lives in BottomBarModel.notchSteps (behavior in model.test.mjs).
const wheel = glyph.slice(glyph.indexOf("onWheel"))
assert.match(glyph, /import "\.\.\/\.\.\/config\/BottomBarModel\.js" as BottomBarModel/)
assert.match(wheel, /const r = BottomBarModel\.notchSteps\(root\.wheelAccum, wheel\.angleDelta\.y\)\s*root\.wheelAccum = r\.accum/)
assert.match(wheel, /for \(let i = 0; i < Math\.abs\(r\.steps\); i\+\+\) root\.cycled\(r\.steps > 0 \? -1 : 1\)/, "wheel up cycles back")
assert.match(glyph, /property real wheelAccum: 0/)
// Dock actions carried over from the deleted tests/dock/window.test.mjs.
assert.match(glyph, /if \(mouse\.button === Qt\.MiddleButton\) root\.closeRequested\(\)\s*else root\.activated\(\)/)
assert.match(shell, /import "config\/DockModel\.js" as DockModel/)
for (const f of ["dockActivate", "dockClose", "dockCycle"]) assert.match(shell, new RegExp("function " + f + "\\("))
assert.match(shell, /ls -t \/run\/user\/\$\(id -u\)\/niri\.\*\.sock/, "niri socket discovery")
const fn = name => {
  const m = shell.match(new RegExp("function " + name + "\\([^)]*\\) \\{[\\s\\S]*?\\n  \\}"))
  assert.ok(m, name + " body")
  return m[0]
}
assert.match(fn("niriAction"), /niri msg action/)
const activate = fn("dockActivate")
assert.match(activate, /niriAction\("focus-window --id "/)
assert.match(fn("dockClose"), /niriAction\("close-window --id "/)
assert.match(fn("dockCycle"), /niriAction\("focus-window --id "/)
assert.match(activate, /count === 0\)[\s\S]*dockLaunch/, "launches when no windows")
assert.match(activate, /focused[\s\S]*DockModel\.nextWindow/, "cycles when app is focused")
assert.match(rd("../../scripts/m3-qmllint-gate.sh"), /bar\/bottombar\/\*\.qml/)
assert.doesNotMatch(rd("../../scripts/m3-qmllint-gate.sh"), /bar\/dock\//)
// Fix round 1.
assert.match(sb, /margins\.bottom: Config\.bottomBarHeight \+ Config\.dp\(7\)/, "open sidebar must not cover the bottom bar")
const osp = fn("openSidebarPage")
assert.match(osp, /^function openSidebarPage\(n\) \{\s*if \(lockScreen\.locked\) return false\n/, "lock guard is the first statement")
assert.match(osp, /if \(r\.open\) \{\s*sidebar\.showPage\(r\.page\)\s*bar\.openPopup = "sidebar"\s*\}/, "open branch shows the page")
assert.match(osp, /\} else \{\s*bar\.openPopup = ""\s*\}/, "close branch")
const scroll = bar.slice(bar.indexOf("onMediaScrolled"), bar.indexOf("onMediaMiddleClicked"))
assert.match(scroll, /const r = BottomBarModel\.notchSteps\(root\.wheelAccum, delta\)\s*root\.wheelAccum = r\.accum/)
assert.match(scroll, /if \(r\.steps !== 0\) AudioService\.setVolume\(AudioService\.volume \+ r\.steps \* Config\.volumeStep \/ 100\)/)
assert.match(bar, /property real wheelAccum: 0/)
assert.match(bar, /SystemClock \{[^}]*enabled: root\.visible/, "no ticking while hidden")
// Fix wave 2.
assert.match(fonts, /textFamily: pick\("Kyok medium"\)/)
assert.match(fonts, /toLowerCase\(\) === want/)
assert.match(fonts, /return Config\.fontFamily/, "falls back to the shell font")
assert.match(rd("../../bar/bottombar/ValuePill.qml"), /font\.family: BottomBarFonts\.textFamily/)
assert.match(rd("../../bar/bottombar/VolumeRing.qml"), /onHeightChanged: canvas\.requestPaint\(\)/)
assert.match(rd("../../bar/NotificationToast.qml"),
  /margins\.bottom: Settings\.notificationToastPosition === "bottom-right"\s*\? Config\.spacingLarge \+ Config\.bottomBarHeight\s*: 0/, "bottom toast clears the bar")
assert.match(rd("../../config/DockSymbols.js"), /var lower = Object\.create\(null\)/)
const ffc = rd("../../scripts/bar-font-check.sh")
assert.match(ffc, /bar\/bottombar\/BottomBarContent\.qml/, "font check reads the bar's glyphs")
assert.match(ffc, /config\/DockSymbols\.js/, "font check reads the dock's glyphs")
assert.doesNotMatch(ffc, /0xE92B/, "no hardcoded codepoint list")
// Regression: heuristicLookup is not reactive. Right after a shell restart the
// desktop entry scan is unfinished, so the lookup must depend on the
// applications list or the dock keeps the glyph fallback until a rebuild.
const dg = rd("../../bar/bottombar/DockGlyph.qml")
assert.match(dg, /DesktopEntries\.applications\.values\.length[^\n]*\n?[^\n]*DesktopEntries\.heuristicLookup\(root\.appId\)/,
  "dock icon lookup re-runs when the desktop entry scan completes")
// Dock icons are normalized: the probe canvas feeds BottomBarModel.iconFit and
// the icon is scaled and re-centered by the result.
assert.match(dg, /BottomBarModel\.iconFit\(alpha, 64, 1\.4\)/, "probe measures opaque bounds through iconFit")
assert.match(dg, /scale: root\.fit\.scale/, "icon scales by the measured fit")
assert.match(dg, /x: -root\.fit\.dx \* appIcon\.width \* root\.fit\.scale/, "icon re-centers horizontally")
console.log("bottom bar wiring: ok")
