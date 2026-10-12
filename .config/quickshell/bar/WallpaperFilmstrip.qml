import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "../config/WallpaperFilmstrip.js" as Film

// Full-width wallpaper picker: a filmstrip of tall leaning slices with one
// wide, accent-bordered card in the middle and its name below. Left/Right,
// the wheel or a click moves the selection; typing jumps to the first name
// that matches; Enter or a click on the card applies it; Ctrl+R applies a
// random wallpaper; Escape clears the typed text, then closes.
PanelWindow {
  id: root

  property bool open: false
  // Text typed into the launcher's "@" mode; jumps to the first match on open.
  property string initialQuery: ""
  property string query: ""
  readonly property bool noMatch: root.query !== "" && Film.find(root.names(), root.query) < 0
  signal dismissed()
  signal previewReady(string name)

  readonly property string wallsDir: Quickshell.env("HOME") + "/Pictures/Walls"
  readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-thumbs"
  readonly property string previewDir: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-previews"
  readonly property string previewScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/generate-previews.sh"
  readonly property string thumbScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/generate-thumbnails.sh"
  readonly property string randomScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/random-wallpaper.sh"
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

  ListModel { id: walls }

  // Previews are made on demand for the selected card, one at a time; a
  // niced bulk run fills in the rest once per session so browsing stays sharp.
  property var previewQueue: []
  property bool bulkStarted: false

  function requestPreview(name) {
    if (!name || root.previewQueue.indexOf(name) >= 0 || previewProc.target === name) return
    root.previewQueue = root.previewQueue.concat([name])
    root.nextPreview()
  }

  function nextPreview() {
    if (previewProc.running || root.previewQueue.length === 0) return
    previewProc.target = root.previewQueue[0]
    root.previewQueue = root.previewQueue.slice(1)
    previewProc.running = true
  }

  Process {
    id: previewProc
    property string target: ""
    command: ["nice", "-n", "5", "bash", root.previewScript, previewProc.target]
    onRunningChanged: {
      if (running) return
      root.previewReady(previewProc.target)
      previewProc.target = ""
      root.nextPreview()
    }
  }

  function apply(name) {
    if (!name) return
    Quickshell.execDetached([
      "bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh", name
    ])
    root.dismissed()
  }

  function names() {
    var out = []
    for (var i = 0; i < walls.count; i++) out.push(walls.get(i).name)
    return out
  }

  function jump(query) {
    root.query = query
    var hit = Film.find(root.names(), query)
    if (hit >= 0) strip.currentIndex = hit
  }

  function step(delta) {
    strip.currentIndex = Film.clampIndex(strip.currentIndex, delta, walls.count)
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
        walls.clear()
        for (var i = 0; i < parsed.items.length; i++) walls.append(parsed.items[i])
        strip.snap = true
        var start = parsed.current
        if (root.initialQuery !== "") {
          var hit = Film.find(root.names(), root.initialQuery)
          if (hit >= 0) start = hit
        }
        strip.currentIndex = -1
        strip.currentIndex = start
        strip.pos = start
        strip.snap = false
      }
    }
  }

  onOpenChanged: {
    if (root.open) {
      root.query = root.initialQuery
      lister.running = false
      lister.running = true
      if (!root.bulkStarted) {
        root.bulkStarted = true
        // Slice thumbnails first (quick), then the 1600 px previews.
        Quickshell.execDetached(["nice", "-n", "15", "bash", "-c",
          "bash \"$1\"; bash \"$2\"", "sh", root.thumbScript, root.previewScript])
      }
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
      var typed = event.text.length === 1 && event.text >= " " && event.text !== "\x7f"
        && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
      if (event.key === Qt.Key_Escape) {
        if (root.query !== "") root.query = ""
        else root.dismissed()
      }
      else if (event.key === Qt.Key_Left) root.step(-1)
      else if (event.key === Qt.Key_Right) root.step(1)
      else if (event.key === Qt.Key_Home) root.step(-walls.count)
      else if (event.key === Qt.Key_End) root.step(walls.count)
      else if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)) {
        Quickshell.execDetached(["bash", root.randomScript])
        root.dismissed()
      }
      else if (event.key === Qt.Key_Backspace) root.jump(root.query.slice(0, -1))
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        if (strip.currentIndex >= 0 && strip.currentIndex < walls.count)
          root.apply(walls.get(strip.currentIndex).name)
      } else if (typed) root.jump(root.query + event.text)
      else return
      event.accepted = true
    }

    // Items are placed by Film.layout() from a fractional position, so a
    // jump of any length slides without the view re-deriving the selection.
    Item {
      id: strip
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      height: root.geo.cardH

      readonly property int spacing: 2
      property int currentIndex: -1
      property real pos: 0
      property bool snap: true
      readonly property int reach: Math.ceil(width / 2 / Math.max(1, root.geo.sliceW)) + 2
      readonly property int base: Math.floor(pos) - reach

      Behavior on pos {
        enabled: !strip.snap && !Config.reducedMotion
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
      }
      // Full-size decodes (some wallpapers are huge PNGs) share one loader
      // thread with the thumbnails, so start one only once the selection rests.
      property bool rested: false
      onCurrentIndexChanged: {
        strip.rested = false
        restTimer.restart()
        if (currentIndex >= 0) strip.pos = currentIndex
      }
      Timer { id: restTimer; interval: 280; onTriggered: strip.rested = true }

      Repeater {
        model: 2 * strip.reach + 3

        delegate: Item {
          id: slot
          required property int index
          // Stable per item: delegate j always shows the index congruent to j
          // modulo the window, so advancing by one reloads a single image.
          readonly property int span: 2 * strip.reach + 3
          readonly property int idx: strip.base + (((slot.index - strip.base) % slot.span) + slot.span) % slot.span
          readonly property bool valid: slot.idx >= 0 && slot.idx < walls.count
          readonly property var geom: Film.layout(slot.idx, strip.pos, root.geo, strip.spacing)
          readonly property bool current: slot.idx === strip.currentIndex
          readonly property string name: slot.valid ? walls.get(slot.idx).name : ""
          property bool thumbMissing: false

          visible: slot.valid
          x: (strip.width - root.geo.cardW) / 2 + slot.geom.x
          width: slot.geom.w
          height: strip.height

          Item {
            id: card
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: slot.geom.h
            antialiasing: true

            // Lean the whole slice, picture included, about its vertical centre.
            transform: Matrix4x4 {
              matrix: Qt.matrix4x4(1, -root.geo.lean, 0, root.geo.lean * card.height / 2,
                                   0, 1, 0, 0,
                                   0, 0, 1, 0,
                                   0, 0, 0, 1)
            }

            Rectangle { anchors.fill: parent; antialiasing: true; color: Colors.surfaceContainer }

            Image {
              anchors.fill: parent
              source: slot.valid ? "file://" + (slot.thumbMissing ? root.wallsDir : root.thumbDir) + "/" + slot.name : ""
              sourceSize: Qt.size(200, 130)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: false
              smooth: true
              mipmap: true
              antialiasing: true
              onStatusChanged: if (status === Image.Error) slot.thumbMissing = true
            }

            // Sharp preview (1600 px) for the selected card once it rests; the
            // thumbnail stays under it until the decode finishes. If the
            // preview is missing it is generated, then loaded; if that fails
            // the original is used.
            Image {
              id: hero
              anchors.fill: parent
              visible: slot.current
              readonly property string previewUrl: "file://" + root.previewDir + "/" + slot.name + ".jpg"
              readonly property string originalUrl: "file://" + root.wallsDir + "/" + slot.name
              property bool previewFailed: false
              property bool asked: false
              source: slot.current && slot.valid && strip.rested
                ? (hero.previewFailed ? hero.originalUrl : hero.previewUrl) : ""
              sourceSize: Qt.size(1600, 900)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: false
              smooth: true
              mipmap: true
              antialiasing: true
              opacity: status === Image.Ready ? 1 : 0
              Behavior on opacity { NumberAnimation { duration: Config.reducedMotion ? 0 : 140 } }

              onStatusChanged: {
                if (status !== Image.Error || hero.previewFailed) return
                if (hero.asked) hero.previewFailed = true
                else { hero.asked = true; root.requestPreview(slot.name) }
              }

              Connections {
                target: root
                function onPreviewReady(name) {
                  if (name !== slot.name || !hero.asked || hero.previewFailed) return
                  var url = hero.source
                  hero.source = ""
                  hero.source = url
                }
              }
            }

            Rectangle {
              anchors.fill: parent
              antialiasing: true
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
              else strip.currentIndex = slot.idx
            }
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
      color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 1)
      visible: walls.count > 0 && strip.currentIndex >= 0 && strip.currentIndex < walls.count

      Row {
        id: captionRow
        anchors.centerIn: parent
        spacing: 14

        Text {
          visible: root.query !== ""
          text: "/" + root.query
          color: root.noMatch ? Colors.error : Colors.primary
          font.family: Config.monoFontFamily
          font.pixelSize: 13
        }
        Text {
          text: caption.visible ? Film.label(walls.get(strip.currentIndex).name) : ""
          color: Colors.fgSurface
          font.family: Config.monoFontFamily
          font.pixelSize: 13
        }
        Text {
          text: caption.visible ? Film.stamp(walls.get(strip.currentIndex).mtime) : ""
          color: Colors.outline
          font.family: Config.monoFontFamily
          font.pixelSize: 13
        }
      }
    }
  }
}
