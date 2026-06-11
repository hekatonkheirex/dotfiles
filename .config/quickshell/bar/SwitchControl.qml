import QtQuick

Item {
  id: root

  property bool checked: false
  property color activeColor: "#D0BCFF"
  property color surfaceContainerHigh: "#2B2930"
  property color surfaceContainerHighest: "#36343B"
  property color outline: "#938F99"
  property color checkmarkColor: activeColor

  signal toggled()

  width: 52
  height: 32

  readonly property bool active: switchMouse.containsMouse || switchMouse.pressed

  // State-driven sizes matching Material 3 Switch spec:
  readonly property real targetThumbSize: {
    if (switchMouse.pressed) return 28;
    if (checked) return 24;
    return 16;
  }

  readonly property real targetX: {
    if (checked) {
      return switchMouse.pressed ? (width - 28 - 2) : (width - 24 - 4);
    } else {
      return switchMouse.pressed ? 2 : 8;
    }
  }

  property real thumbSize: 16
  property real thumbX: 8

  Behavior on thumbSize {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutBack
    }
  }

  Behavior on thumbX {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutBack
    }
  }

  Component.onCompleted: {
    thumbSize = targetThumbSize
    thumbX = targetX
  }

  onTargetThumbSizeChanged: thumbSize = targetThumbSize
  onTargetXChanged: thumbX = targetX

  // Track (pill shape)
  Rectangle {
    id: track
    anchors.fill: parent
    radius: height / 2
    color: root.checked ? root.activeColor : root.surfaceContainerHighest
    border.width: root.checked ? 0 : 2
    border.color: root.outline

    Behavior on color {
      ColorAnimation { duration: 150 }
    }
  }

  // Thumb / Handle (circle)
  Rectangle {
    id: knob
    x: root.thumbX
    y: parent.height / 2 - height / 2
    width: root.thumbSize
    height: root.thumbSize
    radius: width / 2
    color: root.checked ? "#FFFFFF" : root.outline

    Behavior on color {
      ColorAnimation { duration: 150 }
    }

    // Centered checkmark icon for Checked state
    Text {
      anchors.centerIn: parent
      text: "✓"
      font.pixelSize: 14
      font.bold: true
      color: root.checkmarkColor
      visible: root.checked

      opacity: root.checked ? 1.0 : 0.0
      Behavior on opacity {
        NumberAnimation { duration: 150 }
      }
    }
  }

  MouseArea {
    id: switchMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}
