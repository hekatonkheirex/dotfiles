.pragma library

// Pure pactl parsers for the microphone tab (her microphone.sh).

// `pactl get-source-mute`: true muted, false live, null when unreadable.
function parseMute(text) {
  var m = /Mute:\s*(yes|no)/i.exec(String(text))
  return m ? m[1].toLowerCase() === "yes" : null
}

// One `pactl subscribe` line: does it concern a source (not a source-output)?
function isSourceEvent(line) {
  return /\bon source #\d+/.test(String(line))
}

// `pactl list sources` text: the Description of the source called `name`.
function parseDescription(text, name) {
  if (!name) return ""
  var lines = String(text).split(/\r?\n/)
  var inBlock = false
  for (var i = 0; i < lines.length; i++) {
    var t = lines[i].trim()
    if (t.indexOf("Name:") === 0) inBlock = t.slice(5).trim() === name
    else if (inBlock && t.indexOf("Description:") === 0) return t.slice(12).trim()
  }
  return ""
}

// Tab look: live is x1 at full opacity, muted x8 at 0.4 (her scss).
function look(muted) {
  return { slot: muted ? 8 : 1, opacity: muted ? 0.4 : 1.0 }
}
