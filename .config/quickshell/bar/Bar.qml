import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"

PanelWindow {
  id: root

  property int notificationCount: 0
  property QtObject notificationServer: null
  property bool horizontal: true

  readonly property real wSize: Config.widgetSize

  anchors {
    left: true
    right: root.horizontal
    top: true
    bottom: !root.horizontal
  }

  implicitHeight: (Config.barWidth) + 16
  implicitWidth: (Config.barWidth) + 16
  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: Config.barWidth
  WlrLayershell.namespace: "quickshell-panel"
  WlrLayershell.layer: WlrLayer.Top

  property date now: new Date()

  Timer {
    interval: Config.clockIntervalMs
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

  function getCommandCenterX() {
    if (!root.horizontal) return 0
    return commandCenterIndicator ? commandCenterIndicator.mapToItem(null, 0, 0).x + commandCenterIndicator.width / 2 : getMenuIndicatorX()
  }

  function getCommandCenterY() {
    return commandCenterIndicator ? commandCenterIndicator.mapToItem(null, 0, 0).y : getMenuIndicatorY()
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
  property bool fullBar: false
  property real expandProgress: expanded ? 1.0 : 0.0

  onFullBarChanged: {
    if (root.fullBar) {
      collapseTimer.stop()
      root.expanded = true
    } else if (root.openPopup === "" && !barMouseArea.containsMouse) {
      collapseTimer.restart()
    }
  }

  Behavior on expandProgress {
    NumberAnimation {
      duration: Config.motionExtraLong
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
      if (!root.fullBar && !barMouseArea.containsMouse && root.openPopup === "") {
        root.expanded = false
      }
    }
  }

  onOpenPopupChanged: {
    if (openPopup === "") {
      if (!root.fullBar && !barMouseArea.containsMouse) {
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
        : (Config.barWidth) - 8 * (1.0 - root.expandProgress)
      height: root.horizontal
        ? (Config.barWidth) - 8 * (1.0 - root.expandProgress)
        : (layout.implicitHeight + 12) + (parent.height - (layout.implicitHeight + 12)) * root.expandProgress
      radius: (root.horizontal ? height / 2 : width / 2) * (1.0 - root.expandProgress) + (Config.borderRadius) * root.expandProgress
      color: Colors.bg

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
            if (root.openPopup === "" && !root.fullBar) {
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
        columnSpacing: Config.spacingSmall * root.expandProgress
        rowSpacing: Config.spacingSmall * root.expandProgress

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
          Layout.preferredWidth: root.horizontal ? implicitWidth : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : implicitHeight
        }

        Item {
          id: focusedWindowWrapper
          property string programText: wsIndicator.focusedWindowProgram
          property string detailText: wsIndicator.focusedWindowInfo
          readonly property bool hasWindowInfo: programText !== "" || detailText !== ""
          readonly property real windowInfoTextWidth: Math.max(
            focusedWindowProgramText.implicitWidth,
            focusedWindowDetailText.implicitWidth
          )
          readonly property real verticalInfoHeight: Math.min(
            320,
            Math.max(root.wSize, windowInfoTextWidth + 8)
          )
          Layout.preferredWidth: root.horizontal
            ? (hasWindowInfo
              ? Math.min(320, Math.max(140, windowInfoTextWidth + 16)) * root.expandProgress
              : 0)
            : (hasWindowInfo ? parent.width : 0)
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : (hasWindowInfo ? verticalInfoHeight * root.expandProgress : 0)
          Layout.fillHeight: !root.horizontal && root.expanded && hasWindowInfo
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && hasWindowInfo
          clip: true

          ColumnLayout {
            id: focusedWindowContent
            anchors.centerIn: parent
            width: root.horizontal
              ? Math.max(0, parent.width - 16)
              : Math.max(0, parent.height - 8)
            height: root.horizontal
              ? Math.max(0, parent.height - 8)
              : Config.labelSmallSize * 2
            rotation: root.horizontal ? 0 : 90
            spacing: 0

            Text {
              id: focusedWindowProgramText
              text: focusedWindowWrapper.programText
              color: Colors.primary
              font.family: Config.fontFamily
              font.pixelSize: Config.labelSmallSize
              font.weight: Font.Bold
              elide: Text.ElideRight
              maximumLineCount: 1
              horizontalAlignment: Text.AlignLeft
              Layout.fillWidth: true
            }

            Text {
              id: focusedWindowDetailText
              text: focusedWindowWrapper.detailText
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.labelSmallSize
              elide: Text.ElideRight
              maximumLineCount: 1
              horizontalAlignment: Text.AlignLeft
              Layout.fillWidth: true
            }
          }
        }

        Item {
          Layout.fillWidth: root.horizontal && root.expanded
          Layout.fillHeight: !root.horizontal && root.expanded && !focusedWindowWrapper.hasWindowInfo
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
            parentWindow: root
          }
        }

        Item {
          id: clockWrapper
          Layout.preferredWidth: root.horizontal ? root.wSize * 1.75 * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : Config.clockVerticalHeight * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          Item {
            id: clockWidget
            anchors.fill: parent

            Column {
              anchors.centerIn: parent
              spacing: Config.clockLineSpacing

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.horizontal
                  ? root.now.toLocaleString(Qt.locale(), "HH:mm")
                  : root.now.toLocaleString(Qt.locale(), "HH")
                color: Colors.primary
                font.family: Config.fontFamily
                font.pixelSize: Config.clockPrimarySize
                font.weight: Font.Bold
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.horizontal
                  ? root.now.toLocaleDateString(Qt.locale(), "MMM dd")
                  : root.now.toLocaleString(Qt.locale(), "mm")
                color: Colors.fgSurfaceVariant
                font.family: Config.fontFamily
                font.pixelSize: root.horizontal
                  ? Config.clockSecondarySize
                  : Config.clockPrimarySize
                font.weight: root.horizontal ? Font.Medium : Font.Bold
              }
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
            notificationCount: root.notificationCount
            active: root.openPopup === "notification"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("notification", notifIndicator)
            }
          }
        }

        Item {
          id: commandCenterWrapper
          Layout.preferredWidth: root.horizontal ? root.wSize * root.expandProgress : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : root.wSize * root.expandProgress
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          MenuIndicator {
            id: commandCenterIndicator
            anchors.fill: parent
            iconLabel: "space_dashboard"
            accessibleName: "Command Center"
            active: root.openPopup === "commandcenter"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("commandcenter", commandCenterIndicator)
            }
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
            active: root.openPopup === "quickmenu"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("quickmenu", menuIndicator)
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
