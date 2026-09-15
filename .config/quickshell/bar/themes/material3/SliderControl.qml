import QtQuick
import "../../../config"
import "."
// Liquid Glass reuses this accessible control and supplies its material roles
// through the facade; the HIG slider remains a flat control within that system.

Item {
  id: root

  ThemeTokens { id: theme }

  // Liquid Glass shares the slider's input/accessibility behavior, but uses
  // macOS's thin linear track and a neutral lozenge thumb.
  property bool liquidGlass: false
  property real value: 0.5
  property bool muted: false
  property color activeColor: theme.primary
  property color surfaceContainerHigh: theme.surfaceContainerHigh
  property color surfaceContainerHighest: theme.surfaceContainerHighest
  property color outline: theme.outline
  property color focusColor: theme.focus
  property color hoverOverlay: Colors.hoverOverlay
  property color pressOverlay: Colors.pressOverlay
  readonly property color stateOverlay: root.pressed
    ? root.pressOverlay
    : (root.hovered || root.activeFocus ? root.hoverOverlay : Qt.rgba(0, 0, 0, 0))
  property int motionDuration: 150
  property bool reducedMotion: false
  property real stepSize: 0.05
  property string accessibleName: "Slider"
  property string accessibleDescription: "Adjust value"
  property real accessibleMinimumValue: 0
  property real accessibleMaximumValue: 100
  property string accessibleUnit: "%"

  Accessible.role: Accessible.Slider
  Accessible.name: root.accessibleName
  Accessible.description: root.accessibleDescription
    + " Current value " + Math.round(root.accessibleMinimumValue
      + root.value * (root.accessibleMaximumValue - root.accessibleMinimumValue))
    + (root.accessibleUnit !== "" ? " " + root.accessibleUnit : "")
    + ". Range " + root.accessibleMinimumValue + " to " + root.accessibleMaximumValue
    + (root.accessibleUnit !== "" ? " " + root.accessibleUnit : "")
  Accessible.focusable: true
  Accessible.focused: root.activeFocus

  signal changed(real value)
  signal interactionFinished()

  width: parent ? parent.width : 240
  height: root.liquidGlass ? 28 : 40
  activeFocusOnTab: true
  // Liquid Glass uses direct-manipulation feedback for pointer input. Keep
  // its keyboard focus treatment opt-in so popup reactivation cannot leave a
  // rounded focus outline around a slider that was used with the pointer.
  property bool keyboardFocus: false

  readonly property bool hovered: sliderMouse.containsMouse
  readonly property bool pressed: sliderMouse.pressed
  readonly property bool active: hovered || pressed || activeFocus
  readonly property bool focusRingVisible: root.activeFocus
    && (!root.liquidGlass || root.keyboardFocus)
  readonly property real trackHeight: root.liquidGlass ? 5 : 16
  readonly property real trackRadius: trackHeight / 2
  readonly property real trackInsideRadius: root.liquidGlass ? trackRadius : 2
  readonly property real targetThumbWidth: root.liquidGlass
    ? (pressed ? 28 : 24)
    : (pressed ? 8 : (hovered || activeFocus ? 6 : 4))
  readonly property real targetThumbHeight: root.liquidGlass
    ? (pressed ? 22 : 20)
    : (pressed ? 48 : (hovered || activeFocus ? 46 : 44))
  readonly property real targetGap: root.liquidGlass
    ? 0
    : (pressed ? 4 : (hovered || activeFocus ? 5 : 6))
  // Start at the platform geometry so a newly-created Liquid Glass slider
  // never flashes the Material 3 thumb before settling into place.
  property real thumbWidth: root.liquidGlass ? 24 : 4
  property real thumbHeight: root.liquidGlass ? 20 : 44
  property real gap: root.liquidGlass ? 0 : 6

  function animateDuration(base) {
    return root.reducedMotion ? 0 : Math.max(0, root.motionDuration || base)
  }

  function setValue(nextValue) {
    root.changed(Math.max(0, Math.min(1, nextValue)))
  }

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
    if (!root.activeFocus) root.keyboardFocus = false
  }

  Keys.onPressed: function(event) {
    var isAdjustmentKey = event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown
      || event.key === Qt.Key_Left || event.key === Qt.Key_Right
      || event.key === Qt.Key_Up || event.key === Qt.Key_Down
      || event.key === Qt.Key_Home || event.key === Qt.Key_End
    if (!isAdjustmentKey) return

    root.keyboardFocus = true
    var delta = root.stepSize
    if (event.key === Qt.Key_PageUp) delta *= 5
    if (event.key === Qt.Key_PageDown) delta *= -5
    if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) delta *= -1
    if (event.key === Qt.Key_Right || event.key === Qt.Key_Up || event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
      root.setValue(root.value + delta)
      event.accepted = true
    } else if (event.key === Qt.Key_Home) {
      root.setValue(0)
      event.accepted = true
    } else if (event.key === Qt.Key_End) {
      root.setValue(1)
      event.accepted = true
    }
  }

  Keys.onReleased: function(event) {
    if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown
        || event.key === Qt.Key_Left || event.key === Qt.Key_Right
        || event.key === Qt.Key_Up || event.key === Qt.Key_Down
        || event.key === Qt.Key_Home || event.key === Qt.Key_End) {
      root.interactionFinished()
    }
  }

  readonly property real thumbCenter: thumbWidth / 2 + (width - thumbWidth) * value
  readonly property real leftGap: Math.min(gap, thumbCenter - thumbWidth / 2)
  readonly property real rightGap: Math.min(gap, width - thumbCenter - thumbWidth / 2)

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: root.trackRadius + 4
    color: root.focusRingVisible ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    border.width: root.focusRingVisible ? theme.focusBorderWidth : 0
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
    color: Qt.tint(root.muted ? root.outline : root.activeColor, root.stateOverlay)
    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }

    Rectangle {
      anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
      width: Math.min(parent.width, 8)
      radius: root.trackInsideRadius
      color: parent.color
      visible: !root.liquidGlass
    }
  }

  Rectangle {
    id: inactiveTrack
    x: thumbCenter + thumbWidth / 2 + rightGap
    y: parent.height / 2 - height / 2
    width: Math.max(0, parent.width - x)
    height: root.trackHeight
    radius: root.trackRadius
    // macOS linear sliders use a neutral track; the active segment above
    // carries the semantic accent color. Keep it independent from the
    // translucent surfaces that contain settings sliders.
    color: root.liquidGlass ? Colors.liquidGlassControlTrack : theme.surfaceVariant

    Rectangle {
      anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
      width: Math.min(parent.width, 8)
      radius: root.trackInsideRadius
      color: parent.color
      visible: !root.liquidGlass
    }

    Rectangle {
      anchors { right: parent.right; rightMargin: Config.spacingSmall; verticalCenter: parent.verticalCenter }
      width: 4
      height: 4
      radius: 2
      color: root.muted ? root.outline : root.activeColor
      visible: !root.liquidGlass && parent.width > 20
    }
  }

  Rectangle {
    id: knobShadow
    x: thumbCenter - width / 2 + (root.liquidGlass ? 1 : 0)
    y: parent.height / 2 - height / 2 + (root.liquidGlass ? 1 : 0)
    width: root.thumbWidth
    height: root.thumbHeight
    radius: width / 2
    color: Colors.liquidGlassShadow
    visible: root.liquidGlass && root.enabled
  }

  Rectangle {
    id: knob
    x: thumbCenter - width / 2
    y: parent.height / 2 - height / 2
    width: root.thumbWidth
    height: root.thumbHeight
    radius: width / 2
    color: root.liquidGlass
      ? Qt.tint(Colors.liquidGlassControlThumb, root.stateOverlay)
      : Qt.tint(root.muted ? root.outline : root.activeColor, root.stateOverlay)
    border.width: root.liquidGlass
      ? (root.focusRingVisible ? theme.focusBorderWidth : 0)
      : (root.pressed ? theme.focusBorderWidth : 0)
    border.color: root.liquidGlass ? Colors.liquidGlassEdge : root.surfaceContainerHigh
    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }

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
