import QtQuick
import QtTest
import "../../config/ClockTiming.js" as ClockTiming

TestCase {
  name: "ClockTiming"

  function test_minuteClockWaitsForNextMinute() {
    compare(ClockTiming.nextInterval(new Date(2026, 0, 1, 12, 30, 0, 0), false), 60000)
    compare(ClockTiming.nextInterval(new Date(2026, 0, 1, 12, 30, 45, 250), false), 14750)
    compare(ClockTiming.nextInterval(new Date(2026, 0, 1, 12, 30, 59, 999), false), 1)
  }

  function test_secondsClockWaitsForNextSecond() {
    compare(ClockTiming.nextInterval(new Date(2026, 0, 1, 12, 30, 45, 250), true), 750)
    compare(ClockTiming.nextInterval(new Date(2026, 0, 1, 12, 30, 59, 999), true), 1)
  }
}
