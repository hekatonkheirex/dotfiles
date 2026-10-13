import QtQuick
import QtQuick.Layouts
import "../../config"

// The sidebar's cards in one column. No window: Sidebar.qml hosts it, and the
// render check loads it directly.
ColumnLayout {
  id: root
  property bool active: true

  spacing: Config.spacingMedium

  ClockCard { Layout.fillWidth: true; active: root.active }
  BatteryPill { Layout.fillWidth: true }
  WeatherCard { Layout.fillWidth: true }
  MediaCard { Layout.fillWidth: true }
  LevelBars {
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 160
  }
}
