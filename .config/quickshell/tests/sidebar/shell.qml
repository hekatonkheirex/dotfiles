// Staged at the config-copy root by scripts/sidebar-render.sh.
import QtQuick
import QtTest
import Quickshell
import "config"
import "bar/sidebar"

ShellRoot {
  FloatingWindow {
    id: win
    implicitWidth: 320
    implicitHeight: 720
    color: Colors.surface
    mask: Region {}
    property int failures: 0

    function check(name, ok) {
      if (!ok) failures++
      console.log((ok ? "PASS " : "FAIL ") + name)
    }
    function find(item, predicate) {
      if (predicate(item)) return item
      var children = item.children || []
      for (var i = 0; i < children.length; i++) {
        var found = find(children[i], predicate)
        if (found) return found
      }
      return null
    }
    function inner(item) {
      for (var i = 0; i < item.children.length; i++)
        if (item.children[i].item) return item.children[i].item
      return item
    }

    Item {
      id: stage
      width: 320
      height: 720
      Rectangle { anchors.fill: parent; color: Colors.surface }
      SidebarContent {
        id: sidebar
        anchors.fill: parent
        anchors.margins: Config.spacingMedium
        active: false
      }
    }
    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }
    Item {
      TestCase {
        id: tc
        name: "sidebar-pages"
        when: true
        function save(item, path) {
          var done = false
          item.grabToImage(function(result) { done = result.saveToFile(path) })
          tryVerify(function() { return done }, 5000)
        }
        function test_pages() {
          wait(800)
          sidebar.active = true
          wait(100)
          win.check("status visible without statistics polling", sidebar.statusActive && !sidebar.statisticsPolling)
          save(stage, Quickshell.env("GOLDEN_OUT"))
          var clock = win.find(sidebar, function(item) { return typeof item.rescheduleClock === "function" })
          var search = win.find(sidebar, function(item) { return typeof item.focusField === "function" })
          save(clock, Quickshell.env("CLOCK_OUT"))
          save(search, Quickshell.env("SEARCH_OUT"))
          sidebar.searchText = "@ forest"
          search.focusField()
          keyClick(Qt.Key_Left)
          win.check("ordinary cursor keys do not change page", sidebar.currentPage === 0 && sidebar.searchText === "@ forest")
          keyClick(Qt.Key_PageDown, Qt.ControlModifier)
          wait(100)
          win.check("keyboard opens dashboard and retains query", sidebar.dashboardActive && sidebar.searchText === "@ forest")
          win.check("dashboard owns statistics polling", sidebar.statisticsPolling && !sidebar.statusActive)
          var stats = win.find(sidebar, function(item) { return item.uptimeSeconds !== undefined })
          tryVerify(function() { return stats.uptimeSeconds >= 0 && stats.memoryUsage !== null && stats.loadAverage >= 0 }, 5000)
          win.check("dashboard reads real procfs metrics", stats.uptimeSeconds > 0 && stats.memoryUsage.total >= stats.memoryUsage.used && stats.loadAverage >= 0)
          var initialUptime = stats.uptimeSeconds
          wait(5200)
          win.check("visible dashboard refreshes metrics", stats.uptimeSeconds > initialUptime + 2)
          var calendar = win.find(sidebar, function(item) { return typeof item.moveMonth === "function" })
          calendar.displayMonth = new Date(2026, 11, 31)
          calendar.moveMonth(1)
          win.check("calendar crosses year without day drift", calendar.displayMonth.getFullYear() === 2027 && calendar.displayMonth.getMonth() === 0 && calendar.displayMonth.getDate() === 1)
          calendar.displayMonth = new Date(2028, 1, 1)
          win.check("calendar includes leap day", calendar.days.indexOf(29) >= 0 && calendar.days.indexOf(30) < 0)
          calendar.displayMonth = new Date(calendar.today.getFullYear(), calendar.today.getMonth(), 1)
          save(stage, Quickshell.env("DASHBOARD_OUT"))
          search.focusField()
          keyClick(Qt.Key_PageUp, Qt.ControlModifier)
          wait(100)
          win.check("returning to status stops statistics", sidebar.statusActive && !sidebar.statisticsPolling)
          var hiddenUptime = stats.uptimeSeconds
          wait(5200)
          win.check("hidden dashboard leaves metrics unchanged", stats.uptimeSeconds === hiddenUptime)
          var dashboardButton = win.find(sidebar, function(item) { return item.accessibleName === "Dashboard sidebar page" })
          win.inner(dashboardButton).forceActiveFocus()
          keyClick(Qt.Key_Space)
          wait(100)
          win.check("page button supports Space", sidebar.currentPage === 1)
          stage.height = 420
          wait(100)
          var scroll = win.find(sidebar, function(item) { return item.visible && item.contentHeight !== undefined && item.contentHeight > item.height })
          win.check("short dashboard scrolls with fixed search", scroll !== null && search.mapToItem(stage, 0, search.height).y <= stage.height - Config.spacingMedium + 1)
          scroll.contentY = scroll.contentHeight - scroll.height
          wait(100)
          win.check("short dashboard reaches statistics", stats.mapToItem(scroll, 0, stats.height).y <= scroll.height + 1)
          save(stage, Quickshell.env("SHORT_OUT"))
          sidebar.currentPage = 0
          wait(100)
          var statusScroll = win.find(sidebar, function(item) { return item.visible && item.contentHeight !== undefined && item.contentHeight > item.height })
          win.check("short status page scrolls with fixed search", statusScroll !== null && search.mapToItem(stage, 0, search.height).y <= stage.height - Config.spacingMedium + 1)
          sidebar.currentPage = 1
          wait(100)
          sidebar.active = false
          wait(100)
          win.check("closing clears query and stops both page gates", sidebar.searchText === "" && !sidebar.statisticsPolling && !sidebar.statusActive)
          sidebar.active = true
          wait(100)
          win.check("reopening remembers dashboard", sidebar.currentPage === 1 && sidebar.statisticsPolling)
          sidebar.active = false
          console.log("DONE sidebar " + win.failures + " fail")
          quitTimer.start()
        }
      }
    }
  }
}
