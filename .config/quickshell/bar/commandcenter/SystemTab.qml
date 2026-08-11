import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../../config"

Flickable {
  id: systemTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 8
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  property real statsSwapPct: 0
  property string statsSwapStr: "None"
  property real statsCpuTemp: 0
  property real statsFanRpm: 0
  property real statsBattPct: 0
  property string statsBattStatus: ""
  property real statsLoad1: 0
  property real statsLoad5: 0
  property real statsLoad15: 0
  readonly property int cpuCount: 8

  Process {
    id: extraStatsProc
    command: ["sh", "-c",
      "swap=$(free -m | awk '/Swap:/ { if ($2>0) printf \"%d,%d,%d\", $2-$4, $2, ($2-$4)*100/$2; else printf \"0,0,0\" }'); " +
      "sj=$(sensors -j 2>/dev/null); " +
      "cputemp=$(echo \"$sj\" | jq -r '[.[] | to_entries[] | select(.key | test(\"Package id 0|Tctl|Tdie\")) | .value.temp1_input][0] // empty'); " +
      "fanrpm=$(echo \"$sj\" | jq -r '[.[] | .fan1.fan1_input? // empty][0] // empty'); " +
      "battpct=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null); " +
      "battstatus=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null); " +
      "load=$(cut -d' ' -f1-3 /proc/loadavg | tr ' ' ','); " +
      "echo \"$swap|$cputemp|$fanrpm|$battpct,$battstatus|$load\""]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parts = text.trim().split("|");
          var swapParts = parts[0].split(",");
          var swapUsed = parseInt(swapParts[0]);
          var swapTotal = parseInt(swapParts[1]);
          systemTab.statsSwapPct = swapTotal > 0 ? parseFloat(swapParts[2]) / 100.0 : 0;
          systemTab.statsSwapStr = swapTotal > 0 ? (swapUsed + " / " + swapTotal + " MB") : "None";

          systemTab.statsCpuTemp = parseFloat(parts[1]) || 0;
          systemTab.statsFanRpm = parseFloat(parts[2]) || 0;

          var battParts = parts[3].split(",");
          systemTab.statsBattPct = parseFloat(battParts[0]) || 0;
          systemTab.statsBattStatus = battParts[1] || "";

          var loadParts = parts[4].split(",");
          systemTab.statsLoad1 = parseFloat(loadParts[0]) || 0;
          systemTab.statsLoad5 = parseFloat(loadParts[1]) || 0;
          systemTab.statsLoad15 = parseFloat(loadParts[2]) || 0;
        } catch(e) {}
      }
    }
  }

  Timer {
    id: extraStatsTimer
    interval: 3000
    running: systemTab.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      extraStatsProc.running = false;
      extraStatsProc.running = true;
    }
  }

  component StatCell: ColumnLayout {
    id: statCell
    property string icon: ""
    property string label: ""
    property string value: ""
    property real pct: 0
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    spacing: 4

    RowLayout {
      spacing: 6
      Text {
        text: statCell.icon
        font.family: Config.iconFont
        font.pixelSize: 16
        color: Colors.primary
      }
      Text {
        text: statCell.label
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
      }
    }

    Rectangle {
      Layout.fillWidth: true
      height: 8
      radius: 4
      color: Colors.surfaceContainerHigh
      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, statCell.pct))
        height: parent.height
        radius: 4
        color: Colors.primary
      }
    }

    Text {
      text: statCell.value
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: 11
      font.weight: Font.Bold
    }
  }

  ColumnLayout {
    id: mainColumn
    width: systemTab.width
    spacing: 16

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: statsGrid.implicitHeight + 16
      radius: Config.shapeLarge
      color: Colors.surfaceContainer
      border.color: Colors.outlineVariant
      border.width: 1

      GridLayout {
        id: statsGrid
        anchors.fill: parent
        anchors.margins: 12
        columns: 3
        columnSpacing: 20
        rowSpacing: 16

        StatCell {
          icon: "memory"
          label: "CPU Usage"
          value: Math.round(root.statsCpu) + "%"
          pct: root.statsCpu / 100.0
        }

        StatCell {
          icon: "database"
          label: "Memory (RAM)"
          value: root.statsRamStr + " (" + Math.round(root.statsRamPct * 100) + "%)"
          pct: root.statsRamPct
        }

        StatCell {
          icon: "storage"
          label: "Disk Storage"
          value: root.statsDiskStr + " (" + Math.round(root.statsDiskPct * 100) + "%)"
          pct: root.statsDiskPct
        }

        StatCell {
          icon: "sync_alt"
          label: "Swap"
          value: systemTab.statsSwapStr
          pct: systemTab.statsSwapPct
        }

        StatCell {
          icon: "device_thermostat"
          label: "CPU Temp"
          value: systemTab.statsCpuTemp > 0 ? Math.round(systemTab.statsCpuTemp) + "°C" : "—"
          pct: systemTab.statsCpuTemp / 100.0
        }

        StatCell {
          icon: "air"
          label: "Fan Speed"
          value: systemTab.statsFanRpm > 0 ? Math.round(systemTab.statsFanRpm) + " RPM" : "Off"
          pct: systemTab.statsFanRpm / 5000.0
        }

        StatCell {
          icon: "battery_full"
          label: "Battery"
          value: Math.round(systemTab.statsBattPct) + "% " + systemTab.statsBattStatus
          pct: systemTab.statsBattPct / 100.0
        }

        StatCell {
          icon: "speed"
          label: "Load Average"
          value: systemTab.statsLoad1.toFixed(2) + " / " + systemTab.statsLoad5.toFixed(2) + " / " + systemTab.statsLoad15.toFixed(2)
          pct: systemTab.statsLoad1 / systemTab.cpuCount
        }

        Item { Layout.fillWidth: true; Layout.preferredWidth: 1 }
      }
    }

    Text {
      Layout.fillWidth: true
      Layout.leftMargin: 4
      text: "Load average is 1 / 5 / 15 minute, normalized against " + systemTab.cpuCount + " CPU threads."
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: 11
      wrapMode: Text.WordWrap
    }
  }
}
