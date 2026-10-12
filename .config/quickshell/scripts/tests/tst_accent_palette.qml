import QtQuick
import QtTest
import "../../config/AccentPalette.js" as AccentPalette

TestCase {
  name: "AccentPalette"

  function test_normalizeDropsUnknownAndDuplicates() {
    compare(AccentPalette.normalize("tertiary, bogus,tertiary,primary").join(","), "tertiary,primary")
    compare(AccentPalette.normalize("").length, 0)
  }

  function test_capsAtEight() {
    var all = AccentPalette.ROLES.map(function (r) { return r.key }).join(",")
    compare(AccentPalette.normalize(all).length, 8)
  }

  function test_toggleAddsRemovesAndRefusesNinth() {
    var csv = ""
    for (var i = 0; i < 8; i++) csv = AccentPalette.toggle(csv, AccentPalette.ROLES[i].key)
    compare(AccentPalette.normalize(csv).length, 8)
    compare(AccentPalette.toggle(csv, AccentPalette.ROLES[8].key), csv)
    verify(AccentPalette.normalize(AccentPalette.toggle(csv, "primary")).indexOf("primary") < 0)
    compare(AccentPalette.toggle("", "nope"), "")
  }

  function test_resolveRequiresMembership() {
    compare(AccentPalette.resolve("tertiary,secondary", "tertiary"), "tertiary")
    compare(AccentPalette.resolve("secondary", "tertiary"), "")
    compare(AccentPalette.resolve("", ""), "")
  }

  function test_onRolePairs() {
    compare(AccentPalette.onRole("tertiary_container"), "on_tertiary_container")
    compare(AccentPalette.onRole(""), "on_primary")
  }
}
