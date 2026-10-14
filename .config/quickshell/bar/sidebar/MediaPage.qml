import QtQuick
import Quickshell.Widgets
import "../../config"
import "../../config/MediaMath.js" as MediaMath
import "../../config/BottomBarModel.js" as BottomBarModel

// Page 2: round cover with a half-ring of progress along its bottom, title and
// artist pills, the seek line and her gameboy control cross. Plain inputs
// (SidebarContent binds them to MediaService) so the render check can feed
// fixed values.
Item {
  id: root
  property string status: "NoPlayer"
  property string title: ""
  property string artist: ""
  property string artUrl: ""
  property real positionSec: 0
  property real lengthSec: 0

  signal playPause()
  signal previous()
  signal next()
  signal seekBy(real delta)
  signal seekFraction(real f)
  signal stop()
  signal favorite()
  signal volumeStep(real delta)        // system volume, percent
  signal playerVolumeStep(real delta)  // player volume, 0..1 scale

  readonly property real fraction: MediaMath.fraction(root.positionSec, root.lengthSec)
  readonly property bool playing: root.status === "Playing"
  readonly property string playGlyph: root.playing ? "" : ""   // pause : play
  readonly property int buttonGlyph: Math.round(10 * 4 / 3 * Config.elenaScale)   // 10pt

  Column {
    anchors.top: parent.top
    anchors.topMargin: Config.dp(24)
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Config.dp(14)

    Item {   // cover, ring and time labels
      id: cover
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.width
      height: Config.dp(160) + 2 * Config.dp(14)
      readonly property real ringRadius: Config.dp(80) + Config.dp(9)
      readonly property bool hovered: artArea.containsMouse

      Canvas {
        id: ring
        objectName: "artRing"
        anchors.fill: parent
        visible: !cover.hovered
        property real fraction: root.fraction
        property color track: Colors.surfaceContainerHighest
        property color fill: Colors.elenaAccent(5)
        onFractionChanged: requestPaint()
        onTrackChanged: requestPaint()
        onFillChanged: requestPaint()
        // Bottom half, from the left end (9 o'clock) counter-clockwise through
        // 6 o'clock to the right end: position at the left, length at the right.
        onPaint: {
          var ctx = getContext("2d")
          ctx.reset()
          var cx = width / 2, cy = height / 2, r = cover.ringRadius
          ctx.lineWidth = Config.dp(8)
          ctx.lineCap = "round"
          ctx.strokeStyle = track
          ctx.beginPath()
          ctx.arc(cx, cy, r, Math.PI, 0, true)
          ctx.stroke()
          if (fraction > 0) {
            ctx.strokeStyle = fill
            ctx.beginPath()
            ctx.arc(cx, cy, r, Math.PI, Math.PI - Math.PI * fraction, true)
            ctx.stroke()
          }
        }
      }
      // Her position and length labels are both empty without a length.
      Text {
        objectName: "positionText"
        visible: ring.visible && root.lengthSec > 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.horizontalCenter
        anchors.rightMargin: cover.ringRadius + Config.dp(10)
        text: MediaMath.timeText(root.positionSec)
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.dp(9)
      }
      Text {
        visible: ring.visible && root.lengthSec > 0
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.horizontalCenter
        anchors.leftMargin: cover.ringRadius + Config.dp(10)
        text: MediaMath.timeText(root.lengthSec)
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.dp(9)
      }

      ClippingRectangle {
        id: art
        objectName: "mediaArt"
        anchors.centerIn: parent
        width: Config.dp(160)
        height: width
        radius: width / 2
        color: Colors.surfaceContainerHighest

        Image {
          id: artImage
          anchors.fill: parent
          source: root.artUrl
          visible: root.artUrl !== ""
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          // The Image leak is unresolved (see memory notes): keep the cap and no cache.
          cache: false
          sourceSize: Qt.size(320, 320)
        }
        Text {
          anchors.centerIn: parent
          visible: root.artUrl === "" || artImage.status !== Image.Ready
          text: ""
          color: Colors.fgSurfaceVariant
          font.family: BottomBarFonts.family
          font.pixelSize: Config.dp(36)
        }
        Rectangle {   // hover: dim the cover, show play or pause
          anchors.fill: parent
          visible: cover.hovered
          color: Qt.rgba(0, 0, 0, 0.45)
          Text {
            anchors.centerIn: parent
            text: root.playGlyph
            color: Colors.fgSurface
            font.family: BottomBarFonts.family
            font.pixelSize: Config.dp(30)
          }
        }
      }
      // Hover and click only over the cover itself (not the labels or the
      // empty space around it). The clipped content renders through a shader
      // source, so the input item sits on top of it, sized to the cover.
      MouseArea {
        id: artArea
        objectName: "artArea"
        anchors.fill: art
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.playPause()
      }
    }

    TextPill {
      anchors.horizontalCenter: parent.horizontalCenter
      glyph: ""
      text: root.title === "" ? "Nothing playing" : root.title
      bold: true
    }
    TextPill {
      anchors.horizontalCenter: parent.horizontalCenter
      glyph: ""
      text: root.artist === "" ? "Unknown artist" : root.artist
    }

    SeekLine {
      objectName: "seekLine"
      anchors.horizontalCenter: parent.horizontalCenter
      fraction: root.fraction
      onSeekRequested: function(f) { root.seekFraction(f) }
    }

    Row {   // her media-buttons: the gameboy cross, then the B and A buttons
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.dp(35)

      Item {   // cross: prev/next across, volume up/down down the middle, play on top
        id: cross
        objectName: "mediaCross"
        width: Config.dp(100)
        height: Config.dp(100)
        readonly property real r: Config.dp(10)
        readonly property real shift: Config.dp(18) / 2

        Row {
          anchors.centerIn: parent
          PadButton {
            objectName: "prevButton"
            width: Config.dp(50); height: Config.dp(40)
            topLeftRadius: cross.r; bottomLeftRadius: cross.r
            glyph: ""
            glyphDx: -cross.shift
            onLeftClicked: root.previous()
            onRightClicked: root.seekBy(-10)
          }
          PadButton {
            objectName: "nextButton"
            width: Config.dp(50); height: Config.dp(40)
            topRightRadius: cross.r; bottomRightRadius: cross.r
            glyph: ""
            glyphDx: cross.shift
            onLeftClicked: root.next()
            onRightClicked: root.seekBy(10)
          }
        }
        Column {
          anchors.centerIn: parent
          PadButton {
            objectName: "volumeUpButton"
            width: Config.dp(40); height: Config.dp(50)
            topLeftRadius: cross.r; topRightRadius: cross.r
            glyph: ""
            glyphDy: -cross.shift
            onLeftClicked: root.volumeStep(5)
            onRightClicked: root.playerVolumeStep(0.1)
          }
          PadButton {
            objectName: "volumeDownButton"
            width: Config.dp(40); height: Config.dp(50)
            bottomLeftRadius: cross.r; bottomRightRadius: cross.r
            glyph: ""
            glyphDy: cross.shift
            onLeftClicked: root.volumeStep(-5)
            onRightClicked: root.playerVolumeStep(-0.1)
          }
        }
        Rectangle {   // play/pause on top of the cross; the wheel sets the player volume
          objectName: "playButton"
          anchors.centerIn: parent
          width: Config.dp(40 - 4)
          height: width
          radius: width / 2
          color: Colors.surface
          property real wheelAccum: 0
          Text {
            anchors.centerIn: parent
            text: root.playGlyph
            color: root.playing ? Colors.elenaAccent(6) : Colors.elenaAccent(8)
            font.family: BottomBarFonts.family
            font.pixelSize: root.buttonGlyph
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.playPause()
            onWheel: function(w) {
              var r = BottomBarModel.notchSteps(parent.wheelAccum, w.angleDelta.y)
              parent.wheelAccum = r.accum
              if (r.steps !== 0) root.playerVolumeStep(0.02 * r.steps)
            }
          }
        }
      }

      Item {   // B (stop) sits 20 S lower than A (favorite)
        anchors.verticalCenter: parent.verticalCenter
        width: 2 * Config.dp(40) + Config.dp(6)
        height: Config.dp(40) + Config.dp(20)
        PadButton {
          objectName: "stopButton"
          y: Config.dp(20)
          width: Config.dp(40); height: width
          radius: width / 2
          glyph: ""
          glyphColor: Colors.elenaAccent(3)
          onLeftClicked: root.stop()
        }
        PadButton {
          id: favButton
          objectName: "favoriteButton"
          x: Config.dp(40) + Config.dp(6)
          width: Config.dp(40); height: width
          radius: width / 2
          property bool flash: false
          color: flash ? Colors.elenaAccent(1) : Colors.surfaceContainerHighest
          glyph: ""
          glyphColor: flash ? Colors.surface : Colors.elenaAccent(1)
          onLeftClicked: {
            if (root.title === "") return   // nothing to save
            root.favorite(); flash = true; flashTimer.restart()
          }
          Timer { id: flashTimer; interval: 600; onTriggered: favButton.flash = false }
        }
      }
    }
  }
}
