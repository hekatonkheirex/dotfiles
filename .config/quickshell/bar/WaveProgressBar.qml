import QtQuick
import "../config"

Canvas {
  id: root
  implicitHeight: 16


  property real progress: 0.0
  property color activeColor: Colors.primary
  property color trackColor: Colors.surfaceContainerHighest
  property real lineWidth: 6
  property real dotRadius: 2
  property real trackLineWidth: 6
  readonly property real value: Math.max(0, Math.min(1, progress))

  onProgressChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onLineWidthChanged: requestPaint()
  onDotRadiusChanged: requestPaint()
  onTrackLineWidthChanged: requestPaint()
  onActiveColorChanged: requestPaint()
  onTrackColorChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d");
    ctx.clearRect(0, 0, width, height);
    if (width <= 0 || height <= 0) return;
    var midY = height / 2;
    var activeEnd = width * root.value;
    ctx.save();
    ctx.lineCap = "butt";

    if (root.value > 0) {
      ctx.beginPath();
      ctx.lineWidth = root.lineWidth;
      ctx.strokeStyle = root.activeColor;
      for (var x = 0; x < activeEnd; x++) {
        var y = midY + Math.sin(x * 0.15) * 3;
        if (x === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.lineTo(activeEnd, midY + Math.sin(activeEnd * 0.15) * 3);
      ctx.stroke();
    }

    if (root.value > 0 && root.value < 1) {
      ctx.beginPath();
      ctx.fillStyle = root.activeColor;
      ctx.arc(activeEnd, midY + Math.sin(activeEnd * 0.15) * 3,
              root.dotRadius, 0, 2 * Math.PI);
      ctx.fill();
    }

    if (activeEnd < width) {
      ctx.beginPath();
      ctx.lineWidth = root.trackLineWidth;
      ctx.strokeStyle = root.trackColor;
      ctx.moveTo(activeEnd, midY);
      ctx.lineTo(width, midY);
      ctx.stroke();
    }
    ctx.restore();
  }
}
