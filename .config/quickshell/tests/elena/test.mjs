// Gate test: node tests/elena/test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const load = (rel, exports) => {
  const src = readFileSync(fileURLToPath(new URL(rel, import.meta.url)), "utf8")
    .replace(/^\.pragma library$/m, "")
  return new Function(src + `; return { ${exports} }`)()
}
const P = load("../../config/PaletteCatalog.js",
  "palette, resolveVariant, fixedFamilyOptions, familyLabel, variantLabel, migratePaletteId")

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

// Power menu grid is 3 columns x 2 rows: Up and Down jump a row in opposite directions.
const pmSrc = read("../../config/PowerMenuModel.js").replace(/^\.pragma library$/m, "")
const PM = new Function('"use strict";\n' + pmSrc + "; return { step }")()
assert.equal(PM.step(4, "up", 6), 1, "Up moves back one row")
assert.equal(PM.step(1, "down", 6), 4, "Down moves forward one row")
assert.equal(PM.step(0, "left", 6), 5, "Left wraps")
console.log("elena: ok")
