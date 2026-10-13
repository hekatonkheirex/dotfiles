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
  "palette, resolveVariant, fixedFamilyOptions, familyLabel, variantLabel, migratePaletteId")

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
const light = P.palette("elenapan", "auto", false)
const dark = P.palette("elenapan", "auto", true)
assert.ok(light && dark)
assert.deepEqual(light, dark)
assert.equal(dark.primary, "#c77dc8")
assert.equal(dark.secondary, "#f06292")
assert.equal(dark.tertiary, "#5bb8d4")
assert.equal(dark.surface, "#1a1f2b")
const roles = Object.keys(P.palette("tokyonight", "night", true))
for (const k of roles) assert.ok(dark[k], `elenapan missing role ${k}`)
for (const v of ["auto", "dark", "light", "junk", undefined]) assert.equal(P.resolveVariant("elenapan", v, true), "dark")
assert.ok(P.fixedFamilyOptions().some(f => f.value === "elenapan"))
assert.equal(P.familyLabel("elenapan"), "Elenapan")
assert.equal(P.variantLabel("elenapan", "dark"), "Dark")
// existing families untouched
assert.equal(P.palette("material3", "auto", true), null)
assert.equal(P.palette("tokyonight", "night", true).primary, "#7aa2f7")

// The palette id was renamed elenapan -> elenapan (author spelling); stored
// settings written before the rename must keep their palette.
assert.equal(P.migratePaletteId("elenapam"), "elenapan")
for (const same of ["elenapan", "material3", "catppuccin", "", undefined, null]) assert.equal(P.migratePaletteId(same), same)
const read = rel => readFileSync(fileURLToPath(new URL(rel, import.meta.url)), "utf8")
const settingsSrc = read("../../config/Settings.qml")
assert.match(settingsSrc, /PaletteCatalog\.migratePaletteId\(/, "Settings migrates the stored palette id")

// QuickMenu grid is 3 columns x 2 rows: Up and Down jump a row in opposite directions.
const quickMenu = read("../../bar/QuickMenu.qml")
assert.match(quickMenu, /Key_Up \? -3 : 3/, "QuickMenu Up moves back one row, Down forward")
console.log("elena: ok")
