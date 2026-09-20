import QtQuick
import QtQml
import Quickshell
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: Config.nothingEvolution ? Colors.styleAccent : (Config.nothingDesign ? Colors.fgSurface : Colors.brightness)
  accessibleName: "Brightness"
  tooltipText: "Brightness"

  readonly property real pct: BrightnessService.pct
  readonly property bool initialized: BrightnessService.initialized

  Binding {
    target: BrightnessService
    property: "indicatorActive"
    value: root.visible
  }

  iconLabel: {
    if (!root.initialized) return "brightness_medium"
    if (root.pct <= 10) return "brightness_empty"
    if (root.pct <= 40) return "brightness_low"
    if (root.pct <= 70) return "brightness_medium"
    return "brightness_high"
  }
  labelText: root.initialized ? Math.round(root.pct) + "%" : ""

  onWheel: function(wheel) {
    var delta = wheel.angleDelta.y > 0 ? Config.brightnessStep : -Config.brightnessStep
    BrightnessService.setBrightness(root.pct + delta)
  }
}
