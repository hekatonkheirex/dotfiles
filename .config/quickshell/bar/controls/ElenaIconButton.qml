import QtQuick
import QtQuick.Controls
import "../../config"
import "."
import "../primitives"

IconButtonBase {
  id: root

  property color iconColor: root.selected
    ? Colors.surface
    : (root.variant === "filled"
      ? Colors.fgSurface
      : (root.variant === "tonal" ? Colors.fgSecondaryContainer : Colors.fgSurfaceVariant))
  property color hoverColor: Qt.tint("transparent", Colors.hoverOverlay)
  property color pressColor: Qt.tint("transparent", Colors.pressOverlay)
  property color backgroundColor: root.selected
    ? Colors.primary
    : (root.variant === "filled"
      ? Colors.surfaceContainerHighest
      : (root.variant === "tonal" ? Colors.secondaryContainer : "transparent"))
  property color borderColor: Colors.outline
  property bool outlined: root.variant === "outlined" && !root.selected
  property real radius: size / 2

  Rectangle {
    anchors.centerIn: parent
    width: root.size
    height: root.size
    radius: root.radius
    ColorSpring {
      id: containerEffect
      targetColor: Qt.tint(root.backgroundColor, !root.enabled ? "transparent"
        : (root.pressed ? root.pressColor
          : (root.hovered ? root.hoverColor
            : (root.activeFocus ? Colors.focusOverlay : "transparent"))))
    }
    color: containerEffect.color
    border.width: root.outlined ? 1 : 0
    border.color: root.borderColor
  }

  Rectangle {
    anchors.centerIn: parent
    width: root.size + 4
    height: root.size + 4
    radius: root.radius + 2
    color: "transparent"
    border.width: root.activeFocus ? 2 : 0
    border.color: Colors.primary
    visible: border.width > 0
  }

  Rectangle {
    visible: root.selected
    anchors.centerIn: parent
    width: root.size * 0.72
    height: width
    radius: width / 2
    color: "#ffffff"
  }

  IconGlyph {
    anchors.centerIn: parent
    iconLabel: root.iconLabel
    iconColor: root.iconColor
    iconSize: root.iconSize
    iconOpacity: root.enabled ? 1.0 : 0.38
    filled: root.selected
  }
}
