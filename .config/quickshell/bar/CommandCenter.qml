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

  property bool isHorizontal: false
  signal toggleHorizontal()
  property bool fullBar: false
  signal toggleFullBar()

  property int currentTab: 0 // Default to Account tab
  property double openTime: 0

  // Account tab: session info
  property string uptimeText: "up ..."

  property bool caffeineOn: false

  // System Diagnostics Stats (System tab)
  property real statsCpu: 0
  property string statsRamStr: "0.0 / 0.0 GB"
  property real statsRamPct: 0.0
  property string statsDiskStr: "0.0 / 0.0 GB"
  property real statsDiskPct: 0.0

  Process {
    id: statsProc
    command: ["sh", "-c", "cpu=$(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}'); mem=$(free -m | awk '/Mem:/ { printf \"%d,%d,%d\", $3, $2, $3*100/$2 }'); disk=$(df -h / | awk '/\\// {printf \"%s,%s,%s\", $3, $2, $5}' | head -n 1); echo \"$cpu|$mem|$disk\""]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parts = text.trim().split("|");
          if (parts.length >= 3) {
            root.statsCpu = parseFloat(parts[0]);

            var memParts = parts[1].split(",");
            var memUsedGb = (parseFloat(memParts[0]) / 1024.0).toFixed(1);
            var memTotalGb = (parseFloat(memParts[1]) / 1024.0).toFixed(1);
            root.statsRamStr = memUsedGb + " / " + memTotalGb + " GB";
            root.statsRamPct = parseFloat(memParts[2]) / 100.0;

            var diskParts = parts[2].split(",");
            var diskUsed = diskParts[0];
            var diskTotal = diskParts[1];
            var diskPctVal = parseFloat(diskParts[2].replace("%", ""));
            root.statsDiskStr = diskUsed + " / " + diskTotal;
            root.statsDiskPct = diskPctVal / 100.0;
          }
        } catch(e) {}
      }
    }
  }

  Timer {
    id: statsTimer
    interval: 3000
    running: root.visible && root.currentTab === 8
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
          Layout.preferredWidth: 132
          Layout.maximumWidth: 132
          Layout.fillWidth: false
          Layout.fillHeight: true
          spacing: 2

          Repeater {
            id: tabRepeater
            model: [
              { icon: "person", label: "Account" },
              { icon: "palette", label: "Appearance" },
              { icon: "tune", label: "General" },
              { icon: "lock", label: "Lock & Media" },
              { icon: "wifi", label: "Network" },
              { icon: "bluetooth", label: "Bluetooth" },
              { icon: "notifications", label: "Notifications" },
              { icon: "keyboard", label: "Shortcuts" },
              { icon: "monitor_heart", label: "System" }
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
              accessibleName: modelData.label + " tab"

              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  root.currentTab = index
                  event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                  root.currentTab = (index + tabRepeater.count - 1) % tabRepeater.count
                  event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                  root.currentTab = (index + 1) % tabRepeater.count
                  event.accepted = true
                } else if (event.key === Qt.Key_Home) {
                  root.currentTab = 0
                  event.accepted = true
                } else if (event.key === Qt.Key_End) {
                  root.currentTab = tabRepeater.count - 1
                  event.accepted = true
                }
              }

              onClicked: {
                forceActiveFocus()
                root.currentTab = index
              }
            }
          }

          Item { Layout.fillHeight: true }
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

          GeneralTab {
            root: root
          }

          LockMediaTab {
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
