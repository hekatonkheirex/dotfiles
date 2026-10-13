.pragma library

// Verbatim port of window_information in
// config/eww/scripts/daemons/sway-dock.py (github.com/elenapan/dotfiles,
// master 2025-09-07): app id -> icomoon glyph + her color index (1..10).
// Keys are matched case-insensitively (niri app_id spelling varies).
var table = {
  "firefox": { symbol: "\ueb84", color: 3 },
  "kitty": { symbol: "\ueef5", color: 5 },
  "htop": { symbol: "\ue900", color: 2 },
  "btop": { symbol: "\ue900", color: 2 },
  "Sxiv": { symbol: "\uec5a", color: 1 },
  "Nsxiv": { symbol: "\uec5a", color: 1 },
  "nemo": { symbol: "\ueb99", color: 3 },
  "chrome-discordapp.com__channels_@me-Default": { symbol: "\uea0c", color: 4 },
  "chrome-chatgpt.com__-Default": { symbol: "\uecee", color: 2 },
  "lutris": { symbol: "\uec1a", color: 6 },
  "net.lutris.Lutris": { symbol: "\uec1a", color: 6 },
  "editor": { symbol: "\ueb4b", color: 5 },
  "scratchpad": { symbol: "\ueaf3", color: 1 },
  "scratchpad_input": { symbol: "\ueb39", color: 3 },
  "gucharmap": { symbol: "\uebca", color: 2 },
  "steam": { symbol: "\uef96", color: 2 },
  "mpv": { symbol: "\ued83", color: 6 },
  "chromium-browser": { symbol: "\uea3c", color: 4 },
  "org.chromium.Chromium": { symbol: "\uea3c", color: 4 },
  "org.pwmt.zathura": { symbol: "\ueb4f", color: 3 },
  "Emacs": { symbol: "\uea40", color: 2 },
  "org": { symbol: "\uea40", color: 2 },
  "explorer.exe": { symbol: "\uef94", color: 4 },
  "appimagekit_3a48058ef277d45ae2228089429c0259-Telegram_Desktop": { symbol: "\ued28", color: 4 },
  "org.telegram.desktop": { symbol: "\ued28", color: 4 },
  "pavucontrol": { symbol: "\uef6d", color: 4 },
  "org.pulseaudio.pavucontrol": { symbol: "\uef6d", color: 4 },
  "chrome-open.spotify.com__-Default": { symbol: "\ued22", color: 2 },
  "Wine": { symbol: "\uebfa", color: 1 },
  "chrome-mail.proton.me__-Default": { symbol: "\uecb4", color: 6 },
  "Gimp": { symbol: "\ued52", color: 4 },
  "gimp": { symbol: "\ued52", color: 4 },
  "org.inkscape.Inkscape": { symbol: "\uec6b", color: 2 },
  "deluge": { symbol: "\uec4c", color: 1 },
  // her ___default___ glyph (U+E421) is not in remix.ttf: Material Symbols
  // supplies an equivalent window glyph instead.
  "___default___": { symbol: "web_asset", color: 10, material: true }
}

var lower = {}
for (var k in table) lower[k.toLowerCase()] = table[k]

// Her color index 1..10 onto the six accent slots (7..10 wrap onto 1..4).
function slotOf(color) { return ((color - 1) % 6) + 1 }

function symbolFor(appId) {
  var key = appId === undefined || appId === null ? "" : String(appId).toLowerCase()
  var entry = lower[key] || lower["___default___"]
  return { symbol: entry.symbol, font: entry.material ? "material" : "icomoon", slot: slotOf(entry.color) }
}
