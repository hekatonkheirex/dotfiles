import QtQuick
import Quickshell.Widgets
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

  property string valueText: ""
  width: 56
  height: 56
  // A pointer press retains keyboard adjustment without painting a selection
  // outline. Tab focus and keyboard adjustment still show the focus ring.
  property bool pointerFocus: false
  property bool keyboardFocus: false

  readonly property bool hovered: sliderMouse.containsMouse
  readonly property bool pressed: sliderMouse.pressed
  readonly property bool active: hovered || pressed || activeFocus
  readonly property bool focusRingVisible: root.activeFocus && (!root.pointerFocus || root.keyboardFocus)
  readonly property real fillHeight: height * Math.max(0, Math.min(1, value))

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

  // Her slider tile: square rounded trough, fill rising from the bottom, a
  // round label at the bottom-right that carries the value. The trough is a
  // ClippingRectangle so the fill follows its rounded corners.
  ClippingRectangle {  // track tile
    id: trough
    anchors.fill: parent
    radius: Math.round(height * 0.36)
    color: root.surfaceContainerHighest
    Rectangle {  // level fill
      anchors.bottom: parent.bottom
      width: parent.width
      height: root.fillHeight
      ColorSpring {
        id: trackEffect
        animate: !root.reducedMotion && !Config.reducedMotion
        targetColor: Qt.tint(root.muted ? root.outline : root.activeColor, root.stateOverlay)
      }
      color: trackEffect.color
    }
    Rectangle {  // round value label
      visible: root.valueText !== ""
      readonly property real inset: Math.round(parent.height * 0.14)
      height: Math.round(parent.height * 0.4)
      width: Math.min(parent.width - 2 * inset, Math.max(height, labelText.implicitWidth + 8))
      radius: height / 2
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.rightMargin: inset
      anchors.bottomMargin: inset
      color: Colors.fgSurface
      Text {
        id: labelText
        anchors.centerIn: parent
        text: root.valueText
        color: Colors.surface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelSmallSize
        font.weight: Config.typeMediumWeight
      }
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
      handleMouse(mouse.y)
    }
    onPositionChanged: function(mouse) {
      if (pressed) handleMouse(mouse.y)
    }
    function handleMouse(my) {
      root.setValue(1 - my / parent.height)
    }
    onReleased: root.interactionFinished()
  }
}
