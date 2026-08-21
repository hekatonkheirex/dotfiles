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
  property int motionDuration: 150
  property bool reducedMotion: false
  property real stepSize: 0.05
  property string accessibleName: "Slider"
  property string accessibleDescription: "Adjust value"
  property real accessibleMinimumValue: 0
  property real accessibleMaximumValue: 100
  property string accessibleUnit: "%"

  readonly property int segmentCount: 18
  readonly property real segmentGap: 2
  readonly property real normalizedValue: Math.max(0, Math.min(1, root.value))
  readonly property real segmentWidth: root.segmentCount > 0
    ? Math.max(1, (root.width - root.segmentGap * (root.segmentCount - 1)) / root.segmentCount)
    : 0
  readonly property bool hovered: sliderMouse.containsMouse
  readonly property bool pressed: sliderMouse.pressed
  readonly property bool active: root.hovered || root.pressed || root.activeFocus

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
    anchors.fill: parent
    anchors.margins: -4
    radius: theme.controlRadius + 4
    color: root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    border.width: root.activeFocus ? theme.focusBorderWidth : 0
    border.color: root.focusColor
    visible: root.activeFocus
  }

  Row {
    id: segments
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    height: 12
    spacing: root.segmentGap

    Repeater {
      model: root.segmentCount

      Rectangle {
        required property int index
        width: root.segmentWidth
        height: index < Math.ceil(root.normalizedValue * root.segmentCount) ? 12 : 8
        anchors.verticalCenter: segments.verticalCenter
        color: root.enabled
          ? (index < Math.ceil(root.normalizedValue * root.segmentCount)
            ? Qt.tint(root.muted ? root.outline : root.activeColor, root.pressed ? root.pressOverlay : Qt.rgba(0, 0, 0, 0))
            : root.surfaceContainerHighest)
          : root.surfaceContainerHigh

        Behavior on height { NumberAnimation { duration: root.animateDuration(100); easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: root.animateDuration(100) } }
      }
    }
  }

  Rectangle {
    id: marker
    x: Math.max(0, Math.min(root.width - width, root.width * root.normalizedValue - width / 2))
    y: 3
    width: 2
    height: root.height - 6
    radius: 1
    color: root.enabled ? (root.muted ? root.outline : root.activeColor) : root.outline
    visible: root.active || root.normalizedValue > 0
    Behavior on x { NumberAnimation { duration: root.animateDuration(120); easing.type: Easing.OutCubic } }
  }

  MouseArea {
    id: sliderMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: function(mouse) {
      handleMouse(mouse.x)
    }
    onPositionChanged: function(mouse) {
      if (pressed) handleMouse(mouse.x)
    }
    function handleMouse(mx) {
      root.setValue(root.width > 0 ? mx / root.width : 0)
    }
    onReleased: root.interactionFinished()
  }
}
