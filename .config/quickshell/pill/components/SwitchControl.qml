import QtQuick
import "../config"

Item {
  id: root

  property bool checked: false
  property color activeColor: Colors.primary
  property color activeContentColor: Colors.fgPrimary
  // Compatibility name retained for existing callers. Contrasts against the
  // knob (which is filled with activeContentColor when checked), not against it.
  property color checkmarkColor: activeColor
  property color surfaceContainerHigh: Colors.surfaceContainerHigh
  property color surfaceContainerHighest: Colors.surfaceContainerHighest
  property color outline: Colors.outline
  property color focusColor: activeColor
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

  signal toggled()

  width: 52
  height: 32
  activeFocusOnTab: true

  readonly property bool hovered: switchMouse.containsMouse
  readonly property bool pressed: switchMouse.pressed
  readonly property bool active: hovered || pressed || activeFocus
  readonly property real targetThumbSize: pressed ? 28 : (checked ? 24 : 16)
  readonly property real targetX: checked
    ? (pressed ? width - 28 - 2 : width - 24 - 4)
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
    anchors.fill: parent
    anchors.margins: -4
    radius: height / 2 + 4
    color: root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
    border.width: root.activeFocus ? 2 : 0
    border.color: root.focusColor
    visible: root.activeFocus
  }

  Rectangle {
    id: track
    anchors.fill: parent
    radius: height / 2
    color: root.enabled
      ? Qt.tint(root.checked ? root.activeColor : root.surfaceContainerHighest, root.stateOverlay)
      : root.surfaceContainerHighest
    border.width: root.checked || !root.enabled ? 0 : 2
    border.color: root.outline
    opacity: root.enabled ? 1 : 0.55

    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }
  }

  Rectangle {
    id: knob
    x: root.thumbX
    y: parent.height / 2 - height / 2
    width: root.thumbSize
    height: root.thumbSize
    radius: width / 2
    color: root.enabled
      ? Qt.tint(root.checked ? root.activeContentColor : root.outline, root.stateOverlay)
      : root.outline

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
