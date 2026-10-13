import QtQuick
import Quickshell
import "../../config"

// One dock tile in the reference's style: app icon on a squircle, a dot under
// running apps, a wide bar under the focused one, nothing for pinned-but-closed.
Item {
  id: root

  property string appId: ""
  property bool running: false
  property bool focused: false
  property bool urgent: false
  property bool active: true
  property color accent: Colors.primary

  readonly property int tileSize: 50
  readonly property int indicatorHeight: 7
  readonly property int itemMargin: 8
  readonly property int indicatorGap: 8

  property real wheelAccum: 0

  signal activated()
  signal closeRequested()
  signal cycled(int direction)

  // Reading applications.values.length makes this re-run when the desktop-entry
  // database finishes loading, not only when appId changes.
  readonly property var entry: DesktopEntries.applications.values.length >= 0
    ? DesktopEntries.heuristicLookup(root.appId) : null
  readonly property string iconSource: root.entry && root.entry.icon !== ""
    ? Quickshell.iconPath(root.entry.icon, true) : ""
  readonly property color indicatorColor: root.urgent ? Colors.error : root.accent

  implicitWidth: root.tileSize + root.itemMargin * 2
  implicitHeight: root.tileSize + root.indicatorGap + root.indicatorHeight

  Rectangle {
    id: tile
    x: root.itemMargin
    width: root.tileSize
    height: root.tileSize
    radius: Config.shapeLarge
    color: Colors.surfaceContainer

    Image {
      id: icon
      anchors.centerIn: parent
      width: 32
      height: 32
      sourceSize: Qt.size(64, 64)
      source: root.iconSource
      visible: status === Image.Ready
    }
    Text {
      anchors.centerIn: parent
      visible: !icon.visible
      text: root.appId.length > 0 ? root.appId.charAt(0).toUpperCase() : "?"
      color: root.accent
      font.family: Config.fontFamily
      font.pixelSize: 22
      font.weight: Font.Medium
    }
  }

  // Indicator row.
  Item {
    x: root.itemMargin
    y: root.tileSize + root.indicatorGap
    width: root.tileSize
    height: root.indicatorHeight

    Rectangle {          // running, not focused: dot
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.indicatorHeight
      height: root.indicatorHeight
      radius: width / 2
      color: root.indicatorColor
      visible: root.running && !root.focused
      opacity: pulse.opacity
    }
    Rectangle {          // focused: wide bar
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.tileSize - root.itemMargin * 2
      height: root.indicatorHeight
      radius: height / 2
      color: root.indicatorColor
      visible: root.focused
      opacity: pulse.opacity
    }
  }

  // Urgent indicators pulse unless motion is reduced.
  QtObject {
    id: pulse
    property real opacity: 1.0
  }
  SequentialAnimation {
    running: root.urgent && root.active && !Config.reducedMotion
    loops: Animation.Infinite
    onStopped: pulse.opacity = 1.0
    NumberAnimation { target: pulse; property: "opacity"; to: 0.35; duration: 600 }
    NumberAnimation { target: pulse; property: "opacity"; to: 1.0; duration: 600 }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) root.closeRequested()
      else root.activated()
    }
    onWheel: function(wheel) {
      const dy = wheel.angleDelta.y
      if (dy === 0) return
      // Reset on direction flip; one cycle per full 120 notch, so a touchpad
      // swipe of many small deltas does not skip through every window.
      if ((dy > 0) !== (root.wheelAccum > 0)) root.wheelAccum = 0
      root.wheelAccum += dy
      while (Math.abs(root.wheelAccum) >= 120) {
        const dir = root.wheelAccum > 0 ? -1 : 1
        root.wheelAccum -= root.wheelAccum > 0 ? 120 : -120
        root.cycled(dir)
      }
    }
  }
}
