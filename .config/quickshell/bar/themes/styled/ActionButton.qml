import QtQuick
import QtQuick.Controls
import "../../../config"
import "."
import "../shared"

ActionButtonBase {
  id: root

  ThemeTokens { id: theme }

  property bool horizontalContent: false
  // Small mono labels vanish at the shared 0.38; keep disabled legible.
  opacity: root.enabled ? 1.0 : 0.55
  // Full-strength ink: the muted tone made small mono labels hard to read.
  property color iconColor: root.filled ? theme.accentText : theme.ink
  property real radius: theme.controlRadius
  property color color: {
    var overlay = root.pressed ? Colors.pressOverlay
      : (root.hovered ? Colors.hoverOverlay
        : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
    var base = root.filled
      ? theme.accent
      : (root.variant === "quiet" ? "transparent" : theme.surface)
    return Qt.tint(base, overlay)
  }
  property color borderColor: theme.outline
  property real borderWidth: theme.borderWidth

  readonly property bool active: root.hovered || root.pressed || root.selected || root.activeFocus

  Accessible.description: root.accessibleDescription !== ""
    ? root.accessibleDescription
    : (root.selected ? "Selected" : "")

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: root.color
    border.color: root.borderColor
    border.width: root.borderWidth
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 1
    height: 2
    color: theme.signalColor
    visible: root.selected && root.labelText === ""
  }

  // Registration ticks: the recovered GITS panel's corner-bracket motif,
  // surfaced on active/selected state as a live-console readout cue.
  Item {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: root.borderWidth + 1
    width: 8
    height: 8
    visible: theme.registrationTicks && root.active
    opacity: 0.85

    Rectangle { anchors.left: parent.left; anchors.bottom: parent.bottom; width: 8; height: 1; color: theme.accent }
    Rectangle { anchors.left: parent.left; anchors.bottom: parent.bottom; width: 1; height: 8; color: theme.accent }
  }

  Behavior on color {
    ColorAnimation { duration: Config.animationDuration }
  }

  Column {
    anchors.centerIn: parent
    spacing: root.labelText !== "" && root.iconLabel !== "" ? root.contentSpacing : 0

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.iconLabel !== ""
      text: root.iconLabel
      color: root.iconColor
      font.family: Config.iconFont
      font.pixelSize: root.iconSize
      font.variableAxes: Config.iconVariableAxes(root.filled ? 1 : 0, root.iconSize)
    }

    Text {
      visible: root.labelText !== ""
      width: Math.max(0, root.width - Config.spacingCompact * 2)
      horizontalAlignment: Text.AlignHCenter
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.labelText
      color: root.iconColor
      font.family: theme.monoFontFamily
      // NType 82 Mono is light and small at the shared label size.
      font.pixelSize: Config.typeLabelMediumSize + (Config.nothingDesign && !Config.nothingEvolution ? 1 : 0)
      font.weight: Config.typeMediumWeight
      font.letterSpacing: Config.typeMonoTracking
      lineHeight: Config.typeLabelMediumLineHeight
      lineHeightMode: Text.FixedHeight
      elide: Text.ElideRight
      maximumLineCount: 1
    }
  }
}
