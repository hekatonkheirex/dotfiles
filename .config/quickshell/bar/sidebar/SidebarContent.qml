import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import "../../config"
import "../primitives"

// Shared page navigation and search remain outside the scrolling page bodies.
ColumnLayout {
  id: root
  property bool active: true
  property int currentPage: 0
  property alias searchText: search.text
  readonly property bool statusActive: active && currentPage === 0
  readonly property bool dashboardActive: active && currentPage === 1
  readonly property bool statisticsPolling: dashboard.statisticsPolling

  signal searchSubmitted(string text)
  signal escaped()
  signal settingsRequested(int tab)

  Keys.onPressed: function(event) {
    if (!(event.modifiers & Qt.ControlModifier)) return
    if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
      root.currentPage = event.key === Qt.Key_PageUp ? 0 : 1
      event.accepted = true
    }
  }

  spacing: Config.spacingMedium

  RowLayout {
    Layout.fillWidth: true
    spacing: Config.spacingSmall
    Repeater {
      model: ["Status", "Dashboard"]
      ActionButton {
        required property int index
        required property string modelData
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        labelText: modelData
        checkable: true
        selected: root.currentPage === index
        accessibleName: modelData + " sidebar page"
        accessibleDescription: selected ? "Current page" : "Switch to this page"
        onActivated: root.currentPage = index
      }
    }
  }

  StackLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 0
    currentIndex: root.currentPage

    Flickable {
      id: statusView
      enabled: root.currentPage === 0
      clip: true
      contentWidth: width
      contentHeight: statusColumn.height
      boundsBehavior: Flickable.StopAtBounds
      Controls.ScrollBar.vertical: Controls.ScrollBar {}
      ColumnLayout {
        id: statusColumn
        width: statusView.width
        height: Math.max(implicitHeight, statusView.height)
        spacing: Config.spacingMedium
        ClockCard { Layout.fillWidth: true; active: root.statusActive }
        BatteryPill { Layout.fillWidth: true }
        WeatherCard { Layout.fillWidth: true }
        MediaCard { Layout.fillWidth: true }
        LevelBars {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.minimumHeight: 160
          Layout.preferredHeight: 160
        }
      }
    }

    Flickable {
      id: dashboardView
      enabled: root.currentPage === 1
      clip: true
      contentWidth: width
      contentHeight: dashboard.height
      boundsBehavior: Flickable.StopAtBounds
      Controls.ScrollBar.vertical: Controls.ScrollBar {}
      DashboardPage {
        id: dashboard
        width: dashboardView.width
        height: Math.max(implicitHeight, dashboardView.height)
        active: root.dashboardActive
        onSettingsRequested: function(tab) { root.settingsRequested(tab) }
      }
    }
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
    else {
      focusTimer.stop()
      search.clear()
    }
  }
}
