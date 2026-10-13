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

  height: 48
  readonly property real materialTrackWidth: Math.min(52, root.width)
  readonly property real materialTrackX: (root.width - root.materialTrackWidth) / 2

  readonly property real targetThumbSize: pressed ? 28 : (checked ? 24 : 16)
  readonly property real targetX: root.materialTrackX + (checked
    ? (pressed ? root.materialTrackWidth - 28 - 2 : root.materialTrackWidth - 24 - 4)
    : (pressed ? 2 : 8))

  property real thumbSize: 16
  property real thumbX: 8

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
    x: root.materialTrackX
    y: (root.height - 32) / 2
    width: root.materialTrackWidth
    height: 32
    radius: height / 2
    ColorSpring {
      id: trackEffect
      animate: !root.reducedMotion && !Config.reducedMotion
      targetColor: root.enabled
        ? Qt.tint(root.checked ? root.activeColor : root.surfaceContainerHighest, root.stateOverlay)
        : root.surfaceContainerHighest
    }
    color: trackEffect.color
    border.width: root.checked || !root.enabled ? 0 : 2
    border.color: root.outline
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
        ? Qt.tint(root.checked ? root.activeContentColor : root.outline, root.stateOverlay)
        : root.outline
    }
    color: thumbEffect.color

    IconGlyph {
      anchors.centerIn: parent
      iconLabel: "check"
      iconSize: 16
      iconColor: root.checked ? root.checkmarkColor : "transparent"
      iconOpacity: root.checked ? 1 : 0
      filled: true
      visible: root.checked
      Behavior on iconOpacity { NumberAnimation { duration: root.animateDuration(150) } }
    }
  }
}
