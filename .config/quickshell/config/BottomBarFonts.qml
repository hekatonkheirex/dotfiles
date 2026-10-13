pragma Singleton
import QtQml

// Four font files in ~/.local/share/fonts/icomoon share the family "icomoon", so
// a family name cannot pick the remix set. The fontconfig scan rule
// ~/.config/fontconfig/conf.d/61-elena-icons.conf (tracked in the dotfiles repo)
// renames remix.ttf to "ElenaIcons". Without that rule the glyphs render as
// tofu, and scripts/bar-font-check.sh fails.
QtObject {
  readonly property string family: "ElenaIcons"
  readonly property string materialFamily: Config.iconFont
}
