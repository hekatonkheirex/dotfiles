import QtQuick

// Small, font-independent Pacman marker for the workspace indicator. Drawing
// the glyph keeps this option available even when a Nerd Font is not installed.
Item {
  id: marker

  property bool focused: false
  property bool occupied: false
  property bool hovered: false
  property color markerColor: "white"

  implicitWidth: 24
  implicitHeight: 24
  scale: hovered ? 1.08 : 1.0

  onFocusedChanged: pacmanCanvas.requestPaint()
  onOccupiedChanged: pacmanCanvas.requestPaint()
  onHoveredChanged: pacmanCanvas.requestPaint()
  onMarkerColorChanged: pacmanCanvas.requestPaint()
  onWidthChanged: pacmanCanvas.requestPaint()
  onHeightChanged: pacmanCanvas.requestPaint()

  Behavior on scale {
    NumberAnimation {
      duration: 120
      easing.type: Easing.OutCubic
    }
  }

  Canvas {
    id: pacmanCanvas
    anchors.fill: parent
    antialiasing: true

    onPaint: {
      var context = getContext("2d")
      context.reset()

      var centerX = width / 2
      var centerY = height / 2
      var radius = Math.max(1, Math.min(width, height) * 0.34)
      context.fillStyle = String(marker.markerColor)
      context.globalAlpha = marker.hovered ? 1.0 : (marker.focused ? 1.0 : (marker.occupied ? 0.78 : 0.34))

      context.beginPath()
      if (marker.focused) {
        var mouth = 0.62
        context.moveTo(centerX, centerY)
        context.arc(centerX, centerY, radius, mouth, Math.PI * 2 - mouth, false)
        context.closePath()
      } else {
        var markerRadius = marker.occupied ? radius * 0.48 : radius * 0.30
        context.arc(centerX, centerY, markerRadius, 0, Math.PI * 2, false)
        context.closePath()
      }
      context.fill()
    }
  }
}
