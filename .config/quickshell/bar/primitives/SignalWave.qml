import QtQuick
import QtQuick.Shapes
import "../../config"
import "../../config/BarForm.js" as BarForm

// Decorative signal line for the open space between bar groups. Two sine
// layers slide by exactly one period per loop, so the pattern never jumps.
// They travel in opposite directions, so the strands cross and beat.
Item {
  id: root

  property color color: Colors.primary
  property bool running: true
  clip: true

  component Layer: Shape {
    id: layer
    property real period: 56
    property real amp: 5
    property real strokeAlpha: 0.85
    property int loopMs: 2200
    property int direction: 1
    readonly property int periods: Math.ceil(root.width / layer.period) + 1

    y: 0
    width: layer.periods * layer.period
    height: root.height
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: Qt.rgba(root.color.r, root.color.g, root.color.b, layer.strokeAlpha)
      strokeWidth: 1
      fillColor: "transparent"
      PathSvg {
        path: BarForm.wavePath(layer.period, layer.periods, layer.amp, root.height / 2)
      }
    }

    NumberAnimation on x {
      from: layer.direction > 0 ? -layer.period : 0
      to: layer.direction > 0 ? 0 : -layer.period
      duration: layer.loopMs
      loops: Animation.Infinite
      running: root.running && root.visible && !Config.reducedMotion
    }
  }

  // Measured from the reference capture: ~110 px wave moving right at
  // ~51 px/s, ~88 px wave moving left at ~44 px/s.
  Layer { period: 112; amp: 4; strokeAlpha: 0.85; loopMs: 2200; direction: 1 }
  Layer { period: 88; amp: 2.5; strokeAlpha: 0.7; loopMs: 2000; direction: -1 }
}
