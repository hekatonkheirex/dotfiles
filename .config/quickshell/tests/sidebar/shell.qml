// Staged at the config-copy root by scripts/sidebar-render.sh.
// Four 450 px cells: Home, Agenda, Media, page indicators (page 1), all fed
// fixed inputs; GEOM lines give the pixel checks their boxes. A SidebarContent
// off the grabbed stage checks keyboard paging and the compatibility members.
import QtQuick
import QtTest
import Quickshell
import "config"
import "bar/sidebar"

ShellRoot {
  FloatingWindow {
    id: win
    implicitWidth: 1800
    implicitHeight: 831
    color: Colors.surface
    mask: Region {}
    property int failures: 0

    function check(name, ok) {
      if (!ok) failures++
      console.log((ok ? "PASS " : "FAIL ") + name)
    }
    function find(item, name) {
      if (item.objectName === name) return item
      var children = item.children || []
      for (var i = 0; i < children.length; i++) {
        var found = find(children[i], name)
        if (found) return found
      }
      return null
    }
    function geom(name) {
      var it = find(stage, name)
      if (!it) { check("found " + name, false); return }
      var p = it.mapToItem(stage, 0, 0)
      console.log("GEOM " + name + " " + Math.round(p.x) + " " + Math.round(p.y) + " " + Math.round(it.width) + " " + Math.round(it.height))
    }

    Item {
      id: stage
      width: 1800
      height: Config.dp(554)
      Rectangle { anchors.fill: parent; color: Colors.surface }

      HomePage {
        x: 0; width: 450; height: parent.height
        now: new Date(2026, 9, 7, 9, 5)
        testValues: ({ volume: 60, muted: true, battery: 80, charging: false, cpu: 50,
          brightness: 70, temp: 45, ram: 40, swap: 10, disk: 65, net: 20, netLabel: "2.0",
          hostname: "elena", uptime: "1d 2h", weatherStatus: "ok", weatherTemp: "21°",
          weatherDesc: "Partly cloudy" })
      }
      AgendaPage {
        x: 450; width: 450; height: parent.height
        today: new Date(2026, 9, 7, 9, 5)
        weekStartsMonday: false
      }
      MediaPage {
        x: 900; width: 450; height: parent.height
        status: "Playing"
        title: "Aphelion"
        artist: "elenapan"
        positionSec: 30
        lengthSec: 120
      }
      PageIndicators {
        x: 1350; y: Config.dp(40); width: 450
        currentPage: 1
      }
    }

    // Off the grabbed stage: the real page host.
    SidebarContent {
      id: content
      x: 0; y: 0; width: 450; height: 831
      visible: false
      active: false
    }
    // Two writers on one property, as bar/Sidebar.qml (constant false) and the
    // new pages (live value) do until Task 4: the live one must win every toggle.
    QtObject { id: race; property bool target: false; property bool live: false }
    Binding { target: race; property: "target"; value: content.statusActive }
    Binding { target: race; property: "target"; value: race.live }

    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }
    Item {
      TestCase {
        name: "sidebar-pages"
        when: true
        function test_pages() {
          wait(1500)
          var done = false
          stage.grabToImage(function(r) { done = r.saveToFile(Quickshell.env("GOLDEN_OUT")) })
          tryVerify(function() { return done }, 5000)
          var names = ["tile_cpu", "tile_volume", "weekStrip", "todayCell", "dayCell0", "taskList",
                       "artRing", "seekLine", "playButton", "pageDots"]
          for (var i = 0; i < names.length; i++) win.geom(names[i])

          content.visible = true
          content.forceActiveFocus()
          keyClick(Qt.Key_PageDown, Qt.ControlModifier)
          win.check("ctrl+pagedown steps to agenda", content.currentPage === 1)
          keyClick(Qt.Key_PageDown, Qt.ControlModifier)
          keyClick(Qt.Key_PageDown, Qt.ControlModifier)
          win.check("paging clamps at media", content.currentPage === 2)
          keyClick(Qt.Key_PageUp, Qt.ControlModifier)
          win.check("ctrl+pageup steps back", content.currentPage === 1)
          var escaped = false
          content.escaped.connect(function() { escaped = true })
          keyClick(Qt.Key_Escape)
          win.check("escape emits escaped", escaped)
          win.check("compat statusActive is constant false", content.statusActive === false)
          win.check("compat dashboardActive follows page 1", content.dashboardActive === false)

          for (var k = 0; k < 3; k++) {
            race.live = true
            wait(20)
            var on = race.target === true
            race.live = false
            wait(20)
            win.check("live writer wins toggle " + k, on && race.target === false)
          }
          content.visible = false
          console.log("DONE sidebar " + win.failures + " fail")
          quitTimer.start()
        }
      }
    }
  }
}
