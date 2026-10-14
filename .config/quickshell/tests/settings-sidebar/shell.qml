// Staged at the config-copy root by scripts/settings-sidebar-render.sh.
// Six 450 px cells, one per Settings page, each a real SettingsSidebarContent.
// Logs OVERFLOW for any visible item that leaves its cell on the right, then
// saves the grab to GOLDEN_OUT.
import QtQuick
import QtTest
import Quickshell
import "config"
import "bar/settingsbar"

ShellRoot {
  FloatingWindow {
    id: win
    implicitWidth: 2700
    implicitHeight: 760
    color: Colors.surface
    mask: Region {}
    property int failures: 0

    function check(name, ok) {
      if (!ok) failures++
      console.log((ok ? "PASS " : "FAIL ") + name)
    }
    // Visible descendants whose right edge passes the cell's.
    function overflow(item, cell, page, out) {
      var kids = item.children || []
      for (var i = 0; i < kids.length; i++) {
        var k = kids[i]
        if (!k.visible || k.width <= 0 || k.height <= 0 || k.opacity === 0) continue
        var p = k.mapToItem(cell, 0, 0)
        if (p.x + k.width > cell.width + 1)
          out.push("OVERFLOW page " + page + " " + k + " right=" + Math.round(p.x + k.width) + " cell=" + cell.width)
        overflow(k, cell, page, out)
      }
    }

    Item {
      id: stage
      width: 2700
      height: 760
      Rectangle { anchors.fill: parent; color: Colors.surface }
      Repeater {
        id: cells
        model: 6
        Item {
          id: cell
          required property int index
          x: index * 450; width: 450; height: 760
          clip: true
          SettingsSidebarContent {
            objectName: "content" + cell.index
            anchors.fill: parent
            currentPage: cell.index
            active: true
          }
        }
      }
    }

    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }
    Item {
      TestCase {
        name: "settings-sidebar"
        when: true
        function test_pages() {
          wait(2500)
          var done = false
          stage.grabToImage(function(r) { done = r.saveToFile(Quickshell.env("GOLDEN_OUT")) })
          tryVerify(function() { return done }, 5000)
          var out = []
          try {
            for (var i = 0; i < 6; i++) win.overflow(cells.itemAt(i), cells.itemAt(i), i, out)
          } catch (e) { console.log("FAIL walk threw " + e); win.failures++ }
          for (var j = 0; j < out.length; j++) console.log(out[j])
          win.check("no item leaves its page cell", out.length === 0)
          console.log("DONE settings-sidebar " + win.failures + " fail")
          quitTimer.start()
        }
      }
    }
  }
}
