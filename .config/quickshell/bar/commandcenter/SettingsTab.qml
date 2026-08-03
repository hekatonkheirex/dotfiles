import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../../config"

          Flickable {
            property QtObject root: null
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

            RowLayout {
              Layout.fillWidth: true
              spacing: 24
              Layout.alignment: Qt.AlignTop

              // Bar Alignment Card
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.preferredHeight: 104
                radius: 16
                color: Colors.surfaceContainer
                border.color: Colors.outlineVariant
                border.width: 1

                ColumnLayout {
                  anchors.top: parent.top
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.topMargin: 16
                  spacing: 8
                  Layout.alignment: Qt.AlignHCenter

                  Text {
                    text: "Bar Alignment"
                    color: Colors.fgSurface
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                  }

                  Item {
                    width: 180
                    height: 40

                    Row {
                      anchors.fill: parent

                      Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        radius: 20
                        color: root.isHorizontal ? (Colors.primary) : "transparent"

                        Row {
                          anchors.centerIn: parent
                          spacing: 6
                          Text {
                            text: "horizontal_split"
                            font.family: Config.iconFont
                            font.pixelSize: 16
                            color: root.isHorizontal ? (Colors.fgPrimary) : (Colors.fgSurfaceVariant)
                          }
                          Text {
                            text: "Horiz"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: root.isHorizontal ? (Colors.fgPrimary) : (Colors.fgSurfaceVariant)
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
                        color: !root.isHorizontal ? (Colors.primary) : "transparent"

                        Row {
                          anchors.centerIn: parent
                          spacing: 6
                          Text {
                            text: "vertical_split"
                            font.family: Config.iconFont
                            font.pixelSize: 16
                            color: !root.isHorizontal ? (Colors.fgPrimary) : (Colors.fgSurfaceVariant)
                          }
                          Text {
                            text: "Vert"
                            font.family: Config.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: !root.isHorizontal ? (Colors.fgPrimary) : (Colors.fgSurfaceVariant)
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
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.preferredHeight: 104
                radius: 16
                color: Colors.surfaceContainer
                border.color: Colors.outlineVariant
                border.width: 1

                ColumnLayout {
                  anchors.top: parent.top
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.topMargin: 16
                  spacing: 8
                  Layout.alignment: Qt.AlignHCenter

                  Text {
                    text: "Light/Dark Mode"
                    color: Colors.fgSurface
                    font.family: Config.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                  }

                  Item {
                    width: 180
                    height: 40

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
                          color: (Colors.themePreference === modelData.value) ? Colors.primary : "transparent"

                          Column {
                            anchors.centerIn: parent
                            spacing: 1
                            Text {
                              anchors.horizontalCenter: parent.horizontalCenter
                              text: modelData.icon
                              font.family: Config.iconFont
                              font.pixelSize: 15
                              color: (Colors.themePreference === modelData.value) ? Colors.fgPrimary : Colors.fgSurfaceVariant
                            }
                            Text {
                              anchors.horizontalCenter: parent.horizontalCenter
                              text: modelData.label
                              font.family: Config.fontFamily
                              font.pixelSize: 8
                              font.weight: Font.Bold
                              color: (Colors.themePreference === modelData.value) ? Colors.fgPrimary : Colors.fgSurfaceVariant
                            }
                          }

                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              Colors.themePreference = modelData.value
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

            RowLayout {
              Layout.fillWidth: true
              spacing: 24

              // Toggle group card — one shared surface, plain list rows inside (M3: don't box each item, do box the group)
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.preferredHeight: 113
                radius: 16
                color: Colors.surfaceContainer
                border.color: Colors.outlineVariant
                border.width: 1

                ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 0

                // Full bar list item
                RowLayout {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 44
                  spacing: 12

                  Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: Colors.primary
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                      anchors.centerIn: parent
                      text: "dock_to_bottom"
                      color: Colors.fgPrimary
                      font.family: Config.iconFont
                      font.pixelSize: 16
                    }
                  }

                  ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                      text: root.fullBar ? "Full bar" : "Auto-collapse"
                      color: Colors.fgSurface
                      font.family: Config.fontFamily
                      font.pixelSize: 13
                      font.weight: Font.Bold
                    }
                    Text {
                      text: root.fullBar ? "Always visible" : "Expand on hover"
                      color: Colors.fgSurfaceVariant
                      font.family: Config.fontFamily
                      font.pixelSize: 9
                    }
                  }

                  SwitchControl {
                    checked: root.fullBar
                    activeColor: Colors.primary
                    surfaceContainerHigh: Colors.surfaceContainerHigh
                    surfaceContainerHighest: Colors.surfaceContainerHighest
                    outline: Colors.outline
                    motionDuration: Config.motionMedium
                    reducedMotion: Config.reducedMotion
                    accessibleName: "Full bar mode"
                    Layout.alignment: Qt.AlignVCenter
                    onToggled: root.toggleFullBar()
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.topMargin: 4
                  Layout.bottomMargin: 4
                  height: 1
                  color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
                }

                // Reduced motion list item
                RowLayout {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 44
                  spacing: 12

                  Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: Colors.primary
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                      anchors.centerIn: parent
                      text: "motion_photos_off"
                      color: Colors.fgPrimary
                      font.family: Config.iconFont
                      font.pixelSize: 16
                    }
                  }

                  ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Text {
                      text: "Reduced motion"
                      color: Colors.fgSurface
                      font.family: Config.fontFamily
                      font.pixelSize: 13
                      font.weight: Font.Bold
                    }
                    Text {
                      text: Config.reducedMotion ? "Animations minimized" : "Expressive transitions"
                      color: Colors.fgSurfaceVariant
                      font.family: Config.fontFamily
                      font.pixelSize: 9
                    }
                  }

                  SwitchControl {
                    checked: Config.reducedMotion
                    activeColor: Colors.primary
                    surfaceContainerHigh: Colors.surfaceContainerHigh
                    surfaceContainerHighest: Colors.surfaceContainerHighest
                    outline: Colors.outline
                    motionDuration: Config.motionMedium
                    reducedMotion: Config.reducedMotion
                    accessibleName: "Reduced motion"
                    Layout.alignment: Qt.AlignVCenter
                    onToggled: {
                      Settings.reduceMotion = !Settings.reduceMotion
                      Settings.save()
                    }
                  }
                }
              }

              // Caffeine Box
              Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 113
                radius: 16
                color: root.caffeineOn ? (Colors.primary) : (Colors.surfaceContainer)
                border.color: root.caffeineOn ? "transparent" : (Colors.outlineVariant)
                border.width: 1

                Behavior on color {
                  ColorAnimation { duration: Config.animationDuration}
                }

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 4

                  Text {
                    text: "coffee"
                    font.family: Config.iconFont
                    font.pixelSize: 32
                    color: root.caffeineOn ? (Colors.fgPrimary) : (Colors.fgSurfaceVariant)
                    Layout.alignment: Qt.AlignHCenter
                  }

                  Text {
                    text: "Caffeine"
                    color: root.caffeineOn ? (Colors.fgPrimary) : (Colors.fgSurfaceVariant)
                    font.family: Config.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
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
            }

            // System Diagnostics Card
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 120
                radius: 16
                color: Colors.surfaceContainer
                border.color: Colors.outlineVariant
                border.width: 1

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 8

                  Text {
                    text: "System Diagnostics & Resources"
                    color: Colors.fgSurface
                    font.family: Config.fontFamily
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
                          font.family: Config.iconFont
                          font.pixelSize: 16
                          color: Colors.primary
                        }
                        Text {
                          text: "CPU Usage"
                          color: Colors.fgSurfaceVariant
                          font.family: Config.fontFamily
                          font.pixelSize: 11
                          font.weight: Font.Medium
                        }
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Colors.surfaceContainerHigh
                        Rectangle {
                          width: parent.width * (root.statsCpu / 100.0)
                          height: parent.height
                          radius: 4
                          color: Colors.primary
                        }
                      }

                      Text {
                        text: Math.round(root.statsCpu) + "%"
                        color: Colors.fgSurface
                        font.family: Config.fontFamily
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
                          font.family: Config.iconFont
                          font.pixelSize: 16
                          color: Colors.primary
                        }
                        Text {
                          text: "Memory (RAM)"
                          color: Colors.fgSurfaceVariant
                          font.family: Config.fontFamily
                          font.pixelSize: 11
                          font.weight: Font.Medium
                        }
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Colors.surfaceContainerHigh
                        Rectangle {
                          width: parent.width * root.statsRamPct
                          height: parent.height
                          radius: 4
                          color: Colors.primary
                        }
                      }

                      Text {
                        text: root.statsRamStr + " (" + Math.round(root.statsRamPct * 100) + "%)"
                        color: Colors.fgSurface
                        font.family: Config.fontFamily
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
                          font.family: Config.iconFont
                          font.pixelSize: 16
                          color: Colors.primary
                        }
                        Text {
                          text: "Disk Storage"
                          color: Colors.fgSurfaceVariant
                          font.family: Config.fontFamily
                          font.pixelSize: 11
                          font.weight: Font.Medium
                        }
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: Colors.surfaceContainerHigh
                        Rectangle {
                          width: parent.width * root.statsDiskPct
                          height: parent.height
                          radius: 4
                          color: Colors.primary
                        }
                      }

                      Text {
                        text: root.statsDiskStr + " (" + Math.round(root.statsDiskPct * 100) + "%)"
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
          }
        }
