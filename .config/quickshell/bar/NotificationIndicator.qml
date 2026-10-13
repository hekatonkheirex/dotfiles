import QtQuick
import "primitives"
import "../config"

StatusIndicator {
  id: root

  property int notificationCount: 0

  accentColor: (Colors.primary)

  iconColor: ((root.accentColor))
  iconFilled: root.active || root.hasNotifications
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
