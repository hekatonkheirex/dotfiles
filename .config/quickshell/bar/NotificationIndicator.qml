import QtQuick
import "primitives"
import "../config"

StatusIndicator {
  id: root

  property int notificationCount: 0

  accentColor: Config.nothingEvolution ? Colors.styleAccent : (Config.nothingDesign ? Colors.fgSurface : Colors.primary)
  // Vertical Ghost signals history without making a closed popup look open.
  iconColor: Config.ghostTheme && !root.horizontal && root.hasNotifications
    ? Colors.styleAccent
    : (Config.liquidGlassTheme ? Colors.barForeground
      : (Config.ghostTheme && !root.active ? Colors.fgSurfaceVariant : root.accentColor))
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
