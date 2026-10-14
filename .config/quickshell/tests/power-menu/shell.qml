// Staged at the config-copy root by scripts/powermenu-render.sh.
// Grabs PowerMenuContent revealed (a), revealed with reboot selected (b) and
// locked at five ring states (ring_<len>_<action>) to RENDER_DIR, logs GEOM
// boxes relative to each grab, and runs the hover, keyboard, dismiss and
// masked-input checks.
import QtQuick
import QtTest
import Quickshell
import "config"
import "bar/powermenu"

ShellRoot {
  FloatingWindow {
    id: win
    implicitWidth: 1200
    implicitHeight: 800
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
    function geom(img, frame, name) {
      var it = find(frame, name)
      if (!it) { check("found " + name + " in " + img, false); return }
      var p = it.mapToItem(frame, 0, 0)
      console.log("GEOM " + img + " " + name + " " + Math.round(p.x) + " " + Math.round(p.y) + " " + Math.round(it.width) + " " + Math.round(it.height))
    }

    // Each frame paints the surface the overlay host would.
    Rectangle {
      id: frameA
      width: a.implicitWidth; height: a.implicitHeight
      color: Colors.surface
      PowerMenuContent { id: a; anchors.fill: parent; revealed: true }
    }
    Rectangle {
      id: frameB
      y: frameA.height
      width: b.implicitWidth; height: b.implicitHeight
      color: Colors.surface
      PowerMenuContent { id: b; anchors.fill: parent; revealed: true; selected: "reboot" }
    }
    Rectangle {
      id: frameL
      y: frameA.height + frameB.height
      width: l.implicitWidth; height: l.implicitHeight
      color: Colors.surface
      PowerMenuContent { id: l; anchors.fill: parent; locked: true; revealed: true }
    }

    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }
    Item {
      TestCase {
        name: "powermenu"
        when: true
        function grab(item, name) {
          var done = false
          item.grabToImage(function(r) { done = r.saveToFile(Quickshell.env("RENDER_DIR") + "/" + name + ".png") })
          tryVerify(function() { return done }, 5000)
        }
        function test_powermenu() {
          Config.reducedMotion = true
          wait(1500)
          grab(frameA, "a")
          grab(frameB, "b")
          var ids = ["poweroff", "reboot", "exit", "hibernate", "suspend", "lock"]
          for (var i = 0; i < ids.length; i++) {
            win.geom("a", frameA, "button_" + ids[i])
            win.geom("b", frameB, "button_" + ids[i])
          }
          for (i = 0; i < 6; i++) win.geom("a", frameA, "palette_" + i)
          win.geom("a", frameA, "terminalValue")
          win.geom("b", frameB, "terminalValue")
          win.check("terminal shows $ reboot", b.selected === "reboot"
            && win.find(b, "terminalValue").text === "reboot")

          var heart = win.find(a, "heart")
          win.check("heart ligature is one glyph", heart.contentWidth > 0
            && heart.contentWidth <= heart.font.pixelSize * 1.5 + heart.leftPadding)

          // Locked: buttons gone, ring per last action.
          win.check("locked hides the buttons", !win.find(l, "buttonGrid").visible)
          win.check("unlocked shows no ring", !win.find(a, "lockRing").visible)
          var states = [[0, "clear"], [1, "insert"], [2, "insert"], [1, "delete"], [2, "delete"]]
          for (i = 0; i < states.length; i++) {
            l.inputLength = states[i][0]
            l.lastAction = states[i][1]
            wait(50)
            var tag = "ring_" + states[i][0] + "_" + states[i][1]
            grab(frameL, tag)
            win.geom(tag, frameL, "lockRing")
            win.geom(tag, frameL, "lockGlyph")
          }

          // (f) Masked input: the count of characters follows inputLength.
          var mask = win.find(l, "terminalValue")
          l.inputLength = 3
          wait(20)
          var w3 = mask.contentWidth
          win.check("mask shows 3 characters", mask.text === "***")
          l.inputLength = 6
          wait(20)
          win.check("mask shows 6 characters", mask.text === "******")
          win.check("mask width doubles from 3 to 6", w3 > 0 && Math.abs(mask.contentWidth - 2 * w3) <= 2)
          var glyph = win.find(l, "lockGlyph")
          var normal = glyph.text
          l.authFailed = true
          win.check("failed auth swaps the ring glyph", glyph.text !== normal && glyph.text.length > 0)

          // Hover: selection follows the pointer and clears on leave.
          var hovers = []
          a.hovered.connect(function(id) { hovers.push(id) })
          var exitBtn = win.find(a, "button_exit")
          mouseMove(exitBtn, exitBtn.width / 2, exitBtn.height / 2)
          win.check("hover selects exit", a.selected === "exit" && hovers[hovers.length - 1] === "exit")
          win.check("hover dims the others", win.find(a, "button_poweroff").opacity === 0.3 && exitBtn.opacity === 1)
          mouseMove(frameA, 2, 2)
          win.check("leaving clears the selection", a.selected === "" && hovers[hovers.length - 1] === "")
          var bunny = win.find(a, "bunnyHead")
          var head = bunny.text
          mouseMove(win.find(a, "bunnyHover"), 4, 4)
          win.check("hovering the bunny pats its head", bunny.text === "( ^ ^) " && head === "( . .) ")

          // Clicks: a button acts; outside dismisses; middle click dismisses.
          var acted = []
          var dismissed = 0
          a.activated.connect(function(id) { acted.push(id) })
          a.dismissRequested.connect(function() { dismissed++ })
          mouseClick(win.find(a, "button_suspend"))
          win.check("click acts", acted[acted.length - 1] === "suspend" && dismissed === 0)
          mouseClick(frameA, 2, 2)
          win.check("click outside dismisses", dismissed === 1)
          mouseClick(win.find(a, "button_lock"), 5, 5, Qt.MiddleButton)
          win.check("middle click dismisses", dismissed === 2 && acted.length === 1)
          var lockDismiss = 0
          l.dismissRequested.connect(function() { lockDismiss++ })
          mouseClick(frameL, 2, 2)
          mouseClick(frameL, 2, 2, Qt.MiddleButton)
          win.check("locked ignores dismiss clicks", lockDismiss === 0)

          // Keyboard: arrows step the selection (model step), Enter acts, Esc dismisses.
          a.selected = ""
          a.forceActiveFocus()
          keyClick(Qt.Key_Right)
          win.check("first arrow selects poweroff", a.selected === "poweroff")
          keyClick(Qt.Key_Right)
          win.check("right steps to reboot", a.selected === "reboot")
          keyClick(Qt.Key_Up)
          win.check("up wraps to suspend", a.selected === "suspend")
          keyClick(Qt.Key_Left)
          keyClick(Qt.Key_Left)
          win.check("left crosses the row break", a.selected === "exit")
          keyClick(Qt.Key_Return)
          win.check("enter acts on the selection", acted[acted.length - 1] === "exit")
          keyClick(Qt.Key_Escape)
          win.check("escape dismisses", dismissed === 3)
          l.forceActiveFocus()
          keyClick(Qt.Key_Escape)
          win.check("locked leaves keys to the lock surface", lockDismiss === 0)

          console.log("DONE powermenu " + win.failures + " fail")
          quitTimer.start()
        }
      }
    }
  }
}
