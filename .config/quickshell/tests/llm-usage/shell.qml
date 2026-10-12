import QtQuick
import Quickshell
import "config" 1.0

ShellRoot {
  id: root
  property int failures: 0

  LlmUsageService {
    id: service
    providerName: "Test"
    helperScript: "unused.py"
  }

  function check(name, expected) {
    var ok = service.stale === expected
    if (!ok) root.failures++
    console.log((ok ? "PASS " : "FAIL ") + name)
  }

  Component.onCompleted: {
    service.status = "ok"
    service.updatedAt = "2026-10-09T10:00:00Z"
    var updated = Date.parse(service.updatedAt)
    service.pollMinutes = 15
    service.now = updated + 14 * 60000
    check("Claude stays fresh between scheduled checks", false)

    for (var minutes of [5, 15]) {
      service.pollMinutes = minutes
      service.now = updated + 2 * minutes * 60000
      check(minutes + " minute provider: fresh at stale boundary", false)
      service.now += 1
      check(minutes + " minute provider: stale beyond boundary", true)
    }

    service.now = updated
    service.status = "error"
    check("Refresh error immediately marks saved reading stale", true)
    service.updatedAt = ""
    check("Missing reading is not stale", false)
    console.log("DONE " + root.failures + " fail")
    quitTimer.start()
  }

  Timer {
    id: quitTimer
    interval: 100
    onTriggered: Qt.quit()
  }
}
