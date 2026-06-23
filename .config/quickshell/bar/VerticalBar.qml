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
    top: true
    bottom: true
  }


  implicitWidth: (config ? config.barWidth : 50) + 16
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
  readonly property bool horizontal: false

  function getLauncherX() {
    return 0
  }

  function getMenuIndicatorX() {
    return 0
  }

  function getMenuIndicatorY() {
    var wSize = config ? config.widgetSize : 50
    return root.height - 6 - wSize - 6 - wSize - 6 - wSize
  }

  function togglePopup(name, widget) {
    var y = widget ? widget.mapToItem(null, 0, 0).y : 0
    if (openPopup === name) {
      openPopup = ""
    } else {
      popupAnchorY = y
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

  onExpandProgressChanged: console.log("DEBUG VerticalBar expandProgress changed to: " + expandProgress + ", expanded: " + expanded)
  onExpandedChanged: console.log("DEBUG VerticalBar expanded changed to: " + expanded)

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
      x: 8 * (1.0 - root.expandProgress)
      width: (config ? config.barWidth : 50) - 8 * (1.0 - root.expandProgress)
      height: (layout.implicitHeight + 12) + (parent.height - (layout.implicitHeight + 12)) * root.expandProgress
      y: ((config ? config.widgetSize : 50) + 6) * (1.0 - root.expandProgress)
      radius: (width / 2) * (1.0 - root.expandProgress) + (config ? config.borderRadius : 14) * root.expandProgress
      color: colors_ ? colors_.bg : "#1C1B1F"

      // Square-off helper for top-left corner
      Rectangle {
        width: barBg.radius * root.expandProgress
        height: barBg.radius * root.expandProgress
        color: barBg.color
        visible: width > 0
      }

      // Square-off helper for bottom-left corner
      Rectangle {
        width: barBg.radius * root.expandProgress
        height: barBg.radius * root.expandProgress
        y: barBg.height - height
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

      ColumnLayout {
        id: layout
        anchors { fill: parent; topMargin: 6; bottomMargin: 6 }
        spacing: 6 * root.expandProgress

        Item {
          id: launcherWrapper
          Layout.preferredWidth: parent.width
          Layout.preferredHeight: (config ? config.widgetSize : 50) * root.expandProgress
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

        WorkspaceIndicator {
          id: wsIndicator
          colors_: root.colors_
          config: root.config
          Layout.preferredWidth: parent.width
        }



        Item {
          Layout.fillHeight: root.expanded
          Layout.preferredHeight: 0
          visible: root.expandProgress > 0
        }

        Item {
          id: wifiWrapper
          Layout.preferredWidth: parent.width
          Layout.preferredHeight: (config ? config.widgetSize : 50) * root.expandProgress
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
          Layout.preferredWidth: parent.width
          Layout.preferredHeight: (config ? config.widgetSize : 50) * root.expandProgress
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
          Layout.preferredWidth: parent.width
          Layout.preferredHeight: (config ? config.widgetSize : 50) * root.expandProgress
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
          Layout.preferredWidth: parent.width
          Layout.preferredHeight: (config ? config.widgetSize : 50) * root.expandProgress
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
          Layout.preferredWidth: parent.width
          Layout.preferredHeight: (config ? config.widgetSize : 50) * root.expandProgress
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
          Layout.preferredWidth: parent.width
          Layout.preferredHeight: systemTray.preferredHeight * root.expandProgress
          opacity: root.expandProgress
          visible: systemTray.visibleCount > 0 && (root.expandProgress > 0)
          clip: true

          onHeightChanged: console.log("DEBUG systemTrayWrapper height changed to: " + height + ", visible: " + visible + ", opacity: " + opacity + ", expandProgress: " + root.expandProgress + ", systemTray.visible: " + systemTray.visible + ", systemTray.preferredHeight: " + systemTray.preferredHeight)
          onVisibleChanged: console.log("DEBUG systemTrayWrapper visible changed to: " + visible + ", height: " + height)

          SystemTrayArea {
            id: systemTray
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            parentWindow: root
          }
        }

        Item {
          id: menuWrapper
          Layout.preferredWidth: parent.width
          Layout.preferredHeight: (config ? config.widgetSize : 50) * root.expandProgress
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
          Layout.preferredWidth: parent.width
          Layout.preferredHeight: (config ? config.widgetSize : 50) * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          Item {
            id: clockWidget
            anchors.fill: parent

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              anchors.topMargin: 20
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
          Layout.preferredWidth: parent.width
          Layout.preferredHeight: (config ? config.widgetSize : 50) * root.expandProgress
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
