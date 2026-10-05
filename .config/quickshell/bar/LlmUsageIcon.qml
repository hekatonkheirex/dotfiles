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
    readonly property string style: Settings.themeStyle
    onStyleChanged: requestPaint()
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
      if (symbol.style === "liquid-glass") {
        ctx.lineWidth = 4.8;
        ctx.lineJoin = "round";
        ctx.beginPath();
        for (var point = 0; point <= 360; point++) {
          var t = 2 * Math.PI * point / 360;
          var x = 50 + 29 * Math.sin(t) - 16 * Math.sin(5 * t);
          var y = 50 - 29 * Math.cos(t) - 16 * Math.cos(5 * t);
          if (point === 0) ctx.moveTo(x, y);
          else ctx.lineTo(x, y);
        }
        ctx.closePath();
        ctx.stroke();
      } else if (symbol.style === "material3") {
        ctx.beginPath();
        ctx.moveTo(50, 3);
        ctx.bezierCurveTo(55, 32, 68, 45, 97, 50);
        ctx.bezierCurveTo(68, 55, 55, 68, 50, 97);
        ctx.bezierCurveTo(45, 68, 32, 55, 3, 50);
        ctx.bezierCurveTo(32, 45, 45, 32, 50, 3);
        ctx.closePath();
        ctx.fill();
      } else if (symbol.style === "nothing") {
        // Six broad arms reproduce the reference asterisk without its backdrop.
        ctx.lineWidth = 12;
        ctx.beginPath();
        for (var arm = 0; arm < 6; arm++) {
          var angle = arm * Math.PI / 3 - Math.PI / 2;
          ctx.moveTo(50, 50);
          ctx.lineTo(50 + Math.cos(angle) * 42, 50 + Math.sin(angle) * 42);
        }
        ctx.stroke();
      } else {
        // Angular neural core with four circuit traces and registration corners.
        ctx.lineWidth = 6;
        ctx.beginPath();
        ctx.moveTo(50, 24); ctx.lineTo(76, 50);
        ctx.lineTo(50, 76); ctx.lineTo(24, 50); ctx.closePath();
        ctx.moveTo(50, 6); ctx.lineTo(50, 24);
        ctx.moveTo(76, 50); ctx.lineTo(94, 50);
        ctx.moveTo(50, 76); ctx.lineTo(50, 94);
        ctx.moveTo(6, 50); ctx.lineTo(24, 50);
        ctx.moveTo(8, 24); ctx.lineTo(8, 8); ctx.lineTo(24, 8);
        ctx.moveTo(76, 92); ctx.lineTo(92, 92); ctx.lineTo(92, 76);
        ctx.stroke();
        ctx.fillRect(43, 43, 14, 14);
      }
      ctx.restore();
    }
  }
}
