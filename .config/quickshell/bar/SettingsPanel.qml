import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import "settings"
import "primitives"
import "../config"

PanelWindow {
  id: root

  signal dismissed()
  signal lockRequested()
  property QtObject notificationPopup: null

  property bool isHorizontal: false
  signal toggleHorizontal()
  property string barPosition: "top"
  signal setBarPosition(string position)
  signal resetAppearance()
  signal resetAllSettings()
  property bool fullBar: false
  signal toggleFullBar()

  property int currentTab: Math.max(0, Math.min(tabCount - 1, Settings.lastSettingsTab))
  property int focusedTab: currentTab
  property double openTime: 0
  readonly property bool compactLayout: root.implicitWidth <= 480
  readonly property int sidebarWidth: root.implicitWidth <= 480 ? 108 : 168
  readonly property int sidebarRowSpacing: 2
  readonly property int contentMargin: root.implicitHeight < 540 ? Config.spacingMedium : Config.spacingExtraLarge
  readonly property real centeredLeftMargin: Math.max(Config.spacingLarge, (desktopW - root.implicitWidth) / 2)
  readonly property real centeredTopMargin: Math.max(Config.spacingLarge, (desktopH - root.implicitHeight) / 2)
  property bool customPosition: false
  property real panelLeft: 0
  property real panelTop: 0

  property string searchQuery: ""

  // Keep navigation metadata in one place so the sidebar and search results
  // share the same labels and hierarchy. The group names are intentionally
  // broad; the more specific groups belong inside each page.
  readonly property var tabDefinitions: [
    { icon: "person", label: "Account", group: "Personal" },
    { icon: "tune", label: "General", group: "Interface" },
    { icon: "palette", label: "Appearance", group: "Interface" },
    { icon: "wallpaper", label: "Wallpaper", group: "Interface" },
    { icon: "monitor", label: "Display & Input", group: "Devices" },
    { icon: "wifi", label: "Network", group: "Devices" },
    { icon: "bluetooth", label: "Bluetooth", group: "Devices" },
    { icon: "play_circle", label: "Media", group: "Devices" },
    { icon: "lock", label: "Lock & Power", group: "System" },
    { icon: "notifications", label: "Notifications", group: "System" },
    { icon: "monitor_heart", label: "System", group: "System" },
    { icon: "keyboard", label: "Shortcuts", group: "System" }
  ]
  readonly property int tabCount: tabDefinitions.length

  // Search metadata is deliberately separate from the page controls. Some
  // pages use custom sliders or segmented controls, so wrapping every control
  // in a navigation component would make the pages harder to maintain.
  readonly property var searchEntries: [
    { tab: 0, category: "System details", icon: "person", title: "Machine info", subtitle: "Hostname, OS, kernel, CPU, and GPU" },
    { tab: 0, category: "System details", icon: "wifi", title: "Network status", subtitle: "IP address and connection details" },
    { tab: 1, category: "Motion", icon: "motion_photos_off", title: "Reduced motion", subtitle: "Use shorter, calmer transitions" },
    { tab: 1, category: "Clock", icon: "schedule", title: "Show uptime", subtitle: "Show uptime on the Account tab" },
    { tab: 1, category: "Clock", icon: "schedule", title: "24-hour clock", subtitle: "Use a 24-hour clock format" },
    { tab: 1, category: "Clock", icon: "timer", title: "Show seconds", subtitle: "Display seconds in the bar clock" },
    { tab: 1, category: "Calendar", icon: "calendar_view_week", title: "Week starts Monday", subtitle: "Set the first day of the calendar week" },
    { tab: 1, category: "Bar contents", icon: "apps", title: "Bar item visibility", subtitle: "Launcher, workspaces, clock, tray, audio, weather, and more" },
    { tab: 1, category: "Weather and location", icon: "my_location", title: "Use IP geolocation", subtitle: "Use your network location for weather" },
    { tab: 1, category: "Weather and location", icon: "location_on", title: "Weather location", subtitle: "Set a city or town for weather" },
    { tab: 1, category: "Weather and location", icon: "update", title: "Weather refresh interval", subtitle: "Choose how often weather refreshes" },
    { tab: 1, category: "Weather and location", icon: "thermostat", title: "Temperature units", subtitle: "Use metric or imperial units" },
    { tab: 2, category: "General UI", icon: "auto_awesome", title: "UI Style", subtitle: "Material, Neo, Nothing, Ghost, or Evolution" },
    { tab: 2, category: "Color and theme", icon: "palette", title: "Color source", subtitle: "Live wallpaper colors or a fixed palette" },
    { tab: 2, category: "Color and theme", icon: "dark_mode", title: "Color mode", subtitle: "Automatic, light, or dark" },
    { tab: 2, category: "Color and theme", icon: "palette", title: "Color palette", subtitle: "Material 3, Catppuccin, Gruvbox, or TokyoNight" },
    { tab: 2, category: "Color and theme", icon: "contrast", title: "Contrast", subtitle: "Standard, medium, or high contrast" },
    { tab: 2, category: "Bar", icon: "dock_to_bottom", title: "Bar placement", subtitle: "Top, bottom, left, or right" },
    { tab: 2, category: "Bar", icon: "view_week", title: "Bar display style", subtitle: "One continuous bar or separate pills" },
    { tab: 2, category: "Workspaces", icon: "looks_5", title: "Visible workspaces", subtitle: "Show active workspaces, one through five, or one through ten" },
    { tab: 2, category: "Workspaces", icon: "shapes", title: "Workspace marker style", subtitle: "Choose expressive, pill, rounded, circle, dots, glyph, or other shapes" },
    { tab: 2, category: "Sizing", icon: "format_size", title: "UI Font Size", subtitle: "Adjust the shell's base text size" },
    { tab: 2, category: "Sizing", icon: "schedule", title: "Clock Size", subtitle: "Adjust the bar clock size" },
    { tab: 2, category: "Sizing", icon: "photo_size_select_small", title: "Icon Size", subtitle: "Adjust shared icon sizing" },
    { tab: 2, category: "Sizing", icon: "space_bar", title: "Spacing", subtitle: "Adjust the shell density" },
    { tab: 2, category: "Sizing", icon: "height", title: "Bar Size", subtitle: "Adjust bar thickness and widget size" },
    { tab: 2, category: "Reset", icon: "settings_backup_restore", title: "Reset Appearance", subtitle: "Restore appearance defaults" },
    { tab: 3, category: "Wallpaper", icon: "wallpaper", title: "Wallpaper", subtitle: "Browse, set, and randomize wallpapers" },
    { tab: 4, category: "Outputs", icon: "monitor", title: "Display mode", subtitle: "Choose the output resolution and refresh rate" },
    { tab: 4, category: "Outputs", icon: "photo_size_select_small", title: "Display scale", subtitle: "Adjust output scaling" },
    { tab: 4, category: "Outputs", icon: "screen_rotation", title: "Display transform", subtitle: "Rotate or reflect the output" },
    { tab: 4, category: "Touchpad", icon: "touch_app", title: "Tap to click", subtitle: "Use a light tap instead of pressing the pad" },
    { tab: 4, category: "Touchpad", icon: "swap_vert", title: "Touchpad natural scrolling", subtitle: "Scroll in the direction your fingers move" },
    { tab: 4, category: "Touchpad", icon: "touchpad_mouse", title: "Touchpad scroll method", subtitle: "Choose the touchpad scroll gesture" },
    { tab: 4, category: "Mouse", icon: "mouse", title: "Mouse natural scrolling", subtitle: "Reverse the mouse wheel direction" },
    { tab: 4, category: "Trackpoint", icon: "mouse", title: "Trackpoint natural scrolling", subtitle: "Reverse the TrackPoint scroll direction" },
    { tab: 4, category: "Pointer", icon: "speed", title: "Pointer acceleration", subtitle: "Adjust mouse and TrackPoint acceleration" },
    { tab: 5, category: "Connections", icon: "wifi", title: "Wi-Fi", subtitle: "Connect, forget, and manage saved networks" },
    { tab: 6, category: "Connections", icon: "bluetooth", title: "Bluetooth", subtitle: "Pair and connect nearby devices" },
    { tab: 7, category: "Media popup", icon: "image", title: "Show album art", subtitle: "Show artwork in the media popup" },
    { tab: 7, category: "Media popup", icon: "linear_scale", title: "Show progress bar", subtitle: "Show playback progress" },
    { tab: 7, category: "Media popup", icon: "touch_app", title: "Controls always visible", subtitle: "Keep media controls visible when paused" },
    { tab: 8, category: "Lock screen", icon: "music_note", title: "Show now playing", subtitle: "Show the current track on the lock screen" },
    { tab: 8, category: "Lock screen", icon: "wallpaper", title: "Use current wallpaper", subtitle: "Use the active wallpaper on the lock screen" },
    { tab: 8, category: "Lock screen", icon: "schedule", title: "Clock face", subtitle: "Choose the lock-screen clock style" },
    { tab: 8, category: "Idle and power", icon: "lock", title: "Lock after inactivity", subtitle: "Set the idle lock timeout" },
    { tab: 8, category: "Idle and power", icon: "bedtime", title: "Suspend after inactivity", subtitle: "Set the idle suspend timeout" },
    { tab: 8, category: "Power", icon: "bolt", title: "Power Profiles", subtitle: "Choose the automatic power profile" },
    { tab: 8, category: "Power", icon: "coffee", title: "Caffeine", subtitle: "Temporarily prevent idle actions" },
    { tab: 9, category: "Notifications", icon: "do_not_disturb_on", title: "Do Not Disturb", subtitle: "Suppress notification toasts" },
    { tab: 9, category: "Notifications", icon: "bedtime", title: "Quiet hours", subtitle: "Silence notifications during a schedule" },
    { tab: 9, category: "Notifications", icon: "priority_high", title: "Critical notification bypass", subtitle: "Keep critical alerts visible during quiet hours" },
    { tab: 9, category: "Notifications", icon: "timer", title: "Toast duration", subtitle: "Choose how long notification toasts remain visible" },
    { tab: 9, category: "Notifications", icon: "open_in_new", title: "Toast position", subtitle: "Place notification toasts at the top or bottom" },
    { tab: 9, category: "History", icon: "history", title: "Notification history limit", subtitle: "Limit retained notification history" },
    { tab: 10, category: "Diagnostics", icon: "monitor_heart", title: "CPU Usage", subtitle: "View current processor usage" },
    { tab: 10, category: "Diagnostics", icon: "memory", title: "Memory (RAM)", subtitle: "View current memory usage" },
    { tab: 10, category: "Diagnostics", icon: "storage", title: "Disk Storage", subtitle: "View root filesystem usage" },
    { tab: 10, category: "Diagnostics", icon: "swap_horiz", title: "Swap", subtitle: "View swap usage" },
    { tab: 10, category: "Diagnostics", icon: "thermostat", title: "CPU Temperature", subtitle: "View processor temperature" },
    { tab: 10, category: "Diagnostics", icon: "mode_fan", title: "Fan Speed", subtitle: "View fan speed when available" },
    { tab: 10, category: "Diagnostics", icon: "battery_full", title: "Battery", subtitle: "View battery status" },
    { tab: 10, category: "Diagnostics", icon: "battery_alert", title: "Battery Health", subtitle: "View battery health" },
    { tab: 10, category: "Diagnostics", icon: "battery_charging_full", title: "Battery Cycles", subtitle: "View battery cycle count" },
    { tab: 10, category: "Diagnostics", icon: "trending_up", title: "Load Average", subtitle: "View one, five, and fifteen minute load" },
    { tab: 10, category: "Shell actions", icon: "refresh", title: "Reload Quickshell", subtitle: "Restart the shell process" },
    { tab: 11, category: "Application shortcuts", icon: "apps", title: "App shortcuts", subtitle: "Launch applications and common actions" },
    { tab: 11, category: "Window shortcuts", icon: "window", title: "Window shortcuts", subtitle: "Focus, move, and resize windows" },
    { tab: 11, category: "Workspace shortcuts", icon: "workspaces", title: "Workspace shortcuts", subtitle: "Move between and manage workspaces" },
    { tab: 11, category: "System shortcuts", icon: "keyboard", title: "System shortcuts", subtitle: "Use shell, media, brightness, and power shortcuts" }
  ]

  function tabLabel(tabIndex) {
    var tab = root.tabDefinitions[tabIndex]
    return tab ? tab.label : "Settings"
  }

  function entryContext(entry) {
    return root.tabLabel(entry.tab) + " · " + entry.category
  }

  readonly property var searchResults: {
    var q = root.searchQuery.trim().toLowerCase()
    if (q === "") return []
    return root.searchEntries.filter(function(entry) {
      var tabText = root.tabLabel(entry.tab).toLowerCase()
      return entry.title.toLowerCase().indexOf(q) !== -1
          || entry.category.toLowerCase().indexOf(q) !== -1
          || entry.subtitle.toLowerCase().indexOf(q) !== -1
          || tabText.indexOf(q) !== -1
    })
  }

  // Account tab: session info
  property string uptimeText: "up ..."

  property bool caffeineOn: false

  // System Diagnostics Stats (System tab)
  property real statsCpu: -1
  property string statsRamStr: "Unavailable"
  property real statsRamPct: -1
  property string statsDiskStr: "Unavailable"
  property real statsDiskPct: -1
  property int statsCpuCount: -1

  function resetStats() {
    root.statsCpu = -1
    root.statsRamStr = "Unavailable"
    root.statsRamPct = -1
    root.statsDiskStr = "Unavailable"
    root.statsDiskPct = -1
    root.statsCpuCount = -1
  }

  function parseStatNumber(value) {
    var raw = value === undefined || value === null ? "" : String(value).trim()
    if (raw === "") return -1
    var parsed = parseFloat(raw)
    return isFinite(parsed) ? parsed : -1
  }

  Process {
    id: statsProc
    command: ["sh", "-c",
      "cpu=$(top -bn1 2>/dev/null | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}'); " +
      "cpu_count=$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || true); " +
      "mem=$(free -m 2>/dev/null | awk '/^Mem:/ { printf \"%d,%d,%.2f\", $3, $2, ($2 > 0 ? $3*100/$2 : -1); found=1 } END { if (!found) print \"-1,-1,-1\" }'); " +
      "disk=$(df -hP / 2>/dev/null | awk 'NR == 2 { print $3 \",\" $2 \",\" $5; found=1 } END { if (!found) print \"Unavailable,Unavailable,-1\" }'); " +
      "printf '%s|%s|%s|%s\\n' \"$cpu\" \"$cpu_count\" \"$mem\" \"$disk\""]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.resetStats()

        var parts = text.trim().split("|")
        if (parts.length < 4) return

        var cpu = root.parseStatNumber(parts[0])
        var cpuCount = parseInt(parts[1])
        root.statsCpu = cpu >= 0 ? Math.max(0, Math.min(100, cpu)) : -1
        root.statsCpuCount = isFinite(cpuCount) && cpuCount > 0 ? cpuCount : -1

        var memParts = parts[2].split(",")
        var memUsedMb = root.parseStatNumber(memParts[0])
        var memTotalMb = root.parseStatNumber(memParts[1])
        var memPct = root.parseStatNumber(memParts[2])
        if (memUsedMb >= 0 && memTotalMb > 0 && memPct >= 0) {
          root.statsRamStr = (memUsedMb / 1024.0).toFixed(1) + " / " + (memTotalMb / 1024.0).toFixed(1) + " GB"
          root.statsRamPct = Math.max(0, Math.min(1, memPct / 100.0))
        }

        var diskParts = parts[3].split(",")
        var diskPct = root.parseStatNumber(String(diskParts[2] || "").replace("%", ""))
        if (diskParts.length >= 3 && diskParts[0] !== "Unavailable" && diskParts[1] !== "Unavailable" && diskPct >= 0) {
          root.statsDiskStr = diskParts[0] + " / " + diskParts[1]
          root.statsDiskPct = Math.max(0, Math.min(1, diskPct / 100.0))
        }
      }
    }
    onExited: (exitCode) => {
      if (exitCode !== 0) root.resetStats()
    }
  }

  Timer {
    id: statsTimer
    interval: 3000
    running: root.visible && root.currentTab === 10
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statsProc.running = false;
      statsProc.running = true;
    }
  }

  // -1 sentinel means "no custom size yet" (see Settings.settingsPanelWidth/Height);
  // fall back to Config.settingsDefaultWidth/Height until the user drags the resize handle.
  implicitWidth: Math.min(Math.min(Config.settingsMaxWidth, desktopW - Config.spacingPage),
                          Math.max(Config.settingsMinWidth, Settings.settingsPanelWidth > 0 ? Settings.settingsPanelWidth : Config.settingsDefaultWidth))
                 + (Config.neoBrutalism ? Config.themeShadowOffset : 0)
  visible: false
  implicitHeight: Math.min(Math.min(Config.settingsMaxHeight, desktopH - Config.spacingPage),
                           Math.max(Config.settingsMinHeight, Settings.settingsPanelHeight > 0 ? Settings.settingsPanelHeight : Config.settingsDefaultHeight))
                  + (Config.neoBrutalism ? Config.themeShadowOffset : 0)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  // Center the panel until the user moves it. A resized panel stays anchored to
  // its current origin after that, which keeps the drag interaction predictable.
  property int desktopW: Screen.desktopAvailableWidth
  property int desktopH: Screen.desktopAvailableHeight

  function clampPanelPosition() {
    if (!root.customPosition) return

    var maxLeft = Math.max(Config.spacingLarge, root.desktopW - root.implicitWidth - Config.spacingLarge)
    var maxTop = Math.max(Config.spacingLarge, root.desktopH - root.implicitHeight - Config.spacingLarge)
    root.panelLeft = Math.max(Config.spacingLarge, Math.min(maxLeft, root.panelLeft))
    root.panelTop = Math.max(Config.spacingLarge, Math.min(maxTop, root.panelTop))
  }

  anchors.left: true
  margins.left: root.customPosition ? root.panelLeft : root.centeredLeftMargin
  anchors.top: true
  margins.top: root.customPosition ? root.panelTop : root.centeredTopMargin

  onImplicitWidthChanged: root.clampPanelPosition()
  onImplicitHeightChanged: root.clampPanelPosition()
  onDesktopWChanged: root.clampPanelPosition()
  onDesktopHChanged: root.clampPanelPosition()

  // Uptime Process
  Process {
    id: uptimeProc
    command: ["uptime", "-p"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.uptimeText = text.trim();
      }
    }
  }

  Timer {
    id: uptimeTimer
    interval: 60000
    running: root.visible && Settings.systemShowUptime
    repeat: true
    onTriggered: {
      uptimeProc.running = false
      uptimeProc.running = true
    }
  }

  Process {
    id: idleCheck
    command: ["sh", "-c", "pgrep -x swayidle >/dev/null 2>&1 && echo active || echo inactive"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.caffeineOn = text.trim() !== "active"
      }
    }
  }

  Connections {
    target: Settings

    function onSystemShowUptimeChanged() {
      if (!Settings.systemShowUptime) {
        if (uptimeProc.running) uptimeProc.running = false
      } else if (root.visible && !uptimeProc.running) {
        uptimeProc.running = true
      }
    }
  }

  function ensureCurrentTabVisible() {
    if (!sidebarScroll.interactive || tabRepeater.count === 0) return

    var tabEntry = tabRepeater.itemAt(root.currentTab)
    var row = tabEntry ? tabEntry.navigationItem : null
    if (!row) {
      ensureTabVisibilityTimer.restart()
      return
    }

    var rowPosition = row.mapToItem(sidebarColumn, 0, 0)
    var rowTop = rowPosition.y
    var rowBottom = rowTop + row.height
    var nextContentY = sidebarScroll.contentY

    if (rowTop < sidebarScroll.contentY) {
      nextContentY = rowTop
    } else if (rowBottom > sidebarScroll.contentY + sidebarScroll.height) {
      nextContentY = rowBottom - sidebarScroll.height
    }

    sidebarScroll.contentY = Math.max(0, Math.min(
      nextContentY,
      Math.max(0, sidebarScroll.contentHeight - sidebarScroll.height)))
  }

  function focusTab(index) {
    var target = Math.max(0, Math.min(tabRepeater.count - 1, index))
    root.focusedTab = target
    root.ensureCurrentTabVisible()
    if (mainItem) mainItem.forceActiveFocus()
  }

  function selectTab(index) {
    root.currentTab = Math.max(0, Math.min(tabRepeater.count - 1, index))
    root.focusTab(root.currentTab)
  }

  function focusFirstFocusable(item) {
    if (!item || !item.visible) return false

    // Flickable content lives below contentItem rather than directly in the
    // Flickable's visual children. Walk it first so Tab enters the active
    // Settings page instead of stopping on the page shell.
    if (item.contentItem && item.contentItem !== item
        && root.focusFirstFocusable(item.contentItem)) return true

    var children = item.children || []
    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (!child || !child.visible) continue
      if (child.activeFocusOnTab && child.enabled !== false) {
        child.forceActiveFocus()
        return true
      }
      if (root.focusFirstFocusable(child)) return true
    }
    return false
  }

  function focusCurrentTabContent() {
    if (!root.focusFirstFocusable(tabContainer)) mainItem.forceActiveFocus()
  }

  onCurrentTabChanged: {
    root.ensureCurrentTabVisible()
    if (Settings.lastSettingsTab !== root.currentTab) {
      Settings.lastSettingsTab = root.currentTab
      Settings.save()
    }
  }

  Timer {
    id: ensureTabVisibilityTimer
    interval: 1
    repeat: false
    onTriggered: root.ensureCurrentTabVisible()
  }

  Timer {
    id: focusRequestTimer
    interval: 50
    repeat: false
    onTriggered: {
      if (root.visible) mainItem.forceActiveFocus()
    }
  }

  onHeightChanged: ensureTabVisibilityTimer.start()
  onWidthChanged: ensureTabVisibilityTimer.start()

  onVisibleChanged: {
    if (visible) {
      idleCheck.running = true
      if (Config.reducedMotion) {
        entryAnimation.stop()
        scaleTransform.xScale = 1.0
        scaleTransform.yScale = 1.0
        transX.x = 0
        bg.opacity = 1.0
      } else {
        entryAnimation.start()
      }
      focusRequestTimer.restart()
      root.focusedTab = root.currentTab
      mainItem.forceActiveFocus()
      root.ensureCurrentTabVisible()
      root.openTime = Date.now()

      // Refresh dynamic content
      if (Settings.systemShowUptime) {
        uptimeProc.running = false
        uptimeProc.running = true
      }
    } else {
      focusRequestTimer.stop()
    }
  }

  WlrLayershell.focusable: true
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

  FocusScope {
    id: mainItem
    anchors.fill: parent
    focus: true
    Keys.priority: Keys.BeforeItem

    Keys.onPressed: function(event) {
      // Let the search field handle its own keys (typing, cursor movement,
      // its own Escape/Up/Down) instead of the sidebar's global shortcuts —
      // this handler runs BeforeItem, so it would otherwise steal Space,
      // Enter, Up/Down, and Escape from the text being typed.
      if (searchField.input.activeFocus) return

      if (event.key === Qt.Key_Slash) {
        searchField.input.forceActiveFocus()
        event.accepted = true
      } else if (event.key === Qt.Key_Escape) {
        if (Date.now() - root.openTime > 150) {
          root.dismissed()
        }
        event.accepted = true
      } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        root.selectTab(root.focusedTab)
        event.accepted = true
      } else if (event.key === Qt.Key_Up) {
        root.focusTab((root.focusedTab + tabRepeater.count - 1) % tabRepeater.count)
        event.accepted = true
      } else if (event.key === Qt.Key_Down) {
        root.focusTab((root.focusedTab + 1) % tabRepeater.count)
        event.accepted = true
      } else if (event.key === Qt.Key_Home) {
        root.focusTab(0)
        event.accepted = true
      } else if (event.key === Qt.Key_End) {
        root.focusTab(tabRepeater.count - 1)
        event.accepted = true
      } else if (event.key === Qt.Key_Right
                 || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
        root.focusCurrentTabContent()
        event.accepted = true
      } else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) {
        root.focusTab(root.focusedTab)
        event.accepted = true
      }
    }

    Rectangle {
      id: styleShadow
      x: Config.themeShadowOffset
      y: Config.themeShadowOffset
      width: bg.width
      height: bg.height
      radius: bg.radius
      color: Colors.styleShadow
      visible: Config.neoBrutalism
      z: -1
    }

    Rectangle {
      id: bg
      anchors {
        left: parent.left
        top: parent.top
        right: parent.right
        bottom: parent.bottom
        rightMargin: Config.neoBrutalism ? Config.themeShadowOffset : 0
        bottomMargin: Config.neoBrutalism ? Config.themeShadowOffset : 0
      }
      radius: Config.borderRadius
      color: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme
        ? Colors.styleSurface
        : Colors.surface
      clip: true
      border.width: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme ? Config.themeBorderWidth : 0
      border.color: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme
        ? Colors.styleOutline
        : Colors.outlineVariant

      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: bg.width / 2; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

      ParallelAnimation {
        id: entryAnimation
        NumberAnimation {
          target: scaleTransform
          properties: "xScale,yScale"
          from: 0.85
          to: 1.0
          duration: Config.motionLong
          easing.type: Config.themeMotionEasing
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
          to: 0
          duration: Config.motionLong
          easing.type: Config.themeMotionEasing
        }
        NumberAnimation {
          target: bg
          property: "opacity"
          from: 0.0
          to: 1.0
          duration: Config.motionMedium
          easing.type: Easing.OutCubic
        }
      }

      Item {
        id: windowHeader
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          leftMargin: root.contentMargin
          rightMargin: root.contentMargin
          topMargin: root.contentMargin
        }
        height: 44
        z: 2

        MouseArea {
          id: dragHandle
          anchors.fill: parent
          hoverEnabled: true
          enabled: root.visible && !entryAnimation.running
          cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

          property point pressPoint
          property real startLeft: 0
          property real startTop: 0

          onPressed: function(mouse) {
            pressPoint = mapToItem(null, mouse.x, mouse.y)
            if (!root.customPosition) {
              root.panelLeft = root.centeredLeftMargin
              root.panelTop = root.centeredTopMargin
              root.customPosition = true
            }
            startLeft = root.panelLeft
            startTop = root.panelTop
          }

          onPositionChanged: function(mouse) {
            if (!pressed) return
            var point = mapToItem(null, mouse.x, mouse.y)
            root.panelLeft = startLeft + point.x - pressPoint.x
            root.panelTop = startTop + point.y - pressPoint.y
            root.clampPanelPosition()
          }
        }

        Column {
          id: headerTitle
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Config.spacingCompact

          Text {
            id: titleText
            text: "Settings"
            color: Colors.fgSurface
            font.family: Config.displayFontFamily
            font.pixelSize: Config.typeHeadlineSmallSize
            font.weight: Config.themeFontWeight
            font.letterSpacing: Config.typeHeadlineTracking
            lineHeight: Config.typeHeadlineSmallLineHeight
            lineHeightMode: Text.FixedHeight
          }

          Text {
            text: Config.nothingEvolution ? "NOTHING OS EVOLUTION" : "SYSTEM CONTROL"
            color: Colors.fgSurfaceVariant
            font.family: Config.monoFontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.letterSpacing: Config.typeMonoTracking
            lineHeight: Config.typeLabelSmallLineHeight
            lineHeightMode: Text.FixedHeight
            visible: !root.compactLayout
          }
        }

        IconButton {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          size: 36
          iconLabel: "close"
          accessibleName: "Close settings"
          accessibleDescription: "Close the settings panel"
          tooltipText: "Close settings"
          onClicked: root.dismissed()
        }
      }

      RowLayout {
        id: contentColumn
        anchors {
          left: parent.left
          right: parent.right
          top: windowHeader.bottom
          bottom: parent.bottom
          leftMargin: root.contentMargin
          rightMargin: root.contentMargin
          topMargin: Config.spacingMedium
          bottomMargin: root.contentMargin
        }
        spacing: Config.spacingMedium

        // Sidebar navigation
        ColumnLayout {
          id: sidebar
          Layout.preferredWidth: root.sidebarWidth
          Layout.maximumWidth: root.sidebarWidth
          Layout.fillWidth: false
          Layout.fillHeight: true
          spacing: Config.spacingSmall

          TextFieldControl {
            id: searchField
            Layout.fillWidth: true
            leadingIcon: "search"
            leadingIconSize: 16
            placeholder: root.compactLayout ? "Search" : "Search settings"
            accessibleName: "Search settings"
            onEscapePressed: {
              if (root.searchQuery !== "") {
                input.text = ""
              } else {
                root.dismissed()
              }
            }
            onAccepted: {
              var results = root.searchResults
              if (results.length > 0) {
                root.selectTab(results[0].tab)
                input.text = ""
              }
            }
          }

          Connections {
            target: searchField.input
            function onTextChanged() {
              root.searchQuery = searchField.text
            }
          }

          Flickable {
            id: sidebarScroll
            visible: root.searchQuery.trim() === ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: sidebarColumn.implicitHeight
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            clip: true
            ScrollBar.vertical: SettingsScrollBar { scrollTarget: sidebarScroll }

            ColumnLayout {
              id: sidebarColumn
              width: sidebarScroll.width
              spacing: root.sidebarRowSpacing

              Repeater {
                id: tabRepeater
                model: root.tabDefinitions

                delegate: ColumnLayout {
                  id: tabEntry
                  required property var modelData
                  required property int index
                  property var navigationItem: navigationRow
                  readonly property bool firstInGroup: index === 0
                    || root.tabDefinitions[index - 1].group !== modelData.group

                  Layout.fillWidth: true
                  spacing: Config.spacingCompact

                  Text {
                    visible: tabEntry.firstInGroup
                    Layout.fillWidth: true
                    Layout.topMargin: index === 0 ? 0 : Config.spacingSmall
                    text: modelData.group.toUpperCase()
                    color: Colors.fgSurfaceVariant
                    font.family: Config.monoFontFamily
                    font.pixelSize: Config.typeLabelSmallSize
                    font.weight: Config.typeMediumWeight
                    font.letterSpacing: Config.typeMonoTracking
                    lineHeight: Config.typeLabelSmallLineHeight
                    lineHeightMode: Text.FixedHeight
                  }

                  ListItem {
                    id: navigationRow
                    Layout.fillWidth: true
                    activeFocusOnTab: true
                    focus: false
                    navigationFocused: root.focusedTab === index
                    navigationItem: true
                    leadingIcon: modelData.icon
                    title: modelData.label
                    selected: root.currentTab === index
                    accessibleName: modelData.label
                    accessibleDescription: root.currentTab === index
                      ? "Selected Settings page"
                      : "Open Settings page"
                    Accessible.role: Accessible.PageTab
                    Accessible.selected: root.currentTab === index
                    Accessible.selectable: true
                    Accessible.focusable: true

                    Keys.priority: Keys.BeforeItem

                    Keys.onReturnPressed: function(event) {
                      root.selectTab(index)
                      event.accepted = true
                    }

                    Keys.onEnterPressed: function(event) {
                      root.selectTab(index)
                      event.accepted = true
                    }

                    Keys.onSpacePressed: function(event) {
                      root.selectTab(index)
                      event.accepted = true
                    }

                    Keys.onPressed: function(event) {
                      if (event.key === Qt.Key_Up) {
                        root.focusTab((index + tabRepeater.count - 1) % tabRepeater.count)
                        event.accepted = true
                      } else if (event.key === Qt.Key_Down) {
                        root.focusTab((index + 1) % tabRepeater.count)
                        event.accepted = true
                      } else if (event.key === Qt.Key_Home) {
                        root.focusTab(0)
                        event.accepted = true
                      } else if (event.key === Qt.Key_End) {
                        root.focusTab(tabRepeater.count - 1)
                        event.accepted = true
                      } else if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) {
                        root.focusCurrentTabContent()
                        event.accepted = true
                      }
                    }

                    onClicked: root.selectTab(index)
                  }
                }
              }
            }
          }

          Flickable {
            id: searchResultsScroll
            visible: root.searchQuery.trim() !== ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: searchResultsColumn.implicitHeight
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            clip: true
            ScrollBar.vertical: SettingsScrollBar { scrollTarget: searchResultsScroll }

            ColumnLayout {
              id: searchResultsColumn
              width: searchResultsScroll.width
              spacing: root.sidebarRowSpacing

              Repeater {
                model: root.searchResults

                delegate: ColumnLayout {
                  id: searchEntry
                  required property var modelData
                  required property int index
                  readonly property bool firstInContext: index === 0
                    || root.searchResults[index - 1].tab !== modelData.tab
                    || root.searchResults[index - 1].category !== modelData.category

                  Layout.fillWidth: true
                  spacing: Config.spacingCompact

                  Text {
                    visible: searchEntry.firstInContext
                    Layout.fillWidth: true
                    Layout.topMargin: index === 0 ? 0 : Config.spacingSmall
                    text: root.entryContext(searchEntry.modelData)
                    color: Colors.fgSurfaceVariant
                    font.family: Config.monoFontFamily
                    font.pixelSize: Config.typeLabelSmallSize
                    font.weight: Config.typeMediumWeight
                    font.letterSpacing: Config.typeMonoTracking
                    lineHeight: Config.typeLabelSmallLineHeight
                    lineHeightMode: Text.FixedHeight
                  }

                  ListItem {
                    Layout.fillWidth: true
                    activeFocusOnTab: true
                    leadingIcon: searchEntry.modelData.icon
                    title: searchEntry.modelData.title
                    subtitle: searchEntry.modelData.subtitle
                    accessibleName: searchEntry.modelData.title
                    accessibleDescription: "Jump to " + root.entryContext(searchEntry.modelData)
                      + ". " + searchEntry.modelData.subtitle

                    Keys.onReturnPressed: function(event) {
                      root.selectTab(searchEntry.modelData.tab)
                      searchField.text = ""
                      event.accepted = true
                    }
                    Keys.onSpacePressed: function(event) {
                      root.selectTab(searchEntry.modelData.tab)
                      searchField.text = ""
                      event.accepted = true
                    }

                    onClicked: {
                      root.selectTab(searchEntry.modelData.tab)
                      searchField.text = ""
                    }
                  }
                }
              }

              Text {
                visible: root.searchResults.length === 0
                Layout.fillWidth: true
                Layout.topMargin: Config.spacingSmall
                text: "No settings found"
                color: Colors.fgSurfaceVariant
                font.family: Config.fontFamily
                font.pixelSize: Config.typeBodyMediumSize
                font.letterSpacing: Config.typeBodyTracking
                lineHeight: Config.typeBodyMediumLineHeight
                lineHeightMode: Text.FixedHeight
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
              }
            }
          }
        }

        Rectangle {
          id: sidebarDivider
          Layout.preferredWidth: 1
          Layout.fillHeight: true
          color: Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.12)
        }

        // Tab Content Area Container
        Item {
          id: tabContainer
          property QtObject panelRoot: root
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          Loader {
            id: tabLoader
            anchors.fill: parent
            active: root.visible
            sourceComponent: {
              switch (root.currentTab) {
                case 0: return accountTabComponent
                case 1: return generalTabComponent
                case 2: return appearanceTabComponent
                case 3: return wallpaperTabComponent
                case 4: return displayInputTabComponent
                case 5: return networkTabComponent
                case 6: return bluetoothTabComponent
                case 7: return mediaTabComponent
                case 8: return lockMediaTabComponent
                case 9: return notificationsTabComponent
                case 10: return systemTabComponent
                case 11: return shortcutsTabComponent
                default: return generalTabComponent
              }
            }
          }

          Component {
            id: accountTabComponent
            AccountTab { root: tabContainer.panelRoot }
          }

          Component {
            id: generalTabComponent
            GeneralTab { root: tabContainer.panelRoot }
          }

          Component {
            id: appearanceTabComponent
            AppearanceTab { root: tabContainer.panelRoot }
          }

          Component {
            id: wallpaperTabComponent
            WallpaperTab { root: tabContainer.panelRoot }
          }

          Component {
            id: displayInputTabComponent
            DisplayInputTab { root: tabContainer.panelRoot }
          }

          Component {
            id: networkTabComponent
            NetworkTab { root: tabContainer.panelRoot }
          }

          Component {
            id: bluetoothTabComponent
            BluetoothTab { root: tabContainer.panelRoot }
          }

          Component {
            id: mediaTabComponent
            MediaTab { root: tabContainer.panelRoot }
          }

          Component {
            id: lockMediaTabComponent
            LockMediaTab { root: tabContainer.panelRoot }
          }

          Component {
            id: notificationsTabComponent
            NotificationsTab {
              root: tabContainer.panelRoot
              notificationPopup: tabContainer.panelRoot.notificationPopup
            }
          }

          Component {
            id: shortcutsTabComponent
            ShortcutsTab { root: tabContainer.panelRoot }
          }

          Component {
            id: systemTabComponent
            SystemTab { root: tabContainer.panelRoot }
          }
      }
    }

    // Resize handle, bottom-right corner of the visible surface. A direct
    // child of bg (not nested inside contentColumn) so anchoring to bg.right/
    // bg.bottom is valid, and it lines up with bg's real edge even when
    // neo-brutalism's shadow offset shrinks bg relative to the window bounds.
    MouseArea {
      id: resizeHandle
      width: 18
      height: 18
      anchors.right: bg.right
      anchors.bottom: bg.bottom
      z: 1000
      cursorShape: Qt.SizeFDiagCursor
      hoverEnabled: true
      enabled: !entryAnimation.running

      property point pressLocal
      property real startWidth: 0
      property real startHeight: 0
      property bool didResize: false

      onPressed: function(mouse) {
        pressLocal = mapToItem(null, mouse.x, mouse.y)
        startWidth = root.implicitWidth - (Config.neoBrutalism ? Config.themeShadowOffset : 0)
        startHeight = root.implicitHeight - (Config.neoBrutalism ? Config.themeShadowOffset : 0)
        didResize = false
      }

      onPositionChanged: function(mouse) {
        if (!pressed) return
        var p = mapToItem(null, mouse.x, mouse.y)
        var deltaX = p.x - pressLocal.x
        var deltaY = p.y - pressLocal.y
        var maxW = Math.min(Config.settingsMaxWidth, root.desktopW - Config.spacingPage)
        var maxH = Math.min(Config.settingsMaxHeight, root.desktopH - Config.spacingPage)
        Settings.settingsPanelWidth = Math.round(Math.max(Config.settingsMinWidth, Math.min(maxW, startWidth + deltaX)))
        Settings.settingsPanelHeight = Math.round(Math.max(Config.settingsMinHeight, Math.min(maxH, startHeight + deltaY)))
        didResize = true
      }

      onReleased: {
        if (didResize) Settings.save()
      }

      Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 3
        anchors.bottomMargin: 3
        width: 8
        height: 2
        rotation: -45
        color: Colors.fgSurfaceVariant
        opacity: 0.4
      }
      Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 7
        anchors.bottomMargin: 7
        width: 8
        height: 2
        rotation: -45
        color: Colors.fgSurfaceVariant
        opacity: 0.4
      }
    }
  }

}
}
