// Compact icon-only action button: circular hover/press overlay around a
// single icon glyph. For close/refresh/nav/media-style controls scattered
// across popups as duplicated Rectangle + Text + MouseArea blocks.
import QtQuick
import QtQuick.Controls
import "../../config"

Item {
  id: root

  property string iconLabel: ""
  property int size: 32
  property int iconSize: 18
  property color iconColor: Colors.fgSurface
  property color hoverColor: Qt.tint("transparent", Colors.hoverOverlay)
  property color pressColor: Qt.tint("transparent", Colors.pressOverlay)
  property color backgroundColor: "transparent"
  property color borderColor: Colors.outlineVariant
  property bool outlined: false
  property bool enabled: true
  property bool selected: false
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

  Keys.onPressed: function(event) {
    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.clicked(null)
      event.accepted = true
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: root.size / 2
    color: !root.enabled ? "transparent"
      : root.selected ? Qt.tint(Colors.primaryContainer, root.pressColor)
      : (mouseArea.pressed ? root.pressColor
        : (mouseArea.containsMouse ? root.hoverColor
          : (root.activeFocus ? Colors.focusOverlay : root.backgroundColor)))
    border.width: root.outlined ? 1 : 0
    border.color: root.borderColor

    Behavior on color {
      ColorAnimation { duration: Config.animationDuration }
    }
  }

  Text {
    anchors.centerIn: parent
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
