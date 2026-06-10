//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Io
import "config"
import "bar"

ShellRoot {
  id: shell

  Colors {
    id: colors
  }

  Timer {
    id: darkModeTimer
    interval: 5000
    running: true
    repeat: true
    onTriggered: {
      if (!darkModeCheck.running) darkModeCheck.running = true
    }
  }

  Process {
    id: darkModeCheck
    command: ["sh", "-c", "gsettings get org.gnome.desktop.interface color-scheme"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        colors.systemDark = text.trim() === "'prefer-dark'"
      }
    }
  }

  Config {
    id: cfg
  }

  LockScreen {
    id: lockScreen
    colors_: colors
    config: cfg
  }

  IpcHandler {
    id: ipc
    target: "shell"

    function launcher() {
      bar.popupAnchorY = 0
      bar.openPopup = bar.openPopup === "launcher" ? "" : "launcher"
    }

    function lock() {
      lockScreen.lockScreen()
    }

    function quickmenu() {
      bar.popupAnchorY = bar.getMenuIndicatorY()
      bar.openPopup = bar.openPopup === "quickmenu" ? "" : "quickmenu"
    }

  }

  FileTrigger {
    triggerFile: "/tmp/qslauncher-trigger"
    onTriggered: ipc.launcher()
  }

  FileTrigger {
    triggerFile: "/tmp/qsquickmenu-trigger"
    onTriggered: ipc.quickmenu()
  }

  NotificationServer {
    id: notifServer
    bodyMarkupSupported: true
    actionsSupported: true
    onNotification: function(notif) {
      notif.tracked = true
      notificationToast.show(notif)
      notificationPopup.onNotificationReceived(notif)
    }
  }

  NotificationToast {
    id: notificationToast
    colors_: colors
    config: cfg
    notificationServer: notifServer
  }

  PopupShield {
    id: shield
    config: cfg
    visible: bar.openPopup !== "" && !lockScreen.locked
    onShieldClicked: bar.openPopup = ""
  }

  VerticalBar {
    id: bar
    colors_: colors
    config: cfg
    notificationServer: notifServer
    visible: !lockScreen.locked
  }

  AudioPopup {
    id: audioPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "audio" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
  }

  BrightnessPopup {
    id: brightnessPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "brightness" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
  }

  BatteryPopup {
    id: batteryPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "battery" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
  }

  CalendarPopup {
    id: calendarPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "calendar" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
  }

  NotificationPopup {
    id: notificationPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "notification" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
  }

  QuickMenu {
    id: quickMenu
    colors_: colors
    config: cfg
    visible: bar.openPopup === "quickmenu" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
  }

  FileTrigger {
    triggerFile: "/tmp/qsosd-vol"
    onTriggered: osd.show("volume")
  }

  FileTrigger {
    triggerFile: "/tmp/qsosd-bright"
    onTriggered: osd.show("brightness")
  }

  FileTrigger {
    triggerFile: "/tmp/qsosd-mic"
    onTriggered: osd.show("mic")
  }

  OsdOverlay {
    id: osd
    colors_: colors
    config: cfg
  }

  LauncherPopup {
    id: launcherPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "launcher" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
  }
}
