import QtQuick
import "../../../config"
import "."
import "../../primitives"

Item {
  id: root

  ThemeTokens { id: theme }

  // Liquid Glass shares the Material 3 control's interaction and accessibility
  // behavior, but uses the compact macOS switch geometry and flat neutral
  // thumb.
  property bool liquidGlass: false
  property bool checked: false
  property color activeColor: theme.primary
  property color activeContentColor: Colors.fgPrimary
  property color checkmarkColor: activeColor
  property color surfaceContainerHigh: theme.surfaceContainerHigh
  property color surfaceContainerHighest: theme.surfaceContainerHighest
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
  readonly property real liquidTrackWidth: Math.min(38, root.width)
  readonly property real liquidTrackHeight: Math.min(22, root.height)
  readonly property real liquidTrackX: (root.width - root.liquidTrackWidth) / 2
  readonly property real liquidTrackY: (root.height - root.liquidTrackHeight) / 2
  readonly property real liquidThumbInset: 1
  readonly property real targetThumbSize: root.liquidGlass
    ? (pressed ? 22 : 20)
    : (pressed ? 28 : (checked ? 24 : 16))
  readonly property real targetX: root.liquidGlass
    ? (checked
      ? root.liquidTrackX + root.liquidTrackWidth - root.targetThumbSize - root.liquidThumbInset
      : root.liquidTrackX + root.liquidThumbInset)
    : (checked
      ? (pressed ? width - 28 - 2 : width - 24 - 4)
      : (pressed ? 2 : 8))

  property real thumbSize: root.liquidGlass ? 20 : 16
  property real thumbX: root.liquidGlass ? root.targetX : 8

  function animateDuration(base) {
    return root.reducedMotion ? 0 : Math.max(0, root.motionDuration || base)
  }

  function activate() {
    if (root.enabled) root.toggled()
  }

  Behavior on thumbSize {
    enabled: Config.spatialMotion && !root.reducedMotion
    SpringAnimation {
      spring: Config.motionSpatialSpring
      damping: Config.motionSpatialDamping
      mass: Config.motionSpatialMass
      epsilon: Config.motionSpatialEpsilon
    }
  }
  Behavior on thumbX {
    enabled: Config.spatialMotion && !root.reducedMotion
    SpringAnimation {
      spring: Config.motionSpatialSpring
      damping: Config.motionSpatialDamping
      mass: Config.motionSpatialMass
      epsilon: Config.motionSpatialEpsilon
    }
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
    border.width: root.activeFocus ? theme.focusBorderWidth : 0
    border.color: root.focusColor
    visible: root.activeFocus
  }

  Rectangle {
    id: track
    x: root.liquidGlass ? root.liquidTrackX : 0
    y: root.liquidGlass ? root.liquidTrackY : 0
    width: root.liquidGlass ? root.liquidTrackWidth : root.width
    height: root.liquidGlass ? root.liquidTrackHeight : root.height
    radius: height / 2
    color: root.enabled
      ? Qt.tint(root.checked
        ? root.activeColor
        : (root.liquidGlass ? Colors.liquidGlassControlTrack : root.surfaceContainerHighest),
        root.stateOverlay)
      : (root.liquidGlass ? Colors.liquidGlassControlTrack : root.surfaceContainerHighest)
    border.width: root.liquidGlass
      ? 0
      : (root.checked || !root.enabled ? 0 : theme.focusBorderWidth)
    border.color: root.liquidGlass ? Colors.liquidGlassEdge : root.outline
    opacity: root.enabled ? 1 : 0.55

    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }
  }

  Rectangle {
    id: knobShadow
    x: root.thumbX + (root.liquidGlass ? 1 : 0)
    y: parent.height / 2 - height / 2 + (root.liquidGlass ? 1 : 0)
    width: root.thumbSize
    height: root.thumbSize
    radius: width / 2
    color: Colors.liquidGlassShadow
    visible: root.liquidGlass && root.enabled
  }

  Rectangle {
    id: knob
    x: root.thumbX
    y: parent.height / 2 - height / 2
    width: root.thumbSize
    height: root.thumbSize
    radius: width / 2
    color: root.enabled
      ? (root.liquidGlass
        ? Qt.tint(Colors.liquidGlassControlThumb, root.stateOverlay)
        : Qt.tint(root.checked ? root.activeContentColor : root.outline, root.stateOverlay))
      : root.outline
    border.width: root.liquidGlass && root.activeFocus ? theme.focusBorderWidth : 0
    border.color: root.focusColor

    Behavior on color { ColorAnimation { duration: root.animateDuration(150) } }

    IconGlyph {
      anchors.centerIn: parent
      iconLabel: "check"
      iconSize: 16
      iconColor: root.checked ? root.checkmarkColor : "transparent"
      iconOpacity: root.checked && !root.liquidGlass ? 1 : 0
      filled: true
      visible: root.checked && !root.liquidGlass
      Behavior on iconOpacity { NumberAnimation { duration: root.animateDuration(150) } }
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
