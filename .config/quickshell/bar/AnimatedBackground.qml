import QtQuick
import "../config"

Item {
  id: bgContainer
  clip: true

  property bool running: true
  property bool transparentBg: false
  property bool flatMode: false
  property color flatColor: Colors.bg

  readonly property color bgColor: Colors.bg
  readonly property color primaryContainerColor: Colors.primaryContainer
  readonly property color secondaryContainerColor: Colors.secondaryContainer
  readonly property color primaryColor: Colors.primary
  readonly property bool isDark: Colors.darkMode

  // Solid base layer
  Rectangle {
    anchors.fill: parent
    color: bgContainer.transparentBg
      ? "transparent"
      : (bgContainer.flatMode ? bgContainer.flatColor : bgContainer.bgColor)
    Behavior on color { ColorAnimation { duration: Config.motionLong } }
  }

  // Floating Blob 1
  Rectangle {
    id: blob1
    width: Math.min(parent.width, parent.height) * 0.65
    height: width
    radius: width / 2
    color: bgContainer.primaryContainerColor
    opacity: bgContainer.isDark ? 0.35 : 0.45
    visible: !bgContainer.flatMode
    Behavior on color { ColorAnimation { duration: Config.motionLong } }

    SequentialAnimation on x {
      loops: Animation.Infinite
      running: bgContainer.running && !bgContainer.flatMode && !Config.reducedMotion
      NumberAnimation { from: -100; to: bgContainer.width - blob1.width + 100; duration: 35000; easing.type: Easing.InOutSine }
      NumberAnimation { to: -100; duration: 35000; easing.type: Easing.InOutSine }
    }
    SequentialAnimation on y {
      loops: Animation.Infinite
      running: bgContainer.running && !bgContainer.flatMode && !Config.reducedMotion
      NumberAnimation { from: -100; to: bgContainer.height - blob1.height + 100; duration: 27000; easing.type: Easing.InOutSine }
      NumberAnimation { to: -100; duration: 27000; easing.type: Easing.InOutSine }
    }
  }

  // Floating Blob 2
  Rectangle {
    id: blob2
    width: Math.min(parent.width, parent.height) * 0.55
    height: width
    radius: width / 2
    color: bgContainer.secondaryContainerColor
    opacity: bgContainer.isDark ? 0.30 : 0.40
    visible: !bgContainer.flatMode
    Behavior on color { ColorAnimation { duration: Config.motionLong } }

    SequentialAnimation on x {
      loops: Animation.Infinite
      running: bgContainer.running && !bgContainer.flatMode && !Config.reducedMotion
      NumberAnimation { from: bgContainer.width - blob2.width + 100; to: -100; duration: 39000; easing.type: Easing.InOutSine }
      NumberAnimation { to: bgContainer.width - blob2.width + 100; duration: 39000; easing.type: Easing.InOutSine }
    }
    SequentialAnimation on y {
      loops: Animation.Infinite
      running: bgContainer.running && !bgContainer.flatMode && !Config.reducedMotion
      NumberAnimation { from: -100; to: bgContainer.height - blob2.height + 100; duration: 31000; easing.type: Easing.InOutSine }
      NumberAnimation { to: -100; duration: 31000; easing.type: Easing.InOutSine }
    }
  }

  // Floating Blob 3
  Rectangle {
    id: blob3
    width: Math.min(parent.width, parent.height) * 0.45
    height: width
    radius: width / 2
    color: bgContainer.primaryColor
    opacity: bgContainer.isDark ? 0.15 : 0.25
    visible: !bgContainer.flatMode
    Behavior on color { ColorAnimation { duration: Config.motionLong } }

    SequentialAnimation on x {
      loops: Animation.Infinite
      running: bgContainer.running && !bgContainer.flatMode && !Config.reducedMotion
      NumberAnimation { from: bgContainer.width / 4; to: bgContainer.width * 3/4; duration: 45000; easing.type: Easing.InOutSine }
      NumberAnimation { to: bgContainer.width / 4; duration: 45000; easing.type: Easing.InOutSine }
    }
    SequentialAnimation on y {
      loops: Animation.Infinite
      running: bgContainer.running && !bgContainer.flatMode && !Config.reducedMotion
      NumberAnimation { from: bgContainer.height * 3/4; to: bgContainer.height / 4; duration: 37000; easing.type: Easing.InOutSine }
      NumberAnimation { to: bgContainer.height * 3/4; duration: 37000; easing.type: Easing.InOutSine }
    }
  }
}
