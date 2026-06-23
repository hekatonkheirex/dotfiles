import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
  id: horizontalSystemTrayAreaRoot

  property QtObject colors_: null
  property QtObject config: null
  property var parentWindow: null

  property int visibleCount: 0
  readonly property real preferredWidth: visibleCount * (config ? config.widgetSize : 50)

  onPreferredWidthChanged: {
    console.log("DEBUG HorizontalSystemTrayArea preferredWidth changed to: " + preferredWidth + " (count: " + visibleCount + ")")
  }

  Layout.preferredHeight: config ? config.widgetSize : 50
  Layout.preferredWidth: preferredWidth
  visible: visibleCount > 0

  Rectangle {
    anchors {
      fill: parent
      topMargin: 6
      bottomMargin: 6
    }
    radius: config ? config.borderRadius : 14
    clip: true
    color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
    border.color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
    border.width: 1
  }

  RowLayout {
    id: trayRow
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
        Layout.alignment: Qt.AlignVCenter
        width: visible ? (config ? config.widgetSize : 50) : 0
        height: visible ? (config ? config.widgetSize : 50) : 0

        property bool counted: false

        function updateCount() {
          var shouldBeCounted = isIconVisible;
          console.log("DEBUG [HorizontalSystemTrayArea] updateCount: id=" + modelData.id + " isIconVisible=" + isIconVisible + " counted=" + counted + " shouldBeCounted=" + shouldBeCounted + " currentCount=" + horizontalSystemTrayAreaRoot.visibleCount)
          if (shouldBeCounted && !counted) {
            horizontalSystemTrayAreaRoot.visibleCount++;
            counted = true;
            console.log("DEBUG [HorizontalSystemTrayArea] Incremented: id=" + modelData.id + " newCount=" + horizontalSystemTrayAreaRoot.visibleCount)
          } else if (!shouldBeCounted && counted) {
            horizontalSystemTrayAreaRoot.visibleCount--;
            counted = false;
            console.log("DEBUG [HorizontalSystemTrayArea] Decremented: id=" + modelData.id + " newCount=" + horizontalSystemTrayAreaRoot.visibleCount)
          }
        }

        Component.onCompleted: {
          console.log("DEBUG [HorizontalSystemTrayArea] Delegate completed: id=" + modelData.id + " title=" + modelData.title + " icon=" + modelData.icon)
          updateCount()
        }
        Component.onDestruction: {
          if (counted) {
            horizontalSystemTrayAreaRoot.visibleCount--;
            counted = false;
            console.log("DEBUG [HorizontalSystemTrayArea] Destroyed/Decremented: id=" + modelData.id + " newCount=" + horizontalSystemTrayAreaRoot.visibleCount)
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
          anchor.edges: Edges.Bottom
          anchor.gravity: Edges.Bottom
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
