import QtQuick
import "../../config"

// Small, decorative Material 3 Expressive shape primitive. The shape is
// sampled from a radial function so it can morph smoothly without adding a
// second graphics dependency to the shell.
Item {
  id: root

  property color fillColor: Colors.primaryContainer
  property string shape: "blob"
  property real morphProgress: 0.0
  property real targetMorphProgress: 1.0
  property real rotation: 0.0
  property real inset: 0.0
  property int sampleCount: 96
  property bool animateMorph: true

  function radiusFactor(angle) {
    if (root.shape === "softBurst") {
      return 0.89 + 0.11 * (0.5 + 0.5 * Math.cos(angle * 12))
    }
    if (root.shape === "clover") {
      return 0.86 + 0.14 * (0.5 + 0.5 * Math.cos(angle * 4))
    }
    if (root.shape === "circle") return 1.0

    // The default blob is intentionally restrained. It adds expression while
    // preserving the compact silhouettes used by shell controls.
    return 0.94
      + 0.035 * Math.sin(angle * 3 + 0.5)
      + 0.025 * Math.cos(angle * 5 - 0.8)
  }

  Component.onCompleted: root.morphProgress = root.targetMorphProgress
  onTargetMorphProgressChanged: root.morphProgress = root.targetMorphProgress
  onFillColorChanged: shapeCanvas.requestPaint()
  onShapeChanged: shapeCanvas.requestPaint()
  onMorphProgressChanged: shapeCanvas.requestPaint()
  onRotationChanged: shapeCanvas.requestPaint()
  onInsetChanged: shapeCanvas.requestPaint()
  onWidthChanged: shapeCanvas.requestPaint()
  onHeightChanged: shapeCanvas.requestPaint()

  Behavior on morphProgress {
    enabled: root.animateMorph && Config.expressiveMotion && !Config.reducedMotion

    SpringAnimation {
      spring: Config.motionSpatialSpring
      damping: Config.motionSpatialDamping
      mass: Config.motionSpatialMass
      epsilon: Config.motionSpatialEpsilon
    }
  }

  Canvas {
    id: shapeCanvas
    anchors.fill: parent
    antialiasing: true

    onPaint: {
      var context = getContext("2d")
      context.reset()

      var inset = Math.max(0, Math.min(root.inset, Math.min(width, height) / 2))
      var radiusX = Math.max(0, width / 2 - inset)
      var radiusY = Math.max(0, height / 2 - inset)
      if (radiusX <= 0 || radiusY <= 0) return

      var morph = Math.max(0, Math.min(1, root.morphProgress))
      var samples = Math.max(48, root.sampleCount)
      var centerX = width / 2
      var centerY = height / 2

      context.translate(centerX, centerY)
      context.rotate(root.rotation * Math.PI / 180)
      context.beginPath()

      for (var index = 0; index <= samples; index++) {
        var angle = (index / samples) * Math.PI * 2
        var factor = 1 + (root.radiusFactor(angle) - 1) * morph
        var x = Math.cos(angle) * radiusX * factor
        var y = Math.sin(angle) * radiusY * factor

        if (index === 0) context.moveTo(x, y)
        else context.lineTo(x, y)
      }

      context.closePath()
      context.fillStyle = root.fillColor
      context.fill()
    }
  }
}
