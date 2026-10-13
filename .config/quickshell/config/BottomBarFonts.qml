pragma Singleton
import QtQml
import QtQuick
import Quickshell

// Four font files in ~/.local/share/fonts/icomoon share the family "icomoon".
// The FontLoader registers remix.ttf with Qt, but its reported name is that same
// shared "icomoon", so Qt may still resolve glyphs from a different file of the
// family. scripts/bar-font-check.sh measures which file Qt really uses. When the
// file or HOME is missing, the plain family name is used and glyphs may show as
// tofu, which is the failure signal.
QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string path: root.home === "" ? "" : root.home + "/.local/share/fonts/icomoon/remix.ttf"
  readonly property FontLoader loader: FontLoader {
    source: root.path === "" ? "" : "file://" + encodeURI(root.path)
  }
  readonly property string family: root.loader.status === FontLoader.Ready ? root.loader.name : "icomoon"
  readonly property string materialFamily: Config.iconFont
}
