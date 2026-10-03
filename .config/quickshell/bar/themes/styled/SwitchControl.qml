import QtQuick
import "../../../config"
import "."
import "../shared"

SwitchBase {
  id: root

  ThemeTokens { id: theme }

  property color activeColor: theme.accent
  property color activeContentColor: theme.accentText
  property color checkmarkColor: activeColor
  property color surfaceContainerHigh: theme.surfaceRaised
  property color surfaceContainerHighest: theme.controlSurface
  property color outline: theme.outline
  property color focusColor: theme.focus

  height: 28

  readonly property real targetX: root.checked ? root.width - 20 : 6
  property real thumbX: 6

  Behavior on thumbX {
    NumberAnimation { duration: root.animateDuration(150); easing.type: Easing.OutCubic }
  }

  Component.onCompleted: thumbX = targetX
  onTargetXChanged: thumbX = targetX

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: theme.square ? 0 : theme.controlRadius + 4
    color: root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    border.width: root.activeFocus ? theme.focusBorderWidth : 0
    border.color: root.focusColor
    visible: root.activeFocus
  }

  Rectangle {
    id: track
    anchors.fill: parent
    radius: theme.controlRadius
    color: root.enabled
      ? Qt.tint(root.checked ? root.activeColor : root.surfaceContainerHighest, root.pressed ? root.pressOverlay : Qt.rgba(0, 0, 0, 0))
      : root.surfaceContainerHighest
    border.width: theme.borderWidth
    border.color: root.outline
    opacity: root.enabled ? 1 : 0.55

    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }
  }

  Rectangle {
    id: knob
    x: root.thumbX
    y: parent.height / 2 - height / 2
    width: 14
    height: 14
    radius: theme.controlSmallRadius
    color: root.enabled
      ? (root.checked ? root.activeContentColor : root.outline)
      : root.outline

    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }
  }
}
