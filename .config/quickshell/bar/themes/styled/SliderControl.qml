import QtQuick
import "../../../config"
import "."
import "../shared"

SliderBase {
  id: root

  ThemeTokens { id: theme }

  property color activeColor: theme.accent
  property color surfaceContainerHigh: theme.surfaceRaised
  property color surfaceContainerHighest: theme.controlSurface
  property color outline: theme.outline
  property color focusColor: theme.focus

  readonly property int segmentCount: theme.segmentCount
  readonly property real segmentGap: theme.segmentGap
  readonly property real normalizedValue: Math.max(0, Math.min(1, root.value))
  readonly property real segmentWidth: root.segmentCount > 0
    ? Math.max(1, (root.width - root.segmentGap * (root.segmentCount - 1)) / root.segmentCount)
    : 0
  readonly property bool hovered: sliderMouse.containsMouse
  readonly property bool pressed: sliderMouse.pressed
  readonly property bool active: root.hovered || root.pressed || root.activeFocus

  height: 40

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: theme.square ? 0 : theme.controlRadius + 4
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
    radius: theme.segmentRadius
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
