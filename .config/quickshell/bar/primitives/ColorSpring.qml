import QtQuick
import "../../config"

// Qt springs interpolate numbers, so color effects spring each RGBA channel.
// Effects are critically damped: unlike spatial motion they must not overshoot.
Item {
  id: root
  visible: false
  property color targetColor: "transparent"
  property bool animate: Config.material3Theme && !Config.reducedMotion
  property bool ready: false
  readonly property color color: animate ? Qt.rgba(red, green, blue, alpha) : targetColor
  property real red: targetColor.r
  property real green: targetColor.g
  property real blue: targetColor.b
  property real alpha: targetColor.a
  Component.onCompleted: ready = true

  // Rebind after Behavior.enabled observes the preference. Never stop() the
  // springs: Qt rejects it on Behavior-owned animations (log spam).
  onAnimateChanged: if (!animate) Qt.callLater(root.snapChannels)

  function snapChannels() {
    if (animate) return
    red = Qt.binding(function() { return root.targetColor.r })
    green = Qt.binding(function() { return root.targetColor.g })
    blue = Qt.binding(function() { return root.targetColor.b })
    alpha = Qt.binding(function() { return root.targetColor.a })
  }

  Behavior on red {
    enabled: root.ready && root.animate
    SpringAnimation { id: redSpring; spring: Config.motionEffectsSpring; damping: 1; epsilon: 0.001 }
  }
  Behavior on green {
    enabled: root.ready && root.animate
    SpringAnimation { id: greenSpring; spring: Config.motionEffectsSpring; damping: 1; epsilon: 0.001 }
  }
  Behavior on blue {
    enabled: root.ready && root.animate
    SpringAnimation { id: blueSpring; spring: Config.motionEffectsSpring; damping: 1; epsilon: 0.001 }
  }
  Behavior on alpha {
    enabled: root.ready && root.animate
    SpringAnimation { id: alphaSpring; spring: Config.motionEffectsSpring; damping: 1; epsilon: 0.001 }
  }
}
