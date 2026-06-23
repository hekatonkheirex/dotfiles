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

  property bool isHorizontal: true

  Process {
    id: readLayoutPref
    command: ["sh", "-c", "cat " + Quickshell.env("HOME") + "/.config/quickshell/layout 2>/dev/null || echo horizontal"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var pref = text.trim();
        shell.isHorizontal = (pref !== "vertical");
      }
    }
  }

  function toggleLayout() {
    shell.isHorizontal = !shell.isHorizontal;
    var pref = shell.isHorizontal ? "horizontal" : "vertical";
    Quickshell.execDetached(["sh", "-c", "echo " + pref + " > " + Quickshell.env("HOME") + "/.config/quickshell/layout"]);
  }

  Process {
    id: darkModeInitial
    command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        colors.systemDark = text.trim() === "'prefer-dark'"
      }
    }
  }

  Process {
    id: darkModeMonitor
    command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
    running: true

    stdout: SplitParser {
      onRead: function(data) {
        var clean = data.trim()
        var prefix = "color-scheme:"
        var idx = clean.indexOf(prefix)
        if (idx >= 0) {
          var val = clean.substring(idx + prefix.length).trim()
          colors.systemDark = val === "'prefer-dark'"
        }
      }
    }

    onRunningChanged: {
      if (!running) {
        darkModeMonitorRetry.start()
      }
    }
  }

  Timer {
    id: darkModeMonitorRetry
    interval: 5000
    onTriggered: darkModeMonitor.running = true
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
      if (bar.horizontal) {
        bar.popupAnchorX = bar.getLauncherX()
      } else {
        bar.popupAnchorY = 0
      }
      bar.openPopup = bar.openPopup === "launcher" ? "" : "launcher"
    }

    function lock() {
      lockScreen.lockScreen()
    }

    function quickmenu() {
      if (bar.horizontal) {
        bar.popupAnchorX = bar.getMenuIndicatorX()
      } else {
        bar.popupAnchorY = bar.getMenuIndicatorY()
      }
      bar.openPopup = bar.openPopup === "quickmenu" ? "" : "quickmenu"
    }

    function commandcenter() {
      bar.openPopup = bar.openPopup === "commandcenter" ? "" : "commandcenter"
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

  FileTrigger {
    triggerFile: "/tmp/qscommandcenter-trigger"
    onTriggered: ipc.commandcenter()
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

  HorizontalBar {
    id: horizontalBar
    colors_: colors
    config: cfg
    notificationServer: notifServer
    visible: shell.isHorizontal && !lockScreen.locked
  }

  VerticalBar {
    id: verticalBar
    colors_: colors
    config: cfg
    notificationServer: notifServer
    visible: !shell.isHorizontal && !lockScreen.locked
  }

  readonly property QtObject bar: isHorizontal ? horizontalBar : verticalBar

  AudioPopup {
    id: audioPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "audio" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: bar.horizontal
      ? Math.max(0, Math.min(bar.popupAnchorX - implicitWidth / 2, Screen.desktopAvailableWidth - implicitWidth))
      : (config ? config.barWidth + 4 : 48)
    anchors.top: true
    margins.top: bar.horizontal
      ? (config ? config.barWidth + 4 : 48)
      : Math.max(0, Math.min(bar.popupAnchorY - implicitHeight / 2, Screen.desktopAvailableHeight - implicitHeight))
  }

  WifiPopup {
    id: wifiPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "wifi" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: bar.horizontal
      ? Math.max(0, Math.min(bar.popupAnchorX - implicitWidth / 2, Screen.desktopAvailableWidth - implicitWidth))
      : (config ? config.barWidth + 4 : 48)
    anchors.top: true
    margins.top: bar.horizontal
      ? (config ? config.barWidth + 4 : 48)
      : Math.max(0, Math.min(bar.popupAnchorY - implicitHeight / 2, Screen.desktopAvailableHeight - implicitHeight))
  }

  BtPopup {
    id: btPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "bluetooth" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    horizontal: bar.horizontal
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: bar.horizontal
      ? Math.max(0, Math.min(bar.popupAnchorX - implicitWidth / 2, Screen.desktopAvailableWidth - implicitWidth))
      : (config ? config.barWidth + 4 : 48)
    anchors.top: true
    margins.top: bar.horizontal
      ? (config ? config.barWidth + 4 : 48)
      : Math.max(0, Math.min(bar.popupAnchorY - implicitHeight / 2, Screen.desktopAvailableHeight - implicitHeight))
  }

  BrightnessPopup {
    id: brightnessPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "brightness" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: bar.horizontal
      ? Math.max(0, Math.min(bar.popupAnchorX - implicitWidth / 2, Screen.desktopAvailableWidth - implicitWidth))
      : (config ? config.barWidth + 4 : 48)
    anchors.top: true
    margins.top: bar.horizontal
      ? (config ? config.barWidth + 4 : 48)
      : Math.max(0, Math.min(bar.popupAnchorY - implicitHeight / 2, Screen.desktopAvailableHeight - implicitHeight))
  }

  BatteryPopup {
    id: batteryPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "battery" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: bar.horizontal
      ? Math.max(0, Math.min(bar.popupAnchorX - implicitWidth / 2, Screen.desktopAvailableWidth - implicitWidth))
      : (config ? config.barWidth + 4 : 48)
    anchors.top: true
    margins.top: bar.horizontal
      ? (config ? config.barWidth + 4 : 48)
      : Math.max(0, Math.min(bar.popupAnchorY - implicitHeight / 2, Screen.desktopAvailableHeight - implicitHeight))
  }

  CalendarPopup {
    id: calendarPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "calendar" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: bar.horizontal
      ? Math.max(0, Math.min(bar.popupAnchorX - implicitWidth / 2, Screen.desktopAvailableWidth - implicitWidth))
      : (config ? config.barWidth + 4 : 48)
    anchors.top: true
    margins.top: bar.horizontal
      ? (config ? config.barWidth + 4 : 48)
      : Math.max(0, Math.min(bar.popupAnchorY - implicitHeight / 2, Screen.desktopAvailableHeight - implicitHeight))
  }

  NotificationPopup {
    id: notificationPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "notification" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: bar.horizontal
      ? Math.max(0, Math.min(bar.popupAnchorX - implicitWidth / 2, Screen.desktopAvailableWidth - implicitWidth))
      : (config ? config.barWidth + 4 : 48)
    anchors.top: true
    margins.top: bar.horizontal
      ? (config ? config.barWidth + 4 : 48)
      : Math.max(0, Math.min(bar.popupAnchorY - implicitHeight / 2, Screen.desktopAvailableHeight - implicitHeight))
  }

  QuickMenu {
    id: quickMenu
    colors_: colors
    config: cfg
    visible: bar.openPopup === "quickmenu" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
    isHorizontal: shell.isHorizontal
    onToggleHorizontal: shell.toggleLayout()

    anchors.left: true
    margins.left: bar.horizontal
      ? Math.max(0, Math.min(bar.popupAnchorX - implicitWidth / 2, Screen.desktopAvailableWidth - implicitWidth))
      : (config ? config.barWidth + 4 : 48)
    anchors.top: true
    margins.top: bar.horizontal
      ? (config ? config.barWidth + 4 : 48)
      : Math.max(0, Math.min(bar.popupAnchorY - implicitHeight / 2, Screen.desktopAvailableHeight - implicitHeight))
  }

  CommandCenter {
    id: commandCenter
    colors_: colors
    config: cfg
    visible: bar.openPopup === "commandcenter" && !lockScreen.locked
    onDismissed: bar.openPopup = ""
    isHorizontal: shell.isHorizontal
    onToggleHorizontal: shell.toggleLayout()
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

    anchors.left: true
    margins.left: bar.horizontal
      ? Math.max(0, Math.min(bar.popupAnchorX - implicitWidth / 2, Screen.desktopAvailableWidth - implicitWidth))
      : (config ? config.barWidth + 4 : 48)
    anchors.top: true
    margins.top: bar.horizontal
      ? (config ? config.barWidth + 4 : 48)
      : Math.max(0, Math.min(bar.popupAnchorY - implicitHeight / 2, Screen.desktopAvailableHeight - implicitHeight))
  }
}
