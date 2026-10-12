import QtQuick
import "../../config"

// Shared Qt spring adaptation of M3's spatial/effects entrance grammar.
ParallelAnimation {
  id: root
  required property QtObject surfaceTarget
  required property QtObject scaleTarget
  required property QtObject translationTarget
  property real initialScale: Config.surfaceEntryScale
  property real initialOffset: Config.surfaceEntryOffset
  // Large desktop surfaces settle without a rebound; control springs remain expressive.
  property real spatialDamping: 1.0

  property Connections motionPreference: Connections {
    target: Config
    function onReducedMotionChanged() {
      if (!Config.reducedMotion) return
      root.stop()
      root.scaleTarget.xScale = 1
      root.scaleTarget.yScale = 1
      root.translationTarget.x = 0
      root.surfaceTarget.opacity = 1
    }
  }

  SpringAnimation {
    target: root.scaleTarget
    properties: "xScale,yScale"
    from: root.initialScale
    to: 1
    spring: Config.motionSpatialSpring
    damping: root.spatialDamping
    mass: Config.motionSpatialMass
    epsilon: 0.001
  }
  SpringAnimation {
    target: root.translationTarget
    property: "x"
    from: root.initialOffset
    to: 0
    spring: Config.motionSpatialSpring
    damping: root.spatialDamping
    mass: Config.motionSpatialMass
    epsilon: 0.1
  }
  SpringAnimation {
    target: root.surfaceTarget
    property: "opacity"
    from: 0
    to: 1
    spring: Config.motionEffectsSpring
    damping: 1
    epsilon: 0.001
  }
}
