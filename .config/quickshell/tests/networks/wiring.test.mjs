// Gate test: node tests/networks/wiring.test.mjs
// Static wiring for the networks window pieces (R4 task 2). The working
// nmcli commands are pinned here as literals (copied from the old
// bar/WifiPanel.qml) so they survive that file's removal.
import { readFileSync, readdirSync } from "node:fs"
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
assert.match(svc, /"Could not connect to " \+ root\.pendingName/)
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
  .concat(["../../config/NetworkListService.qml", "./shell.qml", "../../scripts/networks-render.sh"])
for (const f of files) {
  const src = rd(f)
  assert.doesNotMatch(src, /^\s*component\s+\w+\s*:/m, `${f}: no inline component`)
  assert.doesNotMatch(src, /—/, `${f}: no em dash`)
}
assert.match(rd("../../scripts/m3-qmllint-gate.sh"), /bar\/networks\/\*\.qml/)
console.log("networks wiring ok")
