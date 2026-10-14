import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: notificationsTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  readonly property int segmentedButtonGap: 0
  anchors.fill: parent
  visible: root.currentTab === 5
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: notificationsTab }

  function formatMinutes(value) {
    var minutes = Math.max(0, Math.min(1439, Math.round(value)))
    return String(Math.floor(minutes / 60)).padStart(2, "0") + ":"
      + String(minutes % 60).padStart(2, "0")
  }

  Process {
    id: testNotifyProc
    command: ["notify-send", "-a", "Quickshell", "Test Notification", "This is what a toast looks like at the current duration."]
    running: false
  }

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, notificationsTab.width - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge

    SettingsPageHeader {
      pageTitle: "Notifications"
      subtitle: "Manage notification behavior and quiet hours."
    }

    // Behavior card
    SettingsCard {
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: behaviorCol.implicitHeight + Config.spacingSmall * 2
      radius: Config.settingsCardRadius
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.outlineVariant
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: behaviorCol
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingSmall

        SettingsSectionLabel {
          text: "Delivery"
          Layout.leftMargin: Config.spacingSmall
        }

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "do_not_disturb_on"
            title: "Do Not Disturb"
            subtitle: Settings.doNotDisturb
              ? "Toasts suppressed"
              : "Toast notifications enabled"
          toggleControl: dndSwitch
          SwitchControl {
            id: dndSwitch
            checked: Settings.doNotDisturb
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Do Not Disturb"
            onToggled: { Settings.doNotDisturb = !Settings.doNotDisturb; Settings.save() }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          Text {
            text: "Toast Duration"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: notificationsTab.compactLayout ? 104 : (110)
            Layout.leftMargin: Config.spacingSmall
          }

          Item { Layout.fillWidth: true }
          SliderControl {
            Layout.rightMargin: Config.spacingSmall
            value: (Settings.notificationToastDurationMs - 2000) / 8000
            stepSize: 500 / 8000
            accessibleMinimumValue: 2
            accessibleMaximumValue: 10
            accessibleUnit: "seconds"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Notification toast duration"
            accessibleDescription: "Adjust how long toast notifications stay on screen"
            onChanged: function(val) {
              Settings.notificationToastDurationMs = Math.round(2000 + val * 8000)
            }
            onInteractionFinished: Settings.save()
            valueText: (Settings.notificationToastDurationMs / 1000).toFixed(1) + "s"
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          Text {
            text: "Toast position"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: notificationsTab.compactLayout ? 82 : (110)
            Layout.leftMargin: Config.spacingSmall
          }

          Item { Layout.fillWidth: true }
          Item {
            Layout.preferredWidth: 160
            Layout.preferredHeight: 30
            Layout.rightMargin: Config.spacingSmall

            Row {
              anchors.fill: parent
              spacing: notificationsTab.segmentedButtonGap

              ActionButton {
                width: (parent.width - notificationsTab.segmentedButtonGap) / 2
                height: parent.height
                labelText: "Top right"
                selected: Settings.notificationToastPosition === "top-right"
                checkable: true
                grouped: true
                groupPosition: "first"
                accessibleName: "Top right notification toasts"
                onActivated: { Settings.notificationToastPosition = "top-right"; Settings.save() }
              }

              ActionButton {
                width: (parent.width - notificationsTab.segmentedButtonGap) / 2
                height: parent.height
                labelText: "Bottom right"
                selected: Settings.notificationToastPosition === "bottom-right"
                checkable: true
                grouped: true
                groupPosition: "last"
                accessibleName: "Bottom right notification toasts"
                onActivated: { Settings.notificationToastPosition = "bottom-right"; Settings.save() }
              }
            }
          }
        }

        SettingsSectionLabel {
          text: "Schedule"
          Layout.leftMargin: Config.spacingSmall
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "bedtime"
          title: "Quiet hours"
          subtitle: Settings.notificationQuietHoursEnabled
            ? formatMinutes(Settings.notificationQuietHoursStart) + " – " + formatMinutes(Settings.notificationQuietHoursEnd)
            : "Off"
          toggleControl: quietHoursSwitch
          SwitchControl {
            id: quietHoursSwitch
            checked: Settings.notificationQuietHoursEnabled
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Quiet hours"
            onToggled: {
              Settings.notificationQuietHoursEnabled = !Settings.notificationQuietHoursEnabled
              Settings.save()
            }
          }
        }

        RowLayout {
          visible: Settings.notificationQuietHoursEnabled
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          Text {
            text: "Starts"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: notificationsTab.compactLayout ? 48 : 64
            Layout.leftMargin: Config.spacingCompact
          }

          Item { Layout.fillWidth: true }
          SliderControl {
            Layout.rightMargin: Config.spacingSmall
            value: Settings.notificationQuietHoursStart / 1439
            stepSize: 1 / 1439
            accessibleMinimumValue: 0
            accessibleMaximumValue: 1439
            accessibleUnit: "minutes after midnight"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Quiet hours start"
            onChanged: function(val) { Settings.notificationQuietHoursStart = Math.round(val * 1439) }
            onInteractionFinished: Settings.save()
            valueText: formatMinutes(Settings.notificationQuietHoursStart)
          }
        }

        RowLayout {
          visible: Settings.notificationQuietHoursEnabled
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          Text {
            text: "Ends"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: notificationsTab.compactLayout ? 48 : 64
            Layout.leftMargin: Config.spacingCompact
          }

          Item { Layout.fillWidth: true }
          SliderControl {
            Layout.rightMargin: Config.spacingSmall
            value: Settings.notificationQuietHoursEnd / 1439
            stepSize: 1 / 1439
            accessibleMinimumValue: 0
            accessibleMaximumValue: 1439
            accessibleUnit: "minutes after midnight"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Quiet hours end"
            onChanged: function(val) { Settings.notificationQuietHoursEnd = Math.round(val * 1439) }
            onInteractionFinished: Settings.save()
            valueText: formatMinutes(Settings.notificationQuietHoursEnd)
          }
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "priority_high"
          title: "Critical notifications bypass quiet hours"
          subtitle: Settings.notificationCriticalBypass ? "Critical alerts remain visible" : "All notifications are suppressed"
          toggleControl: bypassSwitch
          SwitchControl {
            id: bypassSwitch
            checked: Settings.notificationCriticalBypass
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Critical notification bypass"
            onToggled: {
              Settings.notificationCriticalBypass = !Settings.notificationCriticalBypass
              Settings.save()
            }
          }
        }

      }
    }

    ActionButton {
      Layout.fillWidth: true
      Layout.preferredHeight: Config.themeLabeledActionButtonHeight
      iconLabel: "notifications_active"
      contentSpacing: Config.spacingMedium
      labelText: "Send Test Notification"
      variant: "elevated"
      accessibleName: "Send test notification"
      accessibleDescription: "Fires a sample notification; DND suppresses its toast"
      onActivated: {
        testNotifyProc.running = false
        testNotifyProc.running = true
      }
    }


    Text {
      Layout.fillWidth: true
      Layout.leftMargin: Config.spacingCompact
      text: "Critical alerts can bypass Do Not Disturb and quiet hours. Click a toast to dismiss it."
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeLabelSmallSize
      font.letterSpacing: Config.typeLabelTracking
      lineHeight: Config.typeLabelSmallLineHeight
      lineHeightMode: Text.FixedHeight
      wrapMode: Text.WordWrap
    }
  }
}
