import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null
  property int notificationCount: 0
  property QtObject notificationServer: null

  anchors {
    left: true
    right: true
    top: true
    bottom: false
  }

  implicitHeight: (config ? config.barWidth : 50) + 16
  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: config ? config.barWidth : 50
  WlrLayershell.namespace: "quickshell-panel"
  WlrLayershell.layer: WlrLayer.Top

  property date now: new Date()

  Timer {
    interval: config ? config.clockIntervalMs : 1000
    running: root.visible
    repeat: true
    onTriggered: now = new Date()
  }

  property string openPopup: ""
  property int popupAnchorX: 0
  property int popupAnchorY: 0
  readonly property bool horizontal: true

  function getLauncherX() {
    return launcherWidget ? launcherWidget.mapToItem(null, 0, 0).x + launcherWidget.width / 2 : 0
  }

  function getMenuIndicatorX() {
    return menuIndicator ? menuIndicator.mapToItem(null, 0, 0).x + menuIndicator.width / 2 : 0
  }

  function togglePopup(name, widget) {
    var x = widget ? widget.mapToItem(null, 0, 0).x : 0
    var y = widget ? widget.mapToItem(null, 0, 0).y : 0
    var w = widget ? widget.width : 0
    if (openPopup === name) {
      openPopup = ""
    } else {
      popupAnchorX = x + w / 2
      popupAnchorY = root.height - 16 // sit exactly at the bottom of the barBg
      openPopup = name
    }
  }

  property bool expanded: false
  property real expandProgress: expanded ? 1.0 : 0.0

  Behavior on expandProgress {
    NumberAnimation {
      duration: 450
      easing.type: Easing.OutBack
      easing.amplitude: 0.8
    }
  }

  Timer {
    id: collapseTimer
    interval: 5000
    running: false
    repeat: false
    onTriggered: {
      if (!barMouseArea.containsMouse && root.openPopup === "") {
        root.expanded = false
      }
    }
  }

  onOpenPopupChanged: {
    if (openPopup === "") {
      if (!barMouseArea.containsMouse) {
        collapseTimer.restart()
      }
    } else {
      collapseTimer.stop()
      if (barMouseArea.containsMouse) {
        root.expanded = true
      }
    }
  }

  mask: Region { item: barBg }

  Item {
    anchors.fill: parent

    Rectangle {
      id: barBg
      y: 8 * (1.0 - root.expandProgress)
      height: (config ? config.barWidth : 50) - 8 * (1.0 - root.expandProgress)
      x: ((config ? config.widgetSize : 50) + 6) * (1.0 - root.expandProgress)
      width: (layout.implicitWidth + 12) + (parent.width - (layout.implicitWidth + 12)) * root.expandProgress
      radius: (height / 2) * (1.0 - root.expandProgress) + (config ? config.borderRadius : 14) * root.expandProgress
      color: colors_ ? colors_.bg : "#1C1B1F"

      // Square-off helper for top-left corner (docks top)
      Rectangle {
        width: barBg.radius * root.expandProgress
        height: barBg.radius * root.expandProgress
        color: barBg.color
        visible: width > 0
      }

      // Square-off helper for top-right corner (docks top)
      Rectangle {
        width: barBg.radius * root.expandProgress
        height: barBg.radius * root.expandProgress
        x: barBg.width - width
        color: barBg.color
        visible: width > 0
      }

      MouseArea {
        id: barMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.openPopup = ""
        enabled: !root.openPopup

        onContainsMouseChanged: {
          if (containsMouse) {
            collapseTimer.stop()
            root.expanded = true
          } else {
            if (root.openPopup === "") {
              collapseTimer.restart()
            }
          }
        }
      }

      RowLayout {
        id: layout
        anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
        spacing: 6 * root.expandProgress

        Item {
          id: launcherWrapper
          Layout.preferredHeight: parent.height
          Layout.preferredWidth: (config ? config.widgetSize : 50) * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          Launcher {
            id: launcherWidget
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            active: root.openPopup === "launcher"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("launcher", launcherWidget)
            }
          }
        }

        HorizontalWorkspaceIndicator {
          id: wsIndicator
          colors_: root.colors_
          config: root.config
          Layout.preferredHeight: parent.height
        }



        Item {
          Layout.fillWidth: root.expanded
          Layout.preferredWidth: 0
          visible: root.expandProgress > 0
        }

        Item {
          id: wifiWrapper
          Layout.preferredHeight: parent.height
          Layout.preferredWidth: (config ? config.widgetSize : 50) * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          WifiIndicator {
            id: wifiIndicator
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            active: root.openPopup === "wifi"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("wifi", wifiIndicator)
            }
          }
        }

        Item {
          id: btWrapper
          Layout.preferredHeight: parent.height
          Layout.preferredWidth: (config ? config.widgetSize : 50) * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          BtIndicator {
            id: btIndicator
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            active: root.openPopup === "bluetooth"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("bluetooth", btIndicator)
            }
          }
        }

        Item {
          id: audioWrapper
          Layout.preferredHeight: parent.height
          Layout.preferredWidth: (config ? config.widgetSize : 50) * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          AudioIndicator {
            id: audioIndicator
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            active: root.openPopup === "audio"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("audio", audioIndicator)
            }
          }
        }

        Item {
          id: brightnessWrapper
          Layout.preferredHeight: parent.height
          Layout.preferredWidth: (config ? config.widgetSize : 50) * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          BrightnessIndicator {
            id: brightnessIndicator
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            active: root.openPopup === "brightness"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("brightness", brightnessIndicator)
            }
          }
        }

        Item {
          id: batteryWrapper
          Layout.preferredHeight: parent.height
          Layout.preferredWidth: (config ? config.widgetSize : 50) * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          BatteryIndicator {
            id: batteryIndicator
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            active: root.openPopup === "battery"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("battery", batteryIndicator)
            }
          }
        }

        Item {
          id: systemTrayWrapper
          Layout.preferredHeight: parent.height
          Layout.preferredWidth: systemTray.preferredWidth * root.expandProgress
          opacity: root.expandProgress
          visible: systemTray.visibleCount > 0 && (root.expandProgress > 0)
          clip: true

          HorizontalSystemTrayArea {
            id: systemTray
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            parentWindow: root
          }
        }

        Item {
          id: menuWrapper
          Layout.preferredHeight: parent.height
          Layout.preferredWidth: (config ? config.widgetSize : 50) * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          MenuIndicator {
            id: menuIndicator
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            active: root.openPopup === "quickmenu"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("quickmenu", menuIndicator)
            }
          }
        }

        Item {
          id: clockWrapper
          Layout.preferredHeight: parent.height
          Layout.preferredWidth: (config ? config.widgetSize * 1.5 : 75) * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          Item {
            id: clockWidget
            anchors.fill: parent

            Text {
              anchors.centerIn: parent
              text: root.now.toLocaleString(Qt.locale(), "HH:mm")
              color: colors_ ? colors_.primary : "#D0BCFF"
              font.family: config ? config.fontFamily : "Roboto"
              font.pixelSize: config ? (config.fontPixelSize + 2) : 12
              font.weight: Font.Bold
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.togglePopup("calendar", clockWidget)
              }
            }
          }
        }

        Item {
          id: notifWrapper
          Layout.preferredHeight: parent.height
          Layout.preferredWidth: (config ? config.widgetSize : 50) * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          NotificationIndicator {
            id: notifIndicator
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            notificationCount: root.notificationCount
            active: root.openPopup === "notification"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("notification", notifIndicator)
            }
          }
        }
      }
    }
  }

  Binding {
    target: root
    property: "notificationCount"
    value: notificationServer && notificationServer.trackedNotifications ? notificationServer.trackedNotifications.count : 0
  }
}
