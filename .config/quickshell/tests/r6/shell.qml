// Staged at the config-copy root by scripts/r6-render.sh.
// R6a: MicService against fixture pactl output (never the real pactl) and the
// MicIndicator tab pixels. R6b: the NotificationToast stack with fake
// notification objects: urgency colors, duplicate counting, the limit of five,
// expiry, close, default action and close-all. Logs GEOM boxes and the palette
// for the pixel stage.
import QtQuick
import QtTest
import Quickshell
import "config"
import "bar"

ShellRoot {
  Component {
    id: fakeNotif
    QtObject {
      property int urgency: 1
      property string appName: "App"
      property string summary: ""
      property string body: ""
      property real expireTimeout: -1
      property var actions: []
      property int dismissCount: 0
      property int invoked: 0
      signal closed()
      function dismiss() { dismissCount++; closed() }
    }
  }
  Component {
    id: fakeAction
    QtObject {
      property string identifier: "default"
      property string text: "Open"
      property int count: 0
      function invoke() { count++ }
    }
  }

  FloatingWindow {
    id: win
    implicitWidth: 400
    implicitHeight: 200
    color: Colors.surface
    mask: Region {}
    property int failures: 0
    function check(name, ok) {
      if (!ok) failures++
      console.log((ok ? "PASS " : "FAIL ") + name)
    }
    function find(item, name) {
      if (!item) return null
      if (item.objectName === name) return item
      var children = item.children || []
      for (var i = 0; i < children.length; i++) {
        var f = find(children[i], name)
        if (f) return f
      }
      return null
    }
    function geom(img, frame, name, it) {
      if (!it) { check("found " + name + " in " + img, false); return }
      var p = it.mapToItem(frame, 0, 0)
      console.log("GEOM " + img + " " + name + " " + Math.round(p.x) + " " + Math.round(p.y) + " " + Math.round(it.width) + " " + Math.round(it.height))
    }

    MicIndicator { id: tab; allowed: true }
    NotificationToast { id: toast }

    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }
    Item {
      TestCase {
        name: "r6"
        when: true
        function grab(item, name) {
          var done = false
          item.grabToImage(function(r) { done = r.saveToFile(Quickshell.env("RENDER_DIR") + "/" + name + ".png") })
          tryVerify(function() { return done }, 5000)
        }
        function make(urgency, summary, body, expire) {
          return fakeNotif.createObject(win, { urgency: urgency, summary: summary, body: body, expireTimeout: expire === undefined ? -1 : expire })
        }
        function cards() {
          var out = []
          for (var i = 0; i < toast.count; i++) out.push(i)
          return out
        }
        function test_r6() {
          Config.reducedMotion = true
          wait(800)
          var slots = [1, 2, 6, 8]
          for (var i = 0; i < slots.length; i++) console.log("COLOR x" + slots[i] + " " + Colors.elenaAccent(slots[i]))
          console.log("COLOR surface " + Colors.surface)
          console.log("COLOR surfaceContainer " + Colors.surfaceContainer)
          console.log("COLOR fg " + Colors.fgSurface)

          micChecks()
          toastChecks()
          console.log("DONE r6 " + win.failures + " fail")
          quitTimer.start()
        }

        function micChecks() {
          var svc = MicService
          var same = function(x, y) { return JSON.stringify(x) === JSON.stringify(y) }
          win.check("default mute argv", same(svc.commandFor("mute", { source: "s" }), ["pactl", "get-source-mute", "s"]))
          win.check("default toggle argv", same(svc.commandFor("toggle", {}), ["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"]))
          var fx = Quickshell.env("R6_FIXTURES")
          var calls = []
          var state = { source: "mic_a", mute: "Mute: no" }
          svc.commandFor = function(kind, args) {
            calls.push(kind)
            switch (kind) {
            case "source": return ["printf", "%s\n", state.source]
            case "mute": return ["printf", "%s\n", state.mute]
            case "sources": return ["cat", fx + "/sources.txt"]
            case "notify": return ["sh", "-c", "printf '%s\\n' \"$0\" >> \"$R6_LOG\"", args.body]
            case "toggle": return ["sh", "-c", "echo toggle >> \"$R6_LOG\""]
            case "subscribe": return ["sleep", "3600"]
            }
            return ["true"]
          }
          svc.update()
          tryVerify(function() { return svc.ready }, 3000)
          win.check("live mic: ready and not muted", svc.ready && svc.muted === false)
          wait(150)
          win.check("tab visible while live", tab.visible)
          win.check("live look is x1 at full opacity", tab.look.slot === 1 && tab.look.opacity === 1)
          grab(win.find(tab.contentItem, "tab"), "tab-live")
          win.geom("tab-live", win.find(tab.contentItem, "tab"), "tab", win.find(tab.contentItem, "tab"))

          state.mute = "Mute: yes"
          svc.update()
          tryVerify(function() { return svc.muted }, 3000)
          wait(100)
          win.check("muted look is x8 at 0.4", tab.look.slot === 8 && Math.abs(tab.look.opacity - 0.4) < 0.001)
          grab(win.find(tab.contentItem, "tab"), "tab-muted")
          win.geom("tab-muted", win.find(tab.contentItem, "tab"), "tab", win.find(tab.contentItem, "tab"))
          win.check("tab stays visible while muted", tab.visible)

          svc.hide()
          wait(50)
          win.check("middle click hides the tab", !tab.visible)
          state.mute = "Mute: no"
          svc.update()
          tryVerify(function() { return !svc.muted }, 3000)
          wait(100)
          win.check("a mute change shows it again", tab.visible)

          // Default source change posts the recording-device notice once.
          state.source = "mic_b"
          svc.update()
          tryVerify(function() { return svc.deviceName === "Headset Mic" }, 3000)
          wait(250)
          win.check("source change reads the new description", svc.deviceName === "Headset Mic")
          win.check("source change posts one notice", calls.filter(function(c) { return c === "notify" }).length === 1)
          svc.toggle()
          wait(200)

          // Settings off: window and reader stop.
          Settings.micIndicator = false
          wait(100)
          win.check("disabled: tab hidden", !tab.visible && !svc.enabled && !svc.ready)
          Settings.micIndicator = true
          wait(200)
        }

        function toastChecks() {
          toast.suppress()
          win.check("starts empty and hidden", toast.count === 0 && !toast.visible)

          // Colors per urgency (frame x0, glyph in x6, x2, x1).
          var low = make(0, "Low one", "body low")
          var nor = make(1, "Normal one", "body normal")
          var cri = make(2, "Critical one", "body critical")
          toast.show(low); toast.show(nor); toast.show(cri)
          wait(200)
          win.check("three cards", toast.count === 3)
          grab(toast.stackColumn, "toast")
          for (var uid = 1; uid <= 3; uid++) {
            var card = win.find(toast.stackColumn, "toast_" + uid)
            win.geom("toast", toast.stackColumn, "glyph_" + uid, win.find(card, "summaryGlyph"))
            win.geom("toast", toast.stackColumn, "body_" + uid, win.find(card, "bodyGlyph"))
            win.geom("toast", toast.stackColumn, "card_" + uid, card)
          }
          win.check("summary and body text shown", win.find(toast.stackColumn, "summaryText").text === "Low one"
            && win.find(toast.stackColumn, "bodyText").text === "body low")

          // Left click closes that card and dismisses the notification.
          mouseClick(win.find(toast.stackColumn, "toast_1"), 20, 20, Qt.LeftButton)
          wait(100)
          win.check("left click closes the card", toast.count === 2 && low.dismissCount === 1)

          // Middle click runs the default action and closes.
          var act = fakeAction.createObject(win, {})
          var withAct = make(1, "Has default", "")
          withAct.actions = [act]
          toast.show(withAct)
          wait(100)
          var idx = toast.count
          var cardAct = win.find(toast.stackColumn, "toast_4")
          mouseClick(cardAct, 20, 20, Qt.MiddleButton)
          wait(100)
          win.check("middle click invokes the default action", act.count === 1 && toast.count === idx - 1)
          // Middle click without a default action dismisses.
          mouseClick(win.find(toast.stackColumn, "toast_2"), 20, 20, Qt.MiddleButton)
          wait(100)
          win.check("middle click without default action closes", nor.dismissCount === 1)

          // Right click closes every card.
          toast.show(make(1, "R1", "")); toast.show(make(1, "R2", ""))
          wait(100)
          var before = toast.count
          mouseClick(win.find(toast.stackColumn, "toast_" + (toast.count > 0 ? 3 : 3)), 20, 20, Qt.RightButton)
          wait(100)
          win.check("right click closes all (" + before + " cards)", toast.count === 0)
          win.check("critical dismissed with the rest", cri.dismissCount === 1)

          // Duplicates stack with a count.
          var d1 = make(1, "Same", "text"), d2 = make(1, "Same", "text"), d3 = make(1, "Same", "text")
          toast.show(d1); toast.show(d2); toast.show(d3)
          wait(100)
          win.check("duplicates make one card with (3)", toast.count === 1
            && win.find(toast.stackColumn, "summaryText").text === "Same (3)")
          // Different body is a different card.
          toast.show(make(1, "Same", "other"))
          wait(100)
          win.check("different body is a new card", toast.count === 2)
          toast.suppress()

          // Limit of five: the oldest card goes, history keeps it (not dismissed).
          var held = []
          for (var i = 0; i < 7; i++) { var n = make(1, "N" + i, ""); held.push(n); toast.show(n) }
          wait(150)
          win.check("limit of five cards", toast.count === 5)
          win.check("oldest cards dropped", win.find(toast.stackColumn, "summaryText").text === "N2")
          win.check("dropped cards are not dismissed", held[0].dismissCount === 0 && held[1].dismissCount === 0)
          toast.suppress()

          // Expiry: app timeout wins; critical, unset-critical and 0 stay.
          var shortLived = make(1, "Short", "", 300)
          var stickyZero = make(1, "Zero", "", 0)
          var stickyCrit = make(2, "Crit", "")
          toast.show(shortLived); toast.show(stickyZero); toast.show(stickyCrit)
          wait(800)
          win.check("app timeout expires the card", toast.count === 2)
          win.check("timeout 0 and critical stay", win.find(toast.stackColumn, "toast_" + 0) === null && toast.count === 2)
          // Closing from outside removes the card.
          stickyCrit.closed()
          wait(100)
          win.check("closed signal removes the card", toast.count === 1)
          toast.suppress()
          win.check("suppress hides without dismissing", toast.count === 0 && stickyZero.dismissCount === 0)
        }
      }
    }
  }
}
