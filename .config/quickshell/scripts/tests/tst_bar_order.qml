import QtQuick
import QtTest
import "../../config/BarOrder.js" as BarOrder

TestCase {
  name: "BarOrder"

  function test_defaultZonesAndClock() {
    var order = BarOrder.normalize("")
    compare(order.indexOf("launcher"), 0)
    verify(order.indexOf("focused") < order.indexOf("gap"))
    verify(order.indexOf("gap") < order.indexOf("audio"))
    compare(order[order.length - 1], "clock")
  }

  function test_moveAcrossGapPersistsUniqueWidgets() {
    var original = BarOrder.normalize("").join(",")
    var moved = BarOrder.move(original, "focused", 1, false)
    var order = BarOrder.normalize(moved)
    verify(order.indexOf("gap") < order.indexOf("focused"))
    compare(new Set(order).size, order.length)
    compare(BarOrder.move(moved, "focused", -1, false), original)
  }

  function test_hiddenWidgetsRetainSavedPositions() {
    var original = BarOrder.normalize("").join(",")
    var moved = BarOrder.move(original, "weather", -1, false)
    var hidden = BarOrder.edgeOrder(moved, { weather: false, clock: false })
    verify(hidden.indexOf("weather") === -1)
    verify(hidden.indexOf("gap") < hidden.indexOf("media"))
    var shown = BarOrder.edgeOrder(moved, { weather: true, clock: true })
    verify(shown.indexOf("weather") < shown.indexOf("battery"))
  }

  function test_centeredClockIsNotReorderedByOtherWidgets() {
    var original = BarOrder.normalize("").join(",")
    compare(BarOrder.move(original, "notifications", 1, false), original)
    var movedClock = BarOrder.move(original, "clock", -1, false)
    compare(BarOrder.normalize(movedClock).indexOf("clock"),
            BarOrder.normalize(original).indexOf("notifications"))
  }

  function test_invalidSavedOrderFallsBackToKnownLayout() {
    var expected = BarOrder.normalize("").join(",")
    compare(BarOrder.normalize("launcher,launcher,gap").join(","), expected)
    compare(BarOrder.normalize(expected + ",unknown").join(","), expected)
  }

  function test_existingSavedOrderGetsEmptyMiddleWithoutMovingWidgets() {
    var saved = "launcher,workspaces,layout,focused,gap,audio,display,media,weather,battery,tray,notifications,clock"
    var order = BarOrder.normalize(saved)
    compare(order[order.indexOf("gap") + 1], "center")
    compare(order[order.indexOf("center") + 1], "audio")
    compare(BarOrder.zone(saved, "notifications"), "end")
  }

  function test_existingCustomEdgesStayPutOnMigration() {
    var saved = "launcher,workspaces,layout,focused,audio,gap,display,media,weather,battery,tray,notifications,clock"
    compare(BarOrder.zone(saved, "audio"), "start")
    compare(BarOrder.zone(saved, "display"), "end")
    compare(BarOrder.middleOrder(saved, { audio: true, display: true }), [])
  }

  function test_arrowsCrossBothMiddleBoundaries() {
    var original = BarOrder.normalize("").join(",")
    var middle = BarOrder.move(original, "focused", 1, false)
    compare(BarOrder.zone(middle, "focused"), "middle")
    var end = BarOrder.move(middle, "focused", 1, false)
    compare(BarOrder.zone(end, "focused"), "end")
    compare(BarOrder.move(BarOrder.move(end, "focused", -1, false),
                          "focused", -1, false), original)
    compare(BarOrder.zone(BarOrder.move(original, "audio", -1, false), "audio"), "middle")
  }

  function test_directMiddlePlacementSurvivesVisibilityChange() {
    var middle = BarOrder.moveToZone("", "weather", "middle")
    compare(BarOrder.zone(middle, "weather"), "middle")
    verify(BarOrder.middleOrder(middle, { weather: false }).indexOf("weather") === -1)
    compare(BarOrder.middleOrder(middle, { weather: true }), ["weather"])
    verify(BarOrder.edgeOrder(middle, { weather: true }).indexOf("weather") === -1)
    var restored = BarOrder.moveToZone(middle, "weather", "end")
    compare(BarOrder.zone(restored, "weather"), "end")
    compare(new Set(BarOrder.normalize(restored)).size, BarOrder.normalize(restored).length)
  }

  function test_themeClockUsesVisibleZoneUntilMoved() {
    var saved = BarOrder.normalize("").join(",")
    compare(BarOrder.group(saved, "middle", "middle", false), ["clock"])
    verify(BarOrder.group(saved, "end", "middle", false).indexOf("clock") === -1)
    compare(BarOrder.group(saved, "end", "end", false).slice(-1)[0], "clock")
    var moved = BarOrder.moveToZone(saved, "clock", "start")
    compare(BarOrder.group(moved, "start", "middle", true).slice(-1)[0], "clock")
  }

  function test_clockArrowsBeginAtThemeZone() {
    var saved = BarOrder.normalize("").join(",")
    compare(BarOrder.zone(BarOrder.moveClock(saved, -1, "middle"), "clock"), "start")
    compare(BarOrder.zone(BarOrder.moveClock(saved, 1, "middle"), "clock"), "end")
    var ghostUp = BarOrder.moveClock(saved, -1, "end")
    compare(BarOrder.zone(ghostUp, "clock"), "end")
    verify(BarOrder.normalize(ghostUp).indexOf("clock")
      < BarOrder.normalize(ghostUp).indexOf("notifications"))
  }

}
