import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: lockMediaTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  readonly property var lockTimeoutOptions: [0, 60, 120, 180, 300, 600, 900, 1800, 3600]
  readonly property var suspendTimeoutOptions: [0, 300, 600, 900, 1200, 1800, 3600, 7200]
  anchors.fill: parent
  visible: root.currentTab === 7
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + lockMediaTab.neoShadowAllowance
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

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
    width: Math.max(0, lockMediaTab.width - lockMediaTab.neoShadowAllowance)
    spacing: Config.spacingLarge + lockMediaTab.neoShadowAllowance

    // Lock Screen card
    StyledSurface {
      Layout.fillWidth: true
      Layout.preferredHeight: lockCol.implicitHeight + 16
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: lockCol
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingSmall

        Text {
          text: "Lock Screen"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          Layout.leftMargin: 8
          Layout.topMargin: 4
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "music_note"
          title: "Show now playing"
          subtitle: "Display current track on the lock screen"
          SwitchControl {
            checked: Settings.lockShowMedia
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Show now playing on lock screen"
            onToggled: { Settings.lockShowMedia = !Settings.lockShowMedia; Settings.save() }
          }
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "wallpaper"
          title: "Use current wallpaper"
          subtitle: Settings.lockUseWallpaper
            ? "Show the desktop wallpaper behind the lock screen"
            : "Use the animated lock-screen background"
          SwitchControl {
            checked: Settings.lockUseWallpaper
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Use current wallpaper on lock screen"
            onToggled: { Settings.lockUseWallpaper = !Settings.lockUseWallpaper; Settings.save() }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 44
          spacing: Config.spacingMedium

          Text {
            text: "Clock Size"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.textBodySize
            Layout.preferredWidth: lockMediaTab.compactLayout ? 64 : 90
            Layout.leftMargin: 8
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.lockClockSize - 48) / 48
            stepSize: 2 / 48
            accessibleMinimumValue: 48
            accessibleMaximumValue: 96
            accessibleUnit: "px"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Lock screen clock size"
            accessibleDescription: "Adjust the lock screen clock size"
            onChanged: function(val) {
              Settings.lockClockSize = Math.round(48 + val * 48)
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: Math.round(Settings.lockClockSize) + "px"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textCaptionSize
            Layout.preferredWidth: 34
          }
        }
      }
    }

    // Idle & Power card
    StyledSurface {
      Layout.fillWidth: true
      Layout.preferredHeight: idleCol.implicitHeight + 16
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: idleCol
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingSmall

        Text {
          text: "Idle & Power"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          Layout.leftMargin: 8
          Layout.topMargin: 4
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "lock"
          title: "Lock after inactivity"
          subtitle: lockMediaTab.timeoutLabel(Settings.idleLockTimeoutSeconds)
          accessibleName: "Lock after inactivity"
          accessibleDescription: "Choose when the session locks while idle"

          SliderControl {
            width: lockMediaTab.compactLayout ? 104 : 170
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
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Lock after inactivity timeout"
            accessibleDescription: "Select the automatic lock timeout"
            onChanged: function(val) {
              var index = Math.round(val * (lockMediaTab.lockTimeoutOptions.length - 1))
              Settings.idleLockTimeoutSeconds = lockMediaTab.lockTimeoutOptions[index]
            }
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
            width: lockMediaTab.compactLayout ? 104 : 170
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
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Suspend after inactivity timeout"
            accessibleDescription: "Select the automatic suspend timeout"
            onChanged: function(val) {
              var index = Math.round(val * (lockMediaTab.suspendTimeoutOptions.length - 1))
              Settings.idleSuspendTimeoutSeconds = lockMediaTab.suspendTimeoutOptions[index]
            }
            onInteractionFinished: lockMediaTab.applyIdleSettings()
          }
        }

        Text {
          Layout.fillWidth: true
          Layout.leftMargin: 8
          Layout.rightMargin: 8
          text: "Dim after 2.5 min • display off after 10 min • suspend always locks first"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          wrapMode: Text.WordWrap
        }

        ActionButton {
          Layout.fillWidth: true
          Layout.preferredHeight: 48
          iconLabel: "coffee"
          iconSize: 24
          labelText: "Caffeine"
          selected: root.caffeineOn
          accessibleName: "Caffeine mode"
          accessibleDescription: root.caffeineOn
            ? "Enabled; idle lock, display off, and suspend are paused"
            : "Disabled; idle lock, display off, and suspend are active"
          onActivated: {
            if (root.caffeineOn) {
              Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh"])
              root.caffeineOn = false
            } else {
              Quickshell.execDetached(["killall", "swayidle"])
              root.caffeineOn = true
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
