import QtQuick
import "primitives"
import "../config"

StatusIndicator {
  id: root

  iconLabel: "apps"
  accentColor: Config.nothingDesign ? Colors.fgSurface : Colors.primary
  inactiveBg: "transparent"
  borderOnHoverOnly: true
  accessibleName: "Applications launcher"
  tooltipText: "Applications launcher"
}
