import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../primitives"
import "../../config"

Rectangle {
  id: card

  property bool compactLayout: false
  property bool active: false
  property string powerProfile: ""
  property string powerProfileStatus: ""
  property string powerProfileAcDefault: "performance"
  property string powerProfileBatteryDefault: "balanced"
  property bool powerProfileAutoSwitchEnabled: true
  readonly property string automaticPowerProfile: UPower.onBattery
    ? powerProfileBatteryDefault
    : powerProfileAcDefault
  readonly property bool powerProfileAuto: powerProfileAutoSwitchEnabled && powerProfile !== ""
    && powerProfile === automaticPowerProfile

  Layout.fillWidth: true
  Layout.preferredHeight: powerProfileColumn.implicitHeight + Config.spacingMedium * 2
  radius: Config.shapeLarge
  color: Colors.surfaceContainer
  border.color: Colors.outlineVariant
  border.width: 1

  function parsePowerProfile(value) {
    var output = value === undefined || value === null ? "" : String(value).trim().toLowerCase()
    var profiles = ["performance", "balanced", "power-saver"]
    for (var i = 0; i < profiles.length; i++) {
      if (output === profiles[i] || output.indexOf(profiles[i]) >= 0) return profiles[i]
    }
    return ""
  }

  function powerProfileLabel(profile) {
    if (profile === "power-saver") return "Power saver"
    if (profile === "performance") return "Performance"
    if (profile === "balanced") return "Balanced"
    return "Unavailable"
  }

  function configuredPowerProfile(value) {
    var code = value === undefined || value === null ? "" : String(value).trim().toUpperCase()
    if (code === "PRF" || code === "AC") return "performance"
    if (code === "BAL" || code === "BAT") return "balanced"
    if (code === "SAV") return "power-saver"
    return ""
  }

  function refreshPowerProfile() {
    if (powerProfileQueryProc.running || powerProfileConfigProc.running || powerProfileSetProc.running) return
    powerProfileQueryProc.queriedProfile = ""
    card.powerProfileStatus = ""
    powerProfileConfigProc.running = true
    powerProfileQueryProc.running = true
  }

  function setPowerProfile(profile) {
    if (profile === "" || powerProfileQueryProc.running || powerProfileConfigProc.running || powerProfileSetProc.running) return
    card.powerProfileStatus = "Switching to " + card.powerProfileLabel(profile) + "..."
    powerProfileSetProc.targetProfile = profile
    powerProfileSetProc.running = true
  }

  function setAutomaticPowerProfile() {
    if (powerProfileQueryProc.running || powerProfileConfigProc.running || powerProfileSetProc.running) return
    if (!card.powerProfileAutoSwitchEnabled) {
      card.powerProfileStatus = "Automatic switching is disabled in TLP"
      return
    }
    card.powerProfileStatus = "Restoring automatic switching..."
    powerProfileSetProc.targetProfile = card.automaticPowerProfile
    powerProfileSetProc.running = true
  }

  Process {
    id: powerProfileQueryProc
    property string queriedProfile: ""
    command: ["tlpctl", "get"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        powerProfileQueryProc.queriedProfile = card.parsePowerProfile(text)
        card.powerProfile = powerProfileQueryProc.queriedProfile
      }
    }
    onExited: (exitCode) => {
      if (exitCode !== 0 || powerProfileQueryProc.queriedProfile === "") {
        card.powerProfile = ""
        card.powerProfileStatus = "TLP power profiles unavailable"
      }
    }
  }

  Process {
    id: powerProfileConfigProc
    command: ["tlp-stat", "-c"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var config = String(text)
        var switchMatch = config.match(/TLP_AUTO_SWITCH="([012])"/)
        var acMatch = config.match(/TLP_PROFILE_AC="([A-Z]+)"/)
        var batteryMatch = config.match(/TLP_PROFILE_BAT="([A-Z]+)"/)
        if (switchMatch) card.powerProfileAutoSwitchEnabled = switchMatch[1] !== "0"
        var acProfile = card.configuredPowerProfile(acMatch ? acMatch[1] : "")
        var batteryProfile = card.configuredPowerProfile(batteryMatch ? batteryMatch[1] : "")
        if (acProfile !== "") card.powerProfileAcDefault = acProfile
        if (batteryProfile !== "") card.powerProfileBatteryDefault = batteryProfile
      }
    }
  }

  Process {
    id: powerProfileSetProc
    property string targetProfile: ""
    command: ["tlpctl", "set", targetProfile]
    running: false
    onExited: (exitCode) => {
      if (exitCode === 0) {
        card.powerProfile = powerProfileSetProc.targetProfile
        card.powerProfileStatus = ""
      } else {
        card.powerProfileStatus = "Could not change power profile"
      }
    }
  }

  Connections {
    target: UPower
    function onOnBatteryChanged() {
      if (card.active) powerProfileRefreshTimer.start()
    }
  }

  Timer {
    id: powerProfileRefreshTimer
    interval: 500
    repeat: false
    onTriggered: card.refreshPowerProfile()
  }

  onActiveChanged: {
    if (active) card.refreshPowerProfile()
  }

  Component.onCompleted: {
    if (active) card.refreshPowerProfile()
  }

  ColumnLayout {
    id: powerProfileColumn
    anchors.fill: parent
    anchors.margins: Config.spacingMedium
    spacing: Config.spacingSmall

    RowLayout {
      Layout.fillWidth: true

      Text {
        text: "Power Profiles"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.textBodySize
        font.weight: Font.Medium
        Layout.fillWidth: true
      }

      Text {
        text: card.powerProfile !== ""
          ? (card.powerProfileAuto ? "Automatic: " : "Manual: ") + card.powerProfileLabel(card.powerProfile)
          : "Unavailable"
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.textCaptionSize
        horizontalAlignment: Text.AlignRight
      }
    }

    GridLayout {
      Layout.fillWidth: true
      columns: card.compactLayout ? 2 : 4
      columnSpacing: Config.spacingCompact
      rowSpacing: Config.spacingCompact

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        iconLabel: "sync"
        labelText: "Auto"
        selected: card.powerProfileAuto
        enabled: card.powerProfileAutoSwitchEnabled && card.powerProfile !== ""
          && !powerProfileQueryProc.running && !powerProfileConfigProc.running && !powerProfileSetProc.running
        accessibleName: "Automatic power profile"
        accessibleDescription: "Restore TLP's configured AC and battery power-profile switching"
        onActivated: card.setAutomaticPowerProfile()
      }

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        iconLabel: "speed"
        labelText: "Performance"
        selected: !card.powerProfileAuto && card.powerProfile === "performance"
        enabled: card.powerProfile !== ""
          && !powerProfileQueryProc.running && !powerProfileConfigProc.running && !powerProfileSetProc.running
        accessibleName: "Performance power profile"
        accessibleDescription: "Use TLP's performance power profile"
        onActivated: card.setPowerProfile("performance")
      }

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        iconLabel: "balance"
        labelText: "Balanced"
        selected: !card.powerProfileAuto && card.powerProfile === "balanced"
        enabled: card.powerProfile !== ""
          && !powerProfileQueryProc.running && !powerProfileConfigProc.running && !powerProfileSetProc.running
        accessibleName: "Balanced power profile"
        accessibleDescription: "Use TLP's balanced power profile"
        onActivated: card.setPowerProfile("balanced")
      }

      ActionButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        iconLabel: "battery_saver"
        labelText: "Saver"
        selected: !card.powerProfileAuto && card.powerProfile === "power-saver"
        enabled: card.powerProfile !== ""
          && !powerProfileQueryProc.running && !powerProfileConfigProc.running && !powerProfileSetProc.running
        accessibleName: "Power saver profile"
        accessibleDescription: "Use TLP's power-saver profile"
        onActivated: card.setPowerProfile("power-saver")
      }
    }

    Text {
      Layout.fillWidth: true
      text: card.powerProfileStatus
      color: card.powerProfileStatus.indexOf("unavailable") >= 0 || card.powerProfileStatus.indexOf("Could not") >= 0
        ? Colors.error
        : Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.textCaptionSize
      wrapMode: Text.WordWrap
      visible: card.powerProfileStatus !== ""
    }
  }
}
