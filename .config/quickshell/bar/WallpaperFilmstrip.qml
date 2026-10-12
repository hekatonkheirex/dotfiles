import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "../config/WallpaperFilmstrip.js" as Film

// Full-width wallpaper picker: a filmstrip of tall leaning slices with one
// wide, accent-bordered card in the middle and its name below. Left/Right,
// the wheel or a click moves the selection; Enter or a click on the card
// applies it; Escape closes.
PanelWindow {
  id: root

  property bool open: false
  signal dismissed()

  readonly property string wallsDir: Quickshell.env("HOME") + "/Pictures/Walls"
  readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-thumbs"
  readonly property var geo: Film.geometry(root.screen ? root.screen.width : 1920)
  readonly property int captionHeight: 56

  visible: root.open
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("popup")
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.focusable: true

  anchors.left: true
  anchors.right: true
  anchors.top: true
  implicitHeight: root.geo.cardH + root.captionHeight
  margins.top: Math.max(0, ((root.screen ? root.screen.height : 1080) - root.implicitHeight) / 2)

  ListModel { id: model }

  function apply(name) {
    if (!name) return
    Quickshell.execDetached([
      "bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh", name
    ])
    root.dismissed()
  }

  function step(delta) {
    strip.currentIndex = Film.clampIndex(strip.currentIndex, delta, model.count)
  }

  Process {
    id: lister
    command: [
      "bash", "-c",
      "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%f\\t%T@\\n';"
        + " printf '@@current\\t%s\\n' \"$(awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1)\"",
      "sh", root.wallsDir
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        var parsed = Film.parse(text)
        model.clear()
        for (var i = 0; i < parsed.items.length; i++) model.append(parsed.items[i])
        strip.currentIndex = parsed.current
        strip.positionViewAtIndex(parsed.current, ListView.Center)
      }
    }
  }

  onOpenChanged: {
    if (root.open) {
      lister.running = false
      lister.running = true
      keys.forceActiveFocus()
    }
  }

  Item {
    id: keys
    anchors.fill: parent
    focus: true
    opacity: root.open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Config.reducedMotion ? 0 : 160 } }

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) root.dismissed()
      else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) root.step(-1)
      else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) root.step(1)
      else if (event.key === Qt.Key_Home) root.step(-model.count)
      else if (event.key === Qt.Key_End) root.step(model.count)
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        if (strip.currentIndex >= 0 && strip.currentIndex < model.count)
          root.apply(model.get(strip.currentIndex).name)
      } else return
      event.accepted = true
    }

    ListView {
      id: strip
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: root.geo.cardH
      orientation: ListView.Horizontal
      model: model
      spacing: 2
      clip: false
      cacheBuffer: root.geo.cardW
      highlightRangeMode: ListView.StrictlyEnforceRange
      preferredHighlightBegin: (width - root.geo.cardW) / 2
      preferredHighlightEnd: (width + root.geo.cardW) / 2
      highlightMoveDuration: Config.reducedMotion ? 0 : 240
      highlightMoveVelocity: -1
      boundsBehavior: Flickable.StopAtBounds
      interactive: false

      delegate: Item {
        id: slot
        required property int index
        required property string name
        required property real mtime
        readonly property bool current: ListView.isCurrentItem
        property bool thumbMissing: false

        width: slot.current ? root.geo.cardW : root.geo.sliceW
        height: strip.height
        Behavior on width { NumberAnimation { duration: Config.reducedMotion ? 0 : 240; easing.type: Easing.OutCubic } }

        Item {
          id: card
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          height: slot.current ? root.geo.cardH : root.geo.sliceH
          clip: true
          Behavior on height { NumberAnimation { duration: Config.reducedMotion ? 0 : 240; easing.type: Easing.OutCubic } }

          // Lean the whole slice, picture included, about its vertical centre.
          transform: Matrix4x4 {
            matrix: Qt.matrix4x4(1, -root.geo.lean, 0, root.geo.lean * card.height / 2,
                                 0, 1, 0, 0,
                                 0, 0, 1, 0,
                                 0, 0, 0, 1)
          }

          Rectangle { anchors.fill: parent; color: Colors.surfaceContainer }

          Image {
            anchors.fill: parent
            source: "file://" + (slot.thumbMissing ? root.wallsDir : root.thumbDir) + "/" + slot.name
            sourceSize: Qt.size(200, 130)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            onStatusChanged: if (status === Image.Error) slot.thumbMissing = true
          }

          // Full picture only for the selected card; the thumbnail stays under
          // it until the decode finishes.
          Image {
            id: full
            anchors.fill: parent
            visible: slot.current
            source: slot.current ? "file://" + root.wallsDir + "/" + slot.name : ""
            sourceSize: Qt.size(1280, 720)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Config.reducedMotion ? 0 : 140 } }
          }

          Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: slot.current ? 2 : 0
            border.color: Colors.primary
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (slot.current) root.apply(slot.name)
            else strip.currentIndex = slot.index
          }
        }
      }

      WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
          var d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
          if (d !== 0) root.step(d > 0 ? -1 : 1)
        }
      }
    }

    Rectangle {
      id: caption
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: strip.bottom
      anchors.topMargin: 12
      width: captionRow.implicitWidth + 28
      height: captionRow.implicitHeight + 14
      radius: height / 2
      color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.9)
      visible: model.count > 0 && strip.currentIndex >= 0 && strip.currentIndex < model.count

      Row {
        id: captionRow
        anchors.centerIn: parent
        spacing: 14

        Text {
          text: caption.visible ? Film.label(model.get(strip.currentIndex).name) : ""
          color: Colors.fgSurface
          font.family: Config.monoFontFamily
          font.pixelSize: 13
        }
        Text {
          text: caption.visible ? Film.stamp(model.get(strip.currentIndex).mtime) : ""
          color: Colors.outline
          font.family: Config.monoFontFamily
          font.pixelSize: 13
        }
      }
    }
  }
}
