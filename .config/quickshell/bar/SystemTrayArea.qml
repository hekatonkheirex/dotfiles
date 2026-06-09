import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: trayRepeater.count > 0
    ? (trayRepeater.count * (config ? config.widgetSize : 50))
    : 0
  visible: trayRepeater.count > 0

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

        Layout.preferredWidth: config ? config.widgetSize : 50
        Layout.preferredHeight: config ? config.widgetSize : 50
        Layout.alignment: Qt.AlignHCenter
        width: config ? config.widgetSize : 50
        height: config ? config.widgetSize : 50

        IconImage {
          id: trayIcon
          anchors.centerIn: parent
          source: modelData.icon
          width: config ? (config.iconSize + 2) : 24
          height: width
        }

        MouseArea {
          id: trayMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton && modelData.hasMenu) {
              modelData.display(trayColumn, mouse.x, mouse.y)
            } else {
              modelData.activate()
            }
          }
        }
      }
    }
  }
}
