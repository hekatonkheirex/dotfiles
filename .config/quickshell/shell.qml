//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import Quickshell.Io
import "config"
import "bar"

ShellRoot {
  id: shell

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
  property bool fullBar: Settings.fullBar

  function themeModeName(preference) {
    var modes = ["auto", "light", "dark"]
    return modes[preference] || "auto"
  }

  function syncThemeMode() {
    Quickshell.execDetached([
      Quickshell.env("HOME") + "/.local/bin/sync-theme-mode.sh",
      shell.themeModeName(Settings.themePreference)
    ])
  }

  function quietHoursActive() {
    if (!Settings.notificationQuietHoursEnabled) return false

    var now = new Date()
    var minutes = now.getHours() * 60 + now.getMinutes()
    var start = Math.max(0, Math.min(1439, Settings.notificationQuietHoursStart))
    var end = Math.max(0, Math.min(1439, Settings.notificationQuietHoursEnd))
    if (start === end) return true
    return start > end
      ? minutes >= start || minutes < end
      : minutes >= start && minutes < end
  }

  function notificationSuppressed(notif) {
    var critical = notif && notif.urgency === NotificationUrgency.Critical
    if (critical && Settings.notificationCriticalBypass) return false
    return Settings.doNotDisturb || shell.quietHoursActive()
  }

  // Re-apply the persisted mode whenever the shell starts. This keeps the
  // GTK, Qt, terminal, and Niri outputs aligned with Settings after restart.
  Process {
    id: syncThemeOnStartup
    command: [
      Quickshell.env("HOME") + "/.local/bin/sync-theme-mode.sh",
      shell.themeModeName(Settings.themePreference)
    ]
    running: true
  }

  Connections {
    target: Settings
    function onThemePreferenceChanged() { shell.syncThemeMode() }
  }

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
      : Config.barWidth + 4
  }

  function popupMarginTop(h, screenH) {
    return bar.horizontal
      ? Config.barWidth + 4
      : Math.max(0, Math.min(bar.popupAnchorY - h / 2, screenH - h))
  }

  function toggleLayout() {
    shell.isHorizontal = !shell.isHorizontal;
    var pref = shell.isHorizontal ? "horizontal" : "vertical";
    Quickshell.execDetached(["sh", "-c", "echo " + pref + " > " + Quickshell.env("HOME") + "/.config/quickshell/layout"]);
  }

  function toggleFullBar() {
    Settings.fullBar = !Settings.fullBar
    Settings.save()
  }

  LockScreen {
    id: lockScreen
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
      if (bar.horizontal) {
        bar.popupAnchorX = bar.getCommandCenterX()
      } else {
        bar.popupAnchorY = bar.getCommandCenterY()
      }
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
      if (!shell.notificationSuppressed(notif)) notificationToast.show(notif)
      notificationPopup.onNotificationReceived(notif)
    }
  }

  NotificationToast {
    id: notificationToast
    notificationServer: notifServer
  }

  Connections {
    target: Settings

    function onDoNotDisturbChanged() {
      if (Settings.doNotDisturb || shell.quietHoursActive()) notificationToast.suppress()
    }

    function onNotificationQuietHoursEnabledChanged() {
      if (Settings.notificationQuietHoursEnabled && shell.quietHoursActive()) notificationToast.suppress()
    }

    function onNotificationQuietHoursStartChanged() {
      if (shell.quietHoursActive()) notificationToast.suppress()
    }

    function onNotificationQuietHoursEndChanged() {
      if (shell.quietHoursActive()) notificationToast.suppress()
    }
  }

  PopupShield {
    id: shield
    visible: bar.openPopup !== "" && !lockScreen.locked
    onShieldClicked: bar.openPopup = ""
  }

  Bar {
    id: bar
    horizontal: shell.isHorizontal
    notificationServer: notifServer
    fullBar: shell.fullBar
    visible: !lockScreen.locked
  }

  AudioPopup {
    id: audioPopup
    visible: bar.openPopup === "audio" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }

  BrightnessPopup {
    id: brightnessPopup
    visible: bar.openPopup === "brightness" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }

  MediaPopup {
    id: mediaPopup
    visible: bar.openPopup === "media" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }

  WeatherPopup {
    id: weatherPopup
    visible: bar.openPopup === "weather" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }

  BatteryPopup {
    id: batteryPopup
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
    visible: bar.openPopup === "quickmenu" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
    onLockRequested: lockScreen.lockScreen()

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }

  PanelWindow {
    id: powerConfirmationWindow
    visible: quickMenu.pendingPowerIndex >= 0 && !lockScreen.locked
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-confirmation"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.focusable: powerConfirmationWindow.visible

    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true

    PowerConfirmation {
      anchors.fill: parent
      opened: powerConfirmationWindow.visible
      actionLabel: quickMenu.pendingPowerIndex >= 0
        ? quickMenu.powerOptions[quickMenu.pendingPowerIndex].label
        : ""
      actionDescription: quickMenu.pendingPowerIndex >= 0
        ? quickMenu.powerDescription(quickMenu.powerOptions[quickMenu.pendingPowerIndex].label)
        : ""
      actionIcon: quickMenu.pendingPowerIndex >= 0
        ? quickMenu.powerIcon(quickMenu.powerOptions[quickMenu.pendingPowerIndex].label)
        : ""
      onConfirmed: quickMenu.confirmPower()
      onCancelled: quickMenu.cancelPower()
    }
  }

  CommandCenter {
    id: commandCenter
    visible: bar.openPopup === "commandcenter" && !lockScreen.locked
    onDismissed: bar.openPopup = ""
    onLockRequested: lockScreen.lockScreen()
    isHorizontal: shell.isHorizontal
    onToggleHorizontal: shell.toggleLayout()
    fullBar: shell.fullBar
    notificationPopup: notificationPopup
    onToggleFullBar: shell.toggleFullBar()
  }

  OsdOverlay {
    id: osd
  }

  LauncherPopup {
    id: launcherPopup
    visible: bar.openPopup === "launcher" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: launcherPopup.wallpaperMode
      ? Math.max(0, (Screen.desktopAvailableWidth - launcherPopup.implicitWidth) / 2)
      : shell.popupMarginLeft(implicitWidth, Screen.desktopAvailableWidth)
    anchors.top: true
    margins.top: launcherPopup.wallpaperMode
      ? Math.max(0, (Screen.desktopAvailableHeight - launcherPopup.implicitHeight) / 2)
      : shell.popupMarginTop(implicitHeight, Screen.desktopAvailableHeight)
  }
}
