import QtQuick
import "../config"
import "themes/styled" as Styled

Canvas {
  id: root
  implicitHeight: 16

  Styled.ThemeTokens { id: theme }

  property real progress: 0.0
  property color activeColor: Config.ghostTheme ? Colors.styleAccent : Colors.primary
  property color trackColor: Config.ghostTheme ? Colors.styleControl : Colors.surfaceContainerHighest
  property real lineWidth: Config.material3Theme ? 6 : 2.5
  property real dotRadius: Config.material3Theme ? 2 : 4
  property real trackLineWidth: Config.material3Theme ? 6 : 1.5
  readonly property string style: Settings.themeStyle
  readonly property real value: Math.max(0, Math.min(1, progress))

  onProgressChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  onStyleChanged: requestPaint()
  onLineWidthChanged: requestPaint()
  onDotRadiusChanged: requestPaint()
  onTrackLineWidthChanged: requestPaint()
  onActiveColorChanged: requestPaint()
  onTrackColorChanged: requestPaint()

  function capsule(ctx, x, y, w, h) {
    var radius = Math.min(w, h) / 2;
    ctx.beginPath();
    ctx.moveTo(x + radius, y);
    ctx.lineTo(x + w - radius, y);
    ctx.arcTo(x + w, y, x + w, y + h, radius);
    ctx.arcTo(x + w, y + h, x, y + h, radius);
    ctx.arcTo(x, y + h, x, y, radius);
    ctx.arcTo(x, y, x + w, y, radius);
    ctx.closePath();
    ctx.fill();
  }
  onPaint: {
    var ctx = getContext("2d");
    ctx.clearRect(0, 0, width, height);
    if (width <= 0 || height <= 0) return;
    var midY = height / 2;
    var limitX = width * root.value;
    ctx.save();

    if (root.style === "liquid-glass") {
      var thickness = Math.min(10, height - 4);
      ctx.fillStyle = root.trackColor;
      root.capsule(ctx, 0, midY - thickness / 2, width, thickness);
      if (limitX > 0) {
        ctx.shadowColor = root.activeColor;
        ctx.shadowBlur = 3;
        ctx.fillStyle = root.activeColor;
        root.capsule(ctx, 0, midY - thickness / 2, limitX, thickness);
        ctx.shadowBlur = 0;
        ctx.fillStyle = Qt.rgba(1, 1, 1, 0.18);
        root.capsule(ctx, 1, midY - thickness / 2 + 1,
                     Math.max(0, limitX - 2), 1);
      }
    } else if (root.style === "nothing") {
      ctx.fillStyle = root.trackColor;
      root.capsule(ctx, 0, 0, width, height);
      var pitch = 4;
      var columns = Math.max(0, Math.floor((width - 8) / pitch));
      var startX = (width - (columns - 1) * pitch) / 2;
      // Three dot rows, with the active boundary at the exact quota fraction.
      for (var column = 0; column < columns; column++) {
        var dotX = startX + column * pitch;
        ctx.fillStyle = root.activeColor;
        ctx.globalAlpha = dotX <= limitX ? 1 : 0.2;
        for (var row = -1; row <= 1; row++) {
          ctx.beginPath();
          ctx.arc(dotX, midY + row * pitch, 1.2, 0, 2 * Math.PI);
          ctx.fill();
        }
      }
    } else if (root.style === "ghost") {
      var count = theme.segmentCount;
      var gap = Math.min(theme.segmentGap, width / (count * 2));
      var cellWidth = (width - gap * (count - 1)) / count;
      var usedCells = Math.ceil(root.value * count);
      for (var cell = 0; cell < count; cell++) {
        var used = cell < usedCells;
        var cellHeight = Math.min(used ? 12 : 8, height);
        ctx.fillStyle = used ? root.activeColor : root.trackColor;
        ctx.fillRect(cell * (cellWidth + gap), midY - cellHeight / 2,
                     cellWidth, cellHeight);
      }
    } else {
      var material = root.style === "material3";
      var inset = material ? Math.max(root.lineWidth, root.trackLineWidth) / 2 : 0;
      var endX = width - inset;
      var activeEnd = inset + (endX - inset) * root.value;
      ctx.lineCap = material ? "round" : "butt";

      if (root.value > 0) {
        ctx.beginPath();
        ctx.lineWidth = root.lineWidth;
        ctx.strokeStyle = root.activeColor;
        for (var x = inset; x < activeEnd; x++) {
          var y = midY + Math.sin((x - inset) * 0.15) * 3;
          if (x === inset) ctx.moveTo(x, y);
          else ctx.lineTo(x, y);
        }
        ctx.lineTo(activeEnd, midY + Math.sin((activeEnd - inset) * 0.15) * 3);
        ctx.stroke();
      }

      if (!material && root.value > 0 && root.value < 1) {
        ctx.beginPath();
        ctx.fillStyle = root.activeColor;
        ctx.arc(activeEnd, midY + Math.sin(activeEnd * 0.15) * 3,
                root.dotRadius, 0, 2 * Math.PI);
        ctx.fill();
      }

      var trackStart = root.value === 0 ? inset : activeEnd
        + (material ? root.lineWidth / 2 + root.trackLineWidth / 2 + 4 : 0);
      if (trackStart < endX) {
        ctx.beginPath();
        ctx.lineWidth = root.trackLineWidth;
        ctx.strokeStyle = root.trackColor;
        ctx.moveTo(trackStart, midY);
        ctx.lineTo(endX, midY);
        ctx.stroke();
      }
      if (material && root.value < 1) {
        ctx.beginPath();
        ctx.fillStyle = root.activeColor;
        ctx.arc(endX, midY, root.dotRadius, 0, 2 * Math.PI);
        ctx.fill();
      }
    }
    ctx.restore();
  }
}
