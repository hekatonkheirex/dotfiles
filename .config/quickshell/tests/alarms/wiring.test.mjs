// Gate test: node tests/alarms/wiring.test.mjs
// Static wiring for R5: service registration, window namespace, bar count,
// shell routes and IPC, the real default argv pinned as literals.
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")

assert.match(rd("../../config/qmldir"), /^singleton AlarmService 1\.0 AlarmService\.qml$/m)

const svc = rd("../../config/AlarmService.qml")
assert.match(svc, /^pragma Singleton/)
for (const lit of [
  `["pw-play", root.soundFile]`,
  `["notify-send", "-u", "critical", "-t", "0", "-a", "quickshell-alarm", "Alarm", args.body]`,
  `["notify-send", "-u", "low", "-t", "2000", "-a", "quickshell-alarm", "Alarm", args.body]`,
  `/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga`,
  `/.local/state/quickshell"`,
]) assert.ok(svc.includes(lit), `service has ${lit}`)
assert.doesNotMatch(svc, /execDetached\(\[/, "no hard-wired argv: every command goes through commandFor")
assert.doesNotMatch(svc, /\/tmp\//, "alarms never live in /tmp")

const win = rd("../../bar/AlarmsWindow.qml")
assert.match(win, /Config\.layerNamespace\("popup-alarms"\)/, "matches the popup no-blur rule")
assert.match(win, /WlrLayer\.Overlay/)
assert.match(win, /FocusDismiss/)

const shell = rd("../../shell.qml")
assert.match(shell, /id: alarmsWindow\s+visible: bar\.openPopup === "alarms" && !lockScreen\.locked && !lockScreen\.compositorLocked/)
assert.doesNotMatch(shell, /onAlarmsRequested/, "alarms have no bottom-bar button; IPC only")
for (const fn of ["alarmState()", "alarmAdd(minutes: real, label: string)", "alarmRemove(index: int)"])
  assert.ok(shell.includes(`function ${fn}`), fn)

assert.match(rd("../../bar/Bar.qml"), /name === "networks" \|\| name === "alarms"/)
assert.match(rd("../../scripts/popup-ipc-check.sh"), /sidebar networks alarms tray; do/)
console.log("alarms wiring: ok")
