import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: systemTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  anchors.fill: parent
  visible: root.currentTab === 9
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  property real statsSwapPct: -1
  property string statsSwapStr: "Unavailable"
  property real statsCpuTemp: -1
  property real statsFanRpm: -1
  property real statsLoad1: -1
  property real statsLoad5: -1
  property real statsLoad15: -1
  property string batteryCycles: "Unavailable"
  property string batteryHealth: "Unavailable"
  property real batteryHealthPct: -1
  property bool resetConfirm: false
  property string actionStatus: ""
  readonly property int cpuCount: root.statsCpuCount > 0 ? root.statsCpuCount : 1

  property var batteryDevice: {
    for (var i = 0; i < UPower.devices.count; i++) {
      var device = UPower.devices.get(i)
      if (device.ready && device.isLaptopBattery) return device
    }
    if (UPower.displayDevice && UPower.displayDevice.ready) return UPower.displayDevice
    return null
  }
  readonly property real statsBattPct: batteryDevice ? batteryDevice.percentage * 100 : -1
  readonly property string statsBattStatus: {
    if (!batteryDevice) return "Unavailable"
    if (batteryDevice.state === UPowerDeviceState.Charging || batteryDevice.state === UPowerDeviceState.PendingCharge) return "Charging"
    if (batteryDevice.state === UPowerDeviceState.FullyCharged) return "Fully charged"
    if (batteryDevice.state === UPowerDeviceState.Discharging || batteryDevice.state === UPowerDeviceState.PendingDischarge) return "Discharging"
    return "Unknown"
  }

  function resetOptionalStats() {
    systemTab.statsSwapPct = -1
    systemTab.statsSwapStr = "Unavailable"
    systemTab.statsCpuTemp = -1
    systemTab.statsFanRpm = -1
    systemTab.statsLoad1 = -1
    systemTab.statsLoad5 = -1
    systemTab.statsLoad15 = -1
  }

  function parseOptionalNumber(value) {
    var raw = value === undefined || value === null ? "" : String(value).trim()
    if (raw === "") return -1
    var parsed = parseFloat(raw)
    return isFinite(parsed) ? parsed : -1
  }

  function resetBatteryInfo() {
    systemTab.batteryCycles = "Unavailable"
    systemTab.batteryHealth = "Unavailable"
    systemTab.batteryHealthPct = -1
  }

  Process {
    id: extraStatsProc
    command: ["sh", "-c",
      "swap=$(free -m 2>/dev/null | awk '/^Swap:/ { if ($2 > 0) printf \"%d,%d,%.2f\", $3, $2, ($3*100/$2); else printf \"0,0,0\"; found=1 } END { if (!found) print \"-1,-1,-1\" }'); " +
      "sj=$(sensors -j 2>/dev/null || true); " +
      "if command -v sensors >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && [ -n \"$sj\" ]; then " +
      "cputemp=$(printf '%s' \"$sj\" | jq -r '[.[] | to_entries[] | select(.key | test(\"Package id 0|Tctl|Tdie\")) | .value.temp1_input][0] // empty' 2>/dev/null); " +
      "fanrpm=$(printf '%s' \"$sj\" | jq -r '[.[] | .fan1.fan1_input? // empty][0] // empty' 2>/dev/null); " +
      "else cputemp=; fanrpm=; fi; " +
      "load=$(awk '{ print $1 \",\" $2 \",\" $3 }' /proc/loadavg 2>/dev/null); " +
      "printf '%s|%s|%s|%s\\n' \"$swap\" \"$cputemp\" \"$fanrpm\" \"$load\""]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        systemTab.resetOptionalStats()

        var parts = text.trim().split("|")
        if (parts.length < 4) return

        var swapParts = parts[0].split(",")
        var swapUsed = systemTab.parseOptionalNumber(swapParts[0])
        var swapTotal = systemTab.parseOptionalNumber(swapParts[1])
        var swapPct = systemTab.parseOptionalNumber(swapParts[2])
        if (swapTotal === 0) {
          systemTab.statsSwapPct = 0
          systemTab.statsSwapStr = "None"
        } else if (swapUsed >= 0 && swapTotal > 0 && swapPct >= 0) {
          systemTab.statsSwapPct = Math.max(0, Math.min(1, swapPct / 100.0))
          systemTab.statsSwapStr = swapUsed + " / " + swapTotal + " MB"
        }

        systemTab.statsCpuTemp = systemTab.parseOptionalNumber(parts[1])
        systemTab.statsFanRpm = systemTab.parseOptionalNumber(parts[2])

        var loadParts = parts[3].split(",")
        systemTab.statsLoad1 = systemTab.parseOptionalNumber(loadParts[0])
        systemTab.statsLoad5 = systemTab.parseOptionalNumber(loadParts[1])
        systemTab.statsLoad15 = systemTab.parseOptionalNumber(loadParts[2])
      }
    }
    onExited: (exitCode) => {
      if (exitCode !== 0) systemTab.resetOptionalStats()
    }
  }

  Process {
    id: batteryInfoProc
    command: ["sh", "-c",
      "battery=$(find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' -print -quit 2>/dev/null); " +
      "if [ -z \"$battery\" ]; then printf '%s|%s\\n' '' ''; exit 0; fi; " +
      "cycles=$(cat \"$battery/cycle_count\" 2>/dev/null || true); " +
      "health=$(cat \"$battery/capacity\" 2>/dev/null || true); " +
      "if [ -z \"$health\" ] && [ -r \"$battery/energy_full\" ] && [ -r \"$battery/energy_full_design\" ]; then " +
      "full=$(cat \"$battery/energy_full\"); design=$(cat \"$battery/energy_full_design\"); " +
      "[ \"$design\" -gt 0 ] 2>/dev/null && health=$(awk -v f=\"$full\" -v d=\"$design\" 'BEGIN { printf \"%.0f\", f * 100 / d }'); fi; " +
      "printf '%s|%s\\n' \"$cycles\" \"$health\"" ]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        systemTab.resetBatteryInfo()
        var parts = text.trim().split("|")
        var cycles = (parts[0] || "").trim()
        var health = systemTab.parseOptionalNumber(parts[1] || "")
        if (cycles !== "" && !isNaN(cycles)) systemTab.batteryCycles = cycles
        if (health >= 0) {
          systemTab.batteryHealthPct = Math.max(0, Math.min(100, health))
          systemTab.batteryHealth = Math.round(systemTab.batteryHealthPct) + "%"
        }
      }
    }
    onExited: (exitCode) => {
      if (exitCode !== 0) systemTab.resetBatteryInfo()
    }
  }

  Process {
    id: copyDiagnosticsProc
    command: ["sh", "-c",
      "if ! command -v wl-copy >/dev/null 2>&1; then exit 2; fi; " +
      "{ printf 'Quickshell diagnostics\\n'; uname -a 2>/dev/null; " +
      "printf '\\nVersions\\n'; quickshell --version 2>/dev/null || true; niri --version 2>/dev/null || true; " +
      "printf '\\nServices\\n'; systemctl --user --no-pager --plain status quickshell.service 2>/dev/null | sed -n '1,12p'; " +
      "printf '\\nConnectivity\\n'; nmcli general status 2>/dev/null || true; bluetoothctl show 2>/dev/null | sed -n '1,8p'; } | wl-copy"]
    running: false
    onExited: (exitCode) => {
      systemTab.actionStatus = exitCode === 0 ? "Diagnostics copied to the clipboard" : "Could not copy diagnostics"
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
      batteryInfoProc.running = false;
      batteryInfoProc.running = true;
    }
  }

  function copyDiagnostics() {
    systemTab.actionStatus = "Copying diagnostics..."
    copyDiagnosticsProc.running = false
    copyDiagnosticsProc.running = true
  }

  function restartShell() {
    systemTab.actionStatus = "Restarting Quickshell..."
    Quickshell.execDetached(["systemctl", "--user", "restart", "quickshell.service"])
  }

  component StatCell: ColumnLayout {
    id: statCell
    property string icon: ""
    property string label: ""
    property string value: ""
    property real pct: 0
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    spacing: Config.spacingCompact

    RowLayout {
      spacing: Config.spacingSmall
      Text {
        text: statCell.icon
        font.family: Config.iconFont
        font.pixelSize: Config.iconSize
        color: Colors.primary
      }
      Text {
        text: statCell.label
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.textCaptionSize
        font.weight: Font.Medium
      }
    }

    Rectangle {
      Layout.fillWidth: true
      height: Config.spacingCompact
      radius: height / 2
      color: Colors.surfaceContainerHigh
      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, statCell.pct))
        height: parent.height
        radius: height / 2
        color: Colors.primary
      }
    }

    Text {
      text: statCell.value
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.textCaptionSize
      font.weight: Font.Bold
    }
  }

  ColumnLayout {
    id: mainColumn
    width: systemTab.width
    spacing: Config.spacingLarge

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
        anchors.margins: Config.spacingMedium
        columns: systemTab.compactLayout ? 1 : 3
        columnSpacing: systemTab.compactLayout ? 0 : 20
        rowSpacing: Config.spacingLarge

        StatCell {
          icon: "memory"
          label: "CPU Usage"
          value: root.statsCpu >= 0 ? Math.round(root.statsCpu) + "%" : "Unavailable"
          pct: root.statsCpu >= 0 ? root.statsCpu / 100.0 : -1
        }

        StatCell {
          icon: "database"
          label: "Memory (RAM)"
          value: root.statsRamPct >= 0 ? root.statsRamStr + " (" + Math.round(root.statsRamPct * 100) + "%)" : "Unavailable"
          pct: root.statsRamPct
        }

        StatCell {
          icon: "storage"
          label: "Disk Storage"
          value: root.statsDiskPct >= 0 ? root.statsDiskStr + " (" + Math.round(root.statsDiskPct * 100) + "%)" : "Unavailable"
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
          value: systemTab.statsCpuTemp >= 0 ? Math.round(systemTab.statsCpuTemp) + "°C" : "Unavailable"
          pct: systemTab.statsCpuTemp >= 0 ? systemTab.statsCpuTemp / 100.0 : -1
        }

        StatCell {
          icon: "air"
          label: "Fan Speed"
          value: systemTab.statsFanRpm < 0 ? "Unavailable" : (systemTab.statsFanRpm > 0 ? Math.round(systemTab.statsFanRpm) + " RPM" : "Off")
          pct: systemTab.statsFanRpm >= 0 ? systemTab.statsFanRpm / 5000.0 : -1
        }

        StatCell {
          icon: "battery_full"
          label: "Battery"
          value: systemTab.statsBattPct >= 0 ? Math.round(systemTab.statsBattPct) + "% " + systemTab.statsBattStatus : "Unavailable"
          pct: systemTab.statsBattPct >= 0 ? systemTab.statsBattPct / 100.0 : -1
        }

        StatCell {
          icon: "health_and_safety"
          label: "Battery Health"
          value: systemTab.batteryHealth
          pct: systemTab.batteryHealthPct >= 0 ? systemTab.batteryHealthPct / 100.0 : -1
        }

        StatCell {
          icon: "repeat"
          label: "Battery Cycles"
          value: systemTab.batteryCycles
          pct: -1
        }

        StatCell {
          icon: "speed"
          label: "Load Average"
          value: systemTab.statsLoad1 >= 0 && systemTab.statsLoad5 >= 0 && systemTab.statsLoad15 >= 0
            ? systemTab.statsLoad1.toFixed(2) + " / " + systemTab.statsLoad5.toFixed(2) + " / " + systemTab.statsLoad15.toFixed(2)
            : "Unavailable"
          pct: systemTab.statsLoad1 >= 0 && root.statsCpuCount > 0 ? systemTab.statsLoad1 / systemTab.cpuCount : -1
        }

        Item { Layout.fillWidth: true; Layout.preferredWidth: 1 }
      }
    }

    Text {
      Layout.fillWidth: true
      Layout.leftMargin: 4
      text: root.statsCpuCount > 0
        ? "Load average is 1 / 5 / 15 minute, normalized against " + systemTab.cpuCount + " CPU threads."
        : "CPU thread count unavailable; load average normalization is unavailable."
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.textCaptionSize
      wrapMode: Text.WordWrap
    }

    GridLayout {
      Layout.fillWidth: true
      columns: systemTab.compactLayout ? 1 : 2
      columnSpacing: Config.spacingSmall
      rowSpacing: Config.spacingSmall

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        iconLabel: "restart_alt"
        labelText: "Reload Quickshell"
        accessibleName: "Reload Quickshell"
        accessibleDescription: "Restart the managed quickshell service"
        onActivated: systemTab.restartShell()
      }

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        iconLabel: "content_copy"
        labelText: "Copy Diagnostics"
        variant: "outlined"
        accessibleName: "Copy diagnostics"
        accessibleDescription: "Copy non-sensitive shell and service diagnostics to the clipboard"
        onActivated: systemTab.copyDiagnostics()
      }

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        iconLabel: "settings_backup_restore"
        labelText: "Reset Settings"
        variant: "outlined"
        visible: !systemTab.resetConfirm
        accessibleName: "Reset settings"
        accessibleDescription: "Show confirmation before restoring default Quickshell settings"
        onActivated: systemTab.resetConfirm = true
      }

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        iconLabel: "warning"
        labelText: "Confirm Reset"
        variant: "filled"
        visible: systemTab.resetConfirm
        accessibleName: "Confirm reset settings"
        onActivated: {
          Settings.resetToDefaults()
          if (systemTab.root) systemTab.root.currentTab = 0
          systemTab.resetConfirm = false
          systemTab.actionStatus = "Settings reset to defaults"
        }
      }

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        iconLabel: "close"
        labelText: "Cancel Reset"
        variant: "quiet"
        visible: systemTab.resetConfirm
        accessibleName: "Cancel reset settings"
        onActivated: systemTab.resetConfirm = false
      }
    }

    Text {
      Layout.fillWidth: true
      Layout.leftMargin: Config.spacingCompact
      text: systemTab.actionStatus
      color: systemTab.actionStatus.indexOf("Could not") >= 0 ? Colors.error : Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.fontPixelSize
      wrapMode: Text.WordWrap
      visible: systemTab.actionStatus !== ""
    }
  }
}
