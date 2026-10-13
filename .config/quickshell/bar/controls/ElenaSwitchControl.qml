import QtQuick
import "../../config"
import "."
import "../primitives"

SwitchBase {
  id: root

  property color activeColor: Colors.primary
  property color activeContentColor: Colors.fgPrimary
  property color checkmarkColor: activeColor
  property color surfaceContainerHigh: Colors.surfaceContainerHigh
  property color surfaceContainerHighest: Colors.surfaceContainerHighest
  property color outline: Colors.outline
  property color focusColor: Colors.primary
  readonly property color stateOverlay: root.pressed
    ? root.pressOverlay
    : (root.hovered || root.activeFocus ? root.hoverOverlay : Qt.rgba(0, 0, 0, 0))

  height: 40
  readonly property real trackWidth: Math.min(58, root.width)
  readonly property real trackX: (root.width - trackWidth) / 2

  readonly property real targetThumbSize: pressed ? 26 : 22
  readonly property real targetX: trackX + (checked ? trackWidth - targetThumbSize - 4 : 4)

  property real thumbSize: 22
  property real thumbX: 4

  Behavior on thumbSize {
    enabled: Config.spatialMotion && !root.reducedMotion
    SpringAnimation {
      spring: Config.motionSpatialSpring
      damping: Config.motionSpatialDamping
      mass: Config.motionSpatialMass
      epsilon: Config.motionSpatialEpsilon
    }
  }
  Behavior on thumbX {
    enabled: Config.spatialMotion && !root.reducedMotion
    SpringAnimation {
      spring: Config.motionSpatialSpring
      damping: Config.motionSpatialDamping
      mass: Config.motionSpatialMass
      epsilon: Config.motionSpatialEpsilon
    }
  }

  Component.onCompleted: {
    thumbSize = targetThumbSize
    thumbX = targetX
  }

  onTargetThumbSizeChanged: thumbSize = targetThumbSize
  onTargetXChanged: thumbX = targetX

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: height / 2 + 4
    color: root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    border.width: root.activeFocus ? 2 : 0
    border.color: root.focusColor
    visible: root.activeFocus
  }

  Rectangle {
    id: track
    x: root.trackX
    y: (root.height - 30) / 2
    width: root.trackWidth
    height: 30
    radius: 15
    ColorSpring {
      id: trackEffect
      animate: !root.reducedMotion && !Config.reducedMotion
      targetColor: root.enabled
        ? Qt.tint(root.checked ? root.activeColor : root.surfaceContainerHighest, root.stateOverlay)
        : root.surfaceContainerHighest
    }
    color: trackEffect.color
    opacity: root.enabled ? 1 : 0.55
  }

  Rectangle {
    id: knob
    x: root.thumbX
    y: parent.height / 2 - height / 2
    width: root.thumbSize
    height: root.thumbSize
    radius: width / 2
    ColorSpring {
      id: thumbEffect
      animate: !root.reducedMotion && !Config.reducedMotion
      targetColor: root.enabled
        ? Qt.tint(root.checked ? "#ffffff" : root.outline, root.stateOverlay)
        : root.outline
    }
    color: thumbEffect.color
  }
}
