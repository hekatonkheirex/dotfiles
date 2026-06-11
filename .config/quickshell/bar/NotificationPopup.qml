import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property int anchorY: 0

  signal dismissed()

  implicitWidth: config ? config.popupWidth : 340
  implicitHeight: Math.min(contentColumn.implicitHeight + 32, 500)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  anchors.left: true
  margins.left: config ? config.barWidth + 4 : 48
  property int screenH: Screen.desktopAvailableHeight

  anchors.top: true
  margins.top: Math.max(0, Math.min(anchorY - implicitHeight / 2, screenH - implicitHeight))

  property var notifications: []
  property int count: 0

  function addNotification(n) {
    var copy = notifications.slice()
    copy.push(n)
    notifications = copy
    count = notifications.length
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


  onVisibleChanged: {
    if (visible) {
      entryAnimation.start()
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.dismissed()

    FocusDismiss {
      target: root
      config: root.config
      onDismissed: root.dismissed()
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: config ? config.borderRadius : 14
      color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
      clip: true

      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: 0; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

      ParallelAnimation {
        id: entryAnimation
        NumberAnimation {
          target: scaleTransform
          properties: "xScale,yScale"
          from: 0.85
          to: 1.0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
          to: 0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: bg
          property: "opacity"
          from: 0.0
          to: 1.0
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

      Column {
        id: contentColumn
        anchors {
          fill: parent
          margins: config ? config.popupPadding : 16
        }
        spacing: 12

        RowLayout {
          width: parent.width

          Text {
            text: "Notifications"
            color: colors_ ? colors_.fgSurface : "#FFFFFF"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: config ? (config.fontPixelSize + 8) : 18
            font.weight: Font.Bold
          }

          Item { Layout.fillWidth: true }

          Text {
            text: count === 0 ? "None" : count.toString()
            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
            font.family: config ? config.fontFamily : "Google Sans Flex"
            font.pixelSize: config ? (config.fontPixelSize + 4) : 14
          }

          Rectangle {
            width: 24
            height: 24
            radius: 12
            visible: count > 0
            color: clearAllMouse.containsMouse ? (colors_ ? colors_.surfaceContainerHighest : "#36343B") : "transparent"

            Behavior on color {
              ColorAnimation { duration: config ? config.animationDuration : 150 }
            }

            Text {
              anchors.centerIn: parent
              text: "delete_sweep"
              color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
              font.family: config ? config.iconFont : "Material Symbols Outlined"
              font.pixelSize: 16
            }

            MouseArea {
              id: clearAllMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.clearAll()
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
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
                radius: 16
                color: notifMouse.containsMouse ? (colors_ ? colors_.surfaceContainerHighest : "#36343B") : (colors_ ? colors_.surfaceContainer : "#211F26")
                border.width: 1
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)

                Behavior on color {
                  ColorAnimation { duration: config ? config.animationDuration : 150 }
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
                      radius: 10
                      color: colors_ ? colors_.primaryContainer : "#4F378B"

                      Text {
                        anchors.centerIn: parent
                        text: {
                          var app = notif ? (notif.appName || "") : ""
                          return app.length > 0 ? app.charAt(0).toUpperCase() : "?"
                        }
                        color: colors_ ? colors_.fgPrimaryContainer : "#EADDFF"
                        font.family: config ? config.fontFamily : "Google Sans Flex"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                      }
                    }

                    Text {
                      text: notif ? (notif.appName || "Notification") : "Notification"
                      color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                      font.family: config ? config.fontFamily : "Google Sans Flex"
                      font.pixelSize: 11
                      font.weight: Font.Medium
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }

                    Rectangle {
                      width: 20
                      height: 20
                      radius: 10
                      color: dismissMouse.containsMouse ? (colors_ ? colors_.surfaceContainerHighest : "#36343B") : "transparent"

                      Behavior on color {
                        ColorAnimation { duration: config ? config.animationDuration : 150 }
                      }

                      Text {
                        anchors.centerIn: parent
                        text: "close"
                        color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                        font.family: config ? config.iconFont : "Material Symbols Outlined"
                        font.pixelSize: 12
                      }

                      MouseArea {
                        id: dismissMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (index >= 0 && index < root.notifications.length) {
                            root.notifications[index].dismiss()
                          }
                        }
                      }
                    }
                  }

                  Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.1) : Qt.rgba(255, 255, 255, 0.05)
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                      Layout.fillWidth: true
                      text: notif ? (notif.summary || "") : ""
                      color: colors_ ? colors_.fgSurface : "#FFFFFF"
                      font.family: config ? config.fontFamily : "Google Sans Flex"
                      font.pixelSize: 14
                      font.weight: Font.Bold
                      elide: Text.ElideRight
                      visible: text !== ""
                    }

                    Text {
                      Layout.fillWidth: true
                      text: notif ? (notif.body || "") : ""
                      color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                      font.family: config ? config.fontFamily : "Google Sans Flex"
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
          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
          font.family: config ? config.fontFamily : "Google Sans Flex"
          font.pixelSize: config ? (config.fontPixelSize + 2) : 12
          visible: count === 0
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }
    }
  }
}
