import QtQuick
import "primitives"
import "../config"

StatusIndicator {
  id: root

  iconLabel: "settings"
  accentColor: Config.nothingDesign ? Colors.fgSurface : Colors.primary
  accessibleName: "Power Options"
  tooltipText: "Power Options"
}
