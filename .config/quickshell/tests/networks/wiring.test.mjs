// Gate test: node tests/networks/wiring.test.mjs
// Static wiring for the networks window pieces (R4 task 2). The working
// nmcli commands are pinned here as literals (copied from the old
// bar/WifiPanel.qml) so they survive that file's removal.
import { existsSync, readFileSync, readdirSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const path = p => fileURLToPath(new URL(p, import.meta.url))
const rd = p => readFileSync(path(p), "utf8")

const qmldir = rd("../../config/qmldir")
assert.match(qmldir, /^singleton NetworkListService 1\.0 NetworkListService\.qml$/m)

const svc = rd("../../config/NetworkListService.qml")
assert.match(svc, /^pragma Singleton/)
for (const argv of [
  `["nmcli", "-t", "-e", "yes", "-f", "active,ssid,signal,security", "dev", "wifi", "list"]`,
  `["nmcli", "-t", "-e", "yes", "-f", "NAME,TYPE,AUTOCONNECT,DEVICE", "connection", "show"]`,
  `["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]`,
  `["nmcli", "dev", "wifi", "rescan"]`,
  `["nmcli", "device", "disconnect", args.device]`,
  `["nmcli", "connection", "delete", args.name]`,
  `["notify-send", "-u", "low", "Networks", args.message]`,
  `["nm-connection-editor"]`,
  `["xdg-open", "https://www.speedtest.net"]`,
  `"stdbuf -oL ping -c 10 -w 30 1.1.1.1 2>&1"`,
]) assert.ok(svc.includes(argv), `service command ${argv}`)
// WifiPanel's connect string and quoting, byte for byte.
assert.ok(svc.includes(`"nmcli dev wifi connect " + root.quote(args.name) + " password " + root.quote(args.password) + " 2>&1"`))
assert.ok(svc.includes(`"nmcli dev wifi connect " + root.quote(args.name) + " 2>&1"`))
assert.ok(svc.includes(`replace(/'/g, "'\\\\''")`), "single quotes escaped as '\\''")
assert.match(svc, /"Could not connect to " \+ root\.pendingConnectName/)
assert.match(svc, /"Could not forget " \+ root\.pendingForgetName/)
// Pending names only change when run() really started the process.
assert.match(svc, /if \(root\.run\(connectProc, "connect", [^)]*\)\) root\.pendingConnectName = name/)
assert.match(svc, /if \(root\.run\(forgetProc, "forget", [^)]*\)\) root\.pendingForgetName = name/)
// Event and poll refreshes read NM's cache; open and scan keep the default (auto).
assert.ok(svc.includes(`.concat(args.rescan === "no" ? ["--rescan", "no"] : [])`), "list --rescan no option")
// Every process gets its argv through the seam; nothing runs a literal argv.
assert.doesNotMatch(svc, /command:\s*\[/, "no hard-wired Process command")
assert.match(svc, /proc\.command = root\.commandFor\(kind/)
assert.match(svc, /running: root\.active && !NetworkStatusService\.monitorRunning/)
assert.match(svc, /function onNmChanged\(\) \{ root\.refresh\(\) \}/)

const status = rd("../../config/NetworkStatusService.qml")
assert.match(status, /signal nmChanged\(\)/)
assert.match(status, /root\.refresh\(\)\s*\n\s*root\.nmChanged\(\)/)

const content = rd("../../bar/networks/NetworksContent.qml")
for (const p of ["var networksModel", "bool scanning", "string pingText", "bool vpnOn", "string downText",
  "string upText", "string passphraseFor", "string forgetFor"])
  assert.match(content, new RegExp(`property ${p}\\b`), `NetworksContent property ${p}`)
for (const s of ["connectRequested(string name, string password)", "disconnectRequested()", "forgetConfirmed(string name)",
  "scanRequested()", "speedtestRequested()", "pingRequested()", "vpnRequested()", "dismissRequested()"])
  assert.ok(content.includes(`signal ${s}`), `NetworksContent signal ${s}`)

// Hot-reload safety and house style across the new files.
const files = readdirSync(path("../../bar/networks")).map(f => `../../bar/networks/${f}`)
  .concat(["../../config/NetworkListService.qml", "./shell.qml", "../../scripts/networks-render.sh", "../../bar/NetworksWindow.qml"])
for (const f of files) {
  const src = rd(f)
  assert.doesNotMatch(src, /^\s*component\s+\w+\s*:/m, `${f}: no inline component`)
  assert.doesNotMatch(src, /—/, `${f}: no em dash`)
}
assert.match(rd("../../scripts/m3-qmllint-gate.sh"), /bar\/networks\/\*\.qml/)
// Task 3: the window, shell wiring, Settings Network tab removed.
const win = rd("../../bar/NetworksWindow.qml")
assert.match(win, /signal dismissed\(\)/)
assert.match(win, /WlrLayershell\.layer: WlrLayer\.Overlay/)
assert.match(win, /exclusionMode: ExclusionMode\.Ignore/)
assert.match(win, /WlrLayershell\.keyboardFocus: root\.visible \? WlrKeyboardFocus\.OnDemand : WlrKeyboardFocus\.None/)
assert.match(win, /anchors\.right: true/)
assert.match(win, /anchors\.bottom: true/)
assert.match(win, /margins\.bottom: Config\.bottomBarHeight \+ Config\.dp\(10\)/)
assert.match(win, /implicitWidth: Config\.dp\(300\)/)
assert.match(win, /Binding \{ target: NetworkListService; property: "active"; value: root\.visible \}/)
assert.match(win, /Binding \{ target: SystemMetricsService; property: "networksActive"; value: root\.visible \}/)
assert.match(win, /onDismissRequested: root\.dismissed\(\)/)
assert.match(win, /FocusDismiss \{/, "focus loss (click on another window) dismisses")
assert.match(win, /property alias forgetFor: content\.forgetFor/)
// SystemMetricsService: the sidebar and the window each own a want flag.
const metrics = rd("../../config/SystemMetricsService.qml")
assert.match(metrics, /readonly property bool active: root\.sidebarActive \|\| root\.networksActive/)
assert.match(rd("../../bar/sidebar/HomePage.qml"), /Binding \{ target: SystemMetricsService; property: "sidebarActive"; value: root\.active \}/)
assert.doesNotMatch(rd("../../bar/sidebar/HomePage.qml"), /target: SystemMetricsService; property: "active"/)

const shell = rd("../../shell.qml")
const winInst = shell.slice(shell.indexOf("\n  NetworksWindow {"))
assert.ok(shell.includes("\n  NetworksWindow {\n    id: networksWindow\n"), "shell instantiates NetworksWindow")
assert.match(winInst, /visible: bar\.openPopup === "networks" && !lockScreen\.locked && !lockScreen\.compositorLocked/)
assert.match(winInst, /onDismissed: bar\.openPopup = ""/)
const bb = shell.slice(shell.indexOf("\n  BottomBar {"))
assert.match(bb, /onNetworkRequested: \{\s*if \(lockScreen\.locked\) return\s*bar\.togglePopupByName\("networks"\)\s*\}/, "network button toggles the window")
assert.doesNotMatch(shell, /settingsPanel\.currentTab = 4/)
assert.doesNotMatch(shell, /devForgetName/)
assert.match(shell, /function forgetPrompt\(name: string\): string \{[^}]*networksWindow\.forgetFor = name[^}]*bar\.openPopup = "networks"/)
assert.match(rd("../../bar/Bar.qml"), /if \(name === "sidebar" \|\| name === "networks" \|\| name === "alarms" \|\| name === "tray"\)/)
assert.match(rd("../../scripts/popup-ipc-check.sh"), /\bnetworks\b/)

assert.ok(!existsSync(path("../../bar/WifiPanel.qml")), "WifiPanel.qml removed")
assert.ok(!existsSync(path("../../bar/settings/NetworkTab.qml")), "NetworkTab.qml removed")
const panel = rd("../../bar/SettingsPanel.qml")
assert.doesNotMatch(panel, /label: "Network"/)
assert.doesNotMatch(panel, /NetworkTab|networkTabComponent|devForgetName|title: "Wi-Fi"/)
const defs = panel.slice(panel.indexOf("tabDefinitions: ["), panel.indexOf("readonly property int tabCount"))
const tabCount = [...defs.matchAll(/label: "/g)].length
assert.equal(tabCount, 10, "eleven tabs minus Network")
for (const m of panel.matchAll(/\{ tab: (\d+),/g)) assert.ok(+m[1] < tabCount, `search tab ${m[1]} < ${tabCount}`)
for (const f of ["../../README.md", "../../shell.qml"]) assert.doesNotMatch(rd(f), /WifiPanel|NetworkTab\.qml/, `${f}: no stale refs`)
console.log("networks wiring ok")
