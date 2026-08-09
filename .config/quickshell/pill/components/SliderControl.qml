import QtQuick
import "../../config"

Item {
  id: root

  property real value: 0.5
  property bool muted: false
  property color activeColor: Colors.primary
  property color surfaceContainerHigh: Colors.surfaceContainerHigh
  property color surfaceContainerHighest: Colors.surfaceContainerHighest
  property color outline: Colors.outline
  property color focusColor: activeColor
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

  Accessible.role: Accessible.Slider
  Accessible.name: root.accessibleName
  Accessible.description: root.accessibleDescription + " Current value " + Math.round(root.value * 100) + " percent"

  signal changed(real value)

  width: parent ? parent.width : 240
  height: 40
  activeFocusOnTab: true

  readonly property bool hovered: sliderMouse.containsMouse
  readonly property bool pressed: sliderMouse.pressed
  readonly property bool active: hovered || pressed || activeFocus
  readonly property real trackHeight: 16
  readonly property real trackRadius: trackHeight / 2
  readonly property real trackInsideRadius: 2
  readonly property real targetThumbWidth: pressed ? 8 : (hovered || activeFocus ? 6 : 4)
  readonly property real targetThumbHeight: pressed ? 48 : (hovered || activeFocus ? 46 : 44)
  readonly property real targetGap: pressed ? 4 : (hovered || activeFocus ? 5 : 6)
  property real thumbWidth: 4
  property real thumbHeight: 44
  property real gap: 6

  function animateDuration(base) {
    return root.reducedMotion ? 0 : Math.max(0, root.motionDuration || base)
  }

  function setValue(nextValue) {
    root.changed(Math.max(0, Math.min(1, nextValue)))
  }

  Behavior on thumbWidth {
    NumberAnimation { duration: root.animateDuration(150); easing.type: Easing.OutBack }
  }
  Behavior on thumbHeight {
    NumberAnimation { duration: root.animateDuration(150); easing.type: Easing.OutBack }
  }
  Behavior on gap {
    NumberAnimation { duration: root.animateDuration(150); easing.type: Easing.OutBack }
  }

  Component.onCompleted: {
    thumbWidth = targetThumbWidth
    thumbHeight = targetThumbHeight
    gap = targetGap
  }

  onTargetThumbWidthChanged: thumbWidth = targetThumbWidth
  onTargetThumbHeightChanged: thumbHeight = targetThumbHeight
  onTargetGapChanged: gap = targetGap

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

  readonly property real thumbCenter: thumbWidth / 2 + (width - thumbWidth) * value
  readonly property real leftGap: Math.min(gap, thumbCenter - thumbWidth / 2)
  readonly property real rightGap: Math.min(gap, width - thumbCenter - thumbWidth / 2)

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: root.trackRadius + 4
    color: root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    border.width: root.activeFocus ? 2 : 0
    border.color: root.focusColor
    visible: root.activeFocus
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
    }
  }

  Rectangle {
    id: inactiveTrack
    x: thumbCenter + thumbWidth / 2 + rightGap
    y: parent.height / 2 - height / 2
    width: Math.max(0, parent.width - x)
    height: root.trackHeight
    radius: root.trackRadius
    color: root.surfaceContainerHighest

    Rectangle {
      anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
      width: Math.min(parent.width, 8)
      radius: root.trackInsideRadius
      color: parent.color
    }

    Rectangle {
      anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
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
    color: Qt.tint(root.muted ? root.outline : root.activeColor, root.stateOverlay)
    border.width: root.pressed ? 2 : 0
    border.color: root.surfaceContainerHigh
    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }
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
      root.setValue(mx / parent.width)
    }
  }
}
