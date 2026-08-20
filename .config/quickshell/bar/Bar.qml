import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "primitives"

PanelWindow {
  id: root

  property int notificationCount: 0
  property QtObject notificationServer: null
  property string barPosition: "top"
  readonly property bool horizontal: barPosition === "top" || barPosition === "bottom"
  readonly property bool dockedTop: barPosition === "top"
  readonly property bool dockedBottom: barPosition === "bottom"
  readonly property bool dockedLeft: barPosition === "left"
  readonly property bool dockedRight: barPosition === "right"

  readonly property real wSize: Config.widgetSize
  readonly property real horizontalPillLength: root.wSize + Config.spacingSmall
  readonly property real verticalPillLength: root.wSize

  anchors {
    left: root.horizontal || root.dockedLeft
    right: root.horizontal || root.dockedRight
    top: root.horizontal ? root.dockedTop : true
    bottom: root.horizontal ? root.dockedBottom : true
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

  // Reinterprets root.now in Settings.timezone (an IANA name) when set,
  // falling back to system-local time if the name is invalid or the JS
  // engine lacks Intl support.
  function displayNow() {
    if (!Settings.timezone) return root.now
    try {
      var parts = new Intl.DateTimeFormat("en-US", {
        timeZone: Settings.timezone, hour12: false,
        year: "numeric", month: "2-digit", day: "2-digit",
        hour: "2-digit", minute: "2-digit", second: "2-digit"
      }).formatToParts(root.now)
      var m = {}
      parts.forEach(function(p) { m[p.type] = p.value })
      return new Date(m.year, m.month - 1, m.day, m.hour, m.minute, m.second)
    } catch (e) {
      return root.now
    }
  }

  function clockFormat() {
    if (Settings.clock24h) return Settings.clockShowSeconds ? "HH:mm:ss" : "HH:mm"
    return Settings.clockShowSeconds ? "h:mm:ss AP" : "h:mm AP"
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

  property bool fullBar: false
  readonly property bool pillsBar: !root.fullBar
  readonly property bool horizontalPillMode: root.horizontal && root.pillsBar
  readonly property real expandProgress: 1.0

  mask: Region { item: barBg }

  Item {
    anchors.fill: parent

    Rectangle {
      id: barBg
      x: root.horizontal
        ? (root.wSize + 6) * (1.0 - root.expandProgress)
        : (root.dockedRight ? parent.width - Config.barWidth : 8 * (1.0 - root.expandProgress))
      y: root.horizontal
        ? (root.dockedBottom ? parent.height - Config.barWidth : 8 * (1.0 - root.expandProgress))
        : (root.wSize + 6) * (1.0 - root.expandProgress)
      width: root.horizontal
        ? (layout.implicitWidth + 12) + (parent.width - (layout.implicitWidth + 12)) * root.expandProgress
        : (Config.barWidth) - 8 * (1.0 - root.expandProgress)
      height: root.horizontal
        ? (Config.barWidth) - 8 * (1.0 - root.expandProgress)
        : (layout.implicitHeight + 12) + (parent.height - (layout.implicitHeight + 12)) * root.expandProgress
      radius: (root.horizontal ? height / 2 : width / 2) * (1.0 - root.expandProgress) + (Config.borderRadius) * root.expandProgress
      color: root.fullBar ? Colors.bg : "transparent"

      // Square-off helper for the docked edge's near corner
      Rectangle {
        width: barBg.radius * root.expandProgress
        height: barBg.radius * root.expandProgress
        x: root.dockedRight ? barBg.width - width : 0
        y: root.dockedBottom ? barBg.height - height : 0
        color: barBg.color
        visible: width > 0
      }

      // Square-off helper for the docked edge's far corner
      Rectangle {
        width: barBg.radius * root.expandProgress
        height: barBg.radius * root.expandProgress
        x: root.horizontal
          ? barBg.width - width
          : (root.dockedRight ? barBg.width - width : 0)
        y: root.horizontal
          ? (root.dockedBottom ? barBg.height - height : 0)
          : barBg.height - height
        color: barBg.color
        visible: width > 0
      }

      MouseArea {
        id: barMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.openPopup = ""
        enabled: !root.openPopup
      }

      GridLayout {
        id: layout
        flow: root.horizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          leftMargin: root.horizontal ? 6 : 0
          rightMargin: root.horizontal ? 6 : 0
          topMargin: root.horizontal ? 0 : 6
          bottomMargin: root.horizontal ? 0 : 6
        }
        height: root.horizontal
          ? parent.height
          : parent.height - 12
        columnSpacing: Config.spacingSmall * root.expandProgress
        rowSpacing: Config.spacingSmall * root.expandProgress

        Item {
          id: launcherWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize)
              * root.expandProgress * (Settings.ccShowLauncher ? 1 : 0)
            : parent.width * (Settings.ccShowLauncher ? 1 : 0)
          Layout.preferredHeight: root.horizontal
            ? parent.height * (Settings.ccShowLauncher ? 1 : 0)
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                launcherWidget.verticalLayoutHeight
              ) * root.expandProgress * (Settings.ccShowLauncher ? 1 : 0)
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowLauncher
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

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
          Layout.preferredWidth: Settings.ccShowWorkspaces
            ? (root.horizontal
              ? Math.max(implicitWidth, root.pillsBar ? root.horizontalPillLength : 0)
              : parent.width)
            : 0
          Layout.preferredHeight: Settings.ccShowWorkspaces
            ? (root.horizontal
              ? parent.height
              : Math.max(implicitHeight, root.pillsBar ? root.verticalPillLength : 0))
            : 0
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowWorkspaces

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }
        }

        Item {
          id: focusedWindowWrapper
          property string programText: wsIndicator.focusedWindowProgram
          property string detailText: wsIndicator.focusedWindowInfo
          readonly property bool hasWindowInfo: programText !== "" || detailText !== ""
          readonly property real windowInfoTextWidth: root.horizontalPillMode
            ? focusedWindowProgramText.implicitWidth
              + (programText !== "" && detailText !== "" ? Config.spacingCompact : 0)
              + focusedWindowDetailText.implicitWidth
            : Math.max(
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
              : 0) * (Settings.ccShowFocusedWindow ? 1 : 0)
            : (hasWindowInfo ? parent.width : 0) * (Settings.ccShowFocusedWindow ? 1 : 0)
          Layout.preferredHeight: (root.horizontal
            ? parent.height
            : (hasWindowInfo ? verticalInfoHeight * root.expandProgress : 0))
            * (Settings.ccShowFocusedWindow ? 1 : 0)
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && hasWindowInfo && Settings.ccShowFocusedWindow
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
            fitContent: !root.horizontal
            contentWidth: parent.width
            contentHeight: focusedWindowWrapper.verticalInfoHeight
          }

          GridLayout {
            id: focusedWindowContent
            anchors.centerIn: parent
            columns: root.horizontalPillMode ? 2 : 1
            rows: root.horizontalPillMode ? 1 : 2
            flow: root.horizontalPillMode
              ? GridLayout.LeftToRight
              : GridLayout.TopToBottom
            width: root.horizontal
              ? Math.max(0, parent.width - 16)
              : Math.max(0, Math.min(
                  parent.height - 8,
                  focusedWindowWrapper.verticalInfoHeight - 8
                ))
            height: root.horizontal
              ? Math.max(0, parent.height - 8)
              : Config.labelSmallSize * 2
            rotation: root.horizontal ? 0 : 90
            columnSpacing: root.horizontalPillMode ? Config.spacingCompact : 0
            rowSpacing: root.horizontalPillMode ? 0 : 0

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
          Layout.fillWidth: root.horizontal
          Layout.fillHeight: !root.horizontal
          Layout.preferredWidth: 0
          Layout.preferredHeight: 0
          visible: root.expandProgress > 0
        }

        Item {
          id: audioWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalPillMode
              ? Math.max(root.horizontalPillLength, audioIndicator.horizontalContentWidth)
              : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                audioIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowAudio
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          AudioIndicator {
            id: audioIndicator
            anchors.fill: parent
            active: root.openPopup === "audio"
            horizontal: root.horizontal
            inlineContent: root.horizontalPillMode
            onClicked: function(mouse) {
              root.togglePopup("audio", audioIndicator)
            }
          }
        }

        Item {
          id: brightnessWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalPillMode
              ? Math.max(root.horizontalPillLength, brightnessIndicator.horizontalContentWidth)
              : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                brightnessIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowDisplay
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          BrightnessIndicator {
            id: brightnessIndicator
            anchors.fill: parent
            active: root.openPopup === "brightness"
            horizontal: root.horizontal
            inlineContent: root.horizontalPillMode
            onClicked: function(mouse) {
              root.togglePopup("brightness", brightnessIndicator)
            }
          }
        }

        Item {
          id: mediaWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalPillMode
              ? Math.max(root.horizontalPillLength, mediaIndicator.horizontalContentWidth)
              : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                mediaIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowMedia
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          MediaIndicator {
            id: mediaIndicator
            anchors.fill: parent
            active: root.openPopup === "media"
            horizontal: root.horizontal
            inlineContent: root.horizontalPillMode
            onClicked: function(mouse) {
              if (Settings.mediaControlsAlwaysVisible) {
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "play"])
              } else {
                root.togglePopup("media", mediaIndicator)
              }
            }
          }
        }

        Item {
          id: weatherWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalPillMode
              ? Math.max(root.horizontalPillLength, weatherIndicator.horizontalContentWidth)
              : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                weatherIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowWeather
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          WeatherIndicator {
            id: weatherIndicator
            anchors.fill: parent
            active: root.openPopup === "weather"
            horizontal: root.horizontal
            inlineContent: root.horizontalPillMode
            onClicked: function(mouse) {
              root.togglePopup("weather", weatherIndicator)
            }
          }
        }

        Item {
          id: batteryWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalPillMode
              ? Math.max(root.horizontalPillLength, batteryIndicator.horizontalContentWidth)
              : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                batteryIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowBattery
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          BatteryIndicator {
            id: batteryIndicator
            anchors.fill: parent
            active: root.openPopup === "battery"
            horizontal: root.horizontal
            inlineContent: root.horizontalPillMode
            onClicked: function(mouse) {
              root.togglePopup("battery", batteryIndicator)
            }
          }
        }

        Item {
          id: systemTrayWrapper
          Layout.preferredWidth: root.horizontal
            ? Math.max(
                systemTray.preferredLength,
                root.pillsBar ? root.horizontalPillLength : 0
              ) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                systemTray.preferredLength,
                root.pillsBar ? root.verticalPillLength : 0
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: Settings.ccShowTray && systemTray.visibleCount > 0 && (root.expandProgress > 0)
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          SystemTrayArea {
            id: systemTray
            horizontal: root.horizontal
            anchors.fill: parent
            parentWindow: root
          }
        }

        Item {
          id: clockWrapper
          Layout.preferredWidth: root.horizontal
            ? Math.max(
                root.wSize * 1.75,
                root.pillsBar ? root.horizontalPillLength : 0
              ) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                Config.clockVerticalHeight,
                root.pillsBar ? root.verticalPillLength : 0
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowClock
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          Item {
            id: clockWidget
            anchors.fill: parent
            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: "Calendar"
            Accessible.description: "Open calendar"
            Accessible.focusable: true
            Accessible.focused: activeFocus

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.togglePopup("calendar", clockWidget)
                event.accepted = true
              }
            }

            Column {
              anchors.centerIn: parent
              spacing: root.horizontalPillMode ? 0 : Config.clockLineSpacing

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
                text: root.horizontal
                  ? root.displayNow().toLocaleString(Qt.locale(), root.clockFormat())
                  : root.displayNow().toLocaleString(Qt.locale(), Settings.clock24h ? "HH" : "h")
                color: Colors.primary
                font.family: Config.fontFamily
                font.pixelSize: Config.clockPrimarySize
                font.weight: Font.Bold
              }

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !root.horizontalPillMode
                text: root.horizontal
                  ? root.displayNow().toLocaleDateString(Qt.locale(), "MMM dd")
                  : root.displayNow().toLocaleString(Qt.locale(), "mm")
                color: Colors.fgSurfaceVariant
                font.family: Config.fontFamily
                font.pixelSize: root.horizontal
                  ? Config.clockSecondarySize
                  : Config.clockPrimarySize
                font.weight: root.horizontal ? Font.Medium : Font.Bold
              }
            }

            Rectangle {
              anchors.fill: parent
              radius: Config.shapeMedium
              color: "transparent"
              border.width: clockWidget.activeFocus ? 2 : 0
              border.color: Colors.primary
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
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                notifIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowNotifications
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

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
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                commandCenterIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          MenuIndicator {
            id: commandCenterIndicator
            anchors.fill: parent
            iconLabel: "settings"
            accessibleName: "Settings"
            active: root.openPopup === "commandcenter"
            horizontal: root.horizontal
            onClicked: function(mouse) {
              root.togglePopup("commandcenter", commandCenterIndicator)
            }
          }
        }

        Item {
          id: menuWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                menuIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal || root.fullBar
          Layout.alignment: root.horizontal || root.fullBar ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          MenuIndicator {
            id: menuIndicator
            anchors.fill: parent
            iconLabel: "power_settings_new"
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
