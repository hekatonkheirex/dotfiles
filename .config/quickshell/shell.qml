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
import "config/BarForm.js" as BarForm
import "config/DockModel.js" as DockModel
import "config/LauncherLayout.js" as LauncherLayout
import "config/BottomBarModel.js" as BottomBarModel
import "bar"

ShellRoot {
  id: shell

  // Full-width wallpaper filmstrip (bar/WallpaperFilmstrip.qml); toggled by
  // `qs ipc call shell wallpapers`.
  property bool wallpaperFilmstripOpen: false
  property string wallpaperFilmstripQuery: ""

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

  property string barPosition: "top"


  readonly property bool isHorizontal: shell.barPosition === "top"
    || shell.barPosition === "bottom"
  property bool paletteActivationComplete: false
  property bool startupThemeRefreshComplete: false

  function normalizeBarPosition(value) {
    var pref = String(value || "").trim()
    if (pref === "top" || pref === "horizontal") return "top"
    if (pref === "bottom" || pref === "left" || pref === "right") return pref
    if (pref === "vertical") return "left"
    return "top"
  }

  function setBarPosition(value) {
    var next = shell.normalizeBarPosition(value)
    if (shell.barPosition === next) return

    shell.barPosition = next
    Quickshell.execDetached([
      "sh", "-c",
      "printf '%s\\n' \"$1\" > \"$2\"",
      "sh", next,
      Quickshell.env("HOME") + "/.config/quickshell/layout"
    ])
  }

  function requestLock() {
    bar.openPopup = ""
    // A pending power confirmation must not come back after unlock.
    powerMenu.cancelPending()
    lockScreen.lockScreen()
  }

  function themeModeName(preference) {
    var modes = ["auto", "light", "dark"]
    return modes[preference] || "auto"
  }

  function syncThemeMode() {
    Quickshell.execDetached([
      Quickshell.env("HOME") + "/.config/quickshell/scripts/sync-theme-mode-locked.sh",
      shell.themeModeName(Settings.themePreference),
      "",
      "--sync-sddm"
    ])
  }


  function startInitialThemeSync() {
    if (!shell.paletteActivationComplete
        || shell.startupThemeRefreshComplete
        || !Settings.initialLoadComplete
        || syncThemeOnStartup.running) return
    syncThemeOnStartup.running = true
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

  // Restore the persisted palette from its source-owned cache whenever the
  // shell starts. Expensive Matugen/theme generation belongs to an explicit
  // palette or wallpaper change, not every Quickshell restart.
  Process {
    id: activatePaletteOnStartup
    command: [
      Quickshell.env("HOME") + "/.config/quickshell/scripts/sync-active-palette.sh",
      "--source",
      "auto",
      "--activate-only"
    ]
    running: true
    onExited: (exitCode) => {
      Colors.reloadMatugenPalette()
      shell.paletteActivationComplete = true
      shell.startupThemeRefreshComplete = false
      shell.startInitialThemeSync()
    }
  }

  Process {
    id: syncThemeOnStartup
    command: [
      Quickshell.env("HOME") + "/.config/quickshell/scripts/sync-theme-mode-locked.sh",
      shell.themeModeName(Settings.themePreference),
      "--quiet"
    ]
    running: false
    onExited: (exitCode) => {
      shell.startupThemeRefreshComplete = exitCode === 0
    }
  }

  Connections {
    target: Settings
    function onInitialLoadCompleteChanged() { shell.startInitialThemeSync() }
    function onThemePreferenceChanged() {
      if (!Settings.initialLoadComplete) return
      shell.syncThemeMode()
    }
  }

  Process {
    id: readLayoutPref
    command: ["sh", "-c", "cat " + Quickshell.env("HOME") + "/.config/quickshell/layout 2>/dev/null || echo horizontal"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var pref = text.trim()
        shell.barPosition = shell.normalizeBarPosition(pref)
      }
    }
  }

  // Shared popup anchoring: centered along the bar, then offset past the
  // selected edge. Callers pass their own implicit size and Screen bound so
  // bindings stay reactive.
  function popupBarInset() {
    return bar.verticalPillPanelWidth + bar.edgeGap + Config.spacingMedium
  }

  // Anchors the launcher exactly as the launcher() IPC call does.
  function anchorLauncher() {
    if (bar.horizontal) {
      bar.popupAnchorX = bar.getLauncherX()
    } else {
      bar.popupAnchorY = 0
    }
  }

  // Opens the launcher with `query` already typed (LauncherPopup.initialQuery).
  // Re-opening while the launcher is already visible must re-run its on-show
  // reset, so close it first.
  // `@` queries skip the launcher: wallpaper mode dismisses it from inside its
  // own show handler, so open the filmstrip with the same query the launcher's
  // onWallpaperModeChanged would pass to onWallpapersRequested.
  function openLauncherWith(query) {
    if (lockScreen.locked) return
    if (query.trim().startsWith("@")) {
      bar.openPopup = ""
      shell.wallpaperFilmstripQuery = query.trim().substring(1).trim()
      shell.wallpaperFilmstripOpen = true
      return
    }
    anchorLauncher()
    if (bar.openPopup === "launcher") bar.openPopup = ""
    launcherPopup.initialQuery = query
    bar.openPopup = "launcher"
  }

  // Bottom-bar page buttons: closed opens at the page, the open page closes
  // it, another page switches (BottomBarModel.sidebarToggle).
  property real sidebarClosedAt: 0
  function openSidebarPage(n) {
    if (lockScreen.locked) return false
    var r = BottomBarModel.sidebarToggle(bar.openPopup, sidebar.currentPage, n, sidebar.pageCount)
    if (r.open) {
      sidebar.showPage(r.page)
      bar.openPopup = "sidebar"
    } else {
      bar.openPopup = ""
    }
    return true
  }

  // niri's socket path changes per session; pick the newest like the other
  // niri helpers in this config.
  function niriAction(args) {
    Quickshell.execDetached(["sh", "-c",
      "NIRI_SOCKET=$(ls -t /run/user/$(id -u)/niri.*.sock 2>/dev/null | head -1) niri msg action " + args])
  }

  function dockLaunch(appId) {
    var entry = DesktopEntries.heuristicLookup(appId)
    if (entry) entry.execute()
    else Quickshell.execDetached([appId])
  }

  function dockActivate(appId) {
    var windows = WindowService.windows
    var own = DockModel.dockItems([appId], windows)[0]
    if (!own || own.count === 0) { shell.dockLaunch(appId); return }
    var id = own.focused
      ? DockModel.nextWindow(windows, appId, WindowService.focusedWindowId, 1)
      : DockModel.relevantWindow(windows, appId)
    if (id !== null) shell.niriAction("focus-window --id " + Math.floor(id))
  }

  function dockClose(appId) {
    var id = DockModel.relevantWindow(WindowService.windows, appId)
    if (id !== null) shell.niriAction("close-window --id " + Math.floor(id))
  }

  function dockCycle(appId, direction) {
    var id = DockModel.nextWindow(WindowService.windows, appId, WindowService.focusedWindowId, direction)
    if (id !== null) shell.niriAction("focus-window --id " + Math.floor(id))
  }

  function popupMarginLeft(w, screenW) {
    if (bar.horizontal) {
      // Float popups off the screen edge instead of clamping flush to it.
      var gap = Config.spacingMedium
      return Math.round(Math.max(gap, Math.min(bar.popupAnchorX - w / 2, screenW - w - gap)))
    }
    return bar.dockedRight
      ? Math.max(0, screenW - w - popupBarInset())
      : popupBarInset()
  }

  function popupMarginTop(h, screenH) {
    if (bar.horizontal) {
      return bar.dockedBottom
        ? Math.max(0, screenH - h - popupBarInset())
        : popupBarInset()
    }
    return Math.round(Math.max(0, Math.min(bar.popupAnchorY - h / 2, screenH - h)))
  }

  function toggleLayout() {
    var next = shell.isHorizontal
      ? (shell.barPosition === "bottom" ? "right" : "left")
      : (shell.barPosition === "right" ? "bottom" : "top")
    shell.setBarPosition(next)
  }


  function resetAppearanceToDefaults() {
    Settings.resetAppearanceToDefaults()
    shell.setBarPosition("top")
  }

  function resetAllSettingsToDefaults() {
    Settings.resetToDefaults()
    shell.setBarPosition("top")
  }

  LockScreen {
    id: lockScreen
  }


  IpcHandler {
    id: ipc
    target: "shell"

    function launcher() {
      shell.anchorLauncher()
      bar.openPopup = bar.openPopup === "launcher" ? "" : "launcher"
    }

    function lockSecure(): bool {
      return lockScreen.secure
    }

    function lock() {
      shell.requestLock()
    }


    // Toggles the full-screen power menu (route name kept for callers).
    function quickmenu() {
      if (lockScreen.locked) return
      bar.openPopup = bar.openPopup === "quickmenu" ? "" : "quickmenu"
    }

    function settings() {
      if (bar.horizontal) {
        bar.popupAnchorX = bar.getSettingsX()
      } else {
        bar.popupAnchorY = bar.getSettingsY()
      }
      bar.openPopup = bar.openPopup === "settings" ? "" : "settings"
    }

    // popup("audio" | "brightness" | "media" | "weather" | "llm" | "battery" |
    // "notification" | "calendar" | "quickmenu" | "launcher" | "sidebar" |
    // "networks" | "alarms"): toggle a bar popup.
    function popup(name: string): bool {
      return bar.togglePopupByName(name)
    }

    // Dev/testing: switch the bar form in memory (full, fit, dock, notch,
    // pill). Unknown names normalize to full. Not saved.
    function barForm(form: string): string {
      Settings.barForm = BarForm.normalize(form)
      return Settings.barForm
    }


    // Dev/testing: select a Settings tab (0-9) in memory. Not saved unless
    // something else calls Settings.save().
    function settingsTab(index: int): int {
      Settings.lastSettingsTab = index
      // currentTab loses its binding to the setting once the panel assigns it
      // (any tab click), so set it directly too.
      settingsPanel.currentTab = index
      return settingsPanel.currentTab
    }

    // Dev/testing: open the networks window with the "forget <name>?" row
    // shown, without touching the keyboard. Never forgets anything by itself;
    // "" clears the row and leaves the window as it is.
    function forgetPrompt(name: string): string {
      if (lockScreen.locked) return ""
      networksWindow.forgetFor = name
      if (name !== "") bar.openPopup = "networks"
      return networksWindow.forgetFor
    }


    // Dev/testing: alarm list as JSON.
    function alarmState(): string {
      return JSON.stringify({ count: AlarmService.count, loaded: AlarmService.loaded,
        lastRung: AlarmService.lastRung, alarms: AlarmService.alarms })
    }

    // Dev/testing: schedule an alarm `minutes` from now (fractions allowed);
    // returns the new count.
    function alarmAdd(minutes: real, label: string): int {
      AlarmService.add(AlarmService.nowFn() + Math.round(minutes * 60000), label === "" ? "beep beep" : label)
      return AlarmService.count
    }

    // Dev/testing: delete the alarm at sorted position `index`; true when it existed.
    function alarmRemove(index: int): bool {
      return AlarmService.removeAt(index)
    }

    // Dev/testing: dock state as JSON (items and window inputs).
    function dockState(): string {
      return JSON.stringify({
        workspaceEmpty: WindowService.workspaceEmpty,
        windows: WindowService.windows.length,
        items: bottomBar.items
      })
    }

    // Bottom-bar page request: same toggle as the bar buttons.
    function openSidebarPage(n: int): bool { return shell.openSidebarPage(n) }

    // Dev/testing: bottom bar inputs as JSON.
    function bottomBarState(): string {
      var c = bottomBar.content
      return JSON.stringify({ items: bottomBar.items, clockText: c.clockText, dateText: c.dateText,
        volume: c.volume, muted: c.muted, batteryPct: c.batteryPct, charging: c.charging,
        signal: c.signal, connected: c.connected, vpn: c.vpn, alarmCount: c.alarmCount,
        height: bottomBar.implicitHeight, page: sidebar.currentPage })
    }

    // Dev/testing: the launcher's current search text.
    function launcherQuery(): string {
      return launcherPopup.searchText
    }

    function currentPopup(): string {
      return bar.openPopup
    }

    function dismissPopups() {
      bar.openPopup = ""
      shell.wallpaperFilmstripOpen = false
    }

    function randomWallpaper() {
      Quickshell.execDetached([
        "bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/random-wallpaper.sh"
      ])
    }

    function wallpapers() {
      bar.openPopup = ""
      shell.wallpaperFilmstripQuery = ""
      shell.wallpaperFilmstripOpen = !shell.wallpaperFilmstripOpen
    }

    // Compatibility alias for existing scripts and external IPC callers.
    function commandcenter() {
      settings()
    }

    function layout() {
      shell.toggleLayout()
    }

    function reloadPalette() {
      Colors.reloadMatugenPalette()
    }

  }

  FileTrigger {
    triggers: ({
      "qslauncher-trigger": "launcher",
      "qsquickmenu-trigger": "quickmenu",
      "qssettings-trigger": "settings",
      "qscommandcenter-trigger": "settings",
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
        case "settings": ipc.settings(); break
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
    barPosition: "top"
    screen: bar.screen
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
    screen: bar.screen
    visible: bar.openPopup !== "" && !lockScreen.locked
    onShieldClicked: bar.openPopup = ""
  }

  Bar {
    id: bar
    // elena is a top-edge block row; the saved position stays untouched.
    barPosition: "top"
    notificationCount: notificationPopup.count
    sessionLocked: lockScreen.locked || lockScreen.compositorLocked
    // Wait for persisted settings before exposing the panel so the first
    // mapped surface uses the final bar geometry and style.
    visible: bar.surfaceReady
      && Settings.initialLoadComplete
      && !lockScreen.locked
      && !lockScreen.compositorLocked
  }

  AudioPopup {
    id: audioPopup
    visible: bar.openPopup === "audio" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
    screen: bar.screen

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, bar.screen.width)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, bar.screen.height)
  }

  BrightnessPopup {
    id: brightnessPopup
    visible: bar.openPopup === "brightness" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    screen: bar.screen
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, bar.screen.width)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, bar.screen.height)
  }

  MediaPopup {
    id: mediaPopup
    visible: bar.openPopup === "media" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    screen: bar.screen
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, bar.screen.width)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, bar.screen.height)
  }

  WeatherPopup {
    id: weatherPopup
    visible: bar.openPopup === "weather" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    screen: bar.screen
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, bar.screen.width)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, bar.screen.height)
  }

  Sidebar {
    id: sidebar
    visible: bar.openPopup === "sidebar" && !lockScreen.locked
    screen: bar.screen
    onDismissed: bar.openPopup = ""
    // Every close path (Esc, middle click, bar button, click outside) passes here.
    onVisibleChanged: if (!visible) shell.sidebarClosedAt = Date.now()
  }

  MicIndicator {
    id: micIndicator
    screen: bar.screen
    allowed: !lockScreen.locked && !lockScreen.compositorLocked
  }

  AlarmsWindow {
    id: alarmsWindow
    visible: bar.openPopup === "alarms" && !lockScreen.locked && !lockScreen.compositorLocked
    screen: bar.screen
    onDismissed: bar.openPopup = ""
  }

  NetworksWindow {
    id: networksWindow
    visible: bar.openPopup === "networks" && !lockScreen.locked && !lockScreen.compositorLocked
    screen: bar.screen
    onDismissed: bar.openPopup = ""
  }

  // Left-edge hover opens the sidebar at the page last shown; an open sidebar
  // stays open (openSidebarPage would toggle it closed).
  SidebarActivator {
    id: sidebarActivator
    screen: bar.screen
    enabledByState: !lockScreen.locked
    // A close with the pointer resting on the edge must not reopen at once.
    onActivated: if (bar.openPopup !== "sidebar" && Date.now() - shell.sidebarClosedAt >= 300)
      shell.openSidebarPage(sidebar.currentPage)
  }

  BottomBar {
    id: bottomBar
    visible: bar.visible && !lockScreen.locked
    screen: bar.screen
    items: DockModel.dockItems(DockModel.normalizePinned(Settings.dockPinned), WindowService.windows)
    onSidebarPageRequested: function(page) { shell.openSidebarPage(page) }
    // Same anchor and toggle as the launcher() IPC call.
    // ipc.launcher() anchors, then toggles (an open launcher closes).
    onLauncherRequested: {
      if (lockScreen.locked) return
      ipc.launcher()
    }
    // Her alarms window; a second click closes it.
    onAlarmsRequested: {
      if (lockScreen.locked) return
      bar.togglePopupByName("alarms")
    }
    // Her networks window; a second click closes it.
    onNetworkRequested: {
      if (lockScreen.locked) return
      bar.togglePopupByName("networks")
    }
    onLogoutRequested: {
      if (lockScreen.locked) return
      bar.togglePopupByName("quickmenu")
    }
    onItemActivated: function(appId) { shell.dockActivate(appId) }
    onItemClosed: function(appId) { shell.dockClose(appId) }
    onItemCycled: function(appId, direction) { shell.dockCycle(appId, direction) }
  }


  LlmUsagePopup {
    visible: bar.openPopup === "llm" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    screen: bar.screen
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, bar.screen.width)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, bar.screen.height)
  }

  BatteryPopup {
    id: batteryPopup
    visible: bar.openPopup === "battery" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    screen: bar.screen
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, bar.screen.width)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, bar.screen.height)
  }

  CalendarPopup {
    id: calendarPopup
    visible: bar.openPopup === "calendar" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    screen: bar.screen
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, bar.screen.width)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, bar.screen.height)
  }

  NotificationPopup {
    id: notificationPopup
    visible: bar.openPopup === "notification" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    screen: bar.screen
    onDismissed: bar.openPopup = ""

    anchors.left: true
    margins.left: shell.popupMarginLeft(implicitWidth, bar.screen.width)
    anchors.top: true
    margins.top: shell.popupMarginTop(implicitHeight, bar.screen.height)
  }

  PowerMenu {
    id: powerMenu
    visible: bar.openPopup === "quickmenu" && !lockScreen.locked && !lockScreen.compositorLocked
    screen: bar.screen
    onDismissed: bar.openPopup = ""
    onLockRequested: shell.requestLock()
  }

  PanelWindow {
    id: powerConfirmationWindow
    screen: bar.screen
    visible: powerMenu.pendingIndex >= 0 && !lockScreen.locked && !lockScreen.compositorLocked
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: Config.layerNamespace("confirmation")
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: powerConfirmationWindow.visible
      ? WlrKeyboardFocus.Exclusive
      : WlrKeyboardFocus.None

    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true

    PowerConfirmation {
      anchors.fill: parent
      opened: powerConfirmationWindow.visible
      actionLabel: powerMenu.labels[powerMenu.pendingId] || ""
      actionDescription: powerMenu.descriptions[powerMenu.pendingId] || ""
      actionIcon: powerMenu.icons[powerMenu.pendingId] || ""
      onConfirmed: powerMenu.confirmPending()
      onCancelled: powerMenu.cancelPending()
    }
  }

  SettingsPanel {
    id: settingsPanel
    screen: bar.screen
    visible: bar.openPopup === "settings" && !lockScreen.locked && !lockScreen.compositorLocked
    onDismissed: bar.openPopup = ""
    onLockRequested: shell.requestLock()
    isHorizontal: bar.horizontal
    barPosition: bar.barPosition
    onResetAppearance: shell.resetAppearanceToDefaults()
    onResetAllSettings: shell.resetAllSettingsToDefaults()
    notificationPopup: notificationPopup
    sessionLocked: lockScreen.locked || lockScreen.compositorLocked
  }

  OsdOverlay {
    id: osd
  }

  WallpaperFilmstrip {
    id: wallpaperFilmstrip
    screen: bar.screen
    open: shell.wallpaperFilmstripOpen && !lockScreen.locked
    initialQuery: shell.wallpaperFilmstripQuery
    onDismissed: shell.wallpaperFilmstripOpen = false
  }

  LauncherPopup {
    id: launcherPopup
    screen: bar.screen
    visible: bar.openPopup === "launcher" && !lockScreen.locked
    anchorY: bar.popupAnchorY
    onDismissed: bar.openPopup = ""
    onWallpapersRequested: function(query) {
      shell.wallpaperFilmstripQuery = query
      shell.wallpaperFilmstripOpen = true
    }

    anchors.left: true
    anchors.right: false
    anchors.top: true
    anchors.bottom: false
    // Her rofi window sits at the screen center (location 0).
    margins.left: LauncherLayout.centered(bar.screen.width, implicitWidth)
    margins.top: LauncherLayout.centered(bar.screen.height, implicitHeight)
  }
}
