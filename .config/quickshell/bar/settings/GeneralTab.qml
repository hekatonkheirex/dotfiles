import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: generalTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false

  anchors.fill: parent
  visible: root.currentTab === 0
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: generalTab }

  function saveWeatherLocation() {
    var value = weatherLocationField.input.text.trim()
    if (Settings.weatherLocation !== value) {
      Settings.weatherLocation = value
      Settings.save()
    }
  }

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, generalTab.width - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge

    SettingsPageHeader {
      pageTitle: "General"
      subtitle: "Calendar, notification times, and weather."
    }

    GridLayout {
      Layout.fillWidth: true
      columns: generalTab.width >= 800 ? 2 : 1
      columnSpacing: Config.spacingLarge
      rowSpacing: Config.spacingLarge

    GridLayout {
      Layout.fillWidth: true
      Layout.preferredWidth: 0
      Layout.alignment: Qt.AlignTop
      columns: 1
      columnSpacing: Config.spacingLarge
      rowSpacing: Config.spacingSmall

      SettingsSectionLabel { text: "Calendar & notifications" }

      // Calendar and notification timestamp preferences
      SettingsCard {
        variant: "filled"
        Layout.fillWidth: true
        Layout.preferredHeight: clockCol.implicitHeight + Config.spacingSmall * 2
        radius: Config.settingsCardRadius
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.outlineVariant
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: clockCol
          anchors.fill: parent
          anchors.margins: Config.spacingSmall
          spacing: 0

          ListItem {
            Layout.fillWidth: true
            leadingIcon: "schedule"
            title: "24-hour notification times"
            subtitle: Settings.clock24h ? "Notification timestamps: 13:00" : "Notification timestamps: 1:00 PM"
            toggleControl: clockSwitch
            SwitchControl {
              id: clockSwitch
              checked: Settings.clock24h
              activeColor: Colors.primary
              surfaceContainerHigh: Colors.surfaceContainerHigh
              surfaceContainerHighest: Colors.surfaceContainerHighest
              outline: Colors.outline
              motionDuration: Config.motionMedium
              reducedMotion: Config.reducedMotion
              accessibleName: "24-hour notification times"
              onToggled: { Settings.clock24h = !Settings.clock24h; Settings.save() }
            }
          }


          ListItem {
            Layout.fillWidth: true
            leadingIcon: "calendar_view_week"
            title: "Week starts Monday"
            subtitle: Settings.calendarWeekStartsMonday ? "Mon - Sun" : "Sun - Sat"
            toggleControl: weekSwitch
            SwitchControl {
              id: weekSwitch
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

        }
      }

    }
    }

    // Weather location, privacy, and units
    SettingsCard {
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: weatherCol.implicitHeight + Config.spacingMedium * 2
      radius: Config.settingsCardRadius
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.outlineVariant
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
            IconGlyph {
              anchors.centerIn: parent
              iconLabel: "device_thermostat"
              iconColor: Colors.fgPrimary
              iconSize: Config.iconSize
            }
          }

          Text {
            text: "Weather"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textBodyLargeSize
            font.weight: Config.typeStrongWeight
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyLargeLineHeight
            lineHeightMode: Text.FixedHeight
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Item {
            width: Math.min(160, Math.max(96,
              generalTab.width - 56))
            height: Math.max(Config.controlHitSize,
              Config.typeLabelMediumLineHeight + (24))

            Row {
              anchors.fill: parent
              spacing: 0

              ActionButton {
                width: parent.width / 2
                height: parent.height
                labelText: "°C"
                selected: Settings.weatherUnits === "metric"
                checkable: true
                grouped: true
                groupPosition: "first"
                accessibleName: "Metric units"
                onActivated: { Settings.weatherUnits = "metric"; Settings.save() }
              }

              ActionButton {
                width: parent.width / 2
                height: parent.height
                labelText: "°F"
                selected: Settings.weatherUnits === "imperial"
                checkable: true
                grouped: true
                groupPosition: "last"
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
          font.pixelSize: Config.typeLabelMediumSize
          font.letterSpacing: Config.typeLabelTracking
          lineHeight: Config.typeLabelMediumLineHeight
          lineHeightMode: Text.FixedHeight
          elide: Text.ElideRight
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "my_location"
          title: "Use IP geolocation"
          subtitle: Settings.weatherAllowIpGeolocation
            ? "Approximate location used when manual location is blank"
            : "Off; set a manual location for weather"
          toggleControl: geolocationSwitch
          SwitchControl {
            id: geolocationSwitch
            checked: Settings.weatherAllowIpGeolocation
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
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
            font.pixelSize: Config.typeBodyMediumSize
            font.letterSpacing: Config.typeBodyTracking
            lineHeight: Config.typeBodyMediumLineHeight
            lineHeightMode: Text.FixedHeight
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
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Weather refresh interval"
            accessibleDescription: "Choose how often weather data is refreshed"
            onChanged: function(val) {
              Settings.weatherRefreshIntervalMinutes = Math.max(5, Math.min(60, Math.round((5 + val * 55) / 5) * 5))
            }
            onInteractionFinished: Settings.save()
            valueText: Settings.weatherRefreshIntervalMinutes + "m"
          }
        }
      }
    }
  }
}
