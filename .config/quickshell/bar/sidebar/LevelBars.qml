import QtQuick
import "../../config"

Card {
  id: root

  implicitHeight: 200

  Row {
    anchors.centerIn: parent
    spacing: Config.spacingLarge * 1.5

    LevelBar {
      height: root.height - Config.spacingLarge * 2
      value: AudioService.volume
      muted: AudioService.muted
      accent: Colors.primary
      iconLabel: AudioService.muted ? "volume_off" : "volume_up"
      accessibleName: "Volume"
      onMoved: function(v) { AudioService.setVolume(v) }
      onIconClicked: AudioService.toggleMute()
    }
    LevelBar {
      height: root.height - Config.spacingLarge * 2
      value: AudioService.micVolume
      muted: AudioService.micMuted
      accent: Colors.secondary
      iconLabel: AudioService.micMuted ? "mic_off" : "mic"
      accessibleName: "Microphone"
      onMoved: function(v) { AudioService.setMicVolume(v) }
      onIconClicked: AudioService.toggleMicMute()
    }
    LevelBar {
      height: root.height - Config.spacingLarge * 2
      value: BrightnessService.pct / 100
      accent: Colors.tertiary
      iconLabel: "brightness_medium"
      accessibleName: "Brightness"
      onMoved: function(v) { BrightnessService.setBrightness(v * 100) }
    }
  }
}
