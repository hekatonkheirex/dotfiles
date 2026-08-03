import QtQuick
import QtQuick.Layouts
import "../config"

Item {
  id: root

  property int notificationCount: 0

  signal clicked(var mouse)

  Layout.preferredWidth: Config.widgetSize
  Layout.preferredHeight: Config.widgetSize

  property bool active: false
  property bool horizontal: false

  readonly property bool hasNotifications: notificationCount > 0

  readonly property string iconLabel: hasNotifications ? "notifications_active" : "notifications"

  Rectangle {
    id: bgOverlay
    anchors {
      fill: parent
      leftMargin: root.horizontal ? 0 : 6
      rightMargin: root.horizontal ? 0 : 6
      topMargin: root.horizontal ? 6 : 0
      bottomMargin: root.horizontal ? 6 : 0
    }
    radius: root.horizontal ? height / 2 : width / 2
    clip: true
    color: {
      var overlay = mouseArea.pressed ? Colors.pressOverlay : (mouseArea.containsMouse ? Colors.hoverOverlay : Qt.rgba(0, 0, 0, 0))
      return Qt.tint(root.active ? Colors.primary : "transparent", overlay)
    }
    border.color: {
      if (root.active) return "transparent"
      if (mouseArea.containsMouse) return Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
      return "transparent"
    }
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: Config.animationDuration}
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    text: root.iconLabel
    color: {
      if (root.active) return Colors.fgPrimary
      if (mouseArea.containsMouse) return Colors.primary
      return Colors.primary
    }
    font.family: Config.iconFont
    font.pixelSize: Config.iconSize
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  Item {
    anchors.fill: parent
    visible: hasNotifications

    Rectangle {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: 4
      anchors.topMargin: 4
      width: badgeText.implicitWidth + 6
      height: 14
      radius: 7
      color: Colors.error

      Text {
        id: badgeText
        anchors.centerIn: parent
        text: notificationCount > 99 ? "99+" : notificationCount.toString()
        color: Colors.fgError
        font.family: Config.fontFamily
        font.pixelSize: (Config.fontPixelSize - 3)
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.clicked(mouse)
    }
  }
}
