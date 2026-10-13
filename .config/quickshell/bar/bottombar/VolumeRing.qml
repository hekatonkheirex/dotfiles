import QtQuick
import "../../config"

// Circular volume indicator: backdrop ring plus an arc that starts at 12
// o'clock and grows counter-clockwise (eww circular-progress :start-at 75,
// :clockwise false).
Item {
  id: root
  property real value: 0          // 0..100
  property bool muted: false
  property color fillColor: root.muted ? Colors.elenaAccent(8) : Colors.fgSurface
  readonly property color backdrop: Colors.surfaceContainerHighest

  implicitWidth: Config.dp(23)
  implicitHeight: Config.dp(23)

  onValueChanged: canvas.requestPaint()
  onMutedChanged: canvas.requestPaint()
  onFillColorChanged: canvas.requestPaint()
  onBackdropChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    antialiasing: true
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      var t = Config.dp(5)
      var r = Math.min(width, height) / 2 - t / 2
      var cx = width / 2, cy = height / 2
      ctx.lineWidth = t
      ctx.lineCap = "butt"
      ctx.strokeStyle = root.backdrop
      ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2, false); ctx.stroke()
      var v = Math.max(0, Math.min(100, root.value)) / 100
      if (v <= 0) return
      ctx.strokeStyle = root.fillColor
      ctx.beginPath()
      ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 - Math.PI * 2 * v, true)
      ctx.stroke()
    }
  }
}
