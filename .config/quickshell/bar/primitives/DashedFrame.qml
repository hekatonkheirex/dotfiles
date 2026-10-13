import QtQuick
import "../../config"

// Reference framing shared by launcher, session menu and confirmation cards.
Canvas {
  id: root
  property bool active: true
  property real radius: Config.popupRadius
  property color strokeColor: Colors.outline
  readonly property var dashPattern: [6, 6]
  visible: active
  onStrokeColorChanged: requestPaint()
  onRadiusChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onVisibleChanged: if (visible) requestPaint()
  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    ctx.strokeStyle = strokeColor
    ctx.lineWidth = 1.5
    ctx.setLineDash(dashPattern)
    ctx.beginPath()
    ctx.roundedRect(2, 2, width - 4, height - 4, radius, radius)
    ctx.stroke()
  }
}
