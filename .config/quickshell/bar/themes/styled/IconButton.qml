import QtQuick
import QtQuick.Controls
import "../../../config"
import "."
import "../shared"

IconButtonBase {
  id: root

  ThemeTokens { id: theme }

  property color iconColor: theme.ink
  property color hoverColor: Qt.tint("transparent", Colors.hoverOverlay)
  property color pressColor: Qt.tint("transparent", Colors.pressOverlay)
  property color backgroundColor: "transparent"
  property color borderColor: theme.outline
  property bool outlined: false
  property real radius: theme.controlSmallRadius

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: !root.enabled ? "transparent"
      : root.selected ? theme.accent
      : (root.pressed ? root.pressColor
        : (root.hovered ? root.hoverColor
          : (root.activeFocus ? Colors.focusOverlay : root.backgroundColor)))
    border.width: root.outlined || root.selected ? theme.borderWidth : 0
    border.color: root.selected ? theme.accent : root.borderColor

    Behavior on color {
      ColorAnimation { duration: Config.animationDuration }
    }
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: -2
    radius: theme.square ? 0 : root.radius + theme.focusBorderWidth
    color: "transparent"
    border.width: root.activeFocus ? theme.focusBorderWidth : 0
    border.color: theme.focusRing
    visible: root.activeFocus
    z: 1
  }

  Text {
    anchors.centerIn: parent
    text: root.iconLabel
    color: root.selected ? theme.accentText : root.iconColor
    opacity: root.enabled ? 1.0 : 0.38
    font.family: Config.iconFont
    font.pixelSize: root.iconSize
    font.variableAxes: Config.iconVariableAxes(root.selected ? 1 : 0, root.iconSize)
  }
}
