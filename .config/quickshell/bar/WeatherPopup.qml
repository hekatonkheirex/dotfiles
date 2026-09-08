import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

PopupBase {
  id: root

  surfaceWidth: 620
  surfaceHeight: Math.min(contentColumn.implicitHeight + Config.spacingPage, 520)

  property string city: ""
  property string temp: "--°"
  property string desc: ""
  property string status: "loading"
  property string statusMessage: "Loading weather..."
  property string updatedAt: ""
  property var forecast: []
  property var hourly: []
  property string humidity: "--%"
  property string feelsLike: "--"
  property string wind: "--"
  property string pressure: "--"
  property string uv: "--"
  property string precipChance: "--%"

  Process {
    id: weatherProc
    command: [
      "python3",
      "-u",
      Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.py",
      Settings.weatherUnits,
      Settings.weatherLocation,
      Settings.weatherAllowIpGeolocation ? "1" : "0"
    ]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var info = JSON.parse(text.trim());
          root.status = info.status || "ok";
          root.statusMessage = info.message || "";
          root.updatedAt = info.updated_at || "";
          root.city = info.city;
          root.temp = info.current_temp;
          root.desc = info.current_desc;
          root.humidity = info.humidity;
          root.feelsLike = info.apparent_temp;
          root.wind = info.wind_speed;
          root.pressure = info.pressure;
          root.uv = info.uv_index;
          root.precipChance = info.precipitation_chance;
          root.forecast = info.forecast;
          root.hourly = info.hourly;
        } catch (e) { print("WeatherPopup parse error:", e) }
      }
    }
  }

  function refresh() {
    weatherProc.running = false
    weatherProc.running = true
  }

  Connections {
    target: Settings
    function onWeatherUnitsChanged() { if (root.visible) root.refresh() }
    function onWeatherLocationChanged() { if (root.visible) root.refresh() }
    function onWeatherAllowIpGeolocationChanged() { if (root.visible) root.refresh() }
    function onWeatherRefreshIntervalMinutesChanged() { if (root.visible) root.refresh() }
  }

  onShown: {
    root.refresh()
  }

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
          running: weatherProc.running
          indicatorColor: Colors.primary
          accessibleName: "Loading weather"
          Layout.preferredWidth: 32
          Layout.preferredHeight: 32
          Layout.alignment: Qt.AlignVCenter
        }

        Text {
          visible: root.status !== "loading"
          text: "cloud_off"
          color: root.status === "offline" ? Colors.fgErrorContainer : Colors.fgSurfaceVariant
          font.family: Config.iconFont
          font.pixelSize: 22
          font.variableAxes: Config.iconVariableAxes(0, 22)
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

          Text {
            text: Colors.weatherIcon(root.desc)
            font.family: Config.iconFont
            font.pixelSize: 64
            font.variableAxes: Config.iconVariableAxes(0, 64)
            color: Colors.weatherColor(root.desc)
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

                  Text {
                    text: Colors.weatherIcon(modelData.desc)
                    font.family: Config.iconFont
                    font.pixelSize: 28
                    font.variableAxes: Config.iconVariableAxes(0, 28)
                    color: Colors.weatherColor(modelData.desc)
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

            Text {
              text: modelData.icon
              font.family: Config.iconFont
              font.pixelSize: 20
              font.variableAxes: Config.iconVariableAxes(0, 20)
              color: modelData.color
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

            Text {
              text: Colors.weatherIcon(modelData.desc)
              font.family: Config.iconFont
              font.pixelSize: 32
              font.variableAxes: Config.iconVariableAxes(0, 32)
              color: Colors.weatherColor(modelData.desc)
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
