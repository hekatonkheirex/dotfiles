import QtQuick
import QtQuick.Layouts
import Quickshell
import "primitives"
import "../config"

PopupBase {
  id: root

  surfaceHeight: Math.min(contentColumn.implicitHeight + 32, 500)

  property var notifications: []
  property int count: 0
  readonly property int historyLimit: Math.max(1, Settings.notificationHistoryLimit)

  function trimHistory() {
    var copy = notifications.slice()
    var removed = []
    while (copy.length > root.historyLimit) removed.push(copy.shift())
    notifications = copy
    count = notifications.length
    for (var i = 0; i < removed.length; i++) {
      if (removed[i] && removed[i].dismiss) removed[i].dismiss()
    }
  }

  function addNotification(n) {
    var copy = notifications.slice()
    copy.push(n)
    notifications = copy
    count = notifications.length
    root.trimHistory()
  }

  function removeNotification(n) {
    for (var i = 0; i < notifications.length; i++) {
      if (notifications[i] === n) {
        var copy = notifications.slice()
        copy.splice(i, 1)
        notifications = copy
        count = notifications.length
        return
      }
    }
  }

  function clearAll() {
    for (var i = 0; i < notifications.length; i++) {
      notifications[i].dismiss()
    }
    notifications = []
    count = 0
  }

  // Called externally from shell.qml on notification received
  function onNotificationReceived(notif) {
    root.addNotification(notif)
    notif.closed.connect(function() {
      root.removeNotification(notif)
    })
  }

  Connections {
    target: Settings
    function onNotificationHistoryLimitChanged() { root.trimHistory() }
  }


  Column {
    id: contentColumn
    anchors {
      fill: parent
      margins: Config.popupPadding
    }
    spacing: 12

        RowLayout {
          width: parent.width

          Text {
            text: "Notifications"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: (Config.fontPixelSize + 8)
            font.weight: Font.Bold
          }

          Item { Layout.fillWidth: true }

          Text {
            text: count === 0 ? "None" : count.toString()
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: (Config.fontPixelSize + 4)
          }

          IconButton {
            size: 24
            iconSize: 16
            visible: count > 0
            iconLabel: "delete_sweep"
            iconColor: Colors.fgSurfaceVariant
            accessibleName: "Clear notifications"
            tooltipText: "Clear notifications"
            onClicked: root.clearAll()
          }
        }

        PopupDivider {
          visible: count > 0
        }

        ListView {
          id: notifList
          width: parent.width
          height: Math.min(400, contentHeight)
          model: root.notifications
          visible: count > 0
          spacing: 8
          clip: true

            delegate: Item {
              id: notifDelegate
              width: parent.width
              height: mainContainer.implicitHeight + 8

              readonly property QtObject notif: modelData

              Rectangle {
                id: mainContainer
                width: parent.width
                implicitHeight: cardLayout.implicitHeight + 24
                radius: Config.shapeLarge
                color: Qt.tint(Colors.surfaceContainer, notifMouse.containsMouse ? Colors.hoverOverlay : Qt.rgba(0, 0, 0, 0))
                border.width: Config.themeBorderWidth
                border.color: Colors.styleOutline

                Behavior on color {
                  ColorAnimation { duration: Config.animationDuration}
                }

                MouseArea {
                  id: notifMouse
                  anchors.fill: parent
                  hoverEnabled: true
                }

                ColumnLayout {
                  id: cardLayout
                  anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 16
                    rightMargin: 16
                    topMargin: 12
                  }
                  spacing: 8

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                      width: 20
                      height: 20
                      radius: width / 2
                      color: Colors.primaryContainer

                      Text {
                        anchors.centerIn: parent
                        text: {
                          var app = notif ? (notif.appName || "") : ""
                          return app.length > 0 ? app.charAt(0).toUpperCase() : "?"
                        }
                        color: Colors.fgPrimaryContainer
                        font.family: Config.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                      }
                    }

                    Text {
                      text: notif ? (notif.appName || "Notification") : "Notification"
                      color: Colors.fgSurfaceVariant
                      font.family: Config.fontFamily
                      font.pixelSize: 11
                      font.weight: Font.Medium
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }

                    IconButton {
                      size: 20
                      iconSize: 12
                      iconLabel: "close"
                      iconColor: Colors.fgSurfaceVariant
                      accessibleName: "Dismiss notification"
                      tooltipText: "Dismiss notification"
                      onClicked: {
                        if (index >= 0 && index < root.notifications.length) {
                          root.notifications[index].dismiss()
                        }
                      }
                    }
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.1)
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                      Layout.fillWidth: true
                      text: notif ? (notif.summary || "") : ""
                      color: Colors.fgSurface
                      font.family: Config.fontFamily
                      font.pixelSize: 14
                      font.weight: Font.Bold
                      elide: Text.ElideRight
                      visible: text !== ""
                    }

                    Text {
                      Layout.fillWidth: true
                      text: notif ? (notif.body || "") : ""
                      color: Colors.fgSurfaceVariant
                      font.family: Config.fontFamily
                      font.pixelSize: 12
                      wrapMode: Text.WordWrap
                      maximumLineCount: 3
                      elide: Text.ElideRight
                      visible: text !== ""
                    }
                  }
                }
              }
            }
        }

        Text {
          text: "No new notifications"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: (Config.fontPixelSize + 2)
          visible: count === 0
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }
}
