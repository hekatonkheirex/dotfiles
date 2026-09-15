import QtQuick
import "primitives"
import "../config"

StatusIndicator {
  id: root

  // Liquid Glass resolves this launcher mark through the symbolic icon theme;
  // the other styles keep their existing Material label.
  iconLabel: "apps"
  accentColor: Config.nothingEvolution ? Colors.styleAccent : (Config.nothingDesign ? Colors.fgSurface : Colors.primary)
  inactiveBg: "transparent"
  borderOnHoverOnly: true
  accessibleName: Config.liquidGlassTheme ? "Apple menu" : "Applications launcher"
  tooltipText: Config.liquidGlassTheme ? "Apple menu" : "Applications launcher"
}
