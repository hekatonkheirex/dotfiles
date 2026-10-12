import QtQuick
import QtQuick.Shapes
import "../../config"
import "../../config/BarForm.js" as BarForm

// Decorative signal line for the open space between bar groups, driven by the
// music. Two sine layers travel in opposite directions and cross; each swells
// with its own audio band (lowLevel, highLevel in 0..1). With no sound the
// line is flat and still. Layers slide by exactly one period per loop, so the
// pattern never jumps.
Item {
  id: root

  property color color: Colors.primary
  property bool running: true
  property real lowLevel: 0
  property real highLevel: 0
  readonly property bool live: root.running && root.visible && !Config.reducedMotion
  clip: true

  component Layer: Shape {
    id: layer
    property real period: 56
    property real amp: 5
    property real strokeAlpha: 0.85
    property int loopMs: 2200
    property int direction: 1
    property real level: 0
    readonly property real drawAmp: layer.amp * (root.live ? layer.level : 0)
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
        path: BarForm.wavePath(layer.period, layer.periods, layer.drawAmp, root.height / 2)
      }
    }

    NumberAnimation on x {
      from: layer.direction > 0 ? -layer.period : 0
      to: layer.direction > 0 ? 0 : -layer.period
      duration: layer.loopMs
      loops: Animation.Infinite
      running: root.live && layer.drawAmp > 0
    }
  }

  // Shapes measured from the reference capture: ~110 px wave moving right at
  // ~51 px/s, ~88 px wave moving left at ~44 px/s.
  Layer { period: 112; amp: 5; strokeAlpha: 0.85; loopMs: 2200; direction: 1; level: root.lowLevel }
  Layer { period: 88; amp: 3; strokeAlpha: 0.7; loopMs: 2000; direction: -1; level: root.highLevel }
}
