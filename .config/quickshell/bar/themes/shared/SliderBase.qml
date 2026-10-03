// Value, keyboard, and accessibility behaviour shared by every SliderControl
// implementation (material3/ and styled/). Implementations extend this and add
// colours, geometry, pointer handling, and visuals. They emit changed() through
// setValue(); adjustmentKey() fires before a keyboard adjustment so an
// implementation can show its focus ring.
import QtQuick
import "../../../config"

Item {
  id: root

  property real value: 0.5
  property bool muted: false
  property color hoverOverlay: Colors.hoverOverlay
  property color pressOverlay: Colors.pressOverlay
  property int motionDuration: 150
  property bool reducedMotion: false
  property real stepSize: 0.05
  property string accessibleName: "Slider"
  property string accessibleDescription: "Adjust value"
  property real accessibleMinimumValue: 0
  property real accessibleMaximumValue: 100
  property string accessibleUnit: "%"

  Accessible.role: Accessible.Slider
  Accessible.name: root.accessibleName
  Accessible.description: root.accessibleDescription
    + " Current value " + Math.round(root.accessibleMinimumValue
      + root.value * (root.accessibleMaximumValue - root.accessibleMinimumValue))
    + (root.accessibleUnit !== "" ? " " + root.accessibleUnit : "")
    + ". Range " + root.accessibleMinimumValue + " to " + root.accessibleMaximumValue
    + (root.accessibleUnit !== "" ? " " + root.accessibleUnit : "")
  Accessible.focusable: true
  Accessible.focused: root.activeFocus

  signal changed(real value)
  signal interactionFinished()
  signal adjustmentKey()

  width: parent ? parent.width : 240
  activeFocusOnTab: true

  function animateDuration(base) {
    return root.reducedMotion ? 0 : Math.max(0, root.motionDuration || base)
  }

  function setValue(nextValue) {
    root.changed(Math.max(0, Math.min(1, nextValue)))
  }

  function isAdjustmentKey(key) {
    return key === Qt.Key_PageUp || key === Qt.Key_PageDown
      || key === Qt.Key_Left || key === Qt.Key_Right
      || key === Qt.Key_Up || key === Qt.Key_Down
      || key === Qt.Key_Home || key === Qt.Key_End
  }

  Keys.onPressed: function(event) {
    if (!root.isAdjustmentKey(event.key)) return

    root.adjustmentKey()
    var delta = root.stepSize
    if (event.key === Qt.Key_PageUp) delta *= 5
    if (event.key === Qt.Key_PageDown) delta *= -5
    if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) delta *= -1
    if (event.key === Qt.Key_Home) root.setValue(0)
    else if (event.key === Qt.Key_End) root.setValue(1)
    else root.setValue(root.value + delta)
    event.accepted = true
  }

  Keys.onReleased: function(event) {
    if (root.isAdjustmentKey(event.key)) root.interactionFinished()
  }
}
