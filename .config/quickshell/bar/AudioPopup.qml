import QtQuick
import QtQml
import QtQuick.Layouts
import "../config"

PopupBase {
  id: root

  surfaceHeight: Math.min(contentColumn.implicitHeight + Config.spacingPage, 400)

  readonly property real volume: AudioService.volume
  readonly property bool muted: AudioService.muted
  readonly property real micVolume: AudioService.micVolume
  readonly property bool micMuted: AudioService.micMuted

  Binding {
    target: AudioService
    property: "popupActive"
    value: root.visible
  }

  function setVolume(value) { AudioService.setVolume(value) }
  function toggleMute() { AudioService.toggleMute() }
  function setMicVolume(value) { AudioService.setMicVolume(value) }
  function toggleMicMute() { AudioService.toggleMicMute() }
  onVisibleChanged: {
    if (!visible) {
      outputSlider.clearFocus()
      microphoneSlider.clearFocus()
    }
  }

  Column {
    id: contentColumn
    anchors {
      fill: parent
      margins: Config.popupPadding
    }
    spacing: Config.spacingLarge

    Item {
      width: parent.width
      height: 32

      Text {
        text: "Volume"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeHeadlineSmallSize
        font.weight: Config.typeStrongWeight
        font.letterSpacing: Config.typeHeadlineTracking
        lineHeight: Config.typeHeadlineSmallLineHeight
        lineHeightMode: Text.FixedHeight
        anchors.verticalCenter: parent.verticalCenter
      }

      SwitchControl {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: !root.muted
        activeColor: Colors.primary
        surfaceContainerHigh: Colors.surfaceContainerHigh
        surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.styleOutlineStrong
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Volume enabled"
        onToggled: root.toggleMute()
      }
    }

    PopupDivider {}

    Text {
      text: muted ? "Muted" : Math.round(volume * 100) + "%"
      color: muted ? (Colors.error) : (Colors.fgSurfaceVariant)
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
      font.letterSpacing: Config.typeTitleTracking
      lineHeight: Config.typeTitleMediumLineHeight
      lineHeightMode: Text.FixedHeight
    }

      SliderControl {
      id: outputSlider
      value: root.volume
      muted: root.muted
      activeColor: Colors.primary
      surfaceContainerHigh: Colors.surfaceContainerHigh
      surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.styleOutlineStrong
        focusColor: Colors.primary
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Volume"
        accessibleDescription: "Adjust output volume"
        onChanged: function(val) { root.setVolume(val) }
    }

    PopupDivider {}

    Item {
      width: parent.width
      height: 32

      Text {
        text: "Microphone"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeHeadlineSmallSize
        font.weight: Config.typeStrongWeight
        font.letterSpacing: Config.typeHeadlineTracking
        lineHeight: Config.typeHeadlineSmallLineHeight
        lineHeightMode: Text.FixedHeight
        anchors.verticalCenter: parent.verticalCenter
      }

      SwitchControl {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: !root.micMuted
        activeColor: Colors.primary
        surfaceContainerHigh: Colors.surfaceContainerHigh
        surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.styleOutlineStrong
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Microphone enabled"
        onToggled: root.toggleMicMute()
      }
    }

    Text {
      text: micMuted ? "Muted" : Math.round(micVolume * 100) + "%"
      color: micMuted ? (Colors.error) : (Colors.fgSurfaceVariant)
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
      font.letterSpacing: Config.typeTitleTracking
      lineHeight: Config.typeTitleMediumLineHeight
      lineHeightMode: Text.FixedHeight
    }

      SliderControl {
      id: microphoneSlider
      value: root.micVolume
      muted: root.micMuted
      activeColor: Colors.primary
      surfaceContainerHigh: Colors.surfaceContainerHigh
      surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.styleOutlineStrong
        focusColor: Colors.primary
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Microphone volume"
        accessibleDescription: "Adjust microphone volume"
        onChanged: function(val) { root.setMicVolume(val) }
    }
  }
}
