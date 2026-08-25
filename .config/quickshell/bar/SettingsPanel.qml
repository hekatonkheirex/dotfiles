import QtQuick
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

  property int currentTab: Math.max(0, Math.min(11, Settings.lastSettingsTab))
  property int focusedTab: currentTab
  property double openTime: 0
  readonly property bool compactLayout: root.implicitWidth <= 480
  readonly property int sidebarWidth: root.implicitWidth <= 480 ? 108 : 168
  readonly property int sidebarRowHeight: 44
  readonly property int sidebarRowSpacing: 2

  property string searchQuery: ""

  // Static settings index for the search box. Section-level entries for tabs
  // built from custom controls (sliders, segmented pickers) that don't wrap
  // each setting in a ListItem; per-setting entries where they do.
  readonly property var searchEntries: [
    { tab: 0, icon: "person", title: "Machine info", subtitle: "Hostname, OS, kernel, CPU, GPU" },
    { tab: 0, icon: "wifi", title: "Network status", subtitle: "Account" },
    { tab: 1, icon: "motion_photos_off", title: "Reduced motion", subtitle: "General" },
    { tab: 1, icon: "schedule", title: "Show uptime", subtitle: "General" },
    { tab: 1, icon: "schedule", title: "24-hour clock", subtitle: "General" },
    { tab: 1, icon: "timer", title: "Show seconds", subtitle: "General" },
    { tab: 1, icon: "calendar_view_week", title: "Week starts Monday", subtitle: "General" },
    { tab: 1, icon: "apps", title: "Bar item visibility", subtitle: "Launcher, workspaces, clock, tray, audio, weather..." },
    { tab: 1, icon: "my_location", title: "Use IP geolocation", subtitle: "General · Weather" },
    { tab: 2, icon: "auto_awesome", title: "UI Style", subtitle: "Appearance · Material, Neo, Nothing, Ghost, Evolution" },
    { tab: 2, icon: "dark_mode", title: "Color Scheme", subtitle: "Appearance · Auto, Light, Dark" },
    { tab: 2, icon: "palette", title: "Color palette", subtitle: "Appearance · Matugen wallpaper colors" },
    { tab: 2, icon: "dock_to_bottom", title: "Bar Placement", subtitle: "Appearance · Top, bottom, left, right" },
    { tab: 2, icon: "format_size", title: "UI Font Size", subtitle: "Appearance · Sizing" },
    { tab: 2, icon: "schedule", title: "Clock Size", subtitle: "Appearance · Sizing" },
    { tab: 2, icon: "photo_size_select_small", title: "Icon Size", subtitle: "Appearance · Sizing" },
    { tab: 2, icon: "space_bar", title: "Spacing", subtitle: "Appearance · Sizing" },
    { tab: 2, icon: "height", title: "Bar Size", subtitle: "Appearance · Sizing" },
    { tab: 3, icon: "wallpaper", title: "Wallpaper", subtitle: "Wallpaper · Browse and set" },
    { tab: 5, icon: "wifi", title: "Wi-Fi", subtitle: "Network · Connect, forget, password" },
    { tab: 6, icon: "bluetooth", title: "Bluetooth", subtitle: "Bluetooth · Pair and connect devices" },
    { tab: 7, icon: "image", title: "Show album art", subtitle: "Media" },
    { tab: 7, icon: "linear_scale", title: "Show progress bar", subtitle: "Media" },
    { tab: 7, icon: "touch_app", title: "Controls always visible", subtitle: "Media" },
    { tab: 8, icon: "music_note", title: "Show now playing", subtitle: "Lock & Power" },
    { tab: 8, icon: "wallpaper", title: "Use current wallpaper", subtitle: "Lock & Power · Lock screen" },
    { tab: 8, icon: "schedule", title: "Clock face", subtitle: "Lock & Power · Lock screen" },
    { tab: 8, icon: "lock", title: "Lock after inactivity", subtitle: "Lock & Power" },
    { tab: 8, icon: "bedtime", title: "Suspend after inactivity", subtitle: "Lock & Power" },
    { tab: 8, icon: "bolt", title: "Power Profiles", subtitle: "Lock & Power" },
    { tab: 9, icon: "do_not_disturb_on", title: "Do Not Disturb", subtitle: "Notifications" },
    { tab: 9, icon: "bedtime", title: "Quiet hours", subtitle: "Notifications" },
    { tab: 9, icon: "priority_high", title: "Critical notifications bypass quiet hours", subtitle: "Notifications" },
    { tab: 10, icon: "monitor_heart", title: "CPU Usage", subtitle: "System · Diagnostics" },
    { tab: 10, icon: "memory", title: "Memory (RAM)", subtitle: "System · Diagnostics" },
    { tab: 10, icon: "storage", title: "Disk Storage", subtitle: "System · Diagnostics" },
    { tab: 10, icon: "swap_horiz", title: "Swap", subtitle: "System · Diagnostics" },
    { tab: 10, icon: "thermostat", title: "CPU Temp", subtitle: "System · Diagnostics" },
    { tab: 10, icon: "mode_fan", title: "Fan Speed", subtitle: "System · Diagnostics" },
    { tab: 10, icon: "battery_full", title: "Battery", subtitle: "System · Diagnostics" },
    { tab: 10, icon: "battery_alert", title: "Battery Health", subtitle: "System · Diagnostics" },
    { tab: 10, icon: "battery_charging_full", title: "Battery Cycles", subtitle: "System · Diagnostics" },
    { tab: 10, icon: "trending_up", title: "Load Average", subtitle: "System · Diagnostics" },
    { tab: 11, icon: "apps", title: "App shortcuts", subtitle: "Shortcuts" },
    { tab: 11, icon: "window", title: "Window shortcuts", subtitle: "Shortcuts" },
    { tab: 11, icon: "workspaces", title: "Workspace shortcuts", subtitle: "Shortcuts" },
    { tab: 11, icon: "keyboard", title: "System shortcuts", subtitle: "Shortcuts" },
    { tab: 4, icon: "monitor", title: "Display scale", subtitle: "Display & Input · Outputs" },
    { tab: 4, icon: "screen_rotation", title: "Display transform", subtitle: "Display & Input · Outputs" },
    { tab: 4, icon: "touch_app", title: "Tap to click", subtitle: "Display & Input · Touchpad" },
    { tab: 4, icon: "swap_vert", title: "Natural scroll", subtitle: "Display & Input · Touchpad, mouse, trackpoint" },
    { tab: 4, icon: "mouse", title: "Pointer accel speed", subtitle: "Display & Input · Mouse, trackpoint" }
  ]

  readonly property var searchResults: {
    var q = root.searchQuery.trim().toLowerCase()
    if (q === "") return []
    return root.searchEntries.filter(function(entry) {
      return entry.title.toLowerCase().indexOf(q) !== -1
          || entry.subtitle.toLowerCase().indexOf(q) !== -1
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
  implicitWidth: Math.min(Math.min(Config.settingsMaxWidth, desktopW - 32),
                          Math.max(Config.settingsMinWidth, Settings.settingsPanelWidth > 0 ? Settings.settingsPanelWidth : Config.settingsDefaultWidth))
                 + (Config.neoBrutalism ? Config.themeShadowOffset : 0)
  visible: false
  implicitHeight: Math.min(Math.min(Config.settingsMaxHeight, desktopH - 32),
                           Math.max(Config.settingsMinHeight, Settings.settingsPanelHeight > 0 ? Settings.settingsPanelHeight : Config.settingsDefaultHeight))
                  + (Config.neoBrutalism ? Config.themeShadowOffset : 0)
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  // Center window on desktop. This is intentional: as the panel is resized via the
  // drag handle, implicitWidth/implicitHeight change and these margins recompute,
  // so the panel grows while staying centered rather than growing from a fixed corner.
  property int desktopW: Screen.desktopAvailableWidth
  property int desktopH: Screen.desktopAvailableHeight

  anchors.left: true
  margins.left: (desktopW - implicitWidth) / 2
  anchors.top: true
  margins.top: (desktopH - implicitHeight) / 2

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

    var rowTop = root.currentTab * (root.sidebarRowHeight + root.sidebarRowSpacing)
    var rowBottom = rowTop + root.sidebarRowHeight
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
      entryAnimation.start()
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
        : Colors.surfaceContainerHigh
      clip: true
      border.width: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme ? Config.themeBorderWidth : 0
      border.color: Colors.styleOutline

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

      RowLayout {
        id: contentColumn
        anchors {
          fill: parent
          margins: (root.implicitHeight < 540 ? Config.spacingMedium : Config.spacingExtraLarge)
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

            ColumnLayout {
              id: sidebarColumn
              width: sidebarScroll.width
              spacing: root.sidebarRowSpacing

              Repeater {
                id: tabRepeater
                model: [
                  { icon: "person", label: "Account" },
                  { icon: "tune", label: "General" },
                  { icon: "palette", label: "Appearance" },
                  { icon: "wallpaper", label: "Wallpaper" },
                  { icon: "monitor", label: "Display & Input" },
                  { icon: "wifi", label: "Network" },
                  { icon: "bluetooth", label: "Bluetooth" },
                  { icon: "play_circle", label: "Media" },
                  { icon: "lock", label: "Lock & Power" },
                  { icon: "notifications", label: "Notifications" },
                  { icon: "monitor_heart", label: "System" },
                  { icon: "keyboard", label: "Shortcuts" }
                ]

                delegate: ListItem {
                  required property var modelData
                  required property int index

                  Layout.fillWidth: true
                  activeFocusOnTab: true
                  focus: false
                  navigationFocused: root.focusedTab === index
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

            ColumnLayout {
              id: searchResultsColumn
              width: searchResultsScroll.width
              spacing: root.sidebarRowSpacing

              Repeater {
                model: root.searchResults

                delegate: ListItem {
                  required property var modelData

                  Layout.fillWidth: true
                  activeFocusOnTab: true
                  leadingIcon: modelData.icon
                  title: modelData.title
                  subtitle: modelData.subtitle
                  accessibleName: modelData.title
                  accessibleDescription: "Jump to " + modelData.subtitle

                  Keys.onReturnPressed: function(event) {
                    root.selectTab(modelData.tab)
                    searchField.text = ""
                    event.accepted = true
                  }
                  Keys.onSpacePressed: function(event) {
                    root.selectTab(modelData.tab)
                    searchField.text = ""
                    event.accepted = true
                  }

                  onClicked: {
                    root.selectTab(modelData.tab)
                    searchField.text = ""
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
                font.pixelSize: Config.fontPixelSize
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
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          AccountTab {
            root: root
          }

          AppearanceTab {
            root: root
          }

          WallpaperTab {
            root: root
          }

          GeneralTab {
            root: root
          }

          LockMediaTab {
            root: root
          }

          MediaTab {
            root: root
          }

          NetworkTab {
            root: root
          }

          BluetoothTab {
            root: root
          }

          NotificationsTab {
            root: root
            notificationPopup: root.notificationPopup
          }

          ShortcutsTab {
            root: root
          }

          SystemTab {
            root: root
          }

          DisplayInputTab {
            root: root
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
        pressLocal = mapToItem(mainItem, mouse.x, mouse.y)
        startWidth = root.implicitWidth - (Config.neoBrutalism ? Config.themeShadowOffset : 0)
        startHeight = root.implicitHeight - (Config.neoBrutalism ? Config.themeShadowOffset : 0)
        didResize = false
      }

      onPositionChanged: function(mouse) {
        if (!pressed) return
        var p = mapToItem(mainItem, mouse.x, mouse.y)
        var deltaX = p.x - pressLocal.x
        var deltaY = p.y - pressLocal.y
        var maxW = Math.min(Config.settingsMaxWidth, root.desktopW - 32)
        var maxH = Math.min(Config.settingsMaxHeight, root.desktopH - 32)
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
