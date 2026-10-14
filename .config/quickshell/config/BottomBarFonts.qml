pragma Singleton
import QtQml

// The four font files in ~/.local/share/fonts/icomoon share the family "icomoon",
// and codepoints repeat across them. Pango falls back per glyph in the order
// icomoon-feather.ttf, remix.ttf, iconic.ttf. The fontconfig scan rules in
// ~/.config/fontconfig/conf.d/61-elena-icons.conf (tracked in the dotfiles repo)
// name those files ElenaIcons1..3 and make a request for ElenaIcons1 fall back
// to 2 then 3, so a Text only sets font.family to `family` (Qt 6.12 has no
// Text font.families). `families` documents that order and is checked by
// scripts/bar-font-check.sh. Without the rules the glyphs render as tofu; scripts/bar-font-check.sh fails.
QtObject {
  readonly property string family: "ElenaIcons1"
  readonly property var families: ["ElenaIcons1", "ElenaIcons2", "ElenaIcons3"]
  readonly property string materialFamily: Config.iconFont
  // Her text font for the value pills (clock, date). The file names the
  // family "Kyok medium" (lowercase m), so match without case; fall back to
  // the shell font when it is not installed.
  function pick(name) {
    var want = name.toLowerCase()
    var all = Qt.fontFamilies()
    for (var i = 0; i < all.length; i++) if (all[i].toLowerCase() === want) return all[i]
    return Config.fontFamily
  }
  readonly property string clockFamily: pick("Baro Plain")
  readonly property string clockMinutesFamily: pick("Baro LineThree")
  readonly property string textFamily: pick("Kyok medium")
}
