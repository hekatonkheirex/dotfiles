import QtQuick
import QtQuick.Layouts
import Quickshell

          ColumnLayout {
            property QtObject root: null
            property QtObject colors_: null
            property QtObject config: null
            anchors.fill: parent
            spacing: 12
            visible: root.currentTab === 3

            // Top Row: Current Weather & Hourly Forecast
            RowLayout {
              Layout.fillWidth: true
              Layout.preferredHeight: 115
              spacing: 12

              // Current Weather Summary Card
              Rectangle {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                RowLayout {
                  anchors.centerIn: parent
                  spacing: 16

                  Text {
                    text: root.getMaterialIcon(root.weatherDesc)
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 82
                    color: root.getMaterialColor(root.weatherDesc)
                    Layout.alignment: Qt.AlignVCenter
                  }

                  ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                      text: root.weatherTemp
                      color: colors_ ? colors_.fgSurface : "#FFFFFF"
                      font.family: config ? config.fontFamily : "Roboto"
                      font.pixelSize: 32
                      font.weight: Font.Bold
                    }

                    Text {
                      text: root.weatherDesc
                      color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                      font.family: config ? config.fontFamily : "Roboto"
                      font.pixelSize: 15
                      font.weight: Font.Medium
                      elide: Text.ElideRight
                    }

                    Text {
                      text: root.weatherCity || "Location Auto"
                      color: colors_ ? Qt.rgba(colors_.fgSurfaceVariant.r, colors_.fgSurfaceVariant.g, colors_.fgSurfaceVariant.b, 0.5) : "#70CAC4D0"
                      font.family: config ? config.fontFamily : "Roboto"
                      font.pixelSize: 11
                    }
                  }
                }
              }

              // Hourly Forecast Card
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: "Loading hourly forecast..."
                  color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                  font.family: config ? config.fontFamily : "Roboto"
                  font.pixelSize: 12
                  visible: !root.weatherHourly || root.weatherHourly.length === 0
                }

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 4
                  visible: root.weatherHourly && root.weatherHourly.length > 0

                  Text {
                    text: "Hourly Forecast"
                    color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                  }

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                      model: root.weatherHourly

                      delegate: Item {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80

                        ColumnLayout {
                          anchors.centerIn: parent
                          spacing: 2

                          Text {
                            text: modelData.time
                            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                            font.family: config ? config.fontFamily : "Roboto"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignHCenter
                          }

                          Text {
                            text: root.getMaterialIcon(modelData.desc)
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 36
                            color: root.getMaterialColor(modelData.desc)
                            Layout.alignment: Qt.AlignHCenter
                          }

                          Text {
                            text: modelData.temp
                            color: colors_ ? colors_.fgSurface : "#FFFFFF"
                            font.family: config ? config.fontFamily : "Roboto"
                            font.pixelSize: 12
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

            // Weather Details Grid (6 Columns)
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                text: "Current Conditions Details"
                color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                font.family: config ? config.fontFamily : "Roboto"
                font.pixelSize: 12
                font.weight: Font.Medium
              }

              GridLayout {
                columns: 6
                Layout.fillWidth: true
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                  model: [
                    { icon: "thermostat", label: "Feels Like", value: root.weatherFeelsLike, color: "#FF5252" },
                    { icon: "water_drop", label: "Humidity", value: root.weatherHumidity, color: "#26C6DA" },
                    { icon: "air", label: "Wind", value: root.weatherWind, color: "#00F5D4" },
                    { icon: "compress", label: "Pressure", value: root.weatherPressure, color: "#BA68C8" },
                    { icon: "sunny", label: "UV Index", value: root.weatherUV, color: "#FFA726" },
                    { icon: "umbrella", label: "Precipitation", value: root.weatherPrecipChance, color: "#4FC3F7" }
                  ]

                  delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 12
                    color: colors_ ? colors_.surfaceContainer : "#25232A"
                    border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1

                    RowLayout {
                      anchors.centerIn: parent
                      spacing: 10

                      Text {
                        text: modelData.icon
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 26
                        font.weight: Font.Medium
                        color: modelData.color
                        Layout.alignment: Qt.AlignVCenter
                      }

                      ColumnLayout {
                        spacing: 0
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                          text: modelData.label
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 9
                          font.weight: Font.Medium
                        }

                        Text {
                          text: modelData.value
                          color: colors_ ? colors_.fgSurface : "#FFFFFF"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 12
                          font.weight: Font.Bold
                        }
                      }
                    }
                  }
                }
              }
            }

            // 5-Day Weather Forecast Row
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                text: "5-Day Weather Forecast"
                color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                font.family: config ? config.fontFamily : "Roboto"
                font.pixelSize: 12
                font.weight: Font.Medium
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                  model: root.weatherForecast

                  delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 115
                    radius: 12
                    color: colors_ ? colors_.surfaceContainer : "#25232A"
                    border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1

                    ColumnLayout {
                      anchors.centerIn: parent
                      spacing: 4

                      Text {
                        text: {
                          var dateStr = modelData.date;
                          var d = new Date(dateStr + "T00:00:00");
                          var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                          if (index === 0) return "Today";
                          return days[d.getDay()];
                        }
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                      }

                      Text {
                        text: root.getMaterialIcon(modelData.desc)
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 46
                        color: root.getMaterialColor(modelData.desc)
                        Layout.alignment: Qt.AlignHCenter
                      }

                      Text {
                        text: modelData.max_temp + " / " + modelData.min_temp
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignHCenter
                      }

                      Text {
                        text: modelData.desc
                        color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 8
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                        Layout.preferredWidth: 65
                        horizontalAlignment: Text.AlignHCenter
                      }
                    }
                  }
                }
              }
            }

            // Spacer to push everything to the top and prevent weird vertical stretching
            Item {
              Layout.fillHeight: true
            }
          }
