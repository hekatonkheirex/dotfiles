.pragma library

// config/PowerMenuModel.js: pure logic for the elena power menu and lock look.
var ACCENTS = [1, 3, 2, 6, 4, 5]
var IDS = ["poweroff", "reboot", "exit", "hibernate", "suspend", "lock"]
var BUTTON_ACCENTS = [1, 2, 4, 6, 3, 5]

function buttons() {
  return IDS.map(function (id, i) {
    return { id: id, label: id, accent: BUTTON_ACCENTS[i], confirm: i < 3 }
  })
}

function paletteAccents() { return ACCENTS.slice() }

function ringBorder(len, action) {
  if (action === "insert" && len >= 1) return { kind: "accent", n: ACCENTS[(len - 1) % 6] }
  if (action === "delete" && len >= 1)
    return (((len - 1) % 6) + 1) % 2 === 1 ? { kind: "muted", n: 8 } : { kind: "border", n: 0 }
  return { kind: "clear", n: 0 }
}

function maskInput(len) { return "*".repeat(Math.max(0, len)) }

function step(index, key, count) {
  var d = { left: -1, right: 1, up: -3, down: 3 }[key]
  if (d === undefined || count <= 0) return index
  return (((index + d) % count) + count) % count
}

function terminalText(selectedId) { return "$ " + (selectedId || "") }
