import QtQuick
import QtQuick.Shapes
import "../../config"
import "../../config/BarForm.js" as BarForm

// Decorative signal line for the open space between bar groups. Two sine
// layers slide by exactly one period per loop, so the pattern never jumps.
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
    property int loopMs: 3200
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
      from: 0
      to: -layer.period
      duration: layer.loopMs
      loops: Animation.Infinite
      running: root.running && root.visible && !Config.reducedMotion
    }
  }

  Layer { period: 56; amp: 5; strokeAlpha: 0.85; loopMs: 3200 }
  Layer { period: 40; amp: 3; strokeAlpha: 0.45; loopMs: 2400 }
}
