import QtQuick
import "../../config"

// Animated indeterminate progress feedback. Keep this component reserved for
// real work in progress; it is not a decorative background animation.
Item {
  id: root

  property int size: 32
  property bool contained: false
  property bool running: true
  property color indicatorColor: root.material3Style
    ? Colors.primary
    : (Config.nothingDesign || Config.ghostTheme ? Colors.styleAccent : Colors.primary)
  property color containerColor: root.material3Style
    ? Colors.primaryContainer
    : (Config.neoBrutalism ? Colors.styleSurface : Colors.styleControl)
  property string accessibleName: "Loading"
  property string accessibleDescription: "Work in progress"
  readonly property bool material3Style: !Config.nothingDesign
    && !Config.neoBrutalism
    && !Config.ghostTheme

  implicitWidth: root.size
  implicitHeight: root.size
  width: root.size
  height: root.size

  Accessible.role: Accessible.ProgressBar
  Accessible.name: root.accessibleName
  Accessible.description: root.accessibleDescription
  Accessible.focusable: false

  Rectangle {
    anchors.fill: parent
    visible: root.contained && root.running
    radius: width / 2
    color: root.containerColor
  }

  Item {
    id: indicatorShape
    width: root.size * (root.contained ? 0.62 : 0.72)
    height: width
    anchors.centerIn: parent
    visible: root.running

    ExpressiveShape {
      anchors.fill: parent
      visible: root.material3Style
      fillColor: root.indicatorColor
      shape: "softBurst"
      targetMorphProgress: root.running ? 1.0 : 0.0
    }

    Item {
      id: classicIndicatorShape
      anchors.fill: parent
      visible: !root.material3Style

      Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.58
        height: width
        radius: width * 0.36
        color: root.indicatorColor
      }

      Repeater {
        model: 4

        delegate: Rectangle {
          width: indicatorShape.width * 0.42
          height: width
          x: indicatorShape.width / 2 - width / 2
            + Math.cos(index * Math.PI / 2) * indicatorShape.width * 0.16
          y: indicatorShape.height / 2 - height / 2
            + Math.sin(index * Math.PI / 2) * indicatorShape.height * 0.16
          radius: width * 0.38
          color: root.indicatorColor
        }
      }
    }

    RotationAnimation on rotation {
      running: root.running && !Config.reducedMotion
      from: 0
      to: 360
      duration: Math.max(1, Config.motionExtraLong * 3)
      loops: Animation.Infinite
    }
  }
}
