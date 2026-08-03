import QtQuick
import "../config"

Canvas {
  id: root
  implicitHeight: 16

  property real progress: 0.0
  property color activeColor: Colors.primary
  property color trackColor: Colors.surfaceContainerHighest
  property real lineWidth: 2.5
  property real dotRadius: 4
  property real trackLineWidth: 1.5

  onProgressChanged: requestPaint()
  onWidthChanged: requestPaint()
  onActiveColorChanged: requestPaint()
  onTrackColorChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d");
    ctx.clearRect(0, 0, width, height);
    var midY = height / 2;

    var limitX = width * progress;
    ctx.beginPath();
    ctx.lineWidth = root.lineWidth;
    ctx.strokeStyle = root.activeColor;
    for (var x = 0; x <= limitX; x++) {
      var y = midY + Math.sin(x * 0.15) * 3;
      if (x === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();

    if (progress > 0 && progress < 1) {
      ctx.beginPath();
      ctx.fillStyle = root.activeColor;
      ctx.arc(limitX, midY + Math.sin(limitX * 0.15) * 3, root.dotRadius, 0, 2 * Math.PI);
      ctx.fill();
    }

    ctx.beginPath();
    ctx.lineWidth = root.trackLineWidth;
    ctx.strokeStyle = root.trackColor;
    ctx.moveTo(limitX, midY);
    ctx.lineTo(width, midY);
    ctx.stroke();
  }
}
