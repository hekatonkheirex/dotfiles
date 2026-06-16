import QtQuick

Item {
  id: root

  property real value: 0.5
  property bool muted: false
  property color activeColor: "#D0BCFF"
  property color surfaceContainerHigh: "#2B2930"
  property color surfaceContainerHighest: "#36343B"
  property color outline: "#938F99"

  signal changed(real value)

  width: parent.width
  height: 32

  readonly property bool active: sliderMouse.containsMouse || sliderMouse.pressed

  // State-driven size parameters matching Material 3 Expressive spec:
  readonly property real trackHeight: 16
  readonly property real trackRadius: trackHeight / 2
  readonly property real trackInsideRadius: 2

  // The thumb/handle is a very tall, thin vertical pill (4px width, 44px height).
  readonly property real targetThumbWidth: {
    if (sliderMouse.pressed) return 8;
    if (sliderMouse.containsMouse) return 6;
    return 4;
  }
  readonly property real targetThumbHeight: {
    if (sliderMouse.pressed) return 48;
    if (sliderMouse.containsMouse) return 46;
    return 44;
  }
  readonly property real targetGap: {
    if (sliderMouse.pressed) return 4;
    if (sliderMouse.containsMouse) return 5;
    return 6;
  }

  // Animated properties for smooth Material 3 Expressive spring-like motion:
  property real thumbWidth: 4
  property real thumbHeight: 44
  property real gap: 6

  Behavior on thumbWidth {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutBack
    }
  }
  Behavior on thumbHeight {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutBack
    }
  }
  Behavior on gap {
    NumberAnimation {
      duration: 150
      easing.type: Easing.OutBack
    }
  }

  // Align thumbWidth/thumbHeight/gap to their targets
  Component.onCompleted: {
    thumbWidth = targetThumbWidth
    thumbHeight = targetThumbHeight
    gap = targetGap
  }

  onTargetThumbWidthChanged: thumbWidth = targetThumbWidth
  onTargetThumbHeightChanged: thumbHeight = targetThumbHeight
  onTargetGapChanged: gap = targetGap

  // Horizontal position of the thumb center:
  // Constrained to remain within the track boundaries.
  readonly property real thumbCenter: thumbWidth / 2 + (width - thumbWidth) * value

  // Dynamic gaps that shrink to 0 as the thumb approaches the edges:
  readonly property real leftGap: Math.min(gap, thumbCenter - thumbWidth / 2)
  readonly property real rightGap: Math.min(gap, width - thumbCenter - thumbWidth / 2)

  // Active track (left side)
  Rectangle {
    id: activeTrack
    x: 0
    y: parent.height / 2 - height / 2
    width: Math.max(0, thumbCenter - thumbWidth / 2 - leftGap)
    height: root.trackHeight
    radius: root.trackRadius
    color: root.muted ? root.outline : root.activeColor

    // Inner corner overlay to set radius to 2
    Rectangle {
      anchors {
        top: parent.top
        bottom: parent.bottom
        right: parent.right
      }
      width: Math.min(parent.width, 8)
      radius: root.trackInsideRadius
      color: parent.color
    }
  }

  // Inactive track (right side)
  Rectangle {
    id: inactiveTrack
    x: thumbCenter + thumbWidth / 2 + rightGap
    y: parent.height / 2 - height / 2
    width: Math.max(0, parent.width - x)
    height: root.trackHeight
    radius: root.trackRadius
    color: root.surfaceContainerHighest

    // Inner corner overlay to set radius to 2
    Rectangle {
      anchors {
        top: parent.top
        bottom: parent.bottom
        left: parent.left
      }
      width: Math.min(parent.width, 8)
      radius: root.trackInsideRadius
      color: parent.color
    }

    // Small white dot at the right end of the track
    Rectangle {
      id: endDot
      anchors {
        right: parent.right
        rightMargin: 8
        verticalCenter: parent.verticalCenter
      }
      width: 4
      height: 4
      radius: 2
      color: root.muted ? root.outline : "#FFFFFF"
      visible: parent.width > 20
    }
  }

  // Thumb / Handle (very tall vertical pill)
  Rectangle {
    id: knob
    x: thumbCenter - width / 2
    y: parent.height / 2 - height / 2
    width: root.thumbWidth
    height: root.thumbHeight
    radius: width / 2
    color: root.muted ? root.outline : root.activeColor

    // Give it a subtle outline when pressed or hovered to stand out:
    border.width: root.active ? 1.5 : 0
    border.color: root.surfaceContainerHigh
  }

  MouseArea {
    id: sliderMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: function(mouse) { handleMouse(mouse.x) }
    onPositionChanged: function(mouse) { if (pressed) handleMouse(mouse.x) }
    function handleMouse(mx) {
      var ratio = Math.max(0, Math.min(1, mx / parent.width))
      root.changed(ratio)
    }
  }
}

