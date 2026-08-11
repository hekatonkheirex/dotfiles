import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

PopupBase {
  id: root

  implicitWidth: 360
  implicitHeight: Math.min(contentColumn.implicitHeight + 32, 480)

  property string mprisStatus: "NoPlayer"
  property string mprisTitle: ""
  property string mprisArtist: ""
  property string mprisAlbum: ""
  property string mprisArtUrl: ""
  property int mprisLengthSec: 0
  property string mprisLengthStr: "0:00"
  property int elapsedSeconds: 0
  property var cavaBarValues: []

  onMprisTitleChanged: root.elapsedSeconds = 0

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
    id: mprisProcess
    command: ["python3", "-u", Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_monitor.py"]
    running: root.visible
    stdout: SplitParser {
      onRead: function(data) {
        try {
          var info = JSON.parse(data.trim());
          root.mprisStatus = info.status;
          root.mprisTitle = info.title;
          root.mprisArtist = info.artist;
          root.mprisAlbum = info.album;
          root.mprisArtUrl = info.artUrl;
          root.mprisLengthSec = info.length_sec;
          root.mprisLengthStr = info.length_str;
        } catch (e) { print("MediaPopup mpris parse error:", e) }
      }
    }
    onRunningChanged: {
      if (!running && root.visible) mprisProcessRetry.start()
    }
  }

  Timer {
    id: mprisProcessRetry
    interval: 3000
    onTriggered: {
      if (root.visible) mprisProcess.running = true
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
    spacing: 20

    Item {
      Layout.alignment: Qt.AlignHCenter
      width: 200
      height: 200
      visible: Settings.mediaShowAlbumArt

      Canvas {
        id: vizCanvas
        anchors.fill: parent

        Connections {
          target: root
          function onCavaBarValuesChanged() { vizCanvas.requestPaint() }
        }

        onPaint: {
          var ctx = getContext("2d");
          ctx.clearRect(0, 0, width, height);
          var bars = root.cavaBarValues;
          if (!bars || bars.length === 0) return;

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
        width: 100
        height: 100
        radius: width / 2
        clip: true
        anchors.centerIn: parent
        color: Colors.surfaceContainerHighest

        Image {
          source: root.mprisArtUrl ? root.mprisArtUrl : ""
          anchors.fill: parent
          fillMode: Image.PreserveAspectCrop
        }

        Rectangle {
          anchors.fill: parent
          color: "transparent"
          visible: root.mprisArtUrl === ""

          Text {
            anchors.centerIn: parent
            text: "music_note"
            font.family: Config.iconFont
            font.pixelSize: 36
            color: Colors.fgSurfaceVariant
          }
        }
      }
    }

    ColumnLayout {
      spacing: 4
      Layout.fillWidth: true

      Text {
        text: root.mprisTitle ? root.mprisTitle : "No Media Playing"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: 15
        font.weight: Font.Bold
        elide: Text.ElideRight
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
      }

      Text {
        text: root.mprisArtist ? root.mprisArtist : "Unknown Artist"
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 10
      visible: Settings.mediaShowProgressBar

      Text {
        text: root.formatTime(root.elapsedSeconds)
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: 10
      }

      WaveProgressBar {
        Layout.fillWidth: true
        Layout.preferredHeight: 14
        progress: root.mprisLengthSec > 0 ? (root.elapsedSeconds / root.mprisLengthSec) : 0.0
        activeColor: Colors.primary
        trackColor: Colors.surfaceContainerHighest
        lineWidth: 2.5
        dotRadius: 4
        trackLineWidth: 1.5
      }

      Text {
        text: root.mprisLengthStr
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: 10
      }
    }

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 16

      IconButton {
        size: 40
        iconSize: 20
        iconLabel: "skip_previous"
        accessibleName: "Previous track"
        tooltipText: "Previous track"
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "prev"])
      }

      IconButton {
        size: 48
        iconSize: 22
        iconLabel: root.mprisStatus === "Playing" ? "pause" : "play_arrow"
        iconColor: Colors.fgPrimary
        backgroundColor: Colors.primary
        accessibleName: root.mprisStatus === "Playing" ? "Pause playback" : "Play playback"
        tooltipText: root.mprisStatus === "Playing" ? "Pause playback" : "Play playback"
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "play"])
      }

      IconButton {
        size: 40
        iconSize: 20
        iconLabel: "skip_next"
        accessibleName: "Next track"
        tooltipText: "Next track"
        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "next"])
      }

      IconButton {
        size: 36
        iconSize: 16
        iconLabel: "queue_music"
        backgroundColor: Colors.surfaceContainer
        outlined: true
        accessibleName: "Switch active player"
        tooltipText: "Switch active player"
        onClicked: Quickshell.execDetached(["sh", "-c", "echo shift > /tmp/qsmpris-fifo"])
      }
    }
  }
}
