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
  readonly property color stateOverlay: root.pressed
    ? root.pressOverlay
    : (root.hovered || root.activeFocus ? root.hoverOverlay : Qt.rgba(0, 0, 0, 0))
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
  height: 32
  activeFocusOnTab: true

  readonly property bool hovered: switchMouse.containsMouse
  readonly property bool pressed: switchMouse.pressed
  readonly property bool active: hovered || pressed || activeFocus
  readonly property real visualWidth: Math.max(0, root.width - theme.shadowOffset)
  readonly property real visualHeight: Math.max(0, root.height - theme.shadowOffset)
  readonly property real targetThumbSize: pressed ? 28 : (checked ? 24 : 16)
  readonly property real targetX: checked
    ? (pressed ? visualWidth - 28 - 2 : visualWidth - 24 - 4)
    : (pressed ? 2 : 8)

  property real thumbSize: 16
  property real thumbX: 8

  function animateDuration(base) {
    return root.reducedMotion ? 0 : Math.max(0, root.motionDuration || base)
  }

  function activate() {
    if (root.enabled) root.toggled()
  }

  Behavior on thumbSize {
    NumberAnimation { duration: root.animateDuration(150); easing.type: Easing.OutBack }
  }
  Behavior on thumbX {
    NumberAnimation { duration: root.animateDuration(150); easing.type: Easing.OutBack }
  }

  Component.onCompleted: {
    thumbSize = targetThumbSize
    thumbX = targetX
  }

  onTargetThumbSizeChanged: thumbSize = targetThumbSize
  onTargetXChanged: thumbX = targetX

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      activate()
      event.accepted = true
    }
  }

  Rectangle {
    id: shadow
    x: theme.shadowOffset
    y: theme.shadowOffset
    width: root.visualWidth
    height: root.visualHeight
    radius: theme.controlRadius
    color: theme.shadow
    visible: root.enabled
    z: -1
  }

  Rectangle {
    id: focusRing
    x: -4
    y: -4
    width: root.visualWidth + 8
    height: root.visualHeight + 8
    radius: theme.controlRadius + 4
    color: root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    border.width: root.activeFocus ? theme.focusBorderWidth : 0
    border.color: root.focusColor
    visible: root.activeFocus
  }

  Rectangle {
    id: track
    width: root.visualWidth
    height: root.visualHeight
    radius: theme.controlRadius
    color: root.enabled
      ? Qt.tint(root.checked ? root.activeColor : root.surfaceContainerHighest, root.stateOverlay)
      : root.surfaceContainerHighest
    border.width: theme.borderWidth
    border.color: theme.outline
    opacity: root.enabled ? 1 : 0.55

    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }
  }

  Rectangle {
    id: knobShadow
    x: root.thumbX + theme.shadowOffset
    y: root.visualHeight / 2 - height / 2 + theme.shadowOffset
    width: root.thumbSize
    height: root.thumbSize
    radius: theme.controlSmallRadius
    color: theme.shadow
    visible: root.enabled
    z: -1
  }

  Rectangle {
    id: knob
    x: root.thumbX
    y: root.visualHeight / 2 - height / 2
    width: root.thumbSize
    height: root.thumbSize
    radius: theme.controlSmallRadius
    color: root.enabled
      ? Qt.tint(root.checked ? root.activeContentColor : root.outline, root.stateOverlay)
      : root.outline
    border.width: theme.borderWidth
    border.color: theme.outline

    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }

    Text {
      anchors.centerIn: parent
      text: "check"
      font.family: "Material Symbols Outlined"
      font.pixelSize: 16
      color: root.checked ? root.checkmarkColor : "transparent"
      visible: root.checked
      opacity: root.checked ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: root.animateDuration(150) } }
    }
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
