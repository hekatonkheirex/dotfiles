import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "primitives"
import "../config"

PopupBase {
  id: root
  surfaceColor: Colors.readingSurface

  surfaceHeight: Math.min(contentColumn.implicitHeight + Config.spacingPage, 500)

  property var notifications: []
  property int count: 0
  readonly property int historyLimit: Math.max(1, Settings.notificationHistoryLimit)

  function twoDigits(value) {
    return value < 10 ? "0" + value : value.toString()
  }

  function formatNotificationTimestamp(timestamp) {
    if (!timestamp) return ""
    var date = new Date(timestamp)
    var hours = date.getHours()
    var minutes = twoDigits(date.getMinutes())
    if (Settings.clock24h) return twoDigits(hours) + ":" + minutes
    var suffix = hours >= 12 ? "PM" : "AM"
    var displayHours = hours % 12
    if (displayHours === 0) displayHours = 12
    return displayHours + ":" + minutes + " " + suffix
  }

  function trimHistory() {
    var copy = notifications.slice()
    var removed = []
    while (copy.length > root.historyLimit) removed.push(copy.shift())
    notifications = copy
    count = notifications.length
    for (var i = 0; i < removed.length; i++) {
      var live = removed[i].liveNotif
      if (live) live.tracked = false
    }
  }

  function addNotification(n) {
    if (!n) return
    var entry = {
      id: n.id,
      appName: n.appName || "",
      summary: n.summary || "",
      body: n.body || "",
      timestamp: Date.now(),
      liveNotif: n
    }
    var copy = notifications.slice()
    copy.push(entry)
    notifications = copy
    count = notifications.length
    root.trimHistory()
    n.closed.connect(function() {
      entry.liveNotif = null
      for (var i = 0; i < root.notifications.length; i++) {
        if (root.notifications[i] !== entry) continue
        var updated = root.notifications.slice()
        updated[i] = Object.assign({}, entry, { liveNotif: null })
        root.notifications = updated
        return
      }
    })
  }

  function removeNotification(entry) {
    var copy = notifications.slice()
    for (var i = 0; i < copy.length; i++) {
      if (copy[i] !== entry) continue
      copy.splice(i, 1)
      notifications = copy
      count = notifications.length
      return
    }
  }

  function clearAll() {
    var copy = notifications.slice()
    notifications = []
    count = 0
    for (var i = 0; i < copy.length; i++) {
      if (copy[i].liveNotif) copy[i].liveNotif.tracked = false
    }
  }

  // Called externally from shell.qml on notification received.
  function onNotificationReceived(notif) {
    root.addNotification(notif)
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
    spacing: Config.spacingMedium

        RowLayout {
          width: parent.width

          Text {
            text: "Notifications"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeHeadlineSmallSize
            font.weight: Config.typeStrongWeight
            font.letterSpacing: Config.typeHeadlineTracking
            lineHeight: Config.typeHeadlineSmallLineHeight
            lineHeightMode: Text.FixedHeight
          }

          Item { Layout.fillWidth: true }

          Text {
            text: count === 0 ? "None" : count.toString()
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeTitleLargeSize
            font.letterSpacing: Config.typeTitleTracking
            lineHeight: Config.typeTitleLargeLineHeight
            lineHeightMode: Text.FixedHeight
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
          spacing: Config.spacingSmall
          clip: true
          ScrollBar.vertical: SettingsScrollBar { scrollTarget: notifList }

            delegate: Item {
              id: notifDelegate
              width: parent.width
              height: mainContainer.implicitHeight + Config.spacingSmall

              readonly property var notif: modelData

              Rectangle {
                id: mainContainer
                width: parent.width
                implicitHeight: cardLayout.implicitHeight + Config.spacingExtraLarge
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
                    leftMargin: Config.spacingLarge
                    rightMargin: Config.spacingLarge
                    topMargin: Config.spacingMedium
                  }
                  spacing: Config.spacingSmall

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: Config.spacingSmall

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
                        font.pixelSize: Config.typeLabelSmallSize
                        font.weight: Config.typeStrongWeight
                        font.letterSpacing: Config.typeLabelTracking
                      }
                    }

                    Text {
                      text: notif ? (notif.appName || "Notification") : "Notification"
                      color: Colors.fgSurfaceVariant
                      font.family: Config.fontFamily
                      font.pixelSize: Config.typeLabelSmallSize
                      font.weight: Config.typeMediumWeight
                      font.letterSpacing: Config.typeLabelTracking
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }

                    Text {
                      text: root.formatNotificationTimestamp(notif ? notif.timestamp : 0)
                      color: Colors.fgSurfaceVariant
                      font.family: Config.fontFamily
                      font.pixelSize: Config.typeLabelSmallSize
                      font.letterSpacing: Config.typeLabelTracking
                      opacity: 0.72
                      Layout.alignment: Qt.AlignVCenter
                    }

                    IconButton {
                      size: 20
                      iconSize: 12
                      iconLabel: notif && notif.liveNotif !== null ? "close" : "delete"
                      iconColor: Colors.fgSurfaceVariant
                      accessibleName: notif && notif.liveNotif !== null ? "Dismiss notification" : "Remove notification"
                      tooltipText: notif && notif.liveNotif !== null ? "Dismiss notification" : "Remove notification"
                      onClicked: {
                        if (!notif) return
                        if (notif.liveNotif) notif.liveNotif.tracked = false
                        else root.removeNotification(notif)
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
                    spacing: Config.spacingCompact

                    Text {
                      Layout.fillWidth: true
                      text: notif ? (notif.summary || "") : ""
                      color: Colors.fgSurface
                      font.family: Config.fontFamily
                      font.pixelSize: Config.typeTitleSmallSize
                      font.weight: Config.typeStrongWeight
                      font.letterSpacing: Config.typeTitleTracking
                      lineHeight: Config.typeTitleSmallLineHeight
                      lineHeightMode: Text.FixedHeight
                      elide: Text.ElideRight
                      visible: text !== ""
                    }

                    Text {
                      Layout.fillWidth: true
                      text: notif ? (notif.body || "") : ""
                      color: Colors.fgSurfaceVariant
                      font.family: Config.fontFamily
                      font.pixelSize: Config.typeBodySmallSize
                      font.letterSpacing: Config.typeBodyTracking
                      lineHeight: Config.typeBodySmallLineHeight
                      lineHeightMode: Text.FixedHeight
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
          font.pixelSize: Config.typeTitleSmallSize
          font.letterSpacing: Config.typeTitleTracking
          visible: count === 0
          anchors.horizontalCenter: parent.horizontalCenter
        }
      }
}
