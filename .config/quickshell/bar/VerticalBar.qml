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


  implicitWidth: config ? config.barWidth : 50
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: implicitWidth
  WlrLayershell.namespace: "quickshell-panel"
  WlrLayershell.layer: WlrLayer.Top

  property date now: new Date()

  Timer {
    interval: config ? config.clockIntervalMs : 1000
    running: true
    repeat: true
    onTriggered: now = new Date()
  }

  property string openPopup: ""
  property int popupAnchorY: 0

  function getMenuIndicatorY() {
    return menuIndicator.mapToItem(null, 0, 0).y
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

  Item {
    anchors.fill: parent

    Rectangle {
      id: barBg
      anchors.fill: parent
      radius: config ? config.borderRadius : 14
      color: colors_ ? colors_.bg : "#1C1B1F"
    }

    Rectangle {
      width: barBg.radius
      height: barBg.radius
      color: barBg.color
    }

    Rectangle {
      width: barBg.radius
      height: barBg.radius
      y: parent.height - barBg.radius
      color: barBg.color
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.openPopup = ""
      // MangoWM may route popup clicks to surfaces below;
      // disable this handler while a popup is open so passthrough clicks don't close it.
      enabled: !root.openPopup
    }

    ColumnLayout {
      id: layout
      anchors { fill: parent; topMargin: 6; bottomMargin: 6 }
      spacing: 6

      Launcher {
        id: launcherWidget
        colors_: root.colors_
        config: root.config
        active: root.openPopup === "launcher"
        onClicked: function(mouse) {
          root.togglePopup("launcher", launcherWidget)
        }
      }

      WorkspaceIndicator {
        id: wsIndicator
        colors_: root.colors_
        config: root.config
      }

      WallpaperChanger {
        id: wallChanger
        colors_: root.colors_
        config: root.config
        onClicked: function(mouse) {
          Quickshell.execDetached(["sh", "-c", Quickshell.env("HOME") + "/.local/bin/wall"])
        }
      }

      Item {
        Layout.fillHeight: true
      }

      AudioIndicator {
        id: audioIndicator
        colors_: root.colors_
        config: root.config
        active: root.openPopup === "audio"
        onClicked: function(mouse) {
          root.togglePopup("audio", audioIndicator)
        }
      }

      BrightnessIndicator {
        id: brightnessIndicator
        colors_: root.colors_
        config: root.config
        active: root.openPopup === "brightness"
        onClicked: function(mouse) {
          root.togglePopup("brightness", brightnessIndicator)
        }
      }

      BatteryIndicator {
        id: batteryIndicator
        colors_: root.colors_
        config: root.config
        active: root.openPopup === "battery"
        onClicked: function(mouse) {
          root.togglePopup("battery", batteryIndicator)
        }
      }

      SystemTrayArea {
        colors_: root.colors_
        config: root.config
        parentWindow: root
      }

      MenuIndicator {
        id: menuIndicator
        colors_: root.colors_
        config: root.config
        active: root.openPopup === "quickmenu"
        onClicked: function(mouse) {
          root.togglePopup("quickmenu", menuIndicator)
        }
      }

      Item {
        id: clockWidget
        Layout.preferredWidth: root.width
        Layout.preferredHeight: root.width

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: 20
          text: root.now.toLocaleString(Qt.locale(), "HH:mm")
          color: colors_ ? colors_.primary : "#D0BCFF"
          font.family: config ? config.fontFamily : "Google Sans Flex"
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

      NotificationIndicator {
        id: notifIndicator
        colors_: root.colors_
        config: root.config
        notificationCount: root.notificationCount
        active: root.openPopup === "notification"
        onClicked: function(mouse) {
          root.togglePopup("notification", notifIndicator)
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
