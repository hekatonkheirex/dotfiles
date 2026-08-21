import QtQuick
import "../../../config"
import "."

Item {
  id: root

  ThemeTokens { id: theme }

  property bool checked: false
  property color activeColor: theme.accent
  property color activeContentColor: theme.accentText
  property color checkmarkColor: activeColor
  property color surfaceContainerHigh: theme.surfaceRaised
  property color surfaceContainerHighest: theme.controlSurface
  property color outline: theme.outline
  property color focusColor: theme.focus
  property color hoverOverlay: Colors.hoverOverlay
  property color pressOverlay: Colors.pressOverlay
  property int motionDuration: 150
  property bool reducedMotion: false
  property string accessibleName: "Switch"
  property string accessibleDescription: "Toggle setting"

  Accessible.role: Accessible.CheckBox
  Accessible.name: root.accessibleName
  Accessible.description: root.accessibleDescription + (root.checked ? " On" : " Off")
  Accessible.checkable: true
  Accessible.checked: root.checked
  Accessible.focusable: true
  Accessible.focused: root.activeFocus

  signal toggled()

  width: 52
  height: 28
  activeFocusOnTab: true

  readonly property bool hovered: switchMouse.containsMouse
  readonly property bool pressed: switchMouse.pressed
  readonly property bool active: root.hovered || root.pressed || root.activeFocus
  readonly property real targetX: root.checked ? root.width - 20 : 6
  property real thumbX: 6

  function animateDuration(base) {
    return root.reducedMotion ? 0 : Math.max(0, root.motionDuration || base)
  }

  function activate() {
    if (root.enabled) root.toggled()
  }

  Behavior on thumbX {
    NumberAnimation { duration: root.animateDuration(150); easing.type: Easing.OutCubic }
  }

  Component.onCompleted: thumbX = targetX
  onTargetXChanged: thumbX = targetX

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      activate()
      event.accepted = true
    }
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: -4
    radius: theme.controlRadius + 4
    color: root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    border.width: root.activeFocus ? theme.focusBorderWidth : 0
    border.color: root.focusColor
    visible: root.activeFocus
  }

  Rectangle {
    id: track
    anchors.fill: parent
    radius: theme.controlRadius
    color: root.enabled
      ? Qt.tint(root.checked ? root.activeColor : root.surfaceContainerHighest, root.pressed ? root.pressOverlay : Qt.rgba(0, 0, 0, 0))
      : root.surfaceContainerHighest
    border.width: theme.borderWidth
    border.color: root.outline
    opacity: root.enabled ? 1 : 0.55

    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }
  }

  Rectangle {
    id: knob
    x: root.thumbX
    y: parent.height / 2 - height / 2
    width: 14
    height: 14
    radius: theme.controlSmallRadius
    color: root.enabled
      ? (root.checked ? root.activeContentColor : root.outline)
      : root.outline

    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }
  }

  MouseArea {
    id: switchMouse
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activate()
  }
}
