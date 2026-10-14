import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import QtQuick.Effects
import "../config"

// The system tray (route "tray"): right and bottom anchored overlay above the
// bottom bar, no reserved space. A grid of the tray icons; left click
// activates, right click opens the app's menu, middle click is the secondary
// action. Dismiss: Esc, middle click on the background, click outside
// (shell.qml's PopupShield) and the bar button again. No focus-loss dismissal:
// an app menu takes the keyboard focus while it is open.
PanelWindow {
  id: root

  signal dismissed()

  readonly property int cell: Config.dp(56)
  readonly property int pad: Config.dp(14)
  readonly property int columns: Math.max(1, Math.min(5, TrayService.count))
  readonly property int rowsShown: Math.max(1, Math.ceil(Math.max(1, TrayService.count) / root.columns))

  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  // Matches the existing popup no-blur rule, including the transparent corners.
  WlrLayershell.namespace: Config.layerNamespace("popup-tray")
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  anchors.right: true
  anchors.bottom: true
  margins.right: 0
  margins.bottom: Config.bottomBarHeight + Config.dp(10)
  implicitWidth: root.columns * root.cell + (root.columns + 1) * root.pad / 2 + root.pad
  implicitHeight: root.rowsShown * root.cell + (root.rowsShown + 1) * root.pad / 2 + root.pad

  onVisibleChanged: if (visible) content.forceActiveFocus()

  FocusScope {
    id: content
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.dismissed()

    Rectangle {
      anchors.fill: parent
      color: Colors.surface
      topLeftRadius: Config.dp(20)
      bottomLeftRadius: Config.dp(20)
      topRightRadius: 0
      bottomRightRadius: 0

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: root.dismissed()
      }

      Text {
        objectName: "emptyText"
        anchors.centerIn: parent
        visible: TrayService.count === 0
        text: "No tray items"
        color: Colors.elenaAccent(8)
        font.family: Config.fontFamily
        font.pixelSize: Math.round(12 * 4 / 3 * Config.elenaScale)
      }

      Grid {
        objectName: "grid"
        anchors.fill: parent
        anchors.margins: root.pad
        columns: root.columns
        spacing: root.pad / 2

        Repeater {
          model: TrayService.items

          delegate: Rectangle {
            id: slot
            required property var modelData
            objectName: "tray_" + modelData.id
            width: root.cell
            height: root.cell
            radius: Config.dp(14)
            color: mouse.containsMouse ? Colors.surfaceContainerHigh : Colors.surfaceContainer

            readonly property bool pixmap: modelData.icon.indexOf("image://qspixmap/") === 0
            readonly property bool tint: /fcitx|ibus/i.test(modelData.id + " " + modelData.title)

            Accessible.role: Accessible.Button
            Accessible.name: modelData.title || modelData.id || "System tray item"

            IconImage {
              anchors.centerIn: parent
              width: Config.dp(26)
              height: width
              source: slot.modelData.icon
              visible: !slot.pixmap
              layer.enabled: slot.tint
              layer.effect: MultiEffect { colorization: 1.0; colorizationColor: Colors.primary }
            }
            Image {
              anchors.centerIn: parent
              width: Config.dp(26)
              height: width
              source: slot.modelData.icon
              fillMode: Image.PreserveAspectFit
              visible: slot.pixmap
              layer.enabled: slot.tint
              layer.effect: MultiEffect { colorization: 1.0; colorizationColor: Colors.primary }
            }

            QsMenuAnchor {
              id: menuAnchor
              menu: slot.modelData.menu
              anchor.window: root
              anchor.item: slot
              anchor.edges: Edges.Top
              anchor.gravity: Edges.Top
            }

            MouseArea {
              id: mouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
              onClicked: function(m) {
                if (m.button === Qt.RightButton && slot.modelData.hasMenu) menuAnchor.open()
                else if (m.button === Qt.MiddleButton) slot.modelData.secondaryActivate()
                else slot.modelData.activate()
              }
            }
          }
        }
      }
    }
  }
}
