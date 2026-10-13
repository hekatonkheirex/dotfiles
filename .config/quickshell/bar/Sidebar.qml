import QtQuick
import Quickshell
import "../config"
import "sidebar"

// Elena's left-edge status panel: an overlay (no reserved space) that joins
// the bar's single-open-popup model through shell.qml.
PopupBase {
  id: root

  surfaceWidth: 320

  signal searchSubmitted(string text)
  anchors.bottom: true
  margins.left: Config.spacingMedium
  margins.top: Config.barWidth + Config.spacingMedium
  margins.bottom: Config.spacingMedium

  // Own flag, not popupActive: the Media/Weather/Audio/Brightness popups bind
  // popupActive to their own visibility and would fight a second writer.
  Binding { target: MediaService; property: "sidebarActive"; value: root.visible }
  Binding { target: WeatherService; property: "sidebarActive"; value: root.visible }
  Binding { target: AudioService; property: "sidebarActive"; value: root.visible }
  Binding { target: BrightnessService; property: "sidebarActive"; value: root.visible }

  SidebarContent {
    anchors.fill: parent
    active: root.visible
    anchors.margins: Config.spacingMedium
    onSearchSubmitted: function(text) { root.searchSubmitted(text) }
    onEscaped: root.dismissed()
  }
}
