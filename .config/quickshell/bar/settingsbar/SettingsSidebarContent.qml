import QtQuick
import Quickshell
import Quickshell.Io
import "../settings"
import "../sidebar"
import "../../config"
import "../../config/SidebarPages.js" as SidebarPages

// Body of the right sidebar: one Settings page at a time over the same page
// dots as the left sidebar. The page files read `root.compactLayout`,
// `root.currentTab`, `root.caffeineOn`, `root.resetAppearance()` and
// `root.visible` from this item. Ctrl+PageUp/PageDown step pages, Esc closes.
Item {
  id: host
  objectName: "settingsContent"
  property bool active: false
  readonly property int pageCount: 6
  property int currentPage: Math.max(0, Math.min(host.pageCount - 1, Settings.lastSettingsTab))
  // Page order: General, Appearance, Display & Input, Bluetooth, Lock & Power, Notifications.
  readonly property int currentTab: host.currentPage
  readonly property bool compactLayout: true
  property bool caffeineOn: false
  signal escaped()
  signal resetAppearance()

  function showPage(n) {
    var p = Math.max(0, Math.min(host.pageCount - 1, Math.floor(n)))
    host.currentPage = p
    Settings.lastSettingsTab = p
  }

  focus: true
  Timer { id: focusTimer; interval: 50; onTriggered: host.forceActiveFocus() }
  onActiveChanged: {
    if (host.active) { focusTimer.restart(); idleCheck.running = true } else focusTimer.stop()
  }

  Keys.onPressed: function(event) {
    if ((event.modifiers & Qt.ControlModifier)
        && (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown)) {
      host.showPage(SidebarPages.stepPage(host.currentPage, event.key === Qt.Key_PageUp ? -1 : 1, host.pageCount))
      event.accepted = true
    } else if (event.key === Qt.Key_Escape) {
      host.escaped(); event.accepted = true
    }
  }

  Process {
    id: idleCheck
    command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh", "status"]
    stdout: StdioCollector {
      onStreamFinished: host.caffeineOn = text.trim() !== "active"
    }
  }

  Item {
    id: pages
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: indicators.top
    anchors.margins: Config.dp(14)
    clip: true

    Loader {
      id: pageLoader
      anchors.fill: parent
      active: host.active
      sourceComponent: {
        switch (host.currentPage) {
          case 1: return appearancePage
          case 2: return displayInputPage
          case 3: return bluetoothPage
          case 4: return lockPage
          case 5: return notificationsPage
          default: return generalPage
        }
      }
    }
    Component { id: generalPage; GeneralTab { root: host } }
    Component { id: appearancePage; AppearanceTab { root: host } }
    Component { id: displayInputPage; DisplayInputTab { root: host } }
    Component { id: bluetoothPage; BluetoothTab { root: host } }
    Component { id: lockPage; LockMediaTab { root: host } }
    Component { id: notificationsPage; NotificationsTab { root: host } }
  }

  PageIndicators {
    id: indicators
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Config.dp(24)
    anchors.left: parent.left
    anchors.right: parent.right
    currentPage: host.currentPage
    count: host.pageCount
    onPageSelected: function(p) { host.showPage(p) }
    onPageStepped: function(d) { host.showPage(SidebarPages.stepPage(host.currentPage, d, host.pageCount)) }
  }
}
