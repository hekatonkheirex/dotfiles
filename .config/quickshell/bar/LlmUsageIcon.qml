import QtQuick
import "../config"

Item {
  id: root
  required property color ink
  implicitWidth: Config.iconSize
  implicitHeight: Config.iconSize

  Canvas {
    id: symbol
    anchors.fill: parent
    onVisibleChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Connections {
      target: root
      function onInkChanged() { symbol.requestPaint() }
    }
    onPaint: {
      var ctx = getContext("2d");
      ctx.clearRect(0, 0, width, height);
      var size = Math.min(width, height);
      if (size <= 0) return;
      ctx.save();
      ctx.translate((width - size) / 2, (height - size) / 2);
      ctx.scale(size / 100, size / 100);
      ctx.strokeStyle = root.ink;
      ctx.fillStyle = root.ink;
      ctx.lineCap = "butt";
      {
        // Angular sparkle: one large four-point star and two small ones.
        function star(cx, cy, outer, inner) {
          ctx.moveTo(cx, cy - outer);
          ctx.lineTo(cx + inner, cy - inner);
          ctx.lineTo(cx + outer, cy);
          ctx.lineTo(cx + inner, cy + inner);
          ctx.lineTo(cx, cy + outer);
          ctx.lineTo(cx - inner, cy + inner);
          ctx.lineTo(cx - outer, cy);
          ctx.lineTo(cx - inner, cy - inner);
          ctx.closePath();
        }
        ctx.beginPath();
        star(42, 58, 38, 9);
        star(80, 20, 17, 4.5);
        star(82, 80, 12, 3.5);
        ctx.fill();
      }
      ctx.restore();
    }
  }
}
