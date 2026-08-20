import QtQuick
import "../../../config"
import "."

Item {
  id: root

  ThemeTokens { id: theme }

  property real value: 0.5
  property bool muted: false
  property color activeColor: theme.accent
  property color surfaceContainerHigh: theme.surfaceRaised
  property color surfaceContainerHighest: theme.controlSurface
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
  height: 40
  activeFocusOnTab: true

  readonly property bool hovered: sliderMouse.containsMouse
  readonly property bool pressed: sliderMouse.pressed
  readonly property bool active: hovered || pressed || activeFocus
  // Neo uses this control as a filled progress bar. The value fill and its
  // contrasting base occupy the whole control box; there is no thumb, frame,
  // or offset shadow competing with the bar itself.
  readonly property real visualWidth: Math.max(0, root.width)
  readonly property real barHeight: 14
  readonly property real barRadius: theme.controlRadius
  readonly property real barInset: 0
  readonly property real barContentHeight: barHeight
  readonly property real normalizedValue: Math.max(0, Math.min(1, root.value))

  function animateDuration(base) {
    return root.reducedMotion ? 0 : Math.max(0, root.motionDuration || base)
  }

  function setValue(nextValue) {
    root.changed(Math.max(0, Math.min(1, nextValue)))
  }

  Keys.onPressed: function(event) {
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

  Rectangle {
    id: focusRing
    x: -2
    y: -2
    width: root.visualWidth + 4
    height: root.height + 4
    color: "transparent"
    border.width: root.activeFocus ? theme.focusBorderWidth : 0
    border.color: root.focusColor
    radius: theme.controlSmallRadius
    visible: root.activeFocus
    z: 5
  }

  Rectangle {
    id: barFrame
    x: 0
    y: root.height / 2 - height / 2
    width: root.visualWidth
    height: root.barHeight
    radius: root.barRadius
    color: root.enabled ? root.surfaceContainerHighest : root.surfaceContainerHigh
    z: 0
  }

  Rectangle {
    id: barFill
    x: barFrame.x
    y: barFrame.y
    width: Math.max(0, barFrame.width * root.normalizedValue)
    height: root.barContentHeight
    radius: root.barRadius
    color: Qt.tint(root.muted ? root.outline : root.activeColor, root.stateOverlay)
    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }
    z: 1
  }

  MouseArea {
    id: sliderMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: function(mouse) {
      root.forceActiveFocus()
      handleMouse(mouse.x)
    }
    onPositionChanged: function(mouse) {
      if (pressed) handleMouse(mouse.x)
    }
    function handleMouse(mx) {
      root.setValue(root.visualWidth > 0
        ? (Math.max(0, Math.min(root.visualWidth, mx)) / root.visualWidth)
        : 0)
    }
    onReleased: root.interactionFinished()
  }
}
