import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"

PopupBase {
  id: root

  implicitWidth: 620
  implicitHeight: Math.min(contentColumn.implicitHeight + 32, 520)

  property string city: ""
  property string temp: "--°"
  property string desc: ""
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
    command: ["python3", "-u", Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.py", Settings.weatherUnits]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var info = JSON.parse(text.trim());
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

  onShown: {
    weatherProc.running = false
    weatherProc.running = true
  }

  ColumnLayout {
    id: contentColumn
    anchors {
      fill: parent
      margins: Config.popupPadding
    }
    spacing: 12

    Text {
      text: "Weather"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: (Config.fontPixelSize + 8)
      font.weight: Font.Bold
    }

    // Top Row: Current Weather & Hourly Forecast
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 115
      spacing: 12

      Rectangle {
        Layout.preferredWidth: 220
        Layout.fillHeight: true
        radius: Config.shapeLarge
        color: Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: 1

        RowLayout {
          anchors.centerIn: parent
          spacing: 16

          Text {
            text: Colors.weatherIcon(root.desc)
            font.family: Config.iconFont
            font.pixelSize: 64
            color: Colors.weatherColor(root.desc)
            Layout.alignment: Qt.AlignVCenter
          }

          ColumnLayout {
            spacing: 1
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            Text {
              text: root.temp
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: 28
              font.weight: Font.Bold
            }

            Text {
              text: root.desc
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: 13
              font.weight: Font.Medium
              elide: Text.ElideRight
            }

            Text {
              text: root.city || "Location Auto"
              color: Qt.rgba(Colors.fgSurfaceVariant.r, Colors.fgSurfaceVariant.g, Colors.fgSurfaceVariant.b, 0.5)
              font.family: Config.fontFamily
              font.pixelSize: 10
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Config.shapeLarge
        color: Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "Loading hourly forecast..."
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: 11
          visible: !root.hourly || root.hourly.length === 0
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 10
          spacing: 4
          visible: root.hourly && root.hourly.length > 0

          Text {
            text: "Hourly Forecast"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: 10
            font.weight: Font.Medium
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
              model: root.hourly

              delegate: Item {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 70

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 2

                  Text {
                    text: modelData.time
                    color: Colors.fgSurfaceVariant
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    Layout.alignment: Qt.AlignHCenter
                  }

                  Text {
                    text: Colors.weatherIcon(modelData.desc)
                    font.family: Config.iconFont
                    font.pixelSize: 28
                    color: Colors.weatherColor(modelData.desc)
                    Layout.alignment: Qt.AlignHCenter
                  }

                  Text {
                    text: modelData.temp
                    color: Colors.fgSurface
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Bold
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
      columnSpacing: 8
      rowSpacing: 8

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
          border.color: Colors.outlineVariant
          border.width: 1

          RowLayout {
            anchors.centerIn: parent
            spacing: 8

            Text {
              text: modelData.icon
              font.family: Config.iconFont
              font.pixelSize: 20
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
                font.pixelSize: 8
                font.weight: Font.Medium
              }

              Text {
                text: modelData.value
                color: Colors.fgSurface
                font.family: Config.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
              }
            }
          }
        }
      }
    }

    // 5-Day Forecast
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: root.forecast

        delegate: Rectangle {
          required property var modelData
          required property int index
          Layout.fillWidth: true
          Layout.preferredHeight: 95
          radius: Config.shapeMedium
          color: Colors.surfaceContainer
          border.color: Colors.outlineVariant
          border.width: 1

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 3

            Text {
              text: {
                var d = new Date(modelData.date + "T00:00:00");
                var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                return index === 0 ? "Today" : days[d.getDay()];
              }
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: 10
              font.weight: Font.Bold
              Layout.alignment: Qt.AlignHCenter
            }

            Text {
              text: Colors.weatherIcon(modelData.desc)
              font.family: Config.iconFont
              font.pixelSize: 32
              color: Colors.weatherColor(modelData.desc)
              Layout.alignment: Qt.AlignHCenter
            }

            Text {
              text: modelData.max_temp + " / " + modelData.min_temp
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: 9
              Layout.alignment: Qt.AlignHCenter
            }
          }
        }
      }
    }
  }
}
