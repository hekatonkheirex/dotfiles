// Staged at the config-copy root by scripts/networks-render.sh.
// Grabs NetworksContent with four fixture rows (a), with the passphrase row
// open and vpn on / scanning (b), the forget confirmation (f) and an empty
// model (e) to RENDER_DIR, logs GEOM boxes and the palette, and runs the
// click, key and service checks. The service only ever runs fixture
// commands: commandFor is swapped before `active` turns on.
import QtQuick
import QtTest
import Quickshell
import "config"
import "bar/networks"

ShellRoot {
  FloatingWindow {
    id: win
    implicitWidth: 1400
    implicitHeight: 900
    color: Colors.surface
    mask: Region {}
    property int failures: 0
    readonly property var rows: [
      { name: "HomeNet", signal: 90, secure: true, active: true, saved: true },
      { name: "CafeGuest", signal: 60, secure: false, active: false, saved: false },
      { name: "TheQuickBrownFoxJumpsOverIt", signal: 30, secure: true, active: false, saved: false },
      { name: "Weak", signal: 10, secure: true, active: false, saved: true }
    ]

    function check(name, ok) {
      if (!ok) failures++
      console.log((ok ? "PASS " : "FAIL ") + name)
    }
    function find(item, name) {
      if (!item) return null
      if (item.objectName === name) return item
      var children = (item.children || [])
      if (item.contentItem && children.indexOf(item.contentItem) < 0) children = children.concat([item.contentItem])
      for (var i = 0; i < children.length; i++) {
        var found = find(children[i], name)
        if (found) return found
      }
      return null
    }
    function geomItem(img, frame, label, it) {
      if (!it) { check("found " + label + " in " + img, false); return }
      var p = it.mapToItem(frame, 0, 0)
      console.log("GEOM " + img + " " + label + " " + Math.round(p.x) + " " + Math.round(p.y) + " " + Math.round(it.width) + " " + Math.round(it.height))
    }
    function geom(img, frame, name) { geomItem(img, frame, name, find(frame, name)) }
    function visibleButtons(content, kind) {
      var n = 0
      for (var i = 0; i < 4; i++) {
        var b = find(find(content, "row_" + i), kind + "Button")
        if (b && b.visible) n++
      }
      return n
    }

    Rectangle {
      id: frameA
      width: a.implicitWidth; height: a.implicitHeight
      color: Colors.surface
      NetworksContent {
        id: a
        anchors.fill: parent
        networksModel: win.rows
        downText: "1.25MB/s"
        upText: "0.40MB/s"
      }
    }
    Rectangle {
      id: frameB
      x: frameA.width + 20
      width: b.implicitWidth; height: b.implicitHeight
      color: Colors.surface
      NetworksContent {
        id: b
        anchors.fill: parent
        networksModel: win.rows
        vpnOn: true
        scanning: true
        pingText: "13ms"
        downText: "0.00MB/s"
        upText: "0.00MB/s"
      }
    }
    Rectangle {
      id: frameE
      x: 2 * (frameA.width + 20)
      width: e.implicitWidth; height: e.implicitHeight
      color: Colors.surface
      NetworksContent { id: e; anchors.fill: parent; networksModel: [] }
    }

    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }
    Item {
      TestCase {
        name: "networks"
        when: true
        function grab(item, name) {
          var done = false
          item.grabToImage(function(r) { done = r.saveToFile(Quickshell.env("RENDER_DIR") + "/" + name + ".png") })
          tryVerify(function() { return done }, 5000)
        }
        function test_networks() {
          Config.reducedMotion = true
          wait(1200)
          var slots = [1, 2, 3, 4, 5, 8]
          for (var s = 0; s < slots.length; s++) console.log("COLOR x" + slots[s] + " " + Colors.elenaAccent(slots[s]))
          console.log("COLOR surface " + Colors.surface)
          console.log("COLOR surfaceContainer " + Colors.surfaceContainer)
          console.log("COLOR fg " + Colors.fgSurface)

          // (a) Rows, buttons, names, bandwidth, toolbar.
          grab(frameA, "a")
          for (var i = 0; i < 4; i++) {
            var row = win.find(a, "row_" + i)
            win.geomItem("a", frameA, "border_" + i, win.find(row, "border"))
            var kinds = ["connect", "disconnect", "forget"]
            for (var k = 0; k < kinds.length; k++) {
              var btn = win.find(row, kinds[k] + "Button")
              if (btn && btn.visible) win.geomItem("a", frameA, kinds[k] + "_" + i, btn)
            }
          }
          win.check("connect buttons: 3", win.visibleButtons(a, "connect") === 3)
          win.check("disconnect buttons: 1", win.visibleButtons(a, "disconnect") === 1)
          win.check("forget buttons: 2", win.visibleButtons(a, "forget") === 2)
          win.check("connected row has disconnect, not connect",
            win.find(win.find(a, "row_0"), "disconnectButton") !== null
            && win.find(win.find(a, "row_0"), "connectButton") === null)
          win.check("long name cut to 19 + ...", win.find(win.find(a, "row_2"), "nameText").text === "TheQuickBrownFoxJum...")
          win.check("short name kept", win.find(win.find(a, "row_0"), "nameText").text === "HomeNet")
          win.check("saved and new rows use different type glyphs",
            win.find(win.find(a, "row_0"), "typeDisc").glyph !== win.find(win.find(a, "row_1"), "typeDisc").glyph)
          win.check("empty state hidden with rows", !win.find(a, "emptyState").visible)
          var labels = [["tool_vpn", "vpn off"], ["tool_scan", "4 nets"], ["tool_speed", "speedtest"], ["tool_ping", "ping"]]
          for (i = 0; i < labels.length; i++) {
            var tool = win.find(a, labels[i][0])
            win.check(labels[i][0] + " label is " + labels[i][1], win.find(tool, "label").text === labels[i][1])
            win.geomItem("a", frameA, labels[i][0] + "_symbol", win.find(tool, "symbol"))
            win.geomItem("a", frameA, labels[i][0] + "_label", win.find(tool, "label"))
          }
          win.check("bandwidth down text", win.find(a, "bandDownText").text === "1.25MB/s")
          win.check("bandwidth up text", win.find(a, "bandUpText").text === "0.40MB/s")
          for (var nm of ["bandDownSymbol", "bandUpSymbol", "bandDownText", "bandUpText"]) win.geom("a", frameA, nm)
          win.check("rows sit in a 4-row list", Math.abs(win.find(a, "listFrame").height - 4 * Config.dp(60)) <= 1)

          // (e) Empty model.
          grab(frameE, "e")
          win.check("empty state shown", win.find(e, "emptyState").visible)
          win.check("empty text", win.find(e, "emptyText").text === "No networks found")
          win.check("empty scan label 0 nets", win.find(win.find(e, "tool_scan"), "label").text === "0 nets")
          win.geom("e", frameE, "emptyText")
          win.geom("e", frameE, "emptySymbol")

          // Signals from clicks.
          var got = []
          a.connectRequested.connect(function(n, p) { got.push("connect:" + n + ":" + p) })
          a.disconnectRequested.connect(function() { got.push("disconnect") })
          a.forgetConfirmed.connect(function(n) { got.push("forget:" + n) })
          a.scanRequested.connect(function() { got.push("scan") })
          a.speedtestRequested.connect(function() { got.push("speedtest") })
          a.pingRequested.connect(function() { got.push("ping") })
          a.vpnRequested.connect(function() { got.push("vpn") })
          a.dismissRequested.connect(function() { got.push("dismiss") })
          function last() { return got.length ? got[got.length - 1] : "" }

          mouseClick(win.find(win.find(a, "row_1"), "connectButton"))
          win.check("open network connects directly", last() === "connect:CafeGuest:" && a.passphraseFor === "")
          mouseClick(win.find(win.find(a, "row_3"), "connectButton"))
          win.check("saved network connects directly", last() === "connect:Weak:" && a.passphraseFor === "")
          mouseClick(win.find(win.find(a, "row_0"), "disconnectButton"))
          win.check("disconnect click", last() === "disconnect")

          // (b) Passphrase row open, vpn on, scanning. Set first: opening it
          // takes keyboard focus.
          b.passphraseFor = "TheQuickBrownFoxJumpsOverIt"
          wait(50)
          win.find(b, "passInput").text = "abc"
          wait(50)
          grab(frameB, "b")
          win.geom("b", frameB, "passInput")
          win.geomItem("b", frameB, "tool_vpn_symbol", win.find(win.find(b, "tool_vpn"), "symbol"))
          win.geomItem("b", frameB, "tool_scan_symbol", win.find(win.find(b, "tool_scan"), "symbol"))
          win.check("vpn on label", win.find(win.find(b, "tool_vpn"), "label").text === "vpn on")
          win.check("ping label follows pingText", win.find(win.find(b, "tool_ping"), "label").text === "13ms")
          b.passphraseFor = ""

          // Passphrase: new secured network.
          var n0 = got.length
          mouseClick(win.find(win.find(a, "row_2"), "connectButton"))
          var pass = win.find(a, "passphraseRow")
          var input = win.find(a, "passInput")
          win.check("new secured network opens the passphrase row", got.length === n0
            && a.passphraseFor === "TheQuickBrownFoxJumpsOverIt" && pass.visible)
          win.check("passphrase input has focus", input.activeFocus)
          keyClick("a"); keyClick("b"); keyClick("c")
          win.check("passphrase is masked", input.text === "abc" && input.echoMode === TextInput.Password
            && input.displayText !== "abc" && input.displayText.length === 3)
          keyClick(Qt.Key_Escape)
          win.check("Esc hides the passphrase row, no dismiss", a.passphraseFor === "" && !pass.visible && last() !== "dismiss")
          mouseClick(win.find(win.find(a, "row_2"), "connectButton"))
          keyClick("p"); keyClick("w")
          keyClick(Qt.Key_Return)
          win.check("Enter connects with the passphrase", last() === "connect:TheQuickBrownFoxJumpsOverIt:pw" && a.passphraseFor === "")
          win.check("focus returns to the content after Enter", a.activeFocus)
          mouseClick(win.find(win.find(a, "row_2"), "connectButton"))
          keyClick("x")
          a.passphraseFor = ""
          win.check("hiding the row clears the typed passphrase", input.text === "")
          mouseClick(win.find(win.find(a, "row_2"), "connectButton"))
          keyClick("y")
          a.passphraseFor = "OtherNet"
          win.check("switching networks clears the typed passphrase", input.text === "" && pass.visible)
          a.passphraseFor = ""
          mouseClick(win.find(win.find(a, "row_2"), "connectButton"))
          win.check("passphrase row has focus again", input.activeFocus)
          mouseClick(win.find(win.find(a, "row_3"), "forgetButton"))
          win.check("forget click closes the passphrase row and refocuses the content",
            a.passphraseFor === "" && a.forgetFor === "Weak" && a.activeFocus)
          keyClick(Qt.Key_Escape)
          win.check("Esc closes the forget row first", a.forgetFor === "" && last() !== "dismiss")
          win.check("input cleared on reopen", (function() { a.passphraseFor = "Weak"; var t = input.text; a.passphraseFor = ""; return t === "" })())
          // Leave the passphrase row open with focus in it: the Esc check below
          // must not depend on a test-side refocus.
          mouseClick(win.find(win.find(a, "row_2"), "connectButton"))
          keyClick("q")
          keyClick(Qt.Key_Return)

          // Forget: Yes/No.
          mouseClick(win.find(win.find(a, "row_0"), "forgetButton"))
          var fr = win.find(a, "forgetRow")
          win.check("forget shows Yes/No", a.forgetFor === "HomeNet" && fr.visible
            && win.find(fr, "forgetYes").visible && win.find(fr, "forgetNo").visible
            && win.find(win.find(fr, "forgetYes"), "label").text === "yes"
            && win.find(win.find(fr, "forgetNo"), "label").text === "no")
          wait(50)
          grab(frameA, "f")
          win.geom("f", frameA, "forgetYes")
          win.geom("f", frameA, "forgetNo")
          mouseClick(win.find(fr, "forgetNo"))
          win.check("No cancels", a.forgetFor === "" && last() !== "forget:HomeNet")
          mouseClick(win.find(win.find(a, "row_3"), "forgetButton"))
          mouseClick(win.find(win.find(a, "forgetRow"), "forgetYes"))
          win.check("Yes confirms", last() === "forget:Weak" && a.forgetFor === "")

          // Toolbar.
          var tools = [["tool_vpn", "vpn"], ["tool_scan", "scan"], ["tool_speed", "speedtest"], ["tool_ping", "ping"]]
          for (i = 0; i < tools.length; i++) {
            mouseClick(win.find(a, tools[i][0]))
            win.check(tools[i][0] + " click", last() === tools[i][1])
          }
          a.networksModel = win.rows.slice(0, 2)
          win.check("two rows: 2 nets", win.find(win.find(a, "tool_scan"), "label").text === "2 nets")
          a.networksModel = win.rows.slice(0, 1)
          win.check("one row: 1 net", win.find(win.find(a, "tool_scan"), "label").text === "1 net")
          a.networksModel = win.rows

          // Dismiss: middle click and Esc.
          var n1 = got.length
          mouseClick(win.find(a, "row_1"), 5, 5, Qt.MiddleButton)
          win.check("middle click dismisses", last() === "dismiss" && got.length === n1 + 1)
          keyClick(Qt.Key_Escape)
          win.check("Esc dismisses (no test-side refocus)", got.length === n1 + 2 && last() === "dismiss")

          serviceChecks()
          console.log("DONE networks " + win.failures + " fail")
          quitTimer.start()
        }

        // NetworkListService against fixture commands only.
        function serviceChecks() {
          var svc = NetworkListService
          var real = svc.commandFor
          var same = function(x, y) { return JSON.stringify(x) === JSON.stringify(y) }
          win.check("default list argv", same(real("list", {}), ["nmcli", "-t", "-e", "yes", "-f", "active,ssid,signal,security", "dev", "wifi", "list"]))
          win.check("event/poll list argv reads the cache", same(real("list", { rescan: "no" }),
            ["nmcli", "-t", "-e", "yes", "-f", "active,ssid,signal,security", "dev", "wifi", "list", "--rescan", "no"]))
          win.check("default saved argv", same(real("saved", {}), ["nmcli", "-t", "-e", "yes", "-f", "NAME,TYPE,AUTOCONNECT,DEVICE", "connection", "show"]))
          win.check("default device argv", same(real("device", {}), ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]))
          win.check("default connect argv (WifiPanel string)", same(real("connect", { name: "it's", password: "p'w" }),
            ["sh", "-c", "nmcli dev wifi connect 'it'\\''s' password 'p'\\''w' 2>&1"]))
          win.check("default connect argv without password", same(real("connect", { name: "Open", password: "" }),
            ["sh", "-c", "nmcli dev wifi connect 'Open' 2>&1"]))
          win.check("default disconnect argv", same(real("disconnect", { device: "wlp3s0" }), ["nmcli", "device", "disconnect", "wlp3s0"]))
          win.check("default forget argv", same(real("forget", { name: "Home" }), ["nmcli", "connection", "delete", "Home"]))
          win.check("default rescan argv", same(real("rescan", {}), ["nmcli", "dev", "wifi", "rescan"]))
          win.check("default notify argv", same(real("notify", { message: "Could not connect to X" }), ["notify-send", "-u", "low", "Networks", "Could not connect to X"]))
          win.check("default vpn argv", same(real("vpn", {}), ["nm-connection-editor"]))
          win.check("default speedtest argv", same(real("speedtest", {}), ["xdg-open", "https://www.speedtest.net"]))
          win.check("default ping argv", same(real("ping", {}), ["sh", "-c", "stdbuf -oL ping -c 10 -w 30 1.1.1.1 2>&1"]))

          var fx = Quickshell.env("NETWORKS_FIXTURES")
          var calls = []
          var pingFile = "ping.txt"
          function count(kind) { return calls.filter(function(c) { return c.kind === kind }).length }
          svc.scanPollInterval = 50
          svc.commandFor = function(kind, args) {
            calls.push({ kind: kind, args: args || {} })
            switch (kind) {
            case "list": return ["cat", fx + "/list.txt"]
            case "saved": return ["cat", fx + "/saved.txt"]
            case "device": return ["cat", fx + "/device.txt"]
            case "ping": return ["cat", fx + "/" + pingFile]
            case "forget": return args.name === "Locked" ? ["sh", "-c", "sleep 0.3; exit 1"] : ["true"]
            case "connect": return args.name === "Bad"
              ? ["sh", "-c", "echo 'Error: Connection activation failed.'; exit 4"]
              : ["sh", "-c", "echo 'Device wlp3s0 successfully activated'"]
            default: return ["true"]
            }
          }
          svc.refresh()
          svc.scan()
          NetworkStatusService.nmChanged()
          wait(300)
          win.check("inactive service stays idle (refresh, scan, NM event)", calls.length === 0 && !svc.scanning)
          svc.active = true
          tryVerify(function() { return svc.networks.length === 3 && svc.device === "wlp3s0" }, 3000)
          var lastList = function() { return calls.filter(function(c) { return c.kind === "list" }).pop() }
          win.check("open refresh keeps the default rescan", calls.filter(function(c) { return c.kind === "list" })[0].args.rescan === undefined)
          var n = svc.networks
          win.check("service merges rows", n.length === 3 && n[0].name === "HomeNet" && n[0].active && n[0].saved
            && n[1].name === "Cafe:Guest" && !n[1].saved && !n[1].secure && n[2].name === "Weak" && n[2].saved)
          win.check("service learns the wifi device", svc.device === "wlp3s0")

          var lists = count("list")
          NetworkStatusService.nmChanged()
          tryVerify(function() { return count("list") > lists }, 2000)
          win.check("NM change refreshes", count("list") > lists)
          win.check("NM change refresh does not rescan", lastList().args.rescan === "no")

          lists = count("list")
          svc.connect("Cafe:Guest", "")
          tryVerify(function() { return count("list") > lists }, 3000)
          var c = calls.filter(function(x) { return x.kind === "connect" })[0]
          win.check("connect goes through the seam", c && c.args.name === "Cafe:Guest" && c.args.password === "")
          win.check("connect success leaves no error and refreshes", svc.lastError === "" && count("notify") === 0)
          win.check("refresh after connect does not rescan", lastList().args.rescan === "no")

          svc.connect("Bad", "pw")
          tryVerify(function() { return svc.lastError !== "" }, 3000)
          var note = calls.filter(function(x) { return x.kind === "notify" })[0]
          win.check("connect failure sets lastError", svc.lastError === "Could not connect to Bad")
          win.check("connect failure notifies", note && note.args.message === "Could not connect to Bad")
          // A forget started while the connect runs must not rename the
          // connect failure; a second connect while running is ignored.
          var notes0 = count("notify"), connects0 = count("connect")
          svc.connect("Bad", "pw")
          svc.connect("Other", "")
          svc.forget("Weak")
          tryVerify(function() { return count("notify") > notes0 }, 3000)
          win.check("connect failure keeps its own name",
            calls.filter(function(x) { return x.kind === "notify" }).pop().args.message === "Could not connect to Bad")
          win.check("second connect while running is ignored", count("connect") === connects0 + 1)

          lists = count("list")
          svc.disconnect()
          tryVerify(function() { return count("list") > lists }, 3000)
          var d = calls.filter(function(x) { return x.kind === "disconnect" })[0]
          win.check("disconnect uses the wifi device", d && d.args.device === "wlp3s0")

          lists = count("list")
          svc.forget("Weak")
          tryVerify(function() { return count("list") > lists }, 3000)
          var f = calls.filter(function(x) { return x.kind === "forget" })[0]
          win.check("forget deletes the named connection", f && f.args.name === "Weak")
          var notes = count("notify")
          svc.forget("Locked")
          svc.forget("Weak")
          tryVerify(function() { return count("notify") > notes }, 3000)
          win.check("forget failure names the running forget, not the ignored one",
            calls.filter(function(x) { return x.kind === "notify" }).pop().args.message === "Could not forget Locked")

          svc.ping()
          svc.ping()
          win.check("ping ignores clicks while running", count("ping") === 1 && svc.pinging)
          tryVerify(function() { return !svc.pinging }, 3000)
          win.check("ping ends on the average", svc.pingText === "13ms")
          pingFile = "ping-unreachable.txt"
          svc.ping()
          tryVerify(function() { return !svc.pinging }, 3000)
          win.check("unreachable ping shows dc", svc.pingText === "dc")

          lists = count("list")
          var scanFrom = calls.length
          svc.scan()
          win.check("scan starts loading", svc.scanning && count("rescan") === 1)
          tryVerify(function() { return !svc.scanning }, 3000)
          win.check("scan polls the list 5 times", count("list") - lists >= 5)
          win.check("scan polls keep the default rescan", calls.slice(scanFrom).filter(function(c) {
            return c.kind === "list" && c.args.rescan === undefined }).length >= 5)

          svc.scan()
          svc.active = false
          win.check("inactive stops scanning and polling", !svc.scanning && !svc.pollRunning)
          lists = count("list")
          wait(400)
          win.check("no list polls while inactive", count("list") === lists)
          svc.scan()
          win.check("scan ignored while inactive", !svc.scanning)
          svc.commandFor = real

          // SystemMetricsService runs while either the sidebar or the window wants it.
          var m = SystemMetricsService
          win.check("metrics idle with no consumer", !m.active)
          m.sidebarActive = true
          m.networksActive = true
          m.networksActive = false
          win.check("closing the window keeps the sidebar's metrics", m.active)
          m.networksActive = true
          m.sidebarActive = false
          win.check("closing the sidebar keeps the window's metrics", m.active)
          m.networksActive = false
          win.check("metrics stop when both close", !m.active)
        }
      }
    }
  }
}
