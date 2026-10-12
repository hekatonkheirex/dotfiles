import QtQuick
import QtQuick.Shapes
import "../../config"
import "../../config/BarForm.js" as BarForm

// Decorative signal line for the open space between bar groups. Two sine
// layers travel in opposite directions and cross while the amplitude breathes
// on a 2.82 s cycle: a linear rise, a quick collapse, a short rest. The cycle
// runs only while `active` (sound is playing); otherwise the line is flat and
// still. Layers slide by exactly one period per loop, so the pattern never
// jumps.
Item {
  id: root

  property color color: Colors.primary
  property bool running: true
  property bool active: false
  readonly property bool live: root.running && root.visible && !Config.reducedMotion
  readonly property bool playing: root.live && root.active
  // 0..1 breathing envelope, and a short fade so start and stop are not abrupt.
  property real breath: 0
  property real gate: root.playing ? 1 : 0
  clip: true

  Behavior on gate { NumberAnimation { duration: 250 } }

  SequentialAnimation on breath {
    loops: Animation.Infinite
    running: root.playing || root.gate > 0
    NumberAnimation { from: 0; to: 1; duration: 1760 }
    NumberAnimation { from: 1; to: 0; duration: 500; easing.type: Easing.InOutSine }
    PauseAnimation { duration: 560 }
  }

  component Layer: Shape {
    id: layer
    property real period: 56
    property real amp: 5
    // Share of the amplitude that stays at the bottom of the cycle.
    property real rest: 0
    property real strokeAlpha: 0.85
    property int loopMs: 2200
    property int direction: 1
    readonly property real drawAmp: layer.amp * (layer.rest + (1 - layer.rest) * root.breath) * root.gate
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

  // Measured from the reference capture: ~110 px wave moving right at
  // ~51 px/s, ~88 px wave moving left at ~44 px/s. The long wave never fully
  // calms (rest 0.12); the short one rests flat. Peak swing ~13-15 px.
  Layer { period: 112; amp: 6; rest: 0.12; strokeAlpha: 0.85; loopMs: 2200; direction: 1 }
  Layer { period: 88; amp: 4; strokeAlpha: 0.7; loopMs: 2000; direction: -1 }
}
