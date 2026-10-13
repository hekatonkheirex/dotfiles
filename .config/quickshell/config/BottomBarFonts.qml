pragma Singleton
import QtQml
import QtQuick
import Quickshell

// Four font files in ~/.local/share/fonts/icomoon share the family "icomoon",
// so the bar loads the remix set explicitly to get a unique family name. When
// the file is missing the plain family name is used (and may resolve to a
// different icon set; glyphs then show as tofu, which is the failure signal).
QtObject {
  id: root

  readonly property string path: Quickshell.env("HOME") + "/.local/share/fonts/icomoon/remix.ttf"
  readonly property FontLoader loader: FontLoader { source: "file://" + root.path }
  readonly property string family: root.loader.status === FontLoader.Ready ? root.loader.name : "icomoon"
  readonly property string materialFamily: Config.iconFont
}
