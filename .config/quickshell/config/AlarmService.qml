pragma Singleton
import QtQml
import Quickshell
import Quickshell.Io
import "Alarms.js" as Alarms

// Her alarms, kept in a file (~/.local/state/quickshell/alarms.json) instead
// of sleeping processes, so a shell restart keeps them. One timer re-arms to
// the earliest deadline, never beyond 30 s, and compares against the clock on
// every tick, so a suspend or a late wake still rings (Alarms.nextDelay).
// Sound and notification argv come from `commandFor`, the clock from `nowFn`:
// the render/integration stage swaps both and never plays or posts anything.
QtObject {
  id: root

  property var alarms: []           // sorted, [{id, at, label}]
  readonly property int count: root.alarms.length
  property bool loaded: false
  property string lastRung: ""      // label of the last alarm that rang

  property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
  readonly property string stateFile: root.stateDir + "/alarms.json"
  property var nowFn: function() { return Date.now() }
  property string soundFile: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

  property var commandFor: function(kind, args) {
    switch (kind) {
    case "mkdir": return ["mkdir", "-p", root.stateDir]
    case "sound": return ["pw-play", root.soundFile]
    case "ring": return ["notify-send", "-u", "critical", "-t", "0", "-a", "quickshell-alarm", "Alarm", args.body]
    case "notice": return ["notify-send", "-u", "low", "-t", "2000", "-a", "quickshell-alarm", "Alarm", args.body]
    }
    return ["true"]
  }

  signal rang(var alarm, bool missed)

  function add(at, label) {
    var list = root.alarms.slice()
    list.push({ id: Alarms.nextId(list), at: at, label: label })
    root.setAlarms(list)
    Quickshell.execDetached(root.commandFor("notice", { body: "Will ring at " + Alarms.formatHM(at) }))
  }

  // index: position in the sorted list, as shown by the window.
  function removeAt(index) {
    if (index < 0 || index >= root.alarms.length) return false
    var list = root.alarms.slice()
    list.splice(index, 1)
    root.setAlarms(list)
    return true
  }

  function setAlarms(list) {
    root.alarms = Alarms.sortAlarms(list)
    if (root.loaded) file.setText(Alarms.serialize(root.alarms))
    timer.restart()
  }

  // Rings everything due. `atStart`: the shell was not running at the time.
  function tick(atStart) {
    var now = root.nowFn()
    var ready = Alarms.due(root.alarms, now)
    if (ready.length === 0) { timer.restart(); return }
    var keep = root.alarms.filter(function(a) { return a.at > now })
    root.setAlarms(keep)
    for (var i = 0; i < ready.length; i++) {
      var late = atStart || now - ready[i].at > Alarms.MISSED_AFTER_MS
      root.ring(ready[i], late)
    }
  }

  function ring(alarm, missed) {
    root.lastRung = alarm.label
    var body = missed ? alarm.label + " (missed, was " + Alarms.formatHM(alarm.at) + ")" : alarm.label
    Quickshell.execDetached(root.commandFor("sound", {}))
    Quickshell.execDetached(root.commandFor("ring", { body: body }))
    root.rang(alarm, missed)
  }

  property Timer timer: Timer {
    repeat: false
    interval: 1000
    onTriggered: root.tick(false)   // tick and setAlarms re-arm
    function restart() {
      var d = Alarms.nextDelay(root.alarms, root.nowFn())
      timer.stop()
      if (d > 0) { timer.interval = d; timer.start() }
    }
  }

  property Process mkdirProc: Process {
    running: true
    command: root.commandFor("mkdir", {})
    onExited: { file.path = root.stateFile; file.reload() }
  }

  property FileView file: FileView {
    printErrors: false
    onLoaded: {
      var disk = Alarms.parse(file.text())
      // Anything added before the first read finished is kept; a reload
      // (tests) takes the file as is.
      var pending = root.loaded ? [] : root.alarms
      root.loaded = true
      var all = disk.concat(pending.map(function(a) { return { id: 0, at: a.at, label: a.label } }))
      root.alarms = Alarms.parse(JSON.stringify(all))
      root.tick(true)
      if (pending.length > 0) file.setText(Alarms.serialize(root.alarms))
      timer.restart()
    }
    onLoadFailed: function(error) {
      // Missing file is the normal first run; a failing read stays in memory only for this run.
      root.loaded = true
      timer.restart()
    }
  }
}
