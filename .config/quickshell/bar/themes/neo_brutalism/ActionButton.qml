import QtQuick
import QtQuick.Controls
import "../../../config"
import "."

Item {
  id: root

  ThemeTokens { id: theme }

  property string iconLabel: ""
  property bool selected: false
  property string labelText: ""
  property string variant: "tonal"
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""
  readonly property bool filled: root.selected || root.variant === "filled"
  property real iconSize: Config.iconSize + 4
  property color iconColor: root.filled ? theme.accentText : theme.mutedInk
  property real radius: theme.controlRadius
  property color color: {
    var overlay = mouseArea.pressed ? Colors.pressOverlay
      : (mouseArea.containsMouse ? Colors.hoverOverlay
        : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
    var base = root.filled
      ? theme.accent
      : (root.variant === "quiet" ? theme.surface : theme.surfaceRaised)
    return Qt.tint(base, overlay)
  }
  property color borderColor: theme.outline
  property real borderWidth: theme.borderWidth

  signal activated()

  activeFocusOnTab: true
  opacity: root.enabled ? 1.0 : 0.38

  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed
  readonly property real contentIconSize: root.labelText !== ""
    ? Math.max(16, root.iconSize - 3)
    : root.iconSize

  Accessible.role: Accessible.Button
  Accessible.name: root.accessibleName !== ""
    ? root.accessibleName
    : (root.labelText !== "" ? root.labelText : (root.tooltipText !== "" ? root.tooltipText : root.iconLabel))
  Accessible.description: root.accessibleDescription !== ""
    ? root.accessibleDescription
    : (root.selected ? "Selected" : "")

  Rectangle {
    id: shadow
    x: theme.shadowOffset
    y: theme.shadowOffset
    width: Math.max(0, root.width - theme.shadowOffset)
    height: Math.max(0, root.height - theme.shadowOffset)
    radius: root.radius
    color: theme.shadow
    visible: root.enabled
    z: -1
  }

  Rectangle {
    id: surface
    width: Math.max(0, root.width - theme.shadowOffset)
    height: Math.max(0, root.height - theme.shadowOffset)
    anchors.left: parent.left
    anchors.top: parent.top
    radius: root.radius
    color: root.color
    border.color: root.borderColor
    border.width: root.borderWidth
  }

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
    anchors.horizontalCenter: surface.horizontalCenter
    anchors.verticalCenter: surface.verticalCenter
    anchors.verticalCenterOffset: theme.contentVerticalOffset
    spacing: root.labelText !== "" ? Config.spacingCompact : 0

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.iconLabel
      color: root.iconColor
      font.family: Config.iconFont
      font.pixelSize: root.contentIconSize
    }

    Text {
      visible: root.labelText !== ""
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.labelText
      color: root.iconColor
      font.family: theme.fontFamily
      font.pixelSize: Config.fontPixelSize
      font.weight: Font.DemiBold
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
