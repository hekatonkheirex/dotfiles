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
  readonly property real fillWidth: value <= 0 ? 0 : Math.max(height, width * Math.max(0, Math.min(1, value)))

  onActiveFocusChanged: {
    if (!root.activeFocus) {
      root.pointerFocus = false
      root.keyboardFocus = false
    }
  }

  onAdjustmentKey: root.keyboardFocus = true

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: Config.shapeMedium + 4
    color: root.focusRingVisible ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    border.width: root.focusRingVisible ? 2 : 0
    border.color: root.focusColor
    visible: root.focusRingVisible
  }

  Rectangle {  // track tile
    anchors.fill: parent
    radius: Config.shapeMedium
    color: root.surfaceContainerHighest
    clip: true
    Rectangle {  // level fill
      width: root.fillWidth
      height: parent.height
      radius: parent.radius
      ColorSpring {
        id: trackEffect
        animate: !root.reducedMotion && !Config.reducedMotion
        targetColor: Qt.tint(root.muted ? root.outline : root.activeColor, root.stateOverlay)
      }
      color: trackEffect.color
    }
    Rectangle {  // white round thumb at the end of the fill
      visible: root.fillWidth > 0
      width: 24
      height: 24
      radius: 12
      x: Math.max(3, root.fillWidth - width - 3)
      anchors.verticalCenter: parent.verticalCenter
      color: "#ffffff"
    }
  }

  MouseArea {
    id: sliderMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onPressed: function(mouse) {
      root.keyboardFocus = false
      root.pointerFocus = true
      root.forceActiveFocus(Qt.MouseFocusReason)
      handleMouse(mouse.x)
    }
    onPositionChanged: function(mouse) {
      if (pressed) handleMouse(mouse.x)
    }
    function handleMouse(mx) {
      root.setValue(mx / parent.width)
    }
    onReleased: root.interactionFinished()
  }
}
