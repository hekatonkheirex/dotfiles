// Gate test: node tests/sidebar/wiring.test.mjs (structural)
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")

const svc = rd("../../config/SystemMetricsService.qml")
assert.match(svc, /pragma Singleton/)
assert.match(svc, /import "SystemMetrics\.js" as SystemMetrics/)
assert.match(svc, /running: root\.active/, "polls only while active")
for (const p of ["/proc/stat", "/proc/meminfo", "/proc/net/dev", "/proc/uptime", "/sys/class/thermal"])
  assert.ok(svc.includes(p), p)
const qmldir = rd("../../config/qmldir")
assert.match(qmldir, /singleton SystemMetricsService 1\.0 SystemMetricsService\.qml/)

const media = rd("../../config/MediaService.qml")
for (const f of ["positionSec", "function seekBy(", "function seekTo(", "function stop(", "function playerVolumeBy("])
  assert.ok(media.includes(f), f)
const ctl = rd("../../scripts/mpris_control.py")
for (const a of ["'seek'", "'position'", "'volume'"]) assert.ok(ctl.includes(a), a)
assert.match(rd("../../scripts/mpris_monitor.py"), /position_sec/)

const fonts = rd("../../config/BottomBarFonts.qml")
assert.match(fonts, /clockFamily/)
assert.match(fonts, /clockMinutesFamily/)
assert.match(fonts, /Baro Plain/)
assert.match(fonts, /Baro LineThree/)

const settings = rd("../../config/Settings.qml")
assert.match(settings, /sidebarEdgeHover: true/)
assert.match(settings, /property alias sidebarEdgeHover: adapter\.sidebarEdgeHover/)
assert.match(rd("../../bar/settings/AppearanceTab.qml"), /sidebarEdgeHover/)
console.log("sidebar wiring (services): ok")
