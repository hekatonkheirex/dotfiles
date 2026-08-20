import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../config"

Item {
  id: systemTrayAreaRoot

  property var parentWindow: null
  property bool horizontal: false
  property bool integrated: false

  property int visibleCount: 0
  readonly property real preferredLength: visibleCount * (Config.widgetSize)

  Layout.preferredWidth: horizontal ? preferredLength : (Config.widgetSize)
  Layout.preferredHeight: horizontal ? (Config.widgetSize) : preferredLength
  visible: visibleCount > 0

  Rectangle {
    id: shadow
    x: (horizontal ? 0 : 6) + Config.themeShadowOffset
    y: (horizontal ? 6 : 0) + Config.themeShadowOffset
    width: horizontal ? systemTrayAreaRoot.width : Math.max(0, systemTrayAreaRoot.width - 12)
    height: horizontal ? Math.max(0, systemTrayAreaRoot.height - 12) : systemTrayAreaRoot.height
    radius: Config.borderRadius
    color: Colors.styleShadow
    visible: Config.neoBrutalism && systemTrayAreaRoot.visible && !systemTrayAreaRoot.integrated
    z: -1
  }

  Rectangle {
    anchors {
      fill: parent
      leftMargin: horizontal ? 0 : 6
      rightMargin: horizontal ? 0 : 6
      topMargin: horizontal ? 6 : 0
      bottomMargin: horizontal ? 6 : 0
    }
    radius: Config.borderRadius
    clip: true
    color: systemTrayAreaRoot.integrated
      ? "transparent"
      : (Config.neoBrutalism ? Colors.styleSurface : Colors.surfaceContainerHigh)
    border.color: Config.neoBrutalism
      ? Colors.styleOutline
      : Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.15)
    border.width: systemTrayAreaRoot.integrated ? 0 : Config.themeBorderWidth
  }

  GridLayout {
    id: trayLayout
    flow: systemTrayAreaRoot.horizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
    anchors.fill: parent
    columnSpacing: 0
    rowSpacing: 0

    Repeater {
      id: trayRepeater
      model: SystemTray.items

      delegate: Item {
        id: trayIconDelegate
        required property SystemTrayItem modelData

        // Filter out blueman and udiskie
        readonly property bool isIconVisible: modelData.id !== "blueman" && modelData.id !== "udiskie"
        visible: isIconVisible

        Layout.preferredWidth: visible ? (Config.widgetSize) : 0
        Layout.preferredHeight: visible ? (Config.widgetSize) : 0
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        width: visible ? (Config.widgetSize) : 0
        height: visible ? (Config.widgetSize) : 0
        activeFocusOnTab: isIconVisible

        Accessible.role: Accessible.Button
        Accessible.name: modelData.title || modelData.id || "System tray item"
        Accessible.description: modelData.hasMenu ? "Open system tray menu" : "Activate system tray item"
        Accessible.focusable: isIconVisible
        Accessible.focused: activeFocus

        Keys.onPressed: function(event) {
          if (isIconVisible && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            modelData.activate()
            event.accepted = true
          }
        }

        property bool counted: false

        function updateCount() {
          var shouldBeCounted = isIconVisible;
          if (shouldBeCounted && !counted) {
            systemTrayAreaRoot.visibleCount++;
            counted = true;
          } else if (!shouldBeCounted && counted) {
            systemTrayAreaRoot.visibleCount--;
            counted = false;
          }
        }

        Component.onCompleted: updateCount()
        Component.onDestruction: {
          if (counted) {
            systemTrayAreaRoot.visibleCount--;
            counted = false;
          }
        }

        readonly property bool isPixmapIcon: modelData.icon.indexOf("image://qspixmap/") === 0

        IconImage {
          id: trayThemeIcon
          anchors.centerIn: parent
          source: modelData.icon
          width: (Config.iconSize + 2)
          height: width
          visible: !isPixmapIcon
        }

        Image {
          id: trayPixmapIcon
          anchors.centerIn: parent
          source: modelData.icon
          width: (Config.iconSize + 2)
          height: width
          fillMode: Image.PreserveAspectFit
          visible: isPixmapIcon
        }

        Rectangle {
          anchors.fill: parent
          radius: Config.shapeMedium
          color: "transparent"
          border.width: trayIconDelegate.activeFocus ? Config.themeFocusBorderWidth : 0
          border.color: Config.neoBrutalism ? Colors.styleOutline : Colors.primary
        }

        QsMenuAnchor {
          id: menuAnchor
          menu: modelData.menu
          anchor.window: parentWindow
          anchor.item: trayIconDelegate
          anchor.edges: systemTrayAreaRoot.horizontal ? Edges.Bottom : Edges.Right
          anchor.gravity: systemTrayAreaRoot.horizontal ? Edges.Bottom : Edges.Right
        }

        MouseArea {
          id: trayMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton && modelData.hasMenu) {
              menuAnchor.open()
            } else if (mouse.button === Qt.MiddleButton) {
              modelData.secondaryActivate()
            } else {
              modelData.activate()
            }
          }
        }
      }
    }
  }
}
