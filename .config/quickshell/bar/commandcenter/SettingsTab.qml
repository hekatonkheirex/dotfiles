import QtQuick
import QtQuick.Layouts
import Quickshell

          Flickable {
            property QtObject root: null
            property QtObject colors_: null
            property QtObject config: null
            anchors.fill: parent
            visible: root.currentTab === 4
            clip: true
            interactive: true
            contentHeight: settingsCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
              id: settingsCol
              width: parent.width
              spacing: 24
              Layout.alignment: Qt.AlignTop

            // Color Scheme Card
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 100
              radius: 16
              color: colors_ ? colors_.surfaceContainer : "#25232A"
              border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
              border.width: 1

              ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                  text: "Color Scheme"
                  color: colors_ ? colors_.fgSurface : "#FFFFFF"
                  font.family: config ? config.fontFamily : "Roboto"
                  font.pixelSize: 13
                  font.weight: Font.Bold
                }

                RowLayout {
                  spacing: 8
                  Layout.fillWidth: true

                  Repeater {
                    model: [
                      { id: "matugen", label: "Matugen",
                        swatch: ["#446829", "#795369", "#4c5d8b", "#11131a"] },
                      { id: "claude",  label: "Claude",
                        swatch: ["#BD5D3A", "#8492A3", "#B0BCB6", "#3D3929"] }
                    ]

                    delegate: Rectangle {
                      required property var modelData
                      property bool active: colors_ && colors_.colorScheme === modelData.id
                      Layout.fillWidth: true
                      height: 48
                      radius: 12
                      color: active
                        ? (colors_ ? colors_.primaryContainer : "#2d4f13")
                        : (colors_ ? colors_.surfaceContainerHigh : "#282A31")
                      border.color: active
                        ? (colors_ ? colors_.primary : "#a9d387")
                        : (colors_ ? colors_.outlineVariant : Qt.rgba(255,255,255,0.08))
                      border.width: active ? 2 : 1

                      Behavior on color { ColorAnimation { duration: 150 } }

                      RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // colour swatches preview
                        Row {
                          spacing: 3
                          Repeater {
                            model: modelData.swatch
                            Rectangle {
                              width: 14; height: 14; radius: 3
                              color: modelData
                            }
                          }
                        }

                        Text {
                          text: modelData.label
                          color: active
                            ? (colors_ ? colors_.fgPrimaryContainer : "#c5efa1")
                            : (colors_ ? colors_.fgSurface : "#FFFFFF")
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 12
                          font.weight: Font.Medium
                          Layout.fillWidth: true
                        }

                        Text {
                          visible: active
                          text: "check_circle"
                          font.family: config ? config.iconFont : "Material Symbols Outlined"
                          font.pixelSize: 16
                          color: colors_ ? colors_.primary : "#a9d387"
                        }
                      }

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (colors_) {
                            colors_.colorScheme = modelData.id
                            var mode = colors_.darkMode ? "dark" : "light"
                            Quickshell.execDetached(["sh", "-c",
                              "echo " + modelData.id + " > " + Quickshell.env("HOME") + "/.config/quickshell/colorscheme"
                              + " && $HOME/.local/bin/sync-terminal-theme.sh " + mode + " " + modelData.id])
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 24
              Layout.alignment: Qt.AlignTop

              // Bar Alignment Card
              Rectangle {
                Layout.fillWidth: false
                Layout.preferredWidth: 200
                Layout.preferredHeight: 130
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 8
                  Layout.alignment: Qt.AlignHCenter

                  Text {
                    text: "Bar Alignment"
                    color: colors_ ? colors_.fgSurface : "#FFFFFF"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                  }

                  Rectangle {
                    width: 180
                    height: 40
                    radius: 20
                    color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                    border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1

                    Row {
                      anchors.fill: parent

                      Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        radius: 20
                        color: root.isHorizontal ? (colors_ ? colors_.primary : "#BEE8C7") : "transparent"

                        Row {
                          anchors.centerIn: parent
                          spacing: 6
                          Text {
                            text: "horizontal_split"
                            font.family: config ? config.iconFont : "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: root.isHorizontal ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                          }
                          Text {
                            text: "Horiz"
                            font.family: config ? config.fontFamily : "Roboto"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: root.isHorizontal ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                          }
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: { if (!root.isHorizontal) root.toggleHorizontal() }
                        }
                      }

                      Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        radius: 20
                        color: !root.isHorizontal ? (colors_ ? colors_.primary : "#BEE8C7") : "transparent"

                        Row {
                          anchors.centerIn: parent
                          spacing: 6
                          Text {
                            text: "vertical_split"
                            font.family: config ? config.iconFont : "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: !root.isHorizontal ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                          }
                          Text {
                            text: "Vert"
                            font.family: config ? config.fontFamily : "Roboto"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: !root.isHorizontal ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                          }
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: { if (root.isHorizontal) root.toggleHorizontal() }
                        }
                      }
                    }
                  }
                }
              }

              // Light/Dark Mode Card
              Rectangle {
                Layout.fillWidth: false
                Layout.preferredWidth: 200
                Layout.preferredHeight: 130
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 8
                  Layout.alignment: Qt.AlignHCenter

                  Text {
                    text: "Light/Dark Mode"
                    color: colors_ ? colors_.fgSurface : "#FFFFFF"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                  }

                  Rectangle {
                    width: 180
                    height: 40
                    radius: 20
                    color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                    border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1

                    Row {
                      anchors.fill: parent

                      Repeater {
                        model: [
                          { value: 0, icon: "brightness_auto", label: "Auto" },
                          { value: 1, icon: "light_mode", label: "Light" },
                          { value: 2, icon: "dark_mode", label: "Dark" }
                        ]

                        delegate: Rectangle {
                          required property var modelData
                          width: parent.width / 3
                          height: parent.height
                          radius: 20
                          color: (colors_ && colors_.themePreference === modelData.value) ? colors_.primary : "transparent"

                          Column {
                            anchors.centerIn: parent
                            spacing: 1
                            Text {
                              anchors.horizontalCenter: parent.horizontalCenter
                              text: modelData.icon
                              font.family: config ? config.iconFont : "Material Symbols Outlined"
                              font.pixelSize: 15
                              color: (colors_ && colors_.themePreference === modelData.value) ? colors_.fgPrimary : colors_.fgSurfaceVariant
                            }
                            Text {
                              anchors.horizontalCenter: parent.horizontalCenter
                              text: modelData.label
                              font.family: config ? config.fontFamily : "Roboto"
                              font.pixelSize: 8
                              font.weight: Font.Bold
                              color: (colors_ && colors_.themePreference === modelData.value) ? colors_.fgPrimary : colors_.fgSurfaceVariant
                            }
                          }

                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              if (colors_) {
                                colors_.themePreference = modelData.value
                                var modes = ["auto", "light", "dark"]
                                Quickshell.execDetached(["/bin/sh", "-c", "$HOME/.local/bin/sync-theme-mode.sh " + modes[modelData.value]])
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }

              // Accent Color Picker Card
              Rectangle {
                Layout.fillWidth: false
                Layout.preferredWidth: 294
                Layout.preferredHeight: 130
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 8

                  RowLayout {
                    spacing: 12
                    Layout.fillWidth: true

                    Rectangle {
                      width: 24
                      height: 24
                      radius: 6
                      color: colors_ ? colors_.primary : "#D0BCFF"
                      Layout.alignment: Qt.AlignVCenter
                      Text {
                        anchors.centerIn: parent
                        text: "palette"
                        color: colors_ ? colors_.fgPrimary : "#0F3C2C"
                        font.family: config ? config.iconFont : "Material Symbols Outlined"
                        font.pixelSize: 16
                      }
                    }

                    ColumnLayout {
                      spacing: 1
                      Layout.fillWidth: true
                      Layout.alignment: Qt.AlignVCenter
                      Text {
                        text: "Accent Color"
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                      }
                      Text {
                        text: "Choose a color"
                        color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 9
                      }
                    }

                    Rectangle {
                      width: 48
                      height: 28
                      radius: 14
                      color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                      border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                      border.width: 1
                      Layout.alignment: Qt.AlignVCenter
                      Rectangle {
                        width: 20
                        height: 20
                        radius: 5
                        anchors.centerIn: parent
                        color: colors_ ? colors_.primary : "#D0BCFF"
                      }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.colorDialog.open() }
                      }
                    }
                  }

                  Flow {
                    spacing: 6
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter

                    Repeater {
                      model: [
                        { name: "Blue",    hex: "6750A4" },
                        { name: "Green",   hex: "4F8A4F" },
                        { name: "Yellow",  hex: "E6A23C" },
                        { name: "Red",     hex: "C44545" },
                        { name: "Purple",  hex: "9C4F96" },
                        { name: "Orange",  hex: "D97A3B" }
                      ]

                      ColumnLayout {
                        spacing: 3
                        Layout.alignment: Qt.AlignHCenter

                        Rectangle {
                          width: 40
                          height: 28
                          radius: 6
                          color: "#" + modelData.hex
                          Layout.alignment: Qt.AlignHCenter
                          border.width: 0

                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.opacity = 0.8
                            onExited: parent.opacity = 1.0
                            onClicked: { root.applyPresetColor(modelData.hex) }
                          }
                        }

                        Text {
                          text: modelData.name
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 7
                          horizontalAlignment: Text.AlignHCenter
                          Layout.alignment: Qt.AlignHCenter
                        }
                      }
                    }
                  }
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 16

              // Caffeine Box
              Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 120
                radius: 16
                color: root.caffeineOn ? (colors_ ? colors_.primary : "#BEE8C7") : (colors_ ? colors_.surfaceContainer : "#25232A")
                border.color: root.caffeineOn ? "transparent" : (colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1))
                border.width: 1

                Behavior on color {
                  ColorAnimation { duration: config ? config.animationDuration : 150 }
                }

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 4

                  Text {
                    text: "coffee"
                    font.family: config ? config.iconFont : "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: root.caffeineOn ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                    Layout.alignment: Qt.AlignHCenter
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
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

              // System Diagnostics Card
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 8

                  Text {
                    text: "System Diagnostics & Resources"
                    color: colors_ ? colors_.fgSurface : "#FFFFFF"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                  }

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    // CPU usage column
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 4

                      RowLayout {
                        spacing: 6
                        Text {
                          text: "memory"
                          font.family: config ? config.iconFont : "Material Symbols Outlined"
                          font.pixelSize: 16
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                        Text {
                          text: "CPU Usage"
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 11
                          font.weight: Font.Medium
                        }
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                        Rectangle {
                          width: parent.width * (root.statsCpu / 100.0)
                          height: parent.height
                          radius: 4
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                      }

                      Text {
                        text: Math.round(root.statsCpu) + "%"
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                      }
                    }

                    // RAM usage column
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 4

                      RowLayout {
                        spacing: 6
                        Text {
                          text: "database"
                          font.family: config ? config.iconFont : "Material Symbols Outlined"
                          font.pixelSize: 16
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                        Text {
                          text: "Memory (RAM)"
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 11
                          font.weight: Font.Medium
                        }
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                        Rectangle {
                          width: parent.width * root.statsRamPct
                          height: parent.height
                          radius: 4
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                      }

                      Text {
                        text: root.statsRamStr + " (" + Math.round(root.statsRamPct * 100) + "%)"
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                      }
                    }

                    // Disk usage column
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 4

                      RowLayout {
                        spacing: 6
                        Text {
                          text: "storage"
                          font.family: config ? config.iconFont : "Material Symbols Outlined"
                          font.pixelSize: 16
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                        Text {
                          text: "Disk Storage"
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 11
                          font.weight: Font.Medium
                        }
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                        Rectangle {
                          width: parent.width * root.statsDiskPct
                          height: parent.height
                          radius: 4
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                      }

                      Text {
                        text: root.statsDiskStr + " (" + Math.round(root.statsDiskPct * 100) + "%)"
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                      }
                    }
                  }
                }
              }
            }
          }
        }
