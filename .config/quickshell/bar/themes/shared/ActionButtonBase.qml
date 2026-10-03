// Input, focus, and accessibility behaviour shared by every ActionButton
// implementation (material3/ and styled/). Implementations extend this, supply
// horizontalContent, Accessible.description, colours, and visuals, and read
// root.hovered / root.pressed for pointer state.
import QtQuick
import "../../../config"

Item {
  id: root

  property string iconLabel: ""
  property bool selected: false
  property bool checkable: false
  property bool grouped: false
  property string groupPosition: "single"
  property string labelText: ""
  property string variant: "tonal"
  property string accessibleName: ""
  property string accessibleDescription: ""
  property string tooltipText: ""
  property bool expressiveSelectedShape: false
  readonly property bool filled: root.selected || root.variant === "filled"
  property real iconSize: Config.iconSize + 4
  property real contentSpacing: Config.spacingMedium

  signal activated()

  activeFocusOnTab: true
  opacity: root.enabled ? 1.0 : 0.38

  readonly property bool hovered: mouseArea.containsMouse
  readonly property bool pressed: mouseArea.pressed

  Accessible.role: root.grouped && root.checkable
    ? Accessible.RadioButton
    : (root.checkable ? Accessible.CheckBox : Accessible.Button)
  Accessible.checkable: root.checkable
  Accessible.checked: root.checkable && root.selected
  Accessible.name: root.accessibleName !== ""
    ? root.accessibleName
    : (root.labelText !== "" ? root.labelText : (root.tooltipText !== "" ? root.tooltipText : root.iconLabel))

  Keys.onPressed: function(event) {
    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.activated()
      event.accepted = true
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
