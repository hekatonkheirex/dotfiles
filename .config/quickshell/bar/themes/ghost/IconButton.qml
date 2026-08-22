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
  property color backgroundColor: "transparent"
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
  Accessible.focusable: root.enabled
  Accessible.focused: root.activeFocus

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: !root.enabled ? "transparent"
      : root.selected ? theme.accent
      : (mouseArea.pressed ? root.pressColor
        : (mouseArea.containsMouse ? root.hoverColor
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
    radius: 0
    color: "transparent"
    border.width: root.activeFocus ? theme.focusBorderWidth : 0
    border.color: theme.accent
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
  }

  Keys.onPressed: function(event) {
    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.clicked(null)
      event.accepted = true
    }
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
