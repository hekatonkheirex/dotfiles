// Gate test: node tests/osd/wiring.test.mjs
// The OSD uses the elena card (toast frame, her glyphs and slider colors) and
// sits above the 48 px bottom bar. Fails if the old Material card returns.
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"
const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const osd = rd("../../bar/OsdOverlay.qml")

assert.match(osd, /color: Colors\.surface\b/, "solid surface, no translucent chrome")
assert.match(osd, /border\.color: Colors\.surfaceContainer/, "toast frame color")
assert.match(osd, /border\.width: Config\.dp\(8\)/, "toast frame width")
assert.match(osd, /radius: Config\.dp\(18\)/, "toast radius")
assert.doesNotMatch(osd, /chromeSurface|Colors\.outlineVariant|shapeLarge|themeBorderWidth/, "old Material card")
assert.doesNotMatch(osd, /Colors\.primary|Colors\.error|Colors\.brightness/, "colors come from elenaAccent")
assert.match(osd, /"\\uef74"/, "volume glyph matches the sidebar tile")
assert.match(osd, /"\\ue983"/, "brightness glyph matches the sidebar tile")
assert.match(osd, /margins\.bottom: Config\.bottomBarHeight \+ Config\.dp\(20\)/, "clears the bottom bar")
assert.match(osd, /Config\.layerNamespace\("osd"\)/, "namespace keeps the niri blur rule")
assert.match(osd, /enabled: !Config\.reducedMotion/, "meter honors reduced motion")
// Delivery path is unchanged: five triggers plus the kbdlight watcher.
const shell = rd("../../shell.qml")
for (const k of ["volume", "brightness", "mic", "airplane", "bluetooth"])
  assert.ok(shell.includes(`osd.show("${k}")`), `shell shows ${k}`)
console.log("osd wiring ok")
