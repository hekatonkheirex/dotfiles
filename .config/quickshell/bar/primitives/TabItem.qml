// Icon + label tab with an underline indicator and hover/press overlay. Lifted
// out of the Settings panel's tab-bar Repeater
// delegate so future tab strips (e.g. a settings sub-nav) don't reinvent it.
import QtQuick
import "../../config"

Item {
  id: root

  property string iconLabel: ""
  property string labelText: ""
  property bool selected: false
  property real iconSize: 28
  property real labelSize: 13
  property real indicatorWidth: 48
  property bool tabFocusable: true
  property string accessibleName: ""
  property string accessibleDescription: ""

  signal clicked()

  activeFocusOnTab: root.tabFocusable && root.enabled
  opacity: root.enabled ? 1.0 : 0.38
  readonly property bool hovered: tabMouse.containsMouse
  readonly property bool pressed: tabMouse.pressed

  Accessible.role: Accessible.PageTab
  Accessible.name: root.accessibleName !== "" ? root.accessibleName : root.labelText
  Accessible.description: root.accessibleDescription !== ""
    ? root.accessibleDescription
    : (root.selected ? "Selected tab" : "")

  Keys.onPressed: function(event) {
    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
      root.clicked()
      event.accepted = true
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: 4

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.iconLabel
      font.family: Config.iconFont
      font.pixelSize: root.iconSize
      color: root.selected ? Colors.primary : Colors.fgSurfaceVariant

      Behavior on color { ColorAnimation { duration: Config.motionMedium } }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.labelText
      font.family: Config.fontFamily
      font.pixelSize: root.labelSize
      font.weight: Font.Medium
      color: root.selected ? Colors.primary : Colors.fgSurfaceVariant

      Behavior on color { ColorAnimation { duration: Config.motionMedium } }
    }
  }

  // Active indicator line below the text
  Rectangle {
    width: root.indicatorWidth
    height: 3
    radius: 1.5
    color: Colors.primary
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    visible: root.selected
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: Config.shapeMedium
    color: tabMouse.pressed ? Colors.pressOverlay
      : (tabMouse.containsMouse ? Colors.hoverOverlay : "transparent")
    enabled: false
  }

  MouseArea {
    id: tabMouse
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.forceActiveFocus()
      root.clicked()
    }
  }

}
