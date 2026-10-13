import QtQuick
import QtQuick.Layouts
import "../../config"

// The sidebar's cards in one column. No window: Sidebar.qml hosts it, and the
// render check loads it directly.
ColumnLayout {
  id: root
  property bool active: true

  signal searchSubmitted(string text)
  signal escaped()

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

  SearchField {
    id: search
    Layout.fillWidth: true
    onSubmitted: function(text) { root.searchSubmitted(text) }
    onEscaped: root.escaped()
  }

  // Focus the field when the sidebar opens (after the window has focus) and
  // clear it when it closes.
  Timer {
    id: focusTimer
    interval: 50
    onTriggered: search.focusField()
  }
  onActiveChanged: {
    if (root.active) focusTimer.restart()
    else search.clear()
  }
}
