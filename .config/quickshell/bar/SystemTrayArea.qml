import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
  id: systemTrayAreaRoot

  property QtObject colors_: null
  property QtObject config: null
  property var parentWindow: null

  property int visibleCount: 0
  readonly property real preferredHeight: visibleCount * (config ? config.widgetSize : 50)

  onPreferredHeightChanged: {
    console.log("DEBUG SystemTrayArea preferredHeight changed to: " + preferredHeight + " (count: " + visibleCount + ")")
  }

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: preferredHeight
  visible: visibleCount > 0

  Rectangle {
    anchors {
      fill: parent
      leftMargin: 6
      rightMargin: 6
    }
    radius: config ? config.borderRadius : 14
    clip: true
    color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
    border.color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
    border.width: 1
  }

  ColumnLayout {
    id: trayColumn
    anchors.fill: parent
    spacing: 0

    Repeater {
      id: trayRepeater
      model: SystemTray.items

      delegate: Item {
        id: trayIconDelegate
        required property SystemTrayItem modelData

        // Filter out blueman and udiskie
        readonly property bool isIconVisible: modelData.id !== "blueman" && modelData.id !== "udiskie"
        visible: isIconVisible

        Layout.preferredWidth: visible ? (config ? config.widgetSize : 50) : 0
        Layout.preferredHeight: visible ? (config ? config.widgetSize : 50) : 0
        Layout.alignment: Qt.AlignHCenter
        width: visible ? (config ? config.widgetSize : 50) : 0
        height: visible ? (config ? config.widgetSize : 50) : 0

        property bool counted: false

        function updateCount() {
          var shouldBeCounted = isIconVisible;
          console.log("DEBUG [SystemTrayArea] updateCount: id=" + modelData.id + " isIconVisible=" + isIconVisible + " counted=" + counted + " shouldBeCounted=" + shouldBeCounted + " currentCount=" + systemTrayAreaRoot.visibleCount)
          if (shouldBeCounted && !counted) {
            systemTrayAreaRoot.visibleCount++;
            counted = true;
            console.log("DEBUG [SystemTrayArea] Incremented: id=" + modelData.id + " newCount=" + systemTrayAreaRoot.visibleCount)
          } else if (!shouldBeCounted && counted) {
            systemTrayAreaRoot.visibleCount--;
            counted = false;
            console.log("DEBUG [SystemTrayArea] Decremented: id=" + modelData.id + " newCount=" + systemTrayAreaRoot.visibleCount)
          }
        }

        Component.onCompleted: {
          console.log("DEBUG [SystemTrayArea] Delegate completed: id=" + modelData.id + " title=" + modelData.title + " icon=" + modelData.icon)
          updateCount()
        }
        Component.onDestruction: {
          if (counted) {
            systemTrayAreaRoot.visibleCount--;
            counted = false;
            console.log("DEBUG [SystemTrayArea] Destroyed/Decremented: id=" + modelData.id + " newCount=" + systemTrayAreaRoot.visibleCount)
          }
        }

        readonly property bool isPixmapIcon: modelData.icon.indexOf("image://qspixmap/") === 0

        IconImage {
          id: trayThemeIcon
          anchors.centerIn: parent
          source: modelData.icon
          width: config ? (config.iconSize + 2) : 24
          height: width
          visible: !isPixmapIcon
        }

        Image {
          id: trayPixmapIcon
          anchors.centerIn: parent
          source: modelData.icon
          width: config ? (config.iconSize + 2) : 24
          height: width
          fillMode: Image.PreserveAspectFit
          visible: isPixmapIcon
        }

        QsMenuAnchor {
          id: menuAnchor
          menu: modelData.menu
          anchor.window: parentWindow
          anchor.item: trayIconDelegate
          anchor.edges: Edges.Right
          anchor.gravity: Edges.Right
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
