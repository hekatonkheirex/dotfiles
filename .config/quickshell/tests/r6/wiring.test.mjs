// Gate test: node tests/r6/wiring.test.mjs
// Static wiring for R6: mic indicator, toast stack, launcher layout.
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")

// R6a
const qmldir = rd("../../config/qmldir")
assert.match(qmldir, /^singleton MicService 1\.0 MicService\.qml$/m)
const mic = rd("../../config/MicService.qml")
for (const lit of [
  `["pactl", "get-default-source"]`, `["pactl", "get-source-mute", args.source]`,
  `["pactl", "list", "sources"]`, `["pactl", "subscribe"]`,
  `["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"]`,
  `["notify-send", "-u", "low", "-a", "quickshell-mic", "Recording device", args.body]`,
]) assert.ok(mic.includes(lit), `mic service has ${lit}`)
assert.match(mic, /running: root\.enabled\b/, "subscriber runs only while enabled")
assert.doesNotMatch(mic, /execDetached\(\[/, "every command goes through commandFor")
const tab = rd("../../bar/MicIndicator.qml")
assert.match(tab, /Config\.layerNamespace\("popup-mic"\)/)
assert.match(tab, /anchors\.top: true/)
assert.match(tab, /MicService\.toggle\(\)/)
assert.match(tab, /MicService\.hide\(\)/)
const settings = rd("../../config/Settings.qml")
assert.match(settings, /micIndicator: true/)
assert.match(settings, /property alias micIndicator: adapter\.micIndicator/)
assert.match(settings, /property bool micIndicator: root\.defaults\.micIndicator/)
assert.match(settings, /micIndicator = root\.defaults\.micIndicator/)
assert.match(rd("../../bar/settings/AppearanceTab.qml"), /Settings\.micIndicator/)
const shell = rd("../../shell.qml")
assert.match(shell, /MicIndicator \{\s+id: micIndicator[\s\S]{0,120}allowed: !lockScreen\.locked/)

// R6b
const toast = rd("../../bar/NotificationToast.qml")
assert.match(toast, /ToastModel\.plan\(root\.keys\(\), key, ToastModel\.LIMIT\)/)
assert.match(toast, /ToastModel\.urgencySlot\(card\.urgency\)/)
assert.match(toast, /Qt\.RightButton\) root\.closeAll\(\)/)
assert.match(toast, /Qt\.MiddleButton\) root\.activateUid\(card\.uid\)/)
assert.match(toast, /margins\.right: Config\.dp\(20\)/)
assert.match(toast, /radius: Config\.dp\(18\)/)
assert.match(toast, /"\\ue944"/)
assert.match(toast, /"\\ue90d"/)
assert.match(shell, /notificationToast\.show\(notif\)/)
assert.match(shell, /notificationToast\.suppress\(\)/)
assert.match(settings, /notificationToastDurationMs: 8000/)
assert.match(settings, /schemaVersion: 3/)
assert.match(settings, /stored\.schemaVersion < 3 && stored\.notificationToastDurationMs === 5000/)

// R6c
const launcher = rd("../../bar/LauncherPopup.qml")
assert.match(launcher, /LauncherLayout\.windowWidth\(Screen\.width/)
assert.match(launcher, /border\.width: Config\.dp\(6\)/)
assert.match(launcher, /radius: Config\.dp\(12\)/)
assert.match(launcher, /leadingGlyph: "\\ueca7"/)
for (const seq of ["Ctrl+N", "Alt+J", "Tab", "Ctrl+P", "Alt+K", "Backtab", "Ctrl+M", "Alt+M", "Alt+A"])
  assert.ok(launcher.includes(`"${seq}"`), `launcher key ${seq}`)
assert.doesNotMatch(launcher, /DashedFrame/, "launcher frame is solid now")
assert.match(shell, /margins\.left: LauncherLayout\.centered\(bar\.screen\.width, implicitWidth\)/)
assert.match(shell, /margins\.top: LauncherLayout\.centered\(bar\.screen\.height, implicitHeight\)/)
// providers and hand-offs stay
for (const kept of ["wallpapersRequested", "actionMode", "clipboardMode", "initialQuery"])
  assert.ok(launcher.includes(kept), `launcher keeps ${kept}`)
console.log("r6 wiring: ok")
