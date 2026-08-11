import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: generalTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 2
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  ColumnLayout {
    id: mainColumn
    width: generalTab.width
    spacing: 16

    RowLayout {
      Layout.fillWidth: true
      spacing: 16

      // Behavior toggle group
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
          spacing: 0

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "motion_photos_off"
            title: "Reduced motion"
            subtitle: Config.reducedMotion ? "Animations minimized" : "Expressive transitions"
            SwitchControl {
              checked: Settings.reduceMotion
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Reduced motion"
              onToggled: { Settings.reduceMotion = !Settings.reduceMotion; Settings.save() }
            }
          }

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "schedule"
            title: "Show uptime"
            subtitle: Settings.systemShowUptime ? "Shown on the Account tab" : "Hidden from the Account tab"
            SwitchControl {
              checked: Settings.systemShowUptime
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Show uptime"
              onToggled: { Settings.systemShowUptime = !Settings.systemShowUptime; Settings.save() }
            }
          }
        }
      }

      ActionButton {
        Layout.preferredWidth: 80
        Layout.preferredHeight: behaviorCol.implicitHeight + 16
        iconLabel: "coffee"
        iconSize: 32
        labelText: "Caffeine"
        selected: root.caffeineOn
        accessibleName: "Caffeine mode"
        accessibleDescription: root.caffeineOn ? "Enabled" : "Disabled"
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

    RowLayout {
      Layout.fillWidth: true
      spacing: 16

      // Clock & Calendar toggle group
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: clockCol.implicitHeight + 16
        radius: Config.shapeLarge
        color: Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: 1

        ColumnLayout {
          id: clockCol
          anchors.fill: parent
          anchors.margins: 8
          spacing: 0

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "schedule"
            title: "24-hour clock"
            subtitle: Settings.clock24h ? "13:00" : "1:00 PM"
            SwitchControl {
              checked: Settings.clock24h
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "24-hour clock"
              onToggled: { Settings.clock24h = !Settings.clock24h; Settings.save() }
            }
          }

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "timer"
            title: "Show seconds"
            subtitle: "Display seconds in the bar clock"
            SwitchControl {
              checked: Settings.clockShowSeconds
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Show seconds"
              onToggled: { Settings.clockShowSeconds = !Settings.clockShowSeconds; Settings.save() }
            }
          }

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "calendar_view_week"
            title: "Week starts Monday"
            subtitle: Settings.calendarWeekStartsMonday ? "Mon - Sun" : "Sun - Sat"
            SwitchControl {
              checked: Settings.calendarWeekStartsMonday
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Week starts Monday"
              onToggled: { Settings.calendarWeekStartsMonday = !Settings.calendarWeekStartsMonday; Settings.save() }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: 8

            Text {
              text: "Timezone"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.fontPixelSize + 3
              font.weight: Font.Medium
              Layout.leftMargin: 8
            }

            TextFieldControl {
              id: timezoneField
              Layout.fillWidth: true
              Layout.preferredHeight: 32
              placeholder: "System default (e.g. America/Asuncion)"
              accessibleName: "Timezone"
              accessibleDescription: "IANA timezone name, blank uses system time"
              Component.onCompleted: input.text = Settings.timezone
              onAccepted: { Settings.timezone = input.text.trim(); Settings.save() }

              Connections {
                target: timezoneField.input
                function onActiveFocusChanged() {
                  if (!timezoneField.input.activeFocus) {
                    Settings.timezone = timezoneField.input.text.trim()
                    Settings.save()
                  }
                }
              }
            }
          }
        }
      }

      // Bar indicators toggle group
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: indicatorsCol.implicitHeight + 16
        radius: Config.shapeLarge
        color: Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: 1

        ColumnLayout {
          id: indicatorsCol
          anchors.fill: parent
          anchors.margins: 8
          spacing: 0

          Text {
            text: "Bar Indicators"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
            Layout.leftMargin: 8
            Layout.topMargin: 4
            Layout.bottomMargin: 4
          }

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "play_circle"
            title: "Media"
            SwitchControl {
              checked: Settings.ccShowMedia
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Show media indicator"
              onToggled: { Settings.ccShowMedia = !Settings.ccShowMedia; Settings.save() }
            }
          }

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "cloud"
            title: "Weather"
            SwitchControl {
              checked: Settings.ccShowWeather
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Show weather indicator"
              onToggled: { Settings.ccShowWeather = !Settings.ccShowWeather; Settings.save() }
            }
          }

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "volume_up"
            title: "Audio"
            SwitchControl {
              checked: Settings.ccShowAudio
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Show audio indicator"
              onToggled: { Settings.ccShowAudio = !Settings.ccShowAudio; Settings.save() }
            }
          }

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "brightness_medium"
            title: "Display"
            SwitchControl {
              checked: Settings.ccShowDisplay
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Show display brightness indicator"
              onToggled: { Settings.ccShowDisplay = !Settings.ccShowDisplay; Settings.save() }
            }
          }
        }
      }
    }

    // Weather units
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 84
      radius: Config.shapeLarge
      color: Colors.surfaceContainer
      border.color: Colors.outlineVariant
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
          width: 24
          height: 24
          radius: 6
          color: Colors.primary
          Layout.alignment: Qt.AlignVCenter
          Text {
            anchors.centerIn: parent
            text: "device_thermostat"
            color: Colors.fgPrimary
            font.family: Config.iconFont
            font.pixelSize: 16
          }
        }

        Text {
          text: "Weather Units"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: 13
          font.weight: Font.Bold
          Layout.fillWidth: true
        }

        Item {
          width: 160
          height: 36

          Row {
            anchors.fill: parent
            spacing: 0

            ActionButton {
              width: parent.width / 2
              height: parent.height
              labelText: "°C"
              selected: Settings.weatherUnits === "metric"
              accessibleName: "Metric units"
              onActivated: { Settings.weatherUnits = "metric"; Settings.save() }
            }

            ActionButton {
              width: parent.width / 2
              height: parent.height
              labelText: "°F"
              selected: Settings.weatherUnits === "imperial"
              accessibleName: "Imperial units"
              onActivated: { Settings.weatherUnits = "imperial"; Settings.save() }
            }
          }
        }
      }
    }
  }
}
