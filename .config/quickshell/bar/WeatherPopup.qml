import QtQuick
import QtQml
import QtQuick.Layouts
import "primitives"
import "../config"

PopupBase {
  id: root

  surfaceWidth: 620
  surfaceHeight: Math.min(contentColumn.implicitHeight + Config.spacingPage, 520)

  readonly property string city: WeatherService.city
  readonly property string temp: WeatherService.temp
  readonly property string desc: WeatherService.desc
  readonly property string status: WeatherService.status
  readonly property string statusMessage: WeatherService.statusMessage
  readonly property string updatedAt: WeatherService.updatedAt
  readonly property var forecast: WeatherService.forecast
  readonly property var hourly: WeatherService.hourly
  readonly property string humidity: WeatherService.humidity
  readonly property string feelsLike: WeatherService.feelsLike
  readonly property string wind: WeatherService.wind
  readonly property string pressure: WeatherService.pressure
  readonly property string uv: WeatherService.uv
  readonly property string precipChance: WeatherService.precipChance

  Binding {
    target: WeatherService
    property: "popupActive"
    value: root.visible
  }

  function refresh() { WeatherService.refresh() }

  ColumnLayout {
    id: contentColumn
    anchors {
      fill: parent
      margins: Config.popupPadding
    }
    spacing: Config.spacingMedium

    RowLayout {
      Layout.fillWidth: true

      Text {
        text: "Weather"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeHeadlineSmallSize
        font.weight: Config.typeStrongWeight
        font.letterSpacing: Config.typeHeadlineTracking
        lineHeight: Config.typeHeadlineSmallLineHeight
        lineHeightMode: Text.FixedHeight
      }

      Item { Layout.fillWidth: true }

      Text {
        text: root.updatedAt !== "" ? "Updated " + root.updatedAt.replace("T", " ") : ""
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelSmallSize
        font.letterSpacing: Config.typeLabelTracking
        elide: Text.ElideLeft
      }

      IconButton {
        size: 28
        iconSize: 18
        iconLabel: "refresh"
        accessibleName: "Refresh weather"
        tooltipText: "Refresh weather"
        onClicked: root.refresh()
      }
    }

    Rectangle {
      visible: root.status !== "ok"
      Layout.fillWidth: true
      Layout.preferredHeight: 48
      radius: Config.shapeMedium
      color: root.status === "offline" ? Colors.errorContainer : Colors.surfaceContainer
      border.color: root.status === "offline" ? Colors.error : Colors.styleOutline
      border.width: Config.themeBorderWidth

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Config.spacingMedium
        anchors.rightMargin: Config.spacingMedium
        spacing: Config.spacingSmall

        LoadingIndicator {
          size: 32
          contained: true
          visible: root.status === "loading"
          running: WeatherService.loading
          indicatorColor: Colors.primary
          accessibleName: "Loading weather"
          Layout.preferredWidth: 32
          Layout.preferredHeight: 32
          Layout.alignment: Qt.AlignVCenter
        }

        IconGlyph {
          visible: root.status !== "loading"
          iconLabel: "cloud_off"
          iconColor: root.status === "offline" ? Colors.fgErrorContainer : Colors.fgSurfaceVariant
          iconSize: 22
          Layout.alignment: Qt.AlignVCenter
        }

        Text {
          Layout.fillWidth: true
          text: root.statusMessage
          color: root.status === "offline" ? Colors.fgErrorContainer : Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodyMediumSize
          font.letterSpacing: Config.typeBodyTracking
          lineHeight: Config.typeBodyMediumLineHeight
          lineHeightMode: Text.FixedHeight
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
        }
      }
    }

    // Top Row: Current Weather & Hourly Forecast
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 115
      spacing: Config.spacingMedium

      Rectangle {
        Layout.preferredWidth: 220
        Layout.fillHeight: true
        radius: Config.shapeLarge
        color: Colors.surfaceContainer
        border.color: Colors.styleOutline
        border.width: Config.themeBorderWidth

        RowLayout {
          anchors.centerIn: parent
          spacing: Config.spacingLarge

          IconGlyph {
            iconLabel: Colors.weatherIcon(root.desc)
            iconSize: 64
            iconColor: Colors.weatherColor(root.desc)
            Layout.alignment: Qt.AlignVCenter
          }

          ColumnLayout {
            spacing: Config.spacingCompact
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
              text: root.temp
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeHeadlineLargeSize
              font.weight: Config.typeStrongWeight
              font.letterSpacing: Config.typeHeadlineTracking
            }

            Text {
              text: root.desc
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeBodyMediumSize
              font.weight: Config.typeMediumWeight
              font.letterSpacing: Config.typeBodyTracking
              elide: Text.ElideRight
            }

            Text {
              text: root.city || (root.status === "unavailable" ? "Location not configured" : "Location unavailable")
              color: Qt.rgba(Colors.fgSurfaceVariant.r, Colors.fgSurfaceVariant.g, Colors.fgSurfaceVariant.b, 0.5)
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelSmallSize
              font.letterSpacing: Config.typeLabelTracking
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Config.shapeLarge
        color: Colors.surfaceContainer
        border.color: Colors.styleOutline
        border.width: Config.themeBorderWidth

        Text {
          anchors.centerIn: parent
          text: root.status === "loading" ? "Loading hourly forecast..." : "Forecast unavailable"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelSmallSize
          font.letterSpacing: Config.typeLabelTracking
          visible: !root.hourly || root.hourly.length === 0
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Config.spacingSmall
          spacing: Config.spacingCompact
          visible: root.hourly && root.hourly.length > 0

          Text {
            text: "Hourly Forecast"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelSmallSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Config.spacingCompact

            Repeater {
              model: root.hourly

              delegate: Item {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 70

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: Config.spacingCompact

                  Text {
                    text: modelData.time
                    color: Colors.fgSurfaceVariant
                    font.family: Config.fontFamily
                    font.pixelSize: Config.typeLabelSmallSize
                    font.weight: Config.typeMediumWeight
                    font.letterSpacing: Config.typeLabelTracking
                    Layout.alignment: Qt.AlignHCenter
                  }

                  IconGlyph {
                    iconLabel: Colors.weatherIcon(modelData.desc)
                    iconSize: 28
                    iconColor: Colors.weatherColor(modelData.desc)
                    Layout.alignment: Qt.AlignHCenter
                  }

                  Text {
                    text: modelData.temp
                    color: Colors.fgSurface
                    font.family: Config.fontFamily
                    font.pixelSize: Config.typeLabelMediumSize
                    font.weight: Config.typeStrongWeight
                    Layout.alignment: Qt.AlignHCenter
                  }
                }
              }
            }
          }
        }
      }
    }

    // Details Grid
    GridLayout {
      columns: 3
      Layout.fillWidth: true
      columnSpacing: Config.spacingSmall
      rowSpacing: Config.spacingSmall

      Repeater {
        model: [
          { icon: "thermostat", label: "Feels Like", value: root.feelsLike, color: Colors.weatherFeelsLike },
          { icon: "water_drop", label: "Humidity", value: root.humidity, color: Colors.weatherHumidity },
          { icon: "air", label: "Wind", value: root.wind, color: Colors.weatherWind },
          { icon: "compress", label: "Pressure", value: root.pressure, color: Colors.weatherPressure },
          { icon: "sunny", label: "UV Index", value: root.uv, color: Colors.weatherUv },
          { icon: "umbrella", label: "Precip.", value: root.precipChance, color: Colors.weatherPrecipitation }
        ]

        delegate: Rectangle {
          required property var modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 50
          radius: Config.shapeMedium
          color: Colors.surfaceContainer
          border.color: Colors.styleOutline
          border.width: Config.themeBorderWidth

          RowLayout {
            anchors.centerIn: parent
            spacing: Config.spacingSmall

            IconGlyph {
              iconLabel: modelData.icon
              iconSize: 20
              iconColor: modelData.color
              Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
              spacing: 0
              Layout.alignment: Qt.AlignVCenter

              Text {
                text: modelData.label
                color: Colors.fgSurfaceVariant
                font.family: Config.fontFamily
                font.pixelSize: Config.typeLabelSmallSize
                font.weight: Config.typeMediumWeight
                font.letterSpacing: Config.typeLabelTracking
              }

              Text {
                text: modelData.value
                color: Colors.fgSurface
                font.family: Config.fontFamily
                font.pixelSize: Config.typeLabelMediumSize
                font.weight: Config.typeStrongWeight
              }
            }
          }
        }
      }
    }

    // 5-Day Forecast
    RowLayout {
      Layout.fillWidth: true
      spacing: Config.spacingSmall

      Repeater {
        model: root.forecast

        delegate: Rectangle {
          required property var modelData
          required property int index
          Layout.fillWidth: true
          Layout.preferredHeight: 95
          radius: Config.shapeMedium
          color: Colors.surfaceContainer
          border.color: Colors.styleOutline
          border.width: Config.themeBorderWidth

          ColumnLayout {
            anchors.centerIn: parent
            spacing: Config.spacingCompact

            Text {
              text: {
                var d = new Date(modelData.date + "T00:00:00");
                var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                return index === 0 ? "Today" : days[d.getDay()];
              }
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelSmallSize
              font.weight: Config.typeStrongWeight
              Layout.alignment: Qt.AlignHCenter
            }

            IconGlyph {
              iconLabel: Colors.weatherIcon(modelData.desc)
              iconSize: 32
              iconColor: Colors.weatherColor(modelData.desc)
              Layout.alignment: Qt.AlignHCenter
            }

            Text {
              text: modelData.max_temp + " / " + modelData.min_temp
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelSmallSize
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: Config.typeLabelSmallLineHeight
              lineHeightMode: Text.FixedHeight
              Layout.alignment: Qt.AlignHCenter
            }
          }
        }
      }
    }
  }
}
