// Gate test: node tests/palettes/test.mjs
// Every fixed family/variant must resolve, define every Material role as a
// hex color, and keep readable text and accent contrast. These palettes feed
// Matugen's cache, so a missing role breaks GTK/Kvantum/kitty/nvim output.
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const src = readFileSync(fileURLToPath(new URL("../../config/PaletteCatalog.js", import.meta.url)), "utf8")
  .replace(/^\.pragma library$/m, "")
const P = new Function(src + "; return { palette, resolveVariant, fixedFamilyOptions, variantOptions, familyLabel }")()

const lum = hex => {
  const c = [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16) / 255)
    .map(v => v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4)
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
}
const ratio = (a, b) => {
  const [x, y] = [lum(a), lum(b)].sort((m, n) => n - m)
  return (x + 0.05) / (y + 0.05)
}

const roles = Object.keys(P.palette("tokyonight", "night", true))
const families = P.fixedFamilyOptions().map(f => f.value)
for (const f of ["catppuccin", "gruvbox", "tokyonight", "elenapan",
                 "nord", "dracula", "rosepine", "everforest", "kanagawa", "solarized",
                 "vapourwave", "synthwave", "monokai", "oxocarbon", "claude"]) {
  assert.ok(families.includes(f), `fixedFamilyOptions lacks ${f}`)
}
assert.ok(!families.includes("material3"))

for (const fam of families) {
  const variants = P.variantOptions(fam).map(v => v.value)
  assert.ok(variants.length > 0, `${fam} has no variants`)
  assert.ok(P.familyLabel(fam) !== "Material 3", `${fam} has no label`)
  for (const v of [...variants, "junk"]) {
    for (const dark of [true, false]) {
      const p = P.palette(fam, v, dark)
      assert.ok(p, `${fam}/${v}/${dark} missing`)
      for (const r of roles) {
        assert.match(p[r], /^#[0-9a-f]{6}$/i, `${fam}/${v} role ${r} = ${p[r]}`)
      }
      assert.ok(ratio(p.on_surface, p.surface) >= 4.5, `${fam}/${v} text contrast ${ratio(p.on_surface, p.surface).toFixed(2)}`)
      for (const c of ["primary", "secondary", "tertiary"]) {
        assert.ok(ratio(p[c], p.surface) >= 3, `${fam}/${v} ${c} on surface ${ratio(p[c], p.surface).toFixed(2)}`)
        assert.ok(ratio(p["on_" + c], p[c]) >= 3, `${fam}/${v} on_${c} ${ratio(p["on_" + c], p[c]).toFixed(2)}`)
      }
    }
  }
}

// Auto picks by mode; explicit variants win; unknown falls back to mode.
assert.equal(P.resolveVariant("rosepine", "auto", true), "main")
assert.equal(P.resolveVariant("rosepine", "auto", false), "dawn")
assert.equal(P.resolveVariant("rosepine", "moon", false), "moon")
assert.equal(P.resolveVariant("everforest", "auto", false), "light")
assert.equal(P.resolveVariant("solarized", "dark", false), "dark")
assert.equal(P.resolveVariant("solarized", "junk", true), "dark")
assert.equal(P.resolveVariant("claude", "auto", true), "dark")
assert.equal(P.resolveVariant("claude", "auto", false), "light")
assert.equal(P.resolveVariant("claude", "dark", false), "dark")
for (const f of ["nord", "dracula", "vapourwave", "synthwave", "monokai", "oxocarbon"]) assert.equal(P.resolveVariant(f, "auto", false), "dark")
assert.equal(P.resolveVariant("kanagawa", "auto", true), "wave")

// Anchor colors from the upstream palettes.
assert.equal(P.palette("nord", "dark", true).primary, "#88c0d0")
assert.equal(P.palette("nord", "dark", true).surface, "#2e3440")
assert.equal(P.palette("dracula", "dark", true).primary, "#bd93f9")
assert.equal(P.palette("dracula", "dark", true).surface, "#282a36")
assert.equal(P.palette("kanagawa", "wave", true).surface, "#1f1f28")
assert.equal(P.palette("rosepine", "main", true).surface, "#191724")
assert.equal(P.palette("rosepine", "dawn", false).surface, "#faf4ed")
assert.equal(P.palette("everforest", "dark", true).surface, "#2d353b")
assert.equal(P.palette("solarized", "dark", true).surface, "#002b36")
assert.equal(P.palette("solarized", "light", false).surface, "#fdf6e3")
assert.equal(P.palette("vapourwave", "dark", true).primary, "#ff71ce")
assert.equal(P.palette("synthwave", "dark", true).surface, "#262335")
assert.equal(P.palette("synthwave", "dark", true).primary, "#ff7edb")
assert.equal(P.palette("monokai", "dark", true).surface, "#272822")
assert.equal(P.palette("monokai", "dark", true).primary, "#a6e22e")
assert.equal(P.palette("oxocarbon", "dark", true).surface, "#161616")
assert.equal(P.palette("oxocarbon", "dark", true).primary, "#78a9ff")
assert.equal(P.palette("claude", "light", false).surface, "#eeece2")
assert.equal(P.palette("claude", "light", false).primary, "#bd5d3a")
assert.equal(P.palette("claude", "dark", true).surface, "#000000")
assert.equal(P.palette("claude", "dark", true).primary, "#da7756")
console.log("palettes: ok")
