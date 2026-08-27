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
  property QtObject notificationPopup: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  readonly property bool material3Theme: !Config.nothingDesign && !Config.neoBrutalism && !Config.ghostTheme
  readonly property int segmentedButtonGap: notificationsTab.material3Theme ? 0 : Config.spacingSmall
  anchors.fill: parent
  visible: root.currentTab === 9
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + notificationsTab.neoShadowAllowance
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
    width: Math.max(0, notificationsTab.width - notificationsTab.neoShadowAllowance - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge + notificationsTab.neoShadowAllowance

    SettingsPageHeader {
      pageTitle: "Notifications"
      subtitle: "Manage notification behavior, quiet hours, and history."
    }

    // Behavior card
    StyledSurface {
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: behaviorCol.implicitHeight + Config.spacingSmall * 2
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: behaviorCol
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingSmall

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "do_not_disturb_on"
            title: "Do Not Disturb"
            subtitle: Settings.doNotDisturb
              ? "Toasts suppressed; history retained"
              : "Toast notifications enabled"
          SwitchControl {
            checked: Settings.doNotDisturb
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Do Not Disturb"
            onToggled: { Settings.doNotDisturb = !Settings.doNotDisturb; Settings.save() }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 40
          spacing: Config.spacingSmall + notificationsTab.neoShadowAllowance

          Text {
            text: "Toast Duration"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: notificationsTab.compactLayout ? 72 : 110
            Layout.leftMargin: Config.spacingSmall
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.notificationToastDurationMs - 2000) / 8000
            stepSize: 500 / 8000
            accessibleMinimumValue: 2
            accessibleMaximumValue: 10
            accessibleUnit: "seconds"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Notification toast duration"
            accessibleDescription: "Adjust how long toast notifications stay on screen"
            onChanged: function(val) {
              Settings.notificationToastDurationMs = Math.round(2000 + val * 8000)
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: (Settings.notificationToastDurationMs / 1000).toFixed(1) + "s"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: 36
            Layout.rightMargin: Config.spacingSmall
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
            Layout.preferredWidth: notificationsTab.compactLayout ? 82 : 110
            Layout.leftMargin: Config.spacingSmall
          }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 36

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

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "bedtime"
          title: "Quiet hours"
          subtitle: Settings.notificationQuietHoursEnabled
            ? formatMinutes(Settings.notificationQuietHoursStart) + " – " + formatMinutes(Settings.notificationQuietHoursEnd)
            : "Off"
          SwitchControl {
            checked: Settings.notificationQuietHoursEnabled
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
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

          SliderControl {
            Layout.fillWidth: true
            value: Settings.notificationQuietHoursStart / 1439
            stepSize: 1 / 1439
            accessibleMinimumValue: 0
            accessibleMaximumValue: 1439
            accessibleUnit: "minutes after midnight"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Quiet hours start"
            onChanged: function(val) { Settings.notificationQuietHoursStart = Math.round(val * 1439) }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: formatMinutes(Settings.notificationQuietHoursStart)
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: 42
            Layout.rightMargin: Config.spacingCompact
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

          SliderControl {
            Layout.fillWidth: true
            value: Settings.notificationQuietHoursEnd / 1439
            stepSize: 1 / 1439
            accessibleMinimumValue: 0
            accessibleMaximumValue: 1439
            accessibleUnit: "minutes after midnight"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Quiet hours end"
            onChanged: function(val) { Settings.notificationQuietHoursEnd = Math.round(val * 1439) }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: formatMinutes(Settings.notificationQuietHoursEnd)
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: 42
            Layout.rightMargin: Config.spacingCompact
          }
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "priority_high"
          title: "Critical notifications bypass quiet hours"
          subtitle: Settings.notificationCriticalBypass ? "Critical alerts remain visible" : "All notifications are suppressed"
          SwitchControl {
            checked: Settings.notificationCriticalBypass
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Critical notification bypass"
            onToggled: {
              Settings.notificationCriticalBypass = !Settings.notificationCriticalBypass
              Settings.save()
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          Text {
            text: "History limit"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: notificationsTab.compactLayout ? 72 : 110
            Layout.leftMargin: Config.spacingCompact
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.notificationHistoryLimit - 10) / 90
            stepSize: 5 / 90
            accessibleMinimumValue: 10
            accessibleMaximumValue: 100
            accessibleUnit: "notifications"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Notification history limit"
            accessibleDescription: "Maximum number of notifications retained in the bell history"
            onChanged: function(val) {
              Settings.notificationHistoryLimit = Math.max(10, Math.min(100, Math.round((10 + val * 90) / 5) * 5))
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: Settings.notificationHistoryLimit
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.preferredWidth: 30
            Layout.rightMargin: Config.spacingCompact
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
      accessibleDescription: "Fires a sample notification; DND suppresses its toast and keeps it in history"
      onActivated: {
        testNotifyProc.running = false
        testNotifyProc.running = true
      }
    }

    ActionButton {
      Layout.fillWidth: true
      Layout.preferredHeight: Config.themeLabeledActionButtonHeight
      iconLabel: "delete_sweep"
      contentSpacing: Config.spacingMedium
      labelText: "Clear Notification History"
      variant: "outlined"
      enabled: notificationPopup !== null && notificationPopup.count > 0
      accessibleName: "Clear notification history"
      accessibleDescription: "Dismiss all notifications retained by the bell history"
      onActivated: if (notificationPopup) notificationPopup.clearAll()
    }

    Text {
      Layout.fillWidth: true
      Layout.leftMargin: Config.spacingCompact
      text: "Quiet hours retain history. Critical alerts can bypass suppression. The bell popup also supports per-notification dismissal."
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
