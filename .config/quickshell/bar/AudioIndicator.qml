import QtQuick
import QtQml
import Quickshell
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: Config.nothingEvolution ? Colors.styleAccent : (Config.nothingDesign ? Colors.fgSurface : Colors.primary)
  accessibleName: "Audio"
  tooltipText: "Audio volume"

  readonly property real volume: AudioService.volume
  readonly property bool muted: AudioService.muted

  Binding {
    target: AudioService
    property: "indicatorActive"
    value: root.visible
  }

  iconLabel: {
    if (root.muted) return "volume_off"
    if (root.volume <= 0) return "volume_mute"
    return "volume_up"
  }
  labelText: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
  // Opening the popup does not recolor the indicator. Ghost treats mute as
  // caution rather than a failure; other styles keep their error signal.
  iconColor: root.muted
    ? (Config.ghostTheme ? Colors.warning : Colors.error)
    : (Config.liquidGlassTheme ? Colors.barForeground
      : (Config.ghostTheme && !root.active ? Colors.fgSurfaceVariant : root.accentColor))
  labelColor: root.muted
    ? (Config.ghostTheme ? Colors.warning : Colors.error)
    : (Config.liquidGlassTheme ? Colors.barForeground
      : (Config.ghostTheme && !root.active ? Colors.fgSurfaceVariant : root.accentColor))

  onWheel: function(wheel) {
    var delta = wheel.angleDelta.y > 0 ? Config.volumeStep / 100 : -Config.volumeStep / 100
    AudioService.setVolume(root.volume + delta)
  }
}
