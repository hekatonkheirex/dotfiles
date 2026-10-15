import QtQuick
import QtQuick.Shapes
import Quickshell.Io
import "../../config"
import "../../config/PowerMenuModel.js" as Model

// Her powermenu (config/eww/windows/powermenu.yuck), window-less so the
// overlay and the lock surfaces host it and the render check can grab it.
// Left: greeting, quote, palette row. Right: pills, 3x2 buttons (or the lock
// ring when `locked`), terminal line. The host paints the backdrop and gives
// this item keyboard focus; key handling is off while locked (the lock
// surface owns password input).
Item {
  id: root

  property bool locked: false
  property bool revealed: false
  property string selected: ""
  property int inputLength: 0
  property string lastAction: "clear"
  property bool authFailed: false

  signal activated(string id)
  signal dismissRequested()
  signal hovered(string id)

  readonly property var buttons: Model.buttons()
  property string hostname: ""
  FileView {
    path: "/etc/hostname"
    onLoaded: root.hostname = String(text()).trim()
    onLoadFailed: root.hostname = ""
  }
  readonly property color border30: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.3)
  readonly property real panelHeight: Math.max(
    leftCol.implicitHeight + Config.dp(27) + Config.dp(54),
    rightCol.implicitHeight + 2 * Config.dp(27))
  function pt(n) { return Math.round(n * 4 / 3 * Config.elenaScale) }
  function indexOf(id) {
    for (var i = 0; i < root.buttons.length; i++) if (root.buttons[i].id === id) return i
    return -1
  }

  implicitWidth: container.implicitWidth
  implicitHeight: container.implicitHeight

  Keys.enabled: !root.locked
  Keys.onPressed: function(e) {
    if (e.key === Qt.Key_Escape) {
      root.dismissRequested()
    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
      if (root.selected !== "") root.activated(root.selected)
    } else {
      var dir = e.key === Qt.Key_Left ? "left" : e.key === Qt.Key_Right ? "right"
        : e.key === Qt.Key_Up ? "up" : e.key === Qt.Key_Down ? "down" : ""
      if (dir === "") return
      var i = root.indexOf(root.selected)
      root.selected = root.buttons[i < 0 ? 0 : Model.step(i, dir, root.buttons.length)].id
    }
    e.accepted = true
  }

  // Click outside the buttons or middle click anywhere dismisses (not locked).
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: if (!root.locked) root.dismissRequested()
  }

  Row {
    id: container
    anchors.centerIn: parent
    // The right side overlaps the borderless right edge of the left side.
    spacing: -Config.dp(27)

    Item {
      id: left
      objectName: "greetingPanel"
      anchors.verticalCenter: parent.verticalCenter
      implicitWidth: leftCol.implicitWidth + Config.dp(47) + Config.dp(74)
      implicitHeight: root.panelHeight
      width: implicitWidth
      height: implicitHeight

      Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: Config.dp(6)
        border.color: root.border30
        radius: Config.dp(27)
        topRightRadius: 0
        bottomRightRadius: 0
      }

      Column {
        id: leftCol
        x: Config.dp(47)
        y: Config.dp(27)
        spacing: 40

        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Wake up"
            color: Colors.elenaAccent(6)
            font.family: BottomBarFonts.pick("Orbitron")
            font.bold: true
            font.pixelSize: root.pt(40)
          }
        }

        Column {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 2
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "❝"
            color: Colors.elenaAccent(3)   // her x11 (bright x3)
            font.family: Config.fontFamily
            font.italic: true
            font.pixelSize: root.pt(27)
          }
          Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Config.dp(6)
            Text {
              objectName: "quoteText"
              width: Math.min(implicitWidth, Config.dp(360))
              wrapMode: Text.Wrap
              text: "“" + Settings.powerMenuQuote + "”"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.italic: true
              font.pixelSize: root.pt(14)
            }
            Text {
              objectName: "quoteAuthor"
              anchors.right: parent.right
              visible: Settings.powerMenuQuoteAuthor !== ""
              text: Settings.powerMenuQuoteAuthor
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.italic: true
              font.pixelSize: root.pt(14)
            }
          }
        }

        PaletteRow { anchors.horizontalCenter: parent.horizontalCenter }
      }
    }

    Rectangle {
      id: right
      objectName: "actionsPanel"
      anchors.verticalCenter: parent.verticalCenter
      implicitWidth: rightCol.implicitWidth + 2 * Config.dp(47)
      implicitHeight: root.panelHeight
      width: implicitWidth
      height: implicitHeight
      radius: Config.dp(27)
      color: Colors.surface

      Shape {
        id: dashes
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          strokeWidth: Config.dp(6)
          strokeColor: root.border30
          strokeStyle: ShapePath.DashLine
          dashPattern: [3, 2]
          fillColor: "transparent"
          PathRectangle {
            x: Config.dp(3)
            y: Config.dp(3)
            width: dashes.width - Config.dp(6)
            height: dashes.height - Config.dp(6)
            radius: Config.dp(27) - Config.dp(3)
          }
        }
      }

      Column {
        id: rightCol
        anchors.centerIn: parent
        spacing: 30

        PillBlock { anchors.horizontalCenter: parent.horizontalCenter }

        // Fixed height: the buttons and the ring swap in the same slot.
        Item {
          anchors.horizontalCenter: parent.horizontalCenter
          width: grid.implicitWidth
          height: Config.dp(114)

          Grid {
            id: grid
            objectName: "buttonGrid"
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 3
            visible: !root.locked
            Repeater {
              model: root.buttons
              PowerButton {
                required property var modelData
                required property int index
                objectName: "button_" + modelData.id
                buttonId: modelData.id
                accent: modelData.accent
                order: index
                revealed: root.revealed
                dimmed: root.selected !== "" && root.selected !== modelData.id
                onEntered: { root.selected = modelData.id; root.hovered(modelData.id) }
                // A previous button can exit after the next one has entered.
                onExited: {
                  if (root.selected !== modelData.id) return
                  root.selected = ""
                  root.hovered("")
                }
                onClicked: root.activated(modelData.id)
              }
            }
          }

          LockRing {
            objectName: "lockRing"
            anchors.centerIn: parent
            visible: root.locked
            inputLength: root.inputLength
            lastAction: root.lastAction
            authFailed: root.authFailed
          }
        }

        TerminalLine {
          objectName: "terminalLine"
          anchors.horizontalCenter: parent.horizontalCenter
          live: root.revealed   // the overlay binds revealed to its window's visibility
          flavor: root.locked ? "[ L O C K D O W N ]" : Model.hostFlavor(root.hostname)
          prompt: root.locked ? "> " : "$ "
          value: root.locked ? Model.maskInput(root.inputLength) : root.selected
          ink: Colors.elenaAccent(root.locked ? 1 : 2)   // locked x1, else her x10 (bright x2)
        }
      }
    }
  }
}
