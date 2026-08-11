// Square toggle-style action tile: filled when selected, tonal container
// otherwise, with hover/press/focus state layers and keyboard activation
// (Space/Enter). Lifted out of QuickMenu's four near-identical layout/wallpaper/
// idle/theme toggle tiles.
import QtQuick
import QtQuick.Controls
import "../../config"

Rectangle {
  id: root

  property string iconLabel: ""
  property bool selected: false
  property string labelText: ""
  property string variant: "tonal"
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""
  readonly property bool filled: root.selected || root.variant === "filled"
  property real iconSize: Config.iconSize + 4
  property color iconColor: root.filled ? Colors.fgPrimary : Colors.fgSurfaceVariant

  signal activated()

  radius: Config.shapeLarge
  activeFocusOnTab: true
  opacity: root.enabled ? 1.0 : 0.38

  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed

  Accessible.role: Accessible.Button
  Accessible.name: root.accessibleName !== ""
    ? root.accessibleName
    : (root.labelText !== "" ? root.labelText : (root.tooltipText !== "" ? root.tooltipText : root.iconLabel))
  Accessible.description: root.accessibleDescription !== ""
    ? root.accessibleDescription
    : (root.selected ? "Selected" : "")

  color: {
    var overlay = mouseArea.pressed ? Colors.pressOverlay
      : (mouseArea.containsMouse ? Colors.hoverOverlay
        : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
    var base = root.filled
      ? Colors.primary
      : (root.variant === "quiet" ? "transparent" : Colors.surfaceContainer)
    return Qt.tint(base, overlay)
  }
  border.color: root.filled || root.variant === "quiet"
    ? "transparent"
    : (root.variant === "outlined"
      ? Colors.outline
      : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15))
  border.width: 1

  Behavior on color {
    ColorAnimation { duration: Config.animationDuration }
  }

  Keys.onPressed: function(event) {
    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.activated()
      event.accepted = true
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: root.labelText !== "" ? Config.spacingCompact : 0

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.iconLabel
      color: root.iconColor
      font.family: Config.iconFont
      font.pixelSize: root.iconSize
    }

    Text {
      visible: root.labelText !== ""
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.labelText
      color: root.iconColor
      font.family: Config.fontFamily
      font.pixelSize: Config.fontPixelSize
      font.weight: Font.Medium
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.forceActiveFocus()
      root.activated()
    }
  }

}
