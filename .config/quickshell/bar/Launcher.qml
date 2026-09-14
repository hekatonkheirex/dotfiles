import QtQuick
import "primitives"
import "../config"

StatusIndicator {
  id: root

  // macOS uses the Apple mark for its menu-bar application menu. The
  // private-use glyph is provided by the locally installed SF Pro font.
  iconLabel: Config.liquidGlassTheme ? "\uf8ff" : "apps"
  iconFont: Config.liquidGlassTheme ? "SF Pro Display" : Config.iconFont
  iconVariableAxes: !Config.liquidGlassTheme
  accentColor: Config.nothingEvolution ? Colors.styleAccent : (Config.nothingDesign ? Colors.fgSurface : Colors.primary)
  inactiveBg: "transparent"
  borderOnHoverOnly: true
  accessibleName: Config.liquidGlassTheme ? "Apple menu" : "Applications launcher"
  tooltipText: Config.liquidGlassTheme ? "Apple menu" : "Applications launcher"
}
