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
  property bool horizontal: true

  readonly property real wSize: config ? config.widgetSize : 50

  anchors {
    left: true
    right: root.horizontal
    top: true
    bottom: !root.horizontal
  }

  implicitHeight: (config ? config.barWidth : 50) + 16
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

  function getLauncherX() {
    if (!root.horizontal) return 0
    return launcherWidget ? launcherWidget.mapToItem(null, 0, 0).x + launcherWidget.width / 2 : 0
  }

  function getMenuIndicatorX() {
    if (!root.horizontal) return 0
    return menuIndicator ? menuIndicator.mapToItem(null, 0, 0).x + menuIndicator.width / 2 : 0
  }

  function getMenuIndicatorY() {
    return root.height - 6 - wSize - 6 - wSize - 6 - wSize
  }

  function togglePopup(name, widget) {
    var x = widget ? widget.mapToItem(null, 0, 0).x : 0
    var y = widget ? widget.mapToItem(null, 0, 0).y : 0
    var w = widget ? widget.width : 0
    if (openPopup === name) {
      openPopup = ""
    } else {
      if (root.horizontal) {
        popupAnchorX = x + w / 2
        popupAnchorY = root.height - 16 // sit exactly at the bottom of the barBg
      } else {
        popupAnchorY = y
      }
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
      x: root.horizontal
        ? (root.wSize + 6) * (1.0 - root.expandProgress)
        : 8 * (1.0 - root.expandProgress)
      y: root.horizontal
        ? 8 * (1.0 - root.expandProgress)
        : (root.wSize + 6) * (1.0 - root.expandProgress)
      width: root.horizontal
        ? (layout.implicitWidth + 12) + (parent.width - (layout.implicitWidth + 12)) * root.expandProgress
        : (config ? config.barWidth : 50) - 8 * (1.0 - root.expandProgress)
      height: root.horizontal
        ? (config ? config.barWidth : 50) - 8 * (1.0 - root.expandProgress)
        : (layout.implicitHeight + 12) + (parent.height - (layout.implicitHeight + 12)) * root.expandProgress
      radius: (root.horizontal ? height / 2 : width / 2) * (1.0 - root.expandProgress) + (config ? config.borderRadius : 14) * root.expandProgress
      color: colors_ ? colors_.bg : "#1C1B1F"

      // Square-off helper for the docked edge's near corner
      Rectangle {
        width: barBg.radius * root.expandProgress
        height: barBg.radius * root.expandProgress
        color: barBg.color
        visible: width > 0
      }

      // Square-off helper for the docked edge's far corner
      Rectangle {
        width: barBg.radius * root.expandProgress
        height: barBg.radius * root.expandProgress
        x: root.horizontal ? barBg.width - width : 0
        y: root.horizontal ? 0 : barBg.height - height
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

      GridLayout {
        id: layout
        flow: root.horizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
        anchors {
          fill: parent
          leftMargin: root.horizontal ? 6 : 0
          rightMargin: root.horizontal ? 6 : 0
          topMargin: root.horizontal ? 0 : 6
          bottomMargin: root.horizontal ? 0 : 6
        }
        columnSpacing: 6 * root.expandProgress
        rowSpacing: 6 * root.expandProgress

        Item {
          id: launcherWrapper
          Layout.preferredWidth: root.horizontal ? root.wSize * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : root.wSize * root.expandProgress
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
          horizontal: root.horizontal
          colors_: root.colors_
          config: root.config
          Layout.preferredWidth: root.horizontal ? implicitWidth : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : implicitHeight
        }

        Item {
          Layout.fillWidth: root.horizontal && root.expanded
          Layout.fillHeight: !root.horizontal && root.expanded
          Layout.preferredWidth: 0
          Layout.preferredHeight: 0
          visible: root.expandProgress > 0
        }

        Item {
          id: wifiWrapper
          Layout.preferredWidth: root.horizontal ? root.wSize * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : root.wSize * root.expandProgress
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
          Layout.preferredWidth: root.horizontal ? root.wSize * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : root.wSize * root.expandProgress
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
          Layout.preferredWidth: root.horizontal ? root.wSize * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : root.wSize * root.expandProgress
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
          Layout.preferredWidth: root.horizontal ? root.wSize * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : root.wSize * root.expandProgress
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
          Layout.preferredWidth: root.horizontal ? root.wSize * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : root.wSize * root.expandProgress
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
          Layout.preferredWidth: root.horizontal ? systemTray.preferredLength * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : systemTray.preferredLength * root.expandProgress
          opacity: root.expandProgress
          visible: systemTray.visibleCount > 0 && (root.expandProgress > 0)
          clip: true

          SystemTrayArea {
            id: systemTray
            horizontal: root.horizontal
            anchors.fill: parent
            colors_: root.colors_
            config: root.config
            parentWindow: root
          }
        }

        Item {
          id: menuWrapper
          Layout.preferredWidth: root.horizontal ? root.wSize * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : root.wSize * root.expandProgress
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
          Layout.preferredWidth: root.horizontal ? root.wSize * 1.5 * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : root.wSize * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          Item {
            id: clockWidget
            anchors.fill: parent

            Text {
              anchors.centerIn: root.horizontal ? parent : undefined
              anchors.horizontalCenter: root.horizontal ? undefined : parent.horizontalCenter
              anchors.top: root.horizontal ? undefined : parent.top
              anchors.topMargin: root.horizontal ? 0 : 20
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
          Layout.preferredWidth: root.horizontal ? root.wSize * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : root.wSize * root.expandProgress
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
