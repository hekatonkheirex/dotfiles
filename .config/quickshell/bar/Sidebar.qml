import QtQuick
import Quickshell
import "../config"
import "sidebar"

// Elena's left-edge status panel: an overlay (no reserved space) that joins
// the bar's single-open-popup model through shell.qml.
PopupBase {
  id: root

  surfaceWidth: 320

  readonly property int currentPage: content.currentPage
  readonly property int pageCount: 2
  // Pages are 0 (Status) and 1 (Dashboard); R2 adds the media page.
  function showPage(n) { content.currentPage = Math.max(0, Math.min(root.pageCount - 1, Math.floor(n))) }

  signal searchSubmitted(string text)
  signal settingsRequested(int tab)
  anchors.bottom: true
  margins.left: Config.spacingMedium
  margins.top: Config.barWidth + Config.spacingMedium
  // Clear the bottom bar so its page buttons stay clickable while open.
  margins.bottom: Config.spacingMedium + Config.bottomBarHeight

  // Own flag, not popupActive: the Media/Weather/Audio/Brightness popups bind
  // popupActive to their own visibility and would fight a second writer.
  Binding { target: MediaService; property: "sidebarActive"; value: content.statusActive }
  Binding { target: WeatherService; property: "sidebarActive"; value: content.statusActive }
  Binding { target: AudioService; property: "sidebarActive"; value: content.statusActive }
  Binding { target: BrightnessService; property: "sidebarActive"; value: content.statusActive }

  SidebarContent {
    id: content
    anchors.fill: parent
    active: root.visible
    anchors.margins: Config.spacingMedium
    onSearchSubmitted: function(text) { root.searchSubmitted(text) }
    onEscaped: root.dismissed()
    onSettingsRequested: function(tab) { root.settingsRequested(tab) }
  }
}
