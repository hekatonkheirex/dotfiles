import QtQuick
import "primitives"
import "../config"

StatusIndicator {
  id: root

  property int notificationCount: 0

  accentColor: Config.nothingEvolution ? Colors.styleAccent : (Config.nothingDesign ? Colors.fgSurface : Colors.primary)
  inactiveBg: "transparent"
  borderOnHoverOnly: true
  accessibleName: "Notifications"
  tooltipText: "Notifications"
  accessibleDescription: root.hasNotifications
    ? root.notificationCount + " notifications"
    : "No notifications"

  readonly property bool hasNotifications: notificationCount > 0
  iconLabel: hasNotifications ? "notifications_active" : "notifications"
}
