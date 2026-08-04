import QtQuick
import "primitives"
import "../config"

StatusIndicator {
  id: root

  iconLabel: "apps"
  accentColor: Colors.primary
  inactiveBg: "transparent"
  borderOnHoverOnly: true
  accessibleName: "Applications launcher"
  tooltipText: "Applications launcher"
}
