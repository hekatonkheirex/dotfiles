import QtQuick
import "../../config"
import "."
import "../primitives"

SliderBase {
  id: root

  property color activeColor: Colors.primary
  property color surfaceContainerHigh: Colors.surfaceContainerHigh
  property color surfaceContainerHighest: Colors.surfaceContainerHighest
  property color outline: Colors.outline
  property color focusColor: Colors.primary
  readonly property color stateOverlay: root.pressed
    ? root.pressOverlay
    : (root.hovered || root.activeFocus ? root.hoverOverlay : Qt.rgba(0, 0, 0, 0))

  height: 40
  // A pointer press retains keyboard adjustment without painting a selection
  // outline. Tab focus and keyboard adjustment still show the focus ring.
  property bool pointerFocus: false
  property bool keyboardFocus: false

  readonly property bool hovered: sliderMouse.containsMouse
  readonly property bool pressed: sliderMouse.pressed
  readonly property bool active: hovered || pressed || activeFocus
  readonly property bool focusRingVisible: root.activeFocus && (!root.pointerFocus || root.keyboardFocus)
  readonly property real trackHeight: 16
  readonly property real trackRadius: trackHeight / 2
  readonly property real trackInsideRadius: 2
  readonly property real targetThumbWidth: pressed ? 8 : (hovered || activeFocus ? 6 : 4)
  readonly property real targetThumbHeight: pressed ? 48 : (hovered || activeFocus ? 46 : 44)
  readonly property real targetGap: pressed ? 4 : (hovered || activeFocus ? 5 : 6)
  property real thumbWidth: 4
  property real thumbHeight: 44
  property real gap: 6

  Behavior on thumbWidth {
    enabled: Config.spatialMotion && !root.reducedMotion
    SpringAnimation {
      spring: Config.motionSpatialSpring
      damping: Config.motionSpatialDamping
      mass: Config.motionSpatialMass
      epsilon: Config.motionSpatialEpsilon
    }
  }
  Behavior on thumbHeight {
    enabled: Config.spatialMotion && !root.reducedMotion
    SpringAnimation {
      spring: Config.motionSpatialSpring
      damping: Config.motionSpatialDamping
      mass: Config.motionSpatialMass
      epsilon: Config.motionSpatialEpsilon
    }
  }
  Behavior on gap {
    enabled: Config.spatialMotion && !root.reducedMotion
    SpringAnimation {
      spring: Config.motionSpatialSpring
      damping: Config.motionSpatialDamping
      mass: Config.motionSpatialMass
      epsilon: Config.motionSpatialEpsilon
    }
  }

  Component.onCompleted: {
    thumbWidth = targetThumbWidth
    thumbHeight = targetThumbHeight
    gap = targetGap
  }

  onTargetThumbWidthChanged: thumbWidth = targetThumbWidth
  onTargetThumbHeightChanged: thumbHeight = targetThumbHeight
  onTargetGapChanged: gap = targetGap

  onActiveFocusChanged: {
    if (!root.activeFocus) {
      root.pointerFocus = false
      root.keyboardFocus = false
    }
  }

  onAdjustmentKey: root.keyboardFocus = true

  readonly property real thumbCenter: thumbWidth / 2 + (width - thumbWidth) * value
  readonly property real leftGap: Math.min(gap, thumbCenter - thumbWidth / 2)
  readonly property real rightGap: Math.min(gap, width - thumbCenter - thumbWidth / 2)

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: root.trackRadius + 4
    color: root.focusRingVisible ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    border.width: root.focusRingVisible ? 2 : 0
    border.color: root.focusColor
    visible: root.focusRingVisible
  }

  Rectangle {
    id: activeTrack
    x: 0
    y: parent.height / 2 - height / 2
    width: Math.max(0, thumbCenter - thumbWidth / 2 - leftGap)
    height: root.trackHeight
    radius: root.trackRadius
    ColorSpring {
      id: trackEffect
      animate: !root.reducedMotion && !Config.reducedMotion
      targetColor: Qt.tint(root.muted ? root.outline : root.activeColor, root.stateOverlay)
    }
    color: trackEffect.color

    Rectangle {
      anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
      width: Math.min(parent.width, 8)
      radius: root.trackInsideRadius
      color: parent.color
    }
  }

  Rectangle {
    id: inactiveTrack
    x: thumbCenter + thumbWidth / 2 + rightGap
    y: parent.height / 2 - height / 2
    width: Math.max(0, parent.width - x)
    height: root.trackHeight
    radius: root.trackRadius
    color: Colors.surfaceVariant

    Rectangle {
      anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
      width: Math.min(parent.width, 8)
      radius: root.trackInsideRadius
      color: parent.color
    }

    Rectangle {
      anchors { right: parent.right; rightMargin: Config.spacingSmall; verticalCenter: parent.verticalCenter }
      width: 4
      height: 4
      radius: 2
      color: root.muted ? root.outline : root.activeColor
      visible: parent.width > 20
    }
  }

  Rectangle {
    id: knob
    x: thumbCenter - width / 2
    y: parent.height / 2 - height / 2
    width: root.thumbWidth
    height: root.thumbHeight
    radius: width / 2
    ColorSpring {
      id: thumbEffect
      animate: !root.reducedMotion && !Config.reducedMotion
      targetColor: Qt.tint(root.muted ? root.outline : root.activeColor, root.stateOverlay)
    }
    color: thumbEffect.color
    border.width: root.pressed ? 2 : 0
    border.color: root.surfaceContainerHigh
  }

  MouseArea {
    id: sliderMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    property real grabOffset: 0
    property bool draggingThumb: false

    onPressed: function(mouse) {
      root.keyboardFocus = false
      root.pointerFocus = true
      root.forceActiveFocus(Qt.MouseFocusReason)
      draggingThumb = Math.abs(mouse.x - root.thumbCenter) <= Math.max(10, root.thumbWidth)
      grabOffset = draggingThumb ? mouse.x - root.thumbCenter : 0
      handleMouse(mouse.x - grabOffset)
    }
    onPositionChanged: function(mouse) {
      if (pressed) handleMouse(mouse.x - grabOffset)
    }
    function handleMouse(mx) {
      root.setValue(mx / parent.width)
    }
    onReleased: {
      draggingThumb = false
      grabOffset = 0
      root.interactionFinished()
    }
  }
}
