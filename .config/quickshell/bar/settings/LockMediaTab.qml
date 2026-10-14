import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: lockMediaTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  readonly property int segmentedButtonGap: 0
  readonly property var lockTimeoutOptions: [0, 60, 120, 180, 300, 600, 900, 1800, 3600]
  readonly property var suspendTimeoutOptions: [0, 300, 600, 900, 1200, 1800, 3600, 7200]
  anchors.fill: parent
  visible: root.currentTab === 4
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: lockMediaTab }

  function timeoutIndex(options, seconds) {
    var closestIndex = 0
    var closestDistance = Math.abs(options[0] - seconds)
    for (var i = 1; i < options.length; i++) {
      var distance = Math.abs(options[i] - seconds)
      if (distance < closestDistance) {
        closestIndex = i
        closestDistance = distance
      }
    }
    return closestIndex
  }

  function timeoutLabel(seconds) {
    if (seconds <= 0) return "Never"
    if (seconds % 3600 === 0) return (seconds / 3600) + " hour" + (seconds === 3600 ? "" : "s")
    return Math.round(seconds / 60) + " min"
  }

  function applyIdleSettings() {
    Settings.save()
    idleSettingsApplyTimer.restart()
  }

  Timer {
    id: idleSettingsApplyTimer
    interval: 150
    repeat: false
    onTriggered: Quickshell.execDetached([
      Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh",
      "restart"
    ])
  }

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, lockMediaTab.width - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge

    SettingsPageHeader {
      pageTitle: "Lock & Power"
      subtitle: "Configure idle behavior and power profiles."
    }

    // Idle & Power card
    SettingsCard {
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: idleCol.implicitHeight + Config.spacingSmall * 2
      radius: Config.settingsCardRadius
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.outlineVariant
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: idleCol
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingSmall

        SettingsSectionLabel {
          text: "Idle & power"
          Layout.leftMargin: Config.spacingSmall
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "lock"
          title: "Lock after inactivity"
          subtitle: lockMediaTab.timeoutLabel(Settings.idleLockTimeoutSeconds)
          accessibleName: "Lock after inactivity"
          accessibleDescription: "Choose when the session locks while idle"

          SliderControl {
            value: lockMediaTab.timeoutIndex(
              lockMediaTab.lockTimeoutOptions,
              Settings.idleLockTimeoutSeconds
            ) / (lockMediaTab.lockTimeoutOptions.length - 1)
            stepSize: 1 / (lockMediaTab.lockTimeoutOptions.length - 1)
            accessibleMinimumValue: 0
            accessibleMaximumValue: lockMediaTab.lockTimeoutOptions.length - 1
            accessibleUnit: "step"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Lock after inactivity timeout"
            accessibleDescription: "Select the automatic lock timeout"
            onChanged: function(val) {
              var index = Math.round(val * (lockMediaTab.lockTimeoutOptions.length - 1))
              Settings.idleLockTimeoutSeconds = lockMediaTab.lockTimeoutOptions[index]
            }
            valueText: lockMediaTab.timeoutLabel(Settings.idleLockTimeoutSeconds)
            onInteractionFinished: lockMediaTab.applyIdleSettings()
          }
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "bedtime"
          title: "Suspend after inactivity"
          subtitle: lockMediaTab.timeoutLabel(Settings.idleSuspendTimeoutSeconds)
          accessibleName: "Suspend after inactivity"
          accessibleDescription: "Choose when the computer suspends while idle"

          SliderControl {
            value: lockMediaTab.timeoutIndex(
              lockMediaTab.suspendTimeoutOptions,
              Settings.idleSuspendTimeoutSeconds
            ) / (lockMediaTab.suspendTimeoutOptions.length - 1)
            stepSize: 1 / (lockMediaTab.suspendTimeoutOptions.length - 1)
            accessibleMinimumValue: 0
            accessibleMaximumValue: lockMediaTab.suspendTimeoutOptions.length - 1
            accessibleUnit: "step"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Suspend after inactivity timeout"
            accessibleDescription: "Select the automatic suspend timeout"
            onChanged: function(val) {
              var index = Math.round(val * (lockMediaTab.suspendTimeoutOptions.length - 1))
              Settings.idleSuspendTimeoutSeconds = lockMediaTab.suspendTimeoutOptions[index]
            }
            valueText: lockMediaTab.timeoutLabel(Settings.idleSuspendTimeoutSeconds)
            onInteractionFinished: lockMediaTab.applyIdleSettings()
          }
        }

        Text {
          Layout.fillWidth: true
          Layout.leftMargin: Config.spacingSmall
          Layout.rightMargin: Config.spacingSmall
          text: "Dim after 2.5 min • display off after 10 min • suspend always locks first"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          wrapMode: Text.WordWrap
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "coffee"
          title: "Caffeine"
          subtitle: root.caffeineOn
            ? "Idle lock, display off, and suspend timers are paused"
            : "Idle lock, display off, and suspend timers are active"
          toggleControl: caffeineSwitch
          SwitchControl {
            id: caffeineSwitch
            checked: root.caffeineOn
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Caffeine mode"
            accessibleDescription: root.caffeineOn
              ? "Enabled; idle lock, display off, and suspend timers are paused; lid-close suspend still locks"
              : "Disabled; idle lock, display off, and suspend timers are active; lid-close suspend still locks"
            onToggled: {
              if (root.caffeineOn) {
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh"])
                root.caffeineOn = false
              } else {
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh", "stop"])
                root.caffeineOn = true
              }
            }
          }
        }
      }
    }

    PowerProfileCard {
      compactLayout: lockMediaTab.compactLayout
      active: lockMediaTab.visible
    }

    Item { Layout.fillHeight: true }
  }
}
