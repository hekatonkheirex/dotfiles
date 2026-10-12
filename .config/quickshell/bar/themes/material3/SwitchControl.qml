import QtQuick
import "../../../config"
import "."
import "../shared"
import "../../primitives"

SwitchBase {
  id: root

  ThemeTokens { id: theme }

  // Liquid Glass shares the Material 3 control's interaction and accessibility
  // behavior, but uses the compact macOS switch geometry and flat neutral
  // thumb.
  property bool liquidGlass: false
  property color activeColor: theme.primary
  property color activeContentColor: Colors.fgPrimary
  property color checkmarkColor: activeColor
  property color surfaceContainerHigh: theme.surfaceContainerHigh
  property color surfaceContainerHighest: theme.surfaceContainerHighest
  property color outline: theme.outline
  property color focusColor: theme.focus
  readonly property color stateOverlay: root.pressed
    ? root.pressOverlay
    : (root.hovered || root.activeFocus ? root.hoverOverlay : Qt.rgba(0, 0, 0, 0))

  height: root.liquidGlass ? 32 : 48
  readonly property real materialTrackWidth: Math.min(52, root.width)
  readonly property real materialTrackX: (root.width - root.materialTrackWidth) / 2

  readonly property real liquidTrackWidth: Math.min(38, root.width)
  readonly property real liquidTrackHeight: Math.min(22, root.height)
  readonly property real liquidTrackX: (root.width - root.liquidTrackWidth) / 2
  readonly property real liquidTrackY: (root.height - root.liquidTrackHeight) / 2
  readonly property real liquidThumbInset: 1
  readonly property real targetThumbSize: root.liquidGlass
    ? (pressed ? 22 : 20)
    : (pressed ? 28 : (checked ? 24 : 16))
  readonly property real targetX: root.liquidGlass
    ? (checked
      ? root.liquidTrackX + root.liquidTrackWidth - root.targetThumbSize - root.liquidThumbInset
      : root.liquidTrackX + root.liquidThumbInset)
    : root.materialTrackX + (checked
      ? (pressed ? root.materialTrackWidth - 28 - 2 : root.materialTrackWidth - 24 - 4)
      : (pressed ? 2 : 8))

  property real thumbSize: root.liquidGlass ? 20 : 16
  property real thumbX: root.liquidGlass ? root.targetX : 8

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
    border.width: root.activeFocus ? theme.focusBorderWidth : 0
    border.color: root.focusColor
    visible: root.activeFocus
  }

  Rectangle {
    id: track
    x: root.liquidGlass ? root.liquidTrackX : root.materialTrackX
    y: root.liquidGlass ? root.liquidTrackY : (root.height - 32) / 2
    width: root.liquidGlass ? root.liquidTrackWidth : root.materialTrackWidth
    height: root.liquidGlass ? root.liquidTrackHeight : 32
    radius: height / 2
    ColorSpring {
      id: trackEffect
      animate: Config.material3Theme && !root.reducedMotion && !Config.reducedMotion
      targetColor: root.enabled
        ? Qt.tint(root.checked ? root.activeColor
          : (root.liquidGlass ? Colors.liquidGlassControlTrack : root.surfaceContainerHighest),
          root.stateOverlay)
        : (root.liquidGlass ? Colors.liquidGlassControlTrack : root.surfaceContainerHighest)
    }
    color: Config.material3Theme ? trackEffect.color : trackEffect.targetColor
    border.width: root.liquidGlass
      ? 0
      : (root.checked || !root.enabled ? 0 : theme.focusBorderWidth)
    border.color: root.liquidGlass ? Colors.liquidGlassEdge : root.outline
    opacity: root.enabled ? 1 : 0.55

    Behavior on color {
      enabled: !Config.material3Theme
      ColorAnimation { duration: root.animateDuration(150) }
    }
  }

  Rectangle {
    id: knobShadow
    x: root.thumbX + (root.liquidGlass ? 1 : 0)
    y: parent.height / 2 - height / 2 + (root.liquidGlass ? 1 : 0)
    width: root.thumbSize
    height: root.thumbSize
    radius: width / 2
    color: Colors.liquidGlassShadow
    visible: root.liquidGlass && root.enabled
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
      animate: Config.material3Theme && !root.reducedMotion && !Config.reducedMotion
      targetColor: root.enabled
        ? (root.liquidGlass
          ? Qt.tint(Colors.liquidGlassControlThumb, root.stateOverlay)
          : Qt.tint(root.checked ? root.activeContentColor : root.outline, root.stateOverlay))
        : root.outline
    }
    color: Config.material3Theme ? thumbEffect.color : thumbEffect.targetColor
    border.width: root.liquidGlass && root.activeFocus ? theme.focusBorderWidth : 0
    border.color: root.focusColor

    Behavior on color {
      enabled: !Config.material3Theme
      ColorAnimation { duration: root.animateDuration(150) }
    }

    IconGlyph {
      anchors.centerIn: parent
      iconLabel: "check"
      iconSize: 16
      iconColor: root.checked ? root.checkmarkColor : "transparent"
      iconOpacity: root.checked && !root.liquidGlass ? 1 : 0
      filled: true
      visible: root.checked && !root.liquidGlass
      Behavior on iconOpacity { NumberAnimation { duration: root.animateDuration(150) } }
    }
  }
}
