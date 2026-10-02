import QtQuick
import QtQuick.Effects
import QtQml
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

PopupBase {
  id: root

  surfaceWidth: 360
  surfaceHeight: Math.min(contentColumn.implicitHeight + Config.spacingPage, 480)

  readonly property string mprisStatus: MediaService.status
  readonly property string mprisTitle: MediaService.title
  readonly property string mprisArtist: MediaService.artist
  readonly property string mprisAlbum: MediaService.album
  readonly property string mprisArtUrl: MediaService.artUrl
  readonly property int mprisLengthSec: MediaService.lengthSec
  readonly property string mprisLengthStr: MediaService.lengthStr
  property int elapsedSeconds: 0
  property var cavaBarValues: []
  readonly property string runtimeDirectory: {
    var xdgRuntime = Quickshell.env("XDG_RUNTIME_DIR")
    return xdgRuntime
      ? xdgRuntime + "/quickshell"
      : Quickshell.env("HOME") + "/.cache/quickshell/runtime"
  }

  onMprisTitleChanged: root.elapsedSeconds = 0

  Binding {
    target: MediaService
    property: "popupActive"
    value: root.visible
  }

  function formatTime(sec) {
    var m = Math.floor(sec / 60)
    var s = sec % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }

  Timer {
    interval: 1000
    running: root.visible && root.mprisStatus === "Playing"
    repeat: true
    onTriggered: {
      if (root.elapsedSeconds < root.mprisLengthSec) root.elapsedSeconds += 1
    }
  }

  Process {
    id: cavaProcess
    command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/config/cava.ini"]
    running: root.visible && root.mprisStatus === "Playing"
    stdout: SplitParser {
      onRead: function(data) {
        var parts = data.trim().split(";");
        var vals = [];
        for (var i = 0; i < parts.length; i++) {
          var n = parseInt(parts[i]);
          if (!isNaN(n)) vals.push(n);
        }
        if (vals.length === 0) return;
        var prev = root.cavaBarValues;
        if (prev && prev.length === vals.length) {
          var smoothed = [];
          for (var j = 0; j < vals.length; j++)
            smoothed.push(prev[j] * 0.4 + vals[j] * 0.6);
          root.cavaBarValues = smoothed;
        } else {
          root.cavaBarValues = vals;
        }
      }
    }
    onRunningChanged: {
      if (!running) {
        root.cavaBarValues = [];
        if (root.visible && root.mprisStatus === "Playing") cavaRetry.start();
      }
    }
  }

  Timer {
    id: cavaRetry
    interval: 2000
    onTriggered: {
      if (root.visible && root.mprisStatus === "Playing") cavaProcess.running = true;
    }
  }

  ColumnLayout {
    id: contentColumn
    anchors {
      fill: parent
      margins: Config.popupPadding
    }
    spacing: Config.spacingExtraLarge

    Item {
      Layout.alignment: Qt.AlignHCenter
      width: 200
      height: Config.ghostTheme ? 176 : 200
      visible: Settings.mediaShowAlbumArt && (!Config.ghostTheme || root.mprisStatus !== "NoPlayer")

      Canvas {
        id: vizCanvas
        anchors.fill: parent

        Connections {
          target: root
          function onCavaBarValuesChanged() { vizCanvas.requestPaint() }
        }
        Connections {
          target: Config
          function onGhostThemeChanged() { vizCanvas.requestPaint() }
        }

        onPaint: {
          var ctx = getContext("2d");
          ctx.clearRect(0, 0, width, height);
          var bars = root.cavaBarValues;
          if (!bars || bars.length === 0) return;

          if (Config.ghostTheme) {
            ctx.fillStyle = Colors.styleAccent;
            var count = Math.min(25, bars.length);
            var step = width / count;
            for (var i = 0; i < count; i++) {
              var value = bars[Math.floor(i * bars.length / count)] / 100;
              if (value <= 0) continue;
              var barHeight = Math.max(2, Math.min(1, value) * 20);
              ctx.fillRect(Math.floor(i * step), height - barHeight - 2, 3, barHeight);
            }
            return;
          }

          var cx = width / 2;
          var cy = height / 2;
          var n = bars.length;
          var baseR = 54;
          var maxExtend = 40;
          var steps = 160;

          var primary = Colors.primary;
          var r = Math.round(primary.r * 255);
          var g = Math.round(primary.g * 255);
          var b = Math.round(primary.b * 255);

          var maxVal = 0;
          for (var k = 0; k < n; k++) maxVal = Math.max(maxVal, bars[k]);
          var intensity = maxVal / 100.0;

          ctx.beginPath();
          for (var s = 0; s <= steps; s++) {
            var angle = (s / steps) * 2 * Math.PI - Math.PI / 2;
            var binFloat = (s / steps) * n;
            var bin0 = Math.floor(binFloat) % n;
            var bin1 = (bin0 + 1) % n;
            var t = binFloat - Math.floor(binFloat);
            t = (1 - Math.cos(t * Math.PI)) / 2;
            var val = (bars[bin0] * (1 - t) + bars[bin1] * t) / 100.0;
            var radius = baseR + val * maxExtend;
            var x = cx + radius * Math.cos(angle);
            var y = cy + radius * Math.sin(angle);
            if (s === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
          }
          ctx.closePath();

          var grad = ctx.createRadialGradient(cx, cy, baseR * 0.6, cx, cy, baseR + maxExtend);
          grad.addColorStop(0, "rgba(" + r + "," + g + "," + b + "," + (intensity * 0.45).toFixed(2) + ")");
          grad.addColorStop(1, "rgba(" + r + "," + g + "," + b + ",0.0)");
          ctx.fillStyle = grad;
          ctx.fill();

          ctx.strokeStyle = "rgba(" + r + "," + g + "," + b + "," + (0.3 + intensity * 0.6).toFixed(2) + ")";
          ctx.lineWidth = 2;
          ctx.lineJoin = "round";
          ctx.stroke();
        }
      }

      Rectangle {
        width: Config.ghostTheme ? 200 : 100
        height: Config.ghostTheme ? 140 : 100
        radius: Config.ghostTheme ? 0 : width / 2
        clip: true
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.ghostTheme ? 0 : (parent.height - height) / 2
        color: Config.ghostTheme ? Colors.styleSurfaceRaised : Colors.surfaceContainerHighest
        border.width: Config.ghostTheme ? Config.themeBorderWidth : 0
        border.color: Colors.styleOutlineStrong

        Image {
          source: root.mprisArtUrl ? root.mprisArtUrl : ""
          anchors.fill: parent
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          sourceSize: Qt.size(width * 2, height * 2)
          // Item.clip only clips to the bounding rectangle, so round the art
          // with a mask. Ghost keeps its square art.
          layer.enabled: !Config.ghostTheme
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: artMask
          }
        }

        Rectangle {
          id: artMask
          anchors.fill: parent
          radius: width / 2
          visible: false
          layer.enabled: true
        }

        Rectangle {
          anchors.fill: parent
          color: "transparent"
          visible: root.mprisArtUrl === ""

          IconGlyph {
            anchors.centerIn: parent
            iconLabel: "music_note"
            iconSize: 36
            iconColor: Colors.fgSurfaceVariant
          }
        }
      }
    }

    ColumnLayout {
      spacing: Config.spacingCompact
      Layout.fillWidth: true

      Text {
        text: root.mprisTitle ? root.mprisTitle : "No Media Playing"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.ghostTheme ? Config.typeTitleLargeSize : Config.typeBodyLargeSize
        font.weight: Config.typeStrongWeight
        font.letterSpacing: Config.typeBodyTracking
        wrapMode: Config.ghostTheme ? Text.WordWrap : Text.NoWrap
        maximumLineCount: Config.ghostTheme ? 2 : 1
        elide: Text.ElideRight
        Layout.fillWidth: true
        horizontalAlignment: Config.ghostTheme ? Text.AlignLeft : Text.AlignHCenter
      }

      Text {
        text: root.mprisArtist ? root.mprisArtist : "Unknown Artist"
        visible: !Config.ghostTheme || root.mprisStatus !== "NoPlayer"
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelMediumSize
        font.letterSpacing: Config.typeLabelTracking
        elide: Text.ElideRight
        Layout.fillWidth: true
        horizontalAlignment: Config.ghostTheme ? Text.AlignLeft : Text.AlignHCenter
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Config.spacingSmall
      visible: Settings.mediaShowProgressBar && (!Config.ghostTheme || root.mprisStatus !== "NoPlayer")

      Text {
        text: root.formatTime(root.elapsedSeconds)
        font.family: Config.ghostTheme ? Config.monoFontFamily : Config.fontFamily
        color: Colors.fgSurfaceVariant
        font.pixelSize: Config.typeLabelSmallSize
        font.letterSpacing: Config.typeLabelTracking
      }

      WaveProgressBar {
        visible: !Config.ghostTheme
        Layout.fillWidth: true
        Layout.preferredHeight: 14
        progress: root.mprisLengthSec > 0 ? (root.elapsedSeconds / root.mprisLengthSec) : 0.0
        activeColor: Colors.primary
        trackColor: Colors.outline
        lineWidth: 2.5
        dotRadius: 4
        trackLineWidth: 2
      }

      Item {
        visible: Config.ghostTheme
        Layout.fillWidth: true
        Layout.preferredHeight: 14

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          height: 2
          color: Colors.styleOutlineStrong

          Rectangle {
            width: parent.width * Math.max(0, Math.min(1,
              root.mprisLengthSec > 0 ? root.elapsedSeconds / root.mprisLengthSec : 0))
            height: parent.height
            color: Colors.styleAccent
          }
        }
      }

      Text {
        text: root.mprisLengthStr
        font.family: Config.ghostTheme ? Config.monoFontFamily : Config.fontFamily
        color: Colors.fgSurfaceVariant
        font.pixelSize: Config.typeLabelSmallSize
        font.letterSpacing: Config.typeLabelTracking
      }
    }

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: Config.spacingLarge
      visible: !Config.ghostTheme || root.mprisStatus !== "NoPlayer"

      IconButton {
        size: 40
        radius: Config.ghostTheme ? 0 : size / 2
        iconSize: 20
        iconLabel: "skip_previous"
        accessibleName: "Previous track"
        tooltipText: "Previous track"
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "prev"])
      }

      IconButton {
        size: 48
        radius: Config.ghostTheme ? 0 : size / 2
        iconSize: 22
        iconLabel: root.mprisStatus === "Playing" ? "pause" : "play_arrow"
        // selected gives the accent fill and its matching glyph colour in every
        // style; the filled variant alone left a dark glyph on a dark disc.
        variant: "filled"
        selected: true
        accessibleName: root.mprisStatus === "Playing" ? "Pause playback" : "Play playback"
        tooltipText: root.mprisStatus === "Playing" ? "Pause playback" : "Play playback"
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "play"])
      }

      IconButton {
        size: 40
        radius: Config.ghostTheme ? 0 : size / 2
        iconSize: 20
        iconLabel: "skip_next"
        accessibleName: "Next track"
        tooltipText: "Next track"
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "next"])
      }

      IconButton {
        size: 36
        radius: Config.ghostTheme ? 0 : size / 2
        iconSize: 16
        iconLabel: "queue_music"
        variant: "outlined"
        accessibleName: "Switch active player"
        tooltipText: "Switch active player"
        onClicked: Quickshell.execDetached([
          "sh", "-c", "printf '%s\\n' shift > \"$1\"", "sh",
          root.runtimeDirectory + "/qsmpris-fifo"
        ])
      }
    }
  }
}
