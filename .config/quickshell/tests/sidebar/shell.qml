// Staged at the config-copy root by scripts/sidebar-render.sh.
// Four 450 px cells: Home, Agenda, Media, page indicators (page 1), all fed
// fixed inputs; GEOM lines give the pixel checks their boxes. A SidebarContent
// off the grabbed stage checks keyboard paging.
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
        id: media
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
          var names = ["tile_cpu", "tile_volume", "weekStrip", "weatherPill", "todayCell", "dayCell0", "taskList",
                       "artRing", "seekLine", "playButton", "prevButton", "nextButton", "volumeUpButton",
                       "volumeDownButton", "stopButton", "favoriteButton", "pageDots"]
          for (var i = 0; i < names.length; i++) win.geom(names[i])

          // Media hover is the cover only; the label area leaves the ring alone.
          var ring = win.find(stage, "artRing")
          var artArea = win.find(stage, "artArea")
          mouseMove(ring, 4, ring.height / 2)
          win.check("hover beside the cover keeps the ring", ring.visible)
          mouseMove(artArea, artArea.width / 2, artArea.height / 2)
          win.check("hover on the cover hides the ring", !ring.visible)
          mouseMove(ring, 4, 4)
          win.check("leaving the cover shows the ring", ring.visible)

          // Seek hover: the line under the pointer turns fgSurface, then reverts.
          var cell10 = win.find(stage, "seekCell10")
          var bar10 = win.find(stage, "seekBar10")
          var idle10 = bar10.color
          mouseMove(cell10, cell10.width / 2, cell10.height / 2)
          win.check("hovered seek line highlights", Qt.colorEqual(bar10.color, Colors.fgSurface))
          mouseMove(ring, 4, 4)
          win.check("seek highlight clears on leave", Qt.colorEqual(bar10.color, idle10))

          // Seek line: line 0's left 40 % seeks to 0, its right side to 1/20.
          var seekTo = -1
          media.seekFraction.connect(function(f) { seekTo = f })
          var cell0 = win.find(stage, "seekCell0")
          mouseClick(cell0, 1, cell0.height / 2)
          win.check("seek line 0 left edge seeks to 0", seekTo === 0)
          mouseClick(cell0, cell0.width - 1, cell0.height / 2)
          win.check("seek line 0 right side seeks to 1/20", Math.abs(seekTo - 0.05) < 1e-9)
          mouseClick(win.find(stage, "seekCell4"), 2, cell0.height / 2)
          win.check("seek line 4 seeks to 5/20", Math.abs(seekTo - 0.25) < 1e-9)

          // The shell's activation path: no forceActiveFocus here; the content
          // takes focus itself when `active` turns true.
          content.visible = true
          content.currentPage = 1
          content.active = true
          wait(150)
          var agenda = win.find(content, "agendaPage")
          mouseClick(win.find(agenda, "monthUp"))
          win.check("month up arrow is next month", agenda.monthOffset === 1)
          mouseClick(win.find(agenda, "yearDown"))
          win.check("year down arrow is previous year", agenda.monthOffset === -11)
          keyClick(Qt.Key_PageDown, Qt.ControlModifier)
          win.check("ctrl+pagedown steps to media after activation", content.currentPage === 2)
          win.check("leaving the agenda page keeps the shown month", agenda.monthOffset === -11)
          keyClick(Qt.Key_PageDown, Qt.ControlModifier)
          win.check("paging clamps at media", content.currentPage === 2)
          keyClick(Qt.Key_PageUp, Qt.ControlModifier)
          win.check("ctrl+pageup steps back", content.currentPage === 1)
          var escaped = false
          content.escaped.connect(function() { escaped = true })
          keyClick(Qt.Key_Escape)
          win.check("escape emits escaped", escaped)
          content.active = false
          wait(20)
          win.check("closing the sidebar resets the shown month", agenda.monthOffset === 0)

          // Wheel over the indicators: one page per 120-unit notch.
          content.currentPage = 2
          var ind = win.find(content, "pageIndicators")
          mouseWheel(ind, 5, 5, 0, 40)
          mouseWheel(ind, 5, 5, 0, 40)
          win.check("two 40-unit deltas do not page", content.currentPage === 2)
          mouseWheel(ind, 5, 5, 0, 40)
          win.check("a full notch steps one page back", content.currentPage === 1)
          mouseWheel(ind, 5, 5, 0, 120)
          win.check("the next notch steps again", content.currentPage === 0)
          mouseWheel(ind, 5, 5, 0, 80)
          mouseWheel(ind, 5, 5, 0, -120)
          win.check("a direction flip drops the partial notch", content.currentPage === 1)

          content.visible = false
          console.log("DONE sidebar " + win.failures + " fail")
          quitTimer.start()
        }
      }
    }
  }
}
