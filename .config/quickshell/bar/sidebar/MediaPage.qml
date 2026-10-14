import QtQuick
import Quickshell.Widgets
import "../../config"
import "../../config/MediaMath.js" as MediaMath
import "../../config/BottomBarModel.js" as BottomBarModel

// Page 2: round cover with a half-ring of progress along its bottom, title and
// artist pills, the seek line and the control row. Plain inputs (SidebarContent
// binds them to MediaService) so the render check can feed fixed values.
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

  // Glyph button: left and right click signals, hover tint.
  component GlyphButton: Text {
    id: btn
    property color tint: Colors.fgSurfaceVariant
    signal leftClicked()
    signal rightClicked()
    color: area.containsMouse ? Colors.elenaAccent(5) : btn.tint
    font.family: BottomBarFonts.family
    font.pixelSize: Config.dp(14)
    MouseArea {
      id: area
      anchors.fill: parent
      anchors.margins: -Config.dp(5)
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: Qt.PointingHandCursor
      onClicked: function(m) { if (m.button === Qt.RightButton) btn.rightClicked(); else btn.leftClicked() }
    }
  }

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

      Canvas {
        id: ring
        objectName: "artRing"
        anchors.fill: parent
        visible: !artHover.hovered
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
      Text {
        visible: ring.visible
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
          visible: artHover.hovered
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
      HoverHandler { id: artHover; target: art }
      MouseArea {
        anchors.fill: art
        cursorShape: Qt.PointingHandCursor
        onClicked: root.playPause()
      }
    }

    Repeater {   // title and artist pills, scrolling sideways when long
      model: [["", root.title === "" ? "Nothing playing" : root.title, true],
              ["", root.artist === "" ? "Unknown artist" : root.artist, false]]
      Rectangle {
        required property var modelData
        anchors.horizontalCenter: parent.horizontalCenter
        width: Config.dp(240)
        height: Config.dp(28)
        radius: height / 2
        color: Colors.surfaceContainerHighest
        Text {
          id: pillGlyph
          anchors.left: parent.left
          anchors.leftMargin: Config.dp(10)
          anchors.verticalCenter: parent.verticalCenter
          text: modelData[0]
          color: modelData[2] ? Colors.elenaAccent(5) : Colors.elenaAccent(2)
          font.family: BottomBarFonts.family
          font.pixelSize: Config.dp(11)
        }
        Flickable {
          anchors.left: pillGlyph.right
          anchors.leftMargin: Config.dp(8)
          anchors.right: parent.right
          anchors.rightMargin: Config.dp(12)
          anchors.verticalCenter: parent.verticalCenter
          height: pillText.implicitHeight
          clip: true
          contentWidth: pillText.implicitWidth
          contentHeight: height
          flickableDirection: Flickable.HorizontalFlick
          boundsBehavior: Flickable.StopAtBounds
          Text {
            id: pillText
            text: modelData[1]
            color: modelData[2] ? Colors.fgSurface : Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.dp(10)
            font.weight: modelData[2] ? Font.Bold : Font.Normal
          }
        }
      }
    }

    SeekLine {
      objectName: "seekLine"
      anchors.horizontalCenter: parent.horizontalCenter
      fraction: root.fraction
      onSeekRequested: function(f) { root.seekFraction(f) }
    }

    Row {   // controls
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.dp(14)

      GlyphButton {
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        onLeftClicked: root.previous()
        onRightClicked: root.seekBy(-10)
      }
      GlyphButton {
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        onLeftClicked: root.next()
        onRightClicked: root.seekBy(10)
      }
      Rectangle {   // play/pause, larger; the wheel sets the player volume
        objectName: "playButton"
        anchors.verticalCenter: parent.verticalCenter
        width: Config.dp(36)
        height: width
        radius: width / 2
        color: Colors.elenaAccent(5)
        property real wheelAccum: 0
        Text {
          anchors.centerIn: parent
          text: root.playGlyph
          color: Colors.surface
          font.family: BottomBarFonts.family
          font.pixelSize: Config.dp(16)
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
      GlyphButton {
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        onLeftClicked: root.volumeStep(5)
        onRightClicked: root.playerVolumeStep(0.1)
      }
      GlyphButton {
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        onLeftClicked: root.volumeStep(-5)
        onRightClicked: root.playerVolumeStep(-0.1)
      }
      GlyphButton {
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        onLeftClicked: root.stop()
      }
      GlyphButton {
        id: favButton
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        property bool flash: false
        tint: flash ? Colors.elenaAccent(1) : Colors.fgSurfaceVariant
        onLeftClicked: {
          if (root.title === "") return   // nothing to save
          root.favorite(); flash = true; flashTimer.restart()
        }
        Timer { id: flashTimer; interval: 600; onTriggered: favButton.flash = false }
      }
    }
  }
}
