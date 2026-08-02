//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import Quickshell.Io
import "config"
import "bar"

ShellRoot {
  id: shell

  Colors {
    id: colors
  }

  Process {
    id: readColorScheme
    command: ["sh", "-c", "cat " + Quickshell.env("HOME") + "/.config/quickshell/colorscheme 2>/dev/null || echo matugen"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var v = text.trim()
        if (v === "claude" || v === "matugen") colors.colorScheme = v
      }
    }
  }

  // Battery low alert — Warning at 20%, Alert at 10%. Persists until manually
  // dismissed or the charger is plugged in (see checkLevel + notifServer capture below).
  QtObject {
    id: batteryAlert
    readonly property string appName: "Battery Monitor"
    property string state: "none" // "none" | "warning" | "alert"
    property var warningNotif: null
    property var alertNotif: null
    property var device: {
      for (var i = 0; i < UPower.devices.count; i++) {
        var d = UPower.devices.get(i)
        if (d.ready && d.isLaptopBattery) return d
      }
      return UPower.displayDevice && UPower.displayDevice.ready ? UPower.displayDevice : null
    }
    property real pct: device ? device.percentage * 100 : 100
    // UPower's own aggregate "running off AC" flag, not the battery's own
    // charge state. This laptop uses a charge threshold/conservation mode
    // that lets the battery sit in "Discharging" down to a floor and then
    // briefly flip to "Charging" to top back up — all while the adapter
    // stays physically connected. Inferring "plugged in" from battery.state
    // followed that sawtooth and dismissed the alert with no user action.
    property bool pluggedIn: !UPower.onBattery

    function dismissWarning() {
      if (warningNotif) { warningNotif.dismiss(); warningNotif = null }
    }
    function dismissAlert() {
      if (alertNotif) { alertNotif.dismiss(); alertNotif = null }
    }

    function checkLevel() {
      if (pluggedIn) {
        dismissWarning()
        dismissAlert()
        state = "none"
        return
      }
      if (pct <= 10) {
        if (state !== "alert") {
          dismissWarning()
          state = "alert"
          Quickshell.execDetached(["notify-send", "-a", appName, "-u", "critical", "-i", "battery-caution", "-t", "0", "Battery Alert", Math.round(pct) + "% remaining — plug in now"])
        }
      } else if (pct <= 20) {
        if (state === "none") {
          state = "warning"
          Quickshell.execDetached(["notify-send", "-a", appName, "-u", "critical", "-i", "battery-caution", "-t", "0", "Battery Warning", Math.round(pct) + "% remaining"])
        }
      }
      // No auto-reset on pct climbing back above 20 while unplugged: UPower's
      // percentage reading wobbles under load. Only plugging in (above) or a
      // manual dismiss clears the notification.
    }

    onPluggedInChanged: checkLevel()
    onPctChanged: checkLevel()
    Component.onCompleted: checkLevel()
  }

  property bool isHorizontal: true

  Process {
    id: readLayoutPref
    command: ["sh", "-c", "cat " + Quickshell.env("HOME") + "/.config/quickshell/layout 2>/dev/null || echo horizontal"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var pref = text.trim()
        shell.isHorizontal = (pref !== "vertical")
      }
    }
  }

  // Shared popup anchoring: centered on the widget along the bar in horizontal
  // mode, offset past the bar edge in vertical mode. Callers pass their own
  // implicit size and Screen bound so bindings stay reactive.
  function popupMarginLeft(w, screenW) {
    return bar.horizontal
      ? Math.max(0, Math.min(bar.popupAnchorX - w / 2, screenW - w))
      : cfg.barWidth + 4
  }

  function popupMarginTop(h, screenH) {
    return bar.horizontal
      ? cfg.barWidth + 4
      : Math.max(0, Math.min(bar.popupAnchorY - h / 2, screenH - h))
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

    function layout() {
      shell.toggleLayout()
    }

  }

  FileTrigger {
    triggers: ({
      "qslauncher-trigger": "launcher",
      "qsquickmenu-trigger": "quickmenu",
      "qscommandcenter-trigger": "commandcenter",
      "qslock-trigger": "lock",
      "qsosd-vol": "osd-volume",
      "qsosd-bright": "osd-brightness",
      "qsosd-mic": "osd-mic",
      "qsosd-airplane": "osd-airplane",
      "qsosd-bluetooth": "osd-bluetooth"
    })
    onTriggered: function(name) {
      switch (name) {
        case "launcher": ipc.launcher(); break
        case "quickmenu": ipc.quickmenu(); break
        case "commandcenter": ipc.commandcenter(); break
        case "lock": ipc.lock(); break
        case "osd-volume": osd.show("volume"); break
        case "osd-brightness": osd.show("brightness"); break
        case "osd-mic": osd.show("mic"); break
        case "osd-airplane": osd.show("airplane"); break
        case "osd-bluetooth": osd.show("bluetooth"); break
      }
    }
  }

  NotificationServer {
    id: notifServer
    bodyMarkupSupported: true
    actionsSupported: true
    onNotification: function(notif) {
      notif.tracked = true
      if (notif.appName === batteryAlert.appName) {
        if (notif.summary === "Battery Alert") batteryAlert.alertNotif = notif
        else if (notif.summary === "Battery Warning") batteryAlert.warningNotif = notif
        notif.closed.connect(function() {
          if (batteryAlert.warningNotif === notif) batteryAlert.warningNotif = null
          if (batteryAlert.alertNotif === notif) batteryAlert.alertNotif = null
        })
      }
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

  Bar {
    id: bar
    horizontal: shell.isHorizontal
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

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }

  WifiPopup {
    id: wifiPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "wifi" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
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
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }

  BrightnessPopup {
    id: brightnessPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "brightness" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }

  BatteryPopup {
    id: batteryPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "battery" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }

  CalendarPopup {
    id: calendarPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "calendar" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }

  NotificationPopup {
    id: notificationPopup
    colors_: colors
    config: cfg
    visible: bar.openPopup === "notification" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
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
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
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
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }
}
