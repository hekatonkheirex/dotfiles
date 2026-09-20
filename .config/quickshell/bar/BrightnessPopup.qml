import QtQuick
import QtQml
import QtQuick.Layouts
import "../config"

PopupBase {
  id: root

  surfaceHeight: Math.min(contentColumn.implicitHeight + Config.spacingPage, 400)

  readonly property real pct: BrightnessService.pct

  Binding {
    target: BrightnessService
    property: "popupActive"
    value: root.visible
  }

  function setBrightness(value) { BrightnessService.setBrightness(value) }

  Column {
    id: contentColumn
    anchors {
      fill: parent
      margins: Config.popupPadding
    }
    spacing: Config.spacingLarge

    Text {
      text: "Brightness"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.typeHeadlineSmallSize
      font.weight: Config.typeStrongWeight
      font.letterSpacing: Config.typeHeadlineTracking
      lineHeight: Config.typeHeadlineSmallLineHeight
      lineHeightMode: Text.FixedHeight
    }

    PopupDivider {}

    Text {
      text: Math.round(root.pct) + "%"
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
      font.letterSpacing: Config.typeTitleTracking
      lineHeight: Config.typeTitleMediumLineHeight
      lineHeightMode: Text.FixedHeight
    }

    SliderControl {
      value: root.pct / 100
      activeColor: Colors.brightness
      surfaceContainerHigh: Colors.surfaceContainerHigh
      surfaceContainerHighest: Colors.surfaceContainerHighest
      outline: Colors.styleOutlineStrong
      focusColor: Colors.brightness
      motionDuration: Config.motionMedium
      reducedMotion: Config.reducedMotion
      accessibleName: "Brightness"
      accessibleDescription: "Adjust display brightness"
      onChanged: function(val) { root.setBrightness(val * 100) }
    }
  }
}
