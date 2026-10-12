import QtQuick
import QtQuick.Controls
import "../../../config"
import "."
import "../shared"
import "../../primitives"

IconButtonBase {
  id: root

  ThemeTokens { id: theme }

  property color iconColor: root.selected
    ? Colors.fgPrimary
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
  property color borderColor: theme.outline
  property bool outlined: root.variant === "outlined" && !root.selected
  property real radius: size / 2

  Rectangle {
    anchors.centerIn: parent
    width: Config.material3Theme ? root.size : root.width
    height: Config.material3Theme ? root.size : root.height
    radius: root.radius
    ColorSpring {
      id: containerEffect
      targetColor: Config.material3Theme
        ? Qt.tint(root.backgroundColor, !root.enabled ? "transparent"
          : (root.pressed ? root.pressColor
            : (root.hovered ? root.hoverColor
              : (root.activeFocus ? Colors.focusOverlay : "transparent"))))
        : (!root.enabled ? "transparent"
          : root.selected ? Qt.tint(Colors.primary, root.pressColor)
            : (root.pressed ? root.pressColor
              : (root.hovered ? root.hoverColor
                : (root.activeFocus ? Colors.focusOverlay : root.backgroundColor))))
    }
    color: Config.material3Theme ? containerEffect.color : containerEffect.targetColor
    border.width: root.outlined ? theme.borderWidth : 0
    border.color: root.borderColor

    Behavior on color {
      enabled: !Config.material3Theme
      ColorAnimation { duration: Config.animationDuration }
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: root.size + 4
    height: root.size + 4
    radius: root.radius + 2
    color: "transparent"
    border.width: Config.material3Theme && root.activeFocus ? theme.focusBorderWidth : 0
    border.color: theme.focus
    visible: border.width > 0
  }

  GlassSheen {
    anchors.fill: parent
    radius: root.radius
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
