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

  Rectangle {
    id: track
    anchors {
      left: parent.left
      right: parent.right
      verticalCenter: parent.verticalCenter
    }
    height: 6
    radius: 3
    color: root.surfaceContainerHighest

    Rectangle {
      anchors {
        left: parent.left
        top: parent.top
        bottom: parent.bottom
      }
      width: parent.width * root.value
      radius: 3
      color: root.muted ? root.outline : root.activeColor
    }
  }

  Rectangle {
    id: knob
    x: track.x + track.width * root.value - width / 2
    y: parent.height / 2 - height / 2
    width: 20
    height: 20
    radius: 10
    color: root.muted ? root.outline : root.activeColor
    border.width: 2
    border.color: root.surfaceContainerHigh
  }

  MouseArea {
    anchors.fill: parent
    onPressed: function(mouse) { handleMouse(mouse.x) }
    onPositionChanged: function(mouse) { handleMouse(mouse.x) }
    function handleMouse(mx) {
      var ratio = Math.max(0, Math.min(1, mx / parent.width))
      root.changed(ratio)
    }
  }
}
