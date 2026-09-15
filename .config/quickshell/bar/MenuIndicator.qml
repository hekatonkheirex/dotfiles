import QtQuick
import "primitives"
import "../config"

StatusIndicator {
  id: root

  iconLabel: "power_settings_new"
  accentColor: Config.nothingEvolution ? Colors.styleAccent : (Config.nothingDesign ? Colors.fgSurface : Colors.primary)
  accessibleName: "Quick Settings"
  tooltipText: "Quick Settings"
}
