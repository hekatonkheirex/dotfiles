import QtQuick
import QtQuick.Controls
import "../../../config"
import "."

Item {
  id: root

  ThemeTokens { id: theme }

  property string iconLabel: ""
  property int size: 32
  property int iconSize: 18
  property color iconColor: theme.ink
  property color hoverColor: Qt.tint("transparent", Colors.hoverOverlay)
  property color pressColor: Qt.tint("transparent", Colors.pressOverlay)
  property color backgroundColor: theme.surface
  property color borderColor: theme.outline
  property bool outlined: false
  property bool selected: false
  property real radius: theme.controlSmallRadius
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""

  signal clicked(var mouse)
  signal wheel(var wheel)

  implicitWidth: size
  implicitHeight: size
  activeFocusOnTab: root.enabled
  opacity: root.enabled ? 1.0 : 0.38

  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed

  Accessible.role: Accessible.Button
  Accessible.name: root.accessibleName !== ""
    ? root.accessibleName
    : (root.tooltipText !== "" ? root.tooltipText : root.iconLabel)
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
    color: !root.enabled ? theme.surface
      : root.selected ? Qt.tint(theme.accent, root.pressColor)
      : (mouseArea.pressed ? root.pressColor
        : (mouseArea.containsMouse ? root.hoverColor
          : (root.activeFocus ? Colors.focusOverlay : root.backgroundColor)))
    border.width: theme.borderWidth
    border.color: root.borderColor

    Behavior on color {
      ColorAnimation { duration: Config.animationDuration }
    }
  }

  Text {
    anchors.centerIn: surface
    text: root.iconLabel
    color: root.iconColor
    opacity: root.enabled ? 1.0 : 0.38
    font.family: Config.iconFont
    font.pixelSize: root.iconSize
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.forceActiveFocus()
      root.clicked(mouse)
    }
    onWheel: function(wheelEvent) { root.wheel(wheelEvent) }
  }
}
