import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: notificationsTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 6
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  Process {
    id: testNotifyProc
    command: ["notify-send", "-a", "Quickshell", "Test Notification", "This is what a toast looks like at the current duration."]
    running: false
  }

  ColumnLayout {
    id: mainColumn
    width: notificationsTab.width
    spacing: 16

    // Behavior card
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: behaviorCol.implicitHeight + 16
      radius: Config.shapeLarge
      color: Colors.surfaceContainer
      border.color: Colors.outlineVariant
      border.width: 1

      ColumnLayout {
        id: behaviorCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

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
            outline: Colors.outline
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Do Not Disturb"
            onToggled: { Settings.doNotDisturb = !Settings.doNotDisturb; Settings.save() }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 40
          spacing: 8

          Text {
            text: "Toast Duration"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: 12
            Layout.preferredWidth: 110
            Layout.leftMargin: 8
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.notificationToastDurationMs - 2000) / 8000
            stepSize: 500 / 8000
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
              Settings.save()
            }
          }

          Text {
            text: (Settings.notificationToastDurationMs / 1000).toFixed(1) + "s"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: 12
            font.weight: Font.Medium
            Layout.preferredWidth: 36
            Layout.rightMargin: 8
          }
        }
      }
    }

    ActionButton {
      Layout.fillWidth: true
      Layout.preferredHeight: 56
      iconLabel: "notifications_active"
      labelText: "Send Test Notification"
      accessibleName: "Send test notification"
      accessibleDescription: "Fires a sample notification; DND suppresses its toast and keeps it in history"
      onActivated: {
        testNotifyProc.running = false
        testNotifyProc.running = true
      }
    }

    Text {
      Layout.fillWidth: true
      Layout.leftMargin: 4
      text: "Notification history and per-app clearing live in the bell icon's popup on the bar."
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: 11
      wrapMode: Text.WordWrap
    }
  }
}
