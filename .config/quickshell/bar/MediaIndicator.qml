import QtQuick
import QtQml
import Quickshell
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: Config.nothingEvolution ? Colors.styleAccent : (Config.nothingDesign ? Colors.fgSurface : Colors.primary)
  accessibleName: "Media"
  tooltipText: root.mprisTitle ? (root.mprisTitle + (root.mprisArtist ? " - " + root.mprisArtist : "")) : "No media playing"

  readonly property string mprisStatus: MediaService.status
  readonly property string mprisTitle: MediaService.title
  readonly property string mprisArtist: MediaService.artist

  Binding {
    target: MediaService
    property: "indicatorActive"
    value: root.visible
  }

  iconLabel: root.mprisStatus === "Playing" ? "pause" : (root.mprisStatus === "Paused" ? "play_arrow" : "music_note")

  onWheel: function(wheel) {
    Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", wheel.angleDelta.y > 0 ? "prev" : "next"])
  }
}
