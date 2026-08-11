import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import "commandcenter"
import "primitives"
import "../config"

PanelWindow {
  id: root

  signal dismissed()
  signal lockRequested()
  property QtObject notificationPopup: null

  property bool isHorizontal: false
  signal toggleHorizontal()
  property bool fullBar: false
  signal toggleFullBar()

  property int currentTab: Math.max(0, Math.min(10, Settings.lastSettingsTab))
  property double openTime: 0
  readonly property bool compactLayout: root.implicitWidth <= 480
  readonly property int sidebarWidth: root.implicitWidth <= 480 ? 96 : 132
  readonly property int sidebarRowHeight: 44
  readonly property int sidebarRowSpacing: 2

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
    running: root.visible && root.currentTab === 9
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statsProc.running = false;
      statsProc.running = true;
    }
  }

  implicitWidth: Math.min(Config.commandCenterMaxWidth,
                          Math.max(Config.commandCenterMinWidth, desktopW - 32))
  visible: false
  implicitHeight: Math.min(Config.commandCenterMaxHeight,
                           Math.max(Config.commandCenterMinHeight, desktopH - 32))
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  // Center window on desktop
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

  function selectTab(index) {
    root.currentTab = Math.max(0, Math.min(tabRepeater.count - 1, index))
    var delegate = tabRepeater.itemAt(root.currentTab)
    if (delegate) delegate.forceActiveFocus()
    root.ensureCurrentTabVisible()
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

  onHeightChanged: ensureTabVisibilityTimer.start()
  onWidthChanged: ensureTabVisibilityTimer.start()

  onVisibleChanged: {
    if (visible) {
      idleCheck.running = true
      entryAnimation.start()
      // Focus the current tab delegate (not mainItem) so arrow-key tab
      // navigation works immediately on open, without requiring a mouse
      // click first. mainItem isn't a FocusScope, so focus: true on the
      // delegate alone never receives active focus otherwise.
      if (tabRepeater.count > 0) {
        tabRepeater.itemAt(root.currentTab).forceActiveFocus()
      } else {
        mainItem.forceActiveFocus()
      }
      root.ensureCurrentTabVisible()
      root.openTime = Date.now()

      // Refresh dynamic content
      if (Settings.systemShowUptime) {
        uptimeProc.running = false
        uptimeProc.running = true
      }
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

  Item {
    id: mainItem
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) {
        if (Date.now() - root.openTime > 150) {
          root.dismissed()
        }
        event.accepted = true
      }
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: Config.borderRadius
      color: Colors.surfaceContainerHigh
      clip: true
      border.width: 1
      border.color: Colors.outlineVariant

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
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
          to: 0
          duration: Config.motionLong
          easing.type: Easing.OutBack
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
          spacing: 0

          Flickable {
            id: sidebarScroll
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
                  focus: root.currentTab === index
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

                  Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                      root.selectTab(index)
                      event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                      root.selectTab((index + tabRepeater.count - 1) % tabRepeater.count)
                      event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                      root.selectTab((index + 1) % tabRepeater.count)
                      event.accepted = true
                    } else if (event.key === Qt.Key_Home) {
                      root.selectTab(0)
                      event.accepted = true
                    } else if (event.key === Qt.Key_End) {
                      root.selectTab(tabRepeater.count - 1)
                      event.accepted = true
                    }
                  }

                  onClicked: root.selectTab(index)
                }
              }
            }
          }
        }

        Rectangle {
          id: sidebarDivider
          Layout.preferredWidth: 1
          Layout.fillHeight: true
          color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.12)
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
      }
    }
  }

}
}
