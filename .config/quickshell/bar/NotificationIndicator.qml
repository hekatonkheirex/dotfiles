import QtQuick
import QtQuick.Layouts

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property int notificationCount: 0

  signal clicked(var mouse)

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: config ? config.widgetSize : 50

  readonly property bool hasNotifications: notificationCount > 0

  readonly property string iconLabel: hasNotifications ? "notifications_active" : "notifications"

  Rectangle {
    id: bgOverlay
    anchors {
      fill: parent
      leftMargin: 6
      rightMargin: 6
    }
    radius: config ? config.borderRadius : 14
    clip: true
    color: colors_ ? (mouseArea.containsMouse ? colors_.surfaceContainerHighest : colors_.surfaceContainerHigh) : "#2B2930"
    border.color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: config ? config.animationDuration : 150 }
    }
  }

  Text {
    id: iconText
    anchors.centerIn: parent
    text: root.iconLabel
    color: colors_ ? colors_.primary : "#D0BCFF"
    font.family: config ? config.iconFont : "Material Symbols Outlined"
    font.pixelSize: config ? config.iconSize : 22
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
      color: colors_ ? colors_.error : "#F2B8B5"

      Text {
        id: badgeText
        anchors.centerIn: parent
        text: notificationCount > 99 ? "99+" : notificationCount.toString()
        color: colors_ ? colors_.fgError : "#601410"
        font.family: config ? config.fontFamily : "Google Sans Flex"
        font.pixelSize: config ? (config.fontPixelSize - 3) : 7
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
