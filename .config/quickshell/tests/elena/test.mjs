// Gate test: node tests/elena/test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const load = (rel, exports) => {
  const src = readFileSync(fileURLToPath(new URL(rel, import.meta.url)), "utf8")
    .replace(/^\.pragma library$/m, "")
  return new Function(src + `; return { ${exports} }`)()
}
const T = load("../../config/TagStrip.js", "tagStates, ACCENT_COUNT")
const P = load("../../config/PaletteCatalog.js",
  "palette, resolveVariant, fixedFamilyOptions, familyLabel, variantLabel")

// tagStates
assert.equal(T.ACCENT_COUNT, 3)
assert.deepEqual(T.tagStates([]), [])
for (const bad of [undefined, null, "x", 5]) assert.deepEqual(T.tagStates(bad), [])
assert.deepEqual(
  T.tagStates([
    { idx: 1, isFocused: false, isOccupied: true },
    { idx: 2, isFocused: true, isOccupied: true },
    { idx: 3, isFocused: false, isOccupied: false },
    { idx: 4, isFocused: false, isOccupied: false },
  ]),
  [
    { idx: 1, state: "occupied", accent: 0 },
    { idx: 2, state: "focused", accent: 1 },
    { idx: 3, state: "empty", accent: 2 },
    { idx: 4, state: "empty", accent: 0 },
  ])
// focused beats occupied; accent follows idx, not list position
assert.deepEqual(T.tagStates([{ idx: 7, isFocused: true, isOccupied: false }]),
  [{ idx: 7, state: "focused", accent: 0 }])
// idx 0 / negative entries must not give negative accents; non-integer idx (NaN, 2.5) is skipped
assert.deepEqual(T.tagStates([{ idx: 0 }, { idx: -1 }, { idx: NaN }, { idx: 2.5 }, null, {}]),
  [{ idx: 0, state: "empty", accent: 2 }, { idx: -1, state: "empty", accent: 1 }])

// palette
const light = P.palette("elenapam", "auto", false)
const dark = P.palette("elenapam", "auto", true)
assert.ok(light && dark)
assert.deepEqual(light, dark)
assert.equal(dark.primary, "#c77dc8")
assert.equal(dark.secondary, "#f06292")
assert.equal(dark.tertiary, "#5bb8d4")
assert.equal(dark.surface, "#1a1f2b")
const roles = Object.keys(P.palette("tokyonight", "night", true))
for (const k of roles) assert.ok(dark[k], `elenapam missing role ${k}`)
for (const v of ["auto", "dark", "light", "junk", undefined]) assert.equal(P.resolveVariant("elenapam", v, true), "dark")
assert.ok(P.fixedFamilyOptions().some(f => f.value === "elenapam"))
assert.equal(P.familyLabel("elenapam"), "Elenapam")
assert.equal(P.variantLabel("elenapam", "dark"), "Dark")
// existing families untouched
assert.equal(P.palette("material3", "auto", true), null)
assert.equal(P.palette("tokyonight", "night", true).primary, "#7aa2f7")

// selectStyle/revertStyle: drive the real QML functions against a fake Settings.
{
  const qml = readFileSync(fileURLToPath(new URL("../../bar/settings/AppearanceTab.qml", import.meta.url)), "utf8")
  const start = qml.indexOf('  property string previousStyle: ""')
  const body = qml.slice(start, qml.indexOf("  property string themeStatus"))
    .replace(/^\s*property string .*$/gm, "")
  const make = (init) => {
    const env = { Settings: { themeStyle: "material3", nothingVariant: "classic", colorSource: "wallpaper",
      colorPalette: "material3", colorVariant: "auto", save() {}, ...init }, syncs: 0 }
    const f = new Function("Settings", "env", `${body}
      let previousStyle = "", previousNothingVariant = "", paletteBeforeElenaSource = "", paletteBeforeElenaPalette = "", paletteBeforeElenaVariant = ""
      const appearanceTab = { leaveElena: () => leaveElena(), requestPaletteSync: () => env.syncs++ }
      return { selectStyle, revertStyle }`)
    return { env, api: f(env.Settings, env) }
  }
  const orig = { colorSource: "wallpaper", colorPalette: "material3", colorVariant: "auto" }
  const pal = S => ({ colorSource: S.colorSource, colorPalette: S.colorPalette, colorVariant: S.colorVariant })
  // tile to tile: Material (live) -> Elena -> Material keeps the original palette
  let t = make({})
  t.api.selectStyle("elena", "")
  assert.equal(t.env.Settings.colorPalette, "elenapam")
  assert.equal(t.env.Settings.colorSource, "fixed")
  t.api.selectStyle("material3", "")
  assert.deepEqual(pal(t.env.Settings), orig)
  assert.equal(t.env.syncs, 2)
  // revert from elena restores too
  t = make({}); t.api.selectStyle("elena", ""); t.api.revertStyle()
  assert.deepEqual(pal(t.env.Settings), orig)
  assert.equal(t.env.Settings.themeStyle, "material3")
  // a palette chosen while in elena survives leaving
  t = make({}); t.api.selectStyle("elena", "")
  Object.assign(t.env.Settings, { colorSource: "fixed", colorPalette: "tokyonight", colorVariant: "night" })
  t.api.selectStyle("ghost", "")
  assert.equal(t.env.Settings.colorPalette, "tokyonight")
  // styles that never enter elena do not touch the palette or sync
  t = make({}); t.api.selectStyle("ghost", ""); t.api.selectStyle("dwm", "")
  assert.deepEqual(pal(t.env.Settings), orig)
  assert.equal(t.env.syncs, 0)
}
console.log("elena: ok")
