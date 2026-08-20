import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: generalTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  readonly property int neoControlAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset * 2
    : 0
  anchors.fill: parent
  visible: root.currentTab === 1
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + generalTab.neoShadowAllowance
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  function saveWeatherLocation() {
    var value = weatherLocationField.input.text.trim()
    if (Settings.weatherLocation !== value) {
      Settings.weatherLocation = value
      Settings.save()
    }
  }

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, generalTab.width - generalTab.neoShadowAllowance)
    spacing: Config.spacingLarge + generalTab.neoShadowAllowance

    GridLayout {
      Layout.fillWidth: true
      columns: 1
      columnSpacing: Config.spacingLarge
      rowSpacing: Config.spacingLarge

      // Behavior toggle group
      StyledSurface {
        Layout.fillWidth: true
        Layout.preferredHeight: behaviorCol.implicitHeight + 16
        radius: Config.shapeLarge
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: behaviorCol
          anchors.fill: parent
          anchors.margins: Config.spacingSmall
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
              outline: Colors.styleOutlineStrong
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
              outline: Colors.styleOutlineStrong
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Show uptime"
              onToggled: { Settings.systemShowUptime = !Settings.systemShowUptime; Settings.save() }
            }
          }
        }
      }

    }

    GridLayout {
      Layout.fillWidth: true
      columns: 1
      columnSpacing: Config.spacingLarge
      rowSpacing: Config.spacingLarge

      // Clock & Calendar toggle group
      StyledSurface {
        Layout.fillWidth: true
        Layout.preferredHeight: clockCol.implicitHeight + 16
        radius: Config.shapeLarge
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: clockCol
          anchors.fill: parent
          anchors.margins: Config.spacingSmall
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
              outline: Colors.styleOutlineStrong
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
              outline: Colors.styleOutlineStrong
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
              outline: Colors.styleOutlineStrong
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "Week starts Monday"
              onToggled: { Settings.calendarWeekStartsMonday = !Settings.calendarWeekStartsMonday; Settings.save() }
            }
          }

          GridLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: generalTab.compactLayout ? 64 : 44
            columns: generalTab.compactLayout ? 1 : 2
            columnSpacing: 8
            rowSpacing: 4

            Text {
              text: "Timezone"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.fontPixelSize + 3
              font.weight: Font.Medium
              Layout.fillWidth: generalTab.compactLayout
              Layout.preferredWidth: generalTab.compactLayout ? 0 : 80
              Layout.minimumWidth: generalTab.compactLayout ? 0 : 80
              Layout.preferredHeight: generalTab.compactLayout ? 20 : 44
              verticalAlignment: Text.AlignVCenter
              elide: Text.ElideRight
              Layout.leftMargin: 8
            }

            TextFieldControl {
              id: timezoneField
              Layout.fillWidth: true
              Layout.minimumWidth: generalTab.compactLayout ? 0 : 160
              Layout.preferredWidth: generalTab.compactLayout ? 0 : 160
              Layout.preferredHeight: 32
              placeholder: generalTab.compactLayout ? "e.g. Asuncion" : "System default (e.g. America/Asuncion)"
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

    }

    // Compact bar contents. Settings and the power menu intentionally stay
    // outside this list so there is always a way back into the shell.
    StyledSurface {
      Layout.fillWidth: true
      Layout.preferredHeight: barContentsCol.implicitHeight + 24
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: barContentsCol
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingCompact

        Text {
          text: "Bar Contents"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.fontPixelSize + 2
          font.weight: Font.Medium
          Layout.leftMargin: Config.spacingCompact
        }

        Text {
          text: "Settings and the power menu always remain available. Wi-Fi and Bluetooth stay Settings-only."
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.fontPixelSize
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
          Layout.leftMargin: Config.spacingCompact
          Layout.rightMargin: Config.spacingCompact
        }

        GridLayout {
          Layout.fillWidth: true
          columns: generalTab.compactLayout ? 1 : 2
          columnSpacing: Config.spacingSmall
          rowSpacing: Config.spacingCompact

          Repeater {
            model: [
              { key: "ccShowLauncher", icon: "apps", title: "Launcher" },
              { key: "ccShowWorkspaces", icon: "workspaces", title: "Workspaces" },
              { key: "ccShowFocusedWindow", icon: "select_window", title: "Focused window" },
              { key: "ccShowClock", icon: "schedule", title: "Clock" },
              { key: "ccShowNotifications", icon: "notifications", title: "Notifications" },
              { key: "ccShowBattery", icon: "battery_full", title: "Battery" },
              { key: "ccShowTray", icon: "extension", title: "System tray" },
              { key: "ccShowAudio", icon: "volume_up", title: "Audio" },
              { key: "ccShowDisplay", icon: "brightness_medium", title: "Display brightness" },
              { key: "ccShowMedia", icon: "play_circle", title: "Media" },
              { key: "ccShowWeather", icon: "cloud", title: "Weather" }
            ]

            delegate: ListItem {
              required property var modelData
              Layout.fillWidth: true
              leadingIcon: modelData.icon
              title: modelData.title
              subtitle: Settings[modelData.key] ? "Shown in the bar" : "Hidden from the bar"
              accessibleName: "Show " + modelData.title
              SwitchControl {
                checked: Settings[modelData.key]
                activeColor: Colors.primary
                surfaceContainerHigh: Colors.surfaceContainerHigh
                surfaceContainerHighest: Colors.surfaceContainerHighest
                outline: Colors.styleOutlineStrong
                motionDuration: Config.motionMedium
                reducedMotion: Config.reducedMotion
                accessibleName: "Show " + modelData.title
                onToggled: {
                  Settings[modelData.key] = !Settings[modelData.key]
                  Settings.save()
                }
              }
            }
          }
        }
      }
    }

    // Weather location, privacy, and units
    StyledSurface {
      Layout.fillWidth: true
      Layout.preferredHeight: weatherCol.implicitHeight + 24
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: weatherCol
        anchors.fill: parent
      anchors.margins: Config.spacingMedium
      spacing: Config.spacingSmall

        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingMedium

          Rectangle {
            width: 24
            height: 24
            radius: Config.shapeCompact
            color: Colors.primary
            Layout.alignment: Qt.AlignVCenter
            Text {
              anchors.centerIn: parent
              text: "device_thermostat"
              color: Colors.fgPrimary
              font.family: Config.iconFont
              font.pixelSize: Config.iconSize
            }
          }

          Text {
            text: "Weather"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textBodyLargeSize
            font.weight: Font.Bold
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Item {
            width: Math.min(160, Math.max(96,
              generalTab.width - 56 - generalTab.neoControlAllowance))
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

        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          TextFieldControl {
            id: weatherLocationField
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            placeholder: "City or town (e.g. Asunción)"
            accessibleName: "Manual weather location"
            accessibleDescription: "City or town used for the weather lookup. Leave blank to use IP geolocation only when enabled."
            Component.onCompleted: input.text = Settings.weatherLocation
            onAccepted: generalTab.saveWeatherLocation()

            Connections {
              target: weatherLocationField.input
              function onActiveFocusChanged() {
                if (!weatherLocationField.input.activeFocus) generalTab.saveWeatherLocation()
              }
            }
          }

          ActionButton {
            Layout.preferredWidth: 76
            Layout.preferredHeight: 36
            labelText: "Apply"
            variant: "filled"
            accessibleName: "Apply weather location"
            onActivated: generalTab.saveWeatherLocation()
          }
        }

        Text {
          Layout.fillWidth: true
          text: Settings.weatherLocation !== ""
            ? "Using manual location: " + Settings.weatherLocation
            : "No manual location configured"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.fontPixelSize
          elide: Text.ElideRight
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "my_location"
          title: "Use IP geolocation"
          subtitle: Settings.weatherAllowIpGeolocation
            ? "Approximate location used when manual location is blank"
            : "Off; set a manual location for weather"
          SwitchControl {
            checked: Settings.weatherAllowIpGeolocation
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Use IP geolocation"
            accessibleDescription: "Allow the weather service to estimate location from your IP address when no manual location is set"
            onToggled: {
              Settings.weatherAllowIpGeolocation = !Settings.weatherAllowIpGeolocation
              Settings.save()
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          Text {
            text: "Refresh interval"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize + 1
            Layout.preferredWidth: generalTab.compactLayout ? 88 : 112
            Layout.leftMargin: Config.spacingCompact
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.weatherRefreshIntervalMinutes - 5) / 55
            stepSize: 5 / 55
            accessibleMinimumValue: 5
            accessibleMaximumValue: 60
            accessibleUnit: "minutes"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Weather refresh interval"
            accessibleDescription: "Choose how often weather data is refreshed"
            onChanged: function(val) {
              Settings.weatherRefreshIntervalMinutes = Math.max(5, Math.min(60, Math.round((5 + val * 55) / 5) * 5))
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: Settings.weatherRefreshIntervalMinutes + "m"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize + 1
            font.weight: Font.Medium
            Layout.preferredWidth: 30
            Layout.rightMargin: Config.spacingCompact
          }
        }
      }
    }
  }
}
