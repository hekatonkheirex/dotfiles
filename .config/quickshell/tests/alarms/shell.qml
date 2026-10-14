// Staged at the config-copy root by scripts/alarms-render.sh.
// Grabs AlarmsContent in its states (browse a, quick q, standard s with the
// label field active, empty e) to RENDER_DIR, logs GEOM boxes and the palette,
// then runs click/key checks and AlarmService integration checks. The service
// only runs fake commands (argv appended to ALARM_LOG) against a fake clock
// and the scratch HOME's state file.
import QtQuick
import QtTest
import Quickshell
import "config"
import "config/Alarms.js" as Alarms
import "bar/alarms"

ShellRoot {
  FloatingWindow {
    id: win
    implicitWidth: 1100
    implicitHeight: 400
    color: Colors.surface
    mask: Region {}
    property int failures: 0
    readonly property real t0: new Date(2026, 9, 14, 10, 0, 0, 0).getTime()
    readonly property var two: [
      { at: new Date(2026, 9, 14, 7, 5).getTime(), label: "gym" },
      { at: new Date(2026, 9, 14, 18, 40).getTime(), label: "call mom" }
    ]

    function check(name, ok) {
      if (!ok) failures++
      console.log((ok ? "PASS " : "FAIL ") + name)
    }
    function find(item, name) {
      if (!item) return null
      if (item.objectName === name) return item
      var children = (item.children || [])
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

    Rectangle { id: frameA; width: a.implicitWidth; height: a.implicitHeight; color: Colors.surface
      AlarmsContent { id: a; anchors.fill: parent; alarmsModel: win.two } }
    Rectangle { id: frameQ; x: frameA.width + 20; width: q.implicitWidth; height: q.implicitHeight; color: Colors.surface
      AlarmsContent { id: q; anchors.fill: parent; alarmsModel: win.two } }
    Rectangle { id: frameS; x: 2 * (frameA.width + 20); width: s.implicitWidth; height: s.implicitHeight; color: Colors.surface
      AlarmsContent { id: s; anchors.fill: parent; alarmsModel: win.two } }
    Rectangle { id: frameE; y: frameA.height + 20; width: e.implicitWidth; height: e.implicitHeight; color: Colors.surface
      AlarmsContent { id: e; anchors.fill: parent; alarmsModel: [] } }

    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }
    Item {
      TestCase {
        name: "alarms"
        when: true
        function grab(item, name) {
          var done = false
          item.grabToImage(function(r) { done = r.saveToFile(Quickshell.env("RENDER_DIR") + "/" + name + ".png") })
          tryVerify(function() { return done }, 5000)
        }
        function txt(c, n) { return win.find(c, n).text }
        function test_alarms() {
          Config.reducedMotion = true
          wait(1200)
          var slots = [1, 2, 3, 6, 8]
          for (var i = 0; i < slots.length; i++) console.log("COLOR x" + slots[i] + " " + Colors.elenaAccent(slots[i]))
          console.log("COLOR surface " + Colors.surface)
          console.log("COLOR surfaceContainer " + Colors.surfaceContainer)
          console.log("COLOR fg " + Colors.fgSurface)

          // Browse.
          win.check("browse top label", txt(a, "topLabel") === "next up")
          win.check("browse shows first alarm", txt(a, "hour") === "07" && txt(a, "minute") === "05"
            && txt(a, "bottomLabel") === "gym" && txt(a, "separator") === ":")
          grab(frameA, "a")
          for (var n of ["btn_quick", "btn_standard", "btn_prev", "btn_delete", "btn_next", "hour", "separator", "minute", "topLabel", "bottomLabel"]) win.geom("a", frameA, n)
          var got = []
          a.confirmed.connect(function(m, inp) { got.push("confirm:" + m) })
          a.deleteRequested.connect(function(ix) { got.push("delete:" + ix) })
          a.dismissRequested.connect(function() { got.push("dismiss") })
          function last() { return got.length ? got[got.length - 1] : "" }
          mouseClick(win.find(a, "btn_prev"))
          win.check("prev at index 0 does nothing", a.index === 0)
          mouseClick(win.find(a, "btn_next"))
          win.check("next moves to the second alarm", a.index === 1 && txt(a, "hour") === "18"
            && txt(a, "minute") === "40" && txt(a, "bottomLabel") === "call mom")
          mouseClick(win.find(a, "btn_next"))
          win.check("next at the end does nothing", a.index === 1)
          mouseClick(win.find(a, "btn_delete"))
          win.check("delete asks for the shown index", last() === "delete:1")
          a.alarmsModel = []
          win.check("count change returns to index 0", a.index === 0)
          win.check("empty browse texts", txt(a, "topLabel") === "no alarms" && txt(a, "hour") === "--"
            && txt(a, "minute") === "--" && txt(a, "bottomLabel") === "all clear")
          mouseClick(win.find(a, "btn_delete"))
          win.check("delete with no alarms does nothing", last() === "delete:1")
          a.alarmsModel = win.two
          grab(frameE, "e")
          for (n of ["topLabel", "hour", "minute", "bottomLabel", "btn_delete", "btn_prev", "btn_next"]) win.geom("e", frameE, n)
          win.check("empty window texts", txt(e, "topLabel") === "no alarms" && txt(e, "bottomLabel") === "all clear")

          // Quick.
          var expander = win.find(q, "expander")
          var closedH = expander.height
          q.confirmed.connect(function(m, inp) { got.push("qconfirm:" + m + ":" + inp.hours + ":" + inp.minutes + ":" + inp.label) })
          mouseClick(win.find(q, "btn_quick"))
          wait(60)   // the Column lays out on the next frame
          win.check("quick state", q.state === "select-time-quick" && txt(q, "topLabel") === "ring in" && txt(q, "separator") === "h")
          win.check("cancel/confirm row expands", expander.height > closedH)
          win.check("quick preview starts at 00h 00", txt(q, "hour") === "00" && txt(q, "minute") === "00")
          mouseClick(win.find(q, "btn_confirm"))
          win.check("quick confirm with 0 minutes does nothing", q.state === "select-time-quick")
          mouseClick(win.find(q, "step_plus_5"))
          mouseClick(win.find(q, "step_plus_60"))
          mouseClick(win.find(q, "step_plus_1"))
          win.check("quick steps add 66 minutes", txt(q, "hour") === "01" && txt(q, "minute") === "06")
          q.forceActiveFocus()
          keyClick(Qt.Key_Tab); keyClick(Qt.Key_Tab)
          for (var c of "gym") keyClick(c)
          win.check("label typed", txt(q, "bottomLabel").indexOf("gym") === 0)
          grab(frameQ, "q")
          for (n of ["btn_quick", "btn_standard", "btn_cancel", "btn_confirm", "hour", "separator", "minute", "topLabel", "bottomLabel", "quickSteps", "step_plus_5"]) win.geom("q", frameQ, n)
          keyClick(Qt.Key_Return)
          win.check("Enter confirms the quick alarm", last() === "qconfirm:quick:1:6:gym" && q.state === "select-type" && q.index === 0)
          // Wheel steps: up decreases, as her script does.
          mouseClick(win.find(q, "btn_quick"))
          wait(60)
          mouseWheel(win.find(q, "minute"), 2, 2, 0, 120)
          win.check("wheel up on minutes steps back one (wraps to 23:59)", txt(q, "hour") === "23" && txt(q, "minute") === "59")
          mouseWheel(win.find(q, "hour"), 2, 2, 0, -120)
          win.check("wheel down on hours steps +60", txt(q, "hour") === "00")
          mouseClick(win.find(q, "labelHit"))
          win.check("clicking the label selects it", q.input.field === "label")
          mouseClick(win.find(q, "minute"))
          win.check("clicking minutes selects it", q.input.field === "minutes")
          keyClick(Qt.Key_Escape)
          win.check("Esc cancels the entry, no dismiss", q.state === "select-type")
          a.forceActiveFocus()

          // Standard.
          mouseClick(win.find(s, "btn_standard"))
          wait(60)
          win.check("standard state", s.state === "select-time-standard" && txt(s, "topLabel") === "ring at" && txt(s, "separator") === ":")
          s.forceActiveFocus()
          keyClick("2"); keyClick("9")
          win.check("hours clamp to 23", txt(s, "hour") === "23")
          keyClick(Qt.Key_Tab)
          keyClick("0"); keyClick("5")
          win.check("minutes entry", txt(s, "minute") === "05")
          keyClick("x")
          win.check("non digit ignored", txt(s, "minute") === "05")
          keyClick(Qt.Key_Tab)
          win.check("label placeholder not shown while active", txt(s, "bottomLabel").indexOf("e.g.") < 0)
          grab(frameS, "s")
          for (n of ["btn_quick", "btn_standard", "btn_cancel", "btn_confirm", "hour", "minute", "bottomLabel", "standardSteps", "step_plus_60"]) win.geom("s", frameS, n)
          keyClick(Qt.Key_Tab)
          win.check("tab cycles back to hours", s.input.field === "hours")
          keyClick(Qt.Key_Backspace)
          win.check("backspace clears the last hour digit", txt(s, "hour") === "02")
          mouseClick(win.find(s, "btn_cancel"))
          win.check("cancel button returns to browse", s.state === "select-type")
          s.begin("select-time-standard")
          wait(30)
          win.check("placeholder when label empty and not active", txt(s, "bottomLabel") === "e.g. gym")
          s.begin("select-type")

          // Dismiss paths.
          var n1 = got.length
          mouseClick(win.find(a, "hour"), 2, 2, Qt.MiddleButton)
          win.check("middle click dismisses", last() === "dismiss" && got.length === n1 + 1)
          a.forceActiveFocus()
          keyClick(Qt.Key_Escape)
          win.check("Esc dismisses from browse", got.length === n1 + 2 && last() === "dismiss")

          serviceChecks()
          console.log("DONE alarms " + win.failures + " fail")
          quitTimer.start()
        }

        function readFile(path) {
          var x = new XMLHttpRequest()
          x.open("GET", "file://" + path, false)
          try { x.send() } catch (err) { return "" }
          return x.responseText
        }
        function logLines() { return readFile(Quickshell.env("ALARM_LOG")).split("\n").filter(function(l) { return l !== "" }) }

        function serviceChecks() {
          var svc = AlarmService
          var same = function(x, y) { return JSON.stringify(x) === JSON.stringify(y) }
          win.check("default sound argv", same(svc.commandFor("sound", {}), ["pw-play", "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"]))
          win.check("default ring argv is critical and sticky", same(svc.commandFor("ring", { body: "x" }),
            ["notify-send", "-u", "critical", "-t", "0", "-a", "quickshell-alarm", "Alarm", "x"]))
          win.check("default notice argv", same(svc.commandFor("notice", { body: "Will ring at 10:05" }),
            ["notify-send", "-u", "low", "-t", "2000", "-a", "quickshell-alarm", "Alarm", "Will ring at 10:05"]))
          tryVerify(function() { return svc.loaded }, 5000)
          win.check("no file on first run: loaded empty", svc.count === 0)

          var clock = win.t0
          svc.nowFn = function() { return clock }
          svc.commandFor = function(kind, args) {
            return ["sh", "-c", "printf '%s|%s\\n' \"$0\" \"$1\" >> \"$ALARM_LOG\"", kind, (args && args.body) || ""]
          }
          var rang = []
          svc.rang.connect(function(al, missed) { rang.push(al.label + ":" + missed) })
          var file = Quickshell.env("HOME") + "/.local/state/quickshell/alarms.json"

          svc.add(clock + 5 * 60000, "tea")
          wait(250)
          win.check("add: count 1, notice logged", svc.count === 1 && logLines().indexOf("notice|Will ring at 10:05") >= 0)
          win.check("add: file written", JSON.parse(readFile(file)).length === 1 && JSON.parse(readFile(file))[0].label === "tea")
          clock = win.t0 + 5 * 60000 - 1
          svc.tick(false)
          wait(150)
          win.check("not due 1 ms early: no ring", rang.length === 0 && svc.count === 1)
          clock = win.t0 + 5 * 60000
          svc.tick(false)
          wait(250)
          var lines = logLines()
          win.check("due: rang once, on time", same(rang, ["tea:false"]) && svc.count === 0)
          win.check("due: sound and sticky notification issued once each",
            lines.filter(function(l) { return l === "sound|" }).length === 1 && lines.indexOf("ring|tea") >= 0)
          win.check("due: file emptied", JSON.parse(readFile(file)).length === 0)
          svc.tick(false)
          wait(100)
          win.check("a rung alarm never rings twice", rang.length === 1)

          // Cancel before due.
          svc.add(clock + 60000, "cancelled")
          win.check("cancel: removeAt out of range is false", svc.removeAt(5) === false && svc.count === 1)
          win.check("cancel: removeAt(0) removes", svc.removeAt(0) === true && svc.count === 0)
          wait(150)
          clock += 120000
          svc.tick(false)
          wait(100)
          win.check("cancelled alarm never rings", rang.length === 1 && JSON.parse(readFile(file)).length === 0)

          // Late wake (suspend): ring marked missed.
          svc.add(clock + 60000, "slept")
          clock += 10 * 60000
          svc.tick(false)
          wait(200)
          win.check("rings after a late wake, marked missed", rang[rang.length - 1] === "slept:true"
            && logLines().indexOf("ring|slept (missed, was 10:08)") >= 0)

          // Restart with a file holding one past and one future alarm.
          rang.length = 0
          clock = win.t0 + 3600000
          var past = clock - 30000, future = clock + 3600000
          Quickshell.execDetached(["sh", "-c", "printf '%s' '" + JSON.stringify([
            { id: 1, at: past, label: "overnight" }, { id: 2, at: future, label: "later" }]) + "' > '" + file + "'"])
          wait(300)
          svc.file.reload()
          tryVerify(function() { return svc.count === 1 }, 3000)
          wait(200)
          win.check("restart: past alarm rings once as missed, future kept",
            same(rang, ["overnight:true"]) && svc.alarms[0].label === "later")
          win.check("restart: file keeps only the future alarm",
            JSON.parse(readFile(file)).length === 1 && JSON.parse(readFile(file))[0].label === "later")
          // Corrupt file: empty list, no crash.
          Quickshell.execDetached(["sh", "-c", "printf 'not json' > '" + file + "'"])
          wait(300)
          svc.file.reload()
          tryVerify(function() { return svc.count === 0 }, 3000)
          win.check("corrupt file loads as empty", svc.count === 0)
        }
      }
    }
  }
}
