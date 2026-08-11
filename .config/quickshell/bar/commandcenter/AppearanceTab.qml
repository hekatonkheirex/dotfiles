import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: appearanceTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  anchors.fill: parent
  visible: root.currentTab === 2
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  property string themeStatus: ""

  onVisibleChanged: {
  }

  function themeModeName() {
    return Settings.themePreference === 1 ? "light"
      : (Settings.themePreference === 2 ? "dark" : "auto")
  }

  function reloadTheme() {
    appearanceTab.themeStatus = "Reloading theme..."
    reloadThemeProc.running = false
    reloadThemeProc.running = true
  }

  Process {
    id: reloadThemeProc
    command: [
      Quickshell.env("HOME") + "/.local/bin/sync-theme-mode.sh",
      appearanceTab.themeModeName()
    ]
    running: false
    onExited: (exitCode) => {
      appearanceTab.themeStatus = exitCode === 0
        ? "Theme synchronized"
        : "Theme synchronization failed"
    }
  }


  ColumnLayout {
    id: mainColumn
    width: appearanceTab.width
    spacing: Config.spacingLarge

    GridLayout {
      Layout.fillWidth: true
      columns: appearanceTab.compactLayout ? 1 : 2
      columnSpacing: Config.spacingLarge
      rowSpacing: Config.spacingLarge

      // Theme card
      Rectangle {
        Layout.column: 0
        Layout.row: 0
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: Math.max(184, themeColumn.implicitHeight + 24)
        radius: Config.shapeLarge
        color: Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: 1

        ColumnLayout {
          id: themeColumn
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.topMargin: 16
          spacing: Config.spacingSmall
          Layout.alignment: Qt.AlignHCenter

          Text {
            text: "Light/Dark Mode"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textTitleSize
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignHCenter
          }

          Item {
            width: appearanceTab.compactLayout ? 160 : 180
            height: 40

            Row {
              anchors.fill: parent
              spacing: 0

              Repeater {
                model: [
                  { value: 0, icon: "brightness_auto", label: "Auto" },
                  { value: 1, icon: "light_mode", label: "Light" },
                  { value: 2, icon: "dark_mode", label: "Dark" }
                ]

                delegate: ActionButton {
                  required property var modelData
                  width: parent.width / 3
                  height: parent.height
                  iconLabel: modelData.icon
                  iconSize: 15
                  labelText: modelData.label
                  selected: Settings.themePreference === modelData.value
                  accessibleName: modelData.label + " theme"
                  onActivated: {
                    Settings.themePreference = modelData.value
                    Settings.save()
                  }
                }
              }
            }
          }

          Text {
            text: "Palette source: " + Colors.paletteSource
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize
            Layout.alignment: Qt.AlignHCenter
          }

          ActionButton {
            Layout.preferredWidth: 90
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignHCenter
            radius: height / 2
            iconLabel: "sync"
            iconSize: Config.iconSize - 2
            labelText: "Reload theme"
            accessibleName: "Reload theme"
            accessibleDescription: "Synchronize GTK, Qt, terminal, and Niri theme outputs"
            onActivated: appearanceTab.reloadTheme()
          }

          Text {
            text: appearanceTab.themeStatus
            color: appearanceTab.themeStatus.indexOf("failed") >= 0 ? Colors.error : Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Math.max(8, Config.fontPixelSize - 1)
            visible: appearanceTab.themeStatus !== ""
            Layout.alignment: Qt.AlignHCenter
          }
        }
      }

      ColumnLayout {
        Layout.column: appearanceTab.compactLayout ? 0 : 1
        Layout.row: appearanceTab.compactLayout ? 1 : 0
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        spacing: Config.spacingLarge

        // Bar Alignment card
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredWidth: 0
          Layout.preferredHeight: 104
          radius: Config.shapeLarge
          color: Colors.surfaceContainer
          border.color: Colors.outlineVariant
          border.width: 1

          ColumnLayout {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 16
            spacing: Config.spacingSmall
            Layout.alignment: Qt.AlignHCenter

            Text {
              text: "Bar Alignment"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.textTitleSize
              font.weight: Font.Bold
              Layout.alignment: Qt.AlignHCenter
            }

            Item {
              width: appearanceTab.compactLayout ? 160 : 180
              height: 40

              Row {
                anchors.fill: parent
                spacing: 0

                ActionButton {
                  width: parent.width / 2
                  height: parent.height
                  iconLabel: "horizontal_split"
                  iconSize: 15
                  labelText: "Horiz"
                  selected: root.isHorizontal
                  accessibleName: "Horizontal bar"
                  accessibleDescription: root.isHorizontal ? "Selected" : "Switch bar to horizontal"
                  onActivated: { if (!root.isHorizontal) root.toggleHorizontal() }
                }

                ActionButton {
                  width: parent.width / 2
                  height: parent.height
                  iconLabel: "vertical_split"
                  iconSize: 15
                  labelText: "Vert"
                  selected: !root.isHorizontal
                  accessibleName: "Vertical bar"
                  accessibleDescription: !root.isHorizontal ? "Selected" : "Switch bar to vertical"
                  onActivated: { if (root.isHorizontal) root.toggleHorizontal() }
                }
              }
            }
          }
        }

        // Full bar toggle
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredWidth: 0
          Layout.preferredHeight: 64
          radius: Config.shapeLarge
          color: Colors.surfaceContainer
          border.color: Colors.outlineVariant
          border.width: 1

          Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 0

            Item {
              width: parent.width / 3
              height: parent.height

              Rectangle {
                anchors.centerIn: parent
                width: 24
                height: 24
                radius: Config.shapeCompact
                color: Colors.primary

                Text {
                  anchors.centerIn: parent
                  text: "dock_to_bottom"
                  color: Colors.fgPrimary
                  font.family: Config.iconFont
                  font.pixelSize: Config.iconSize
                }
              }
            }

            Item {
              width: parent.width / 3
              height: parent.height

              ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                height: implicitHeight
                spacing: 1

                Text {
                  Layout.fillWidth: true
                  text: root.fullBar ? "Full bar" : "Auto-collapse"
                  color: Colors.fgSurface
                  font.family: Config.fontFamily
                  font.pixelSize: Config.textBodyLargeSize
                  font.weight: Font.Bold
                  horizontalAlignment: Text.AlignHCenter
                }

                Text {
                  Layout.fillWidth: true
                  text: root.fullBar ? "Always visible" : "Expand on hover"
                  color: Colors.fgSurfaceVariant
                  font.family: Config.fontFamily
                  font.pixelSize: Config.fontPixelSize
                  horizontalAlignment: Text.AlignHCenter
                }
              }
            }

            Item {
              width: parent.width / 3
              height: parent.height

              SwitchControl {
                anchors.centerIn: parent
                checked: root.fullBar
                activeColor: Colors.primary
                surfaceContainerHigh: Colors.surfaceContainerHigh
                surfaceContainerHighest: Colors.surfaceContainerHighest
                outline: Colors.outline
                motionDuration: Config.motionMedium
                reducedMotion: Config.reducedMotion
                accessibleName: "Full bar mode"
                onToggled: root.toggleFullBar()
              }
            }
          }
        }
      }
    }

    // Font / Icon / Spacing sliders
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: sizingColumn.implicitHeight + 24
      radius: Config.shapeLarge
      color: Colors.surfaceContainer
      border.color: Colors.outlineVariant
      border.width: 1

      ColumnLayout {
        id: sizingColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: Config.spacingSmall

        Text {
          text: "Sizing"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.textTitleSize
          font.weight: Font.Bold
        }

        // Font size
        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingMedium

          Text {
            text: "Font Size"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.textBodySize
            Layout.preferredWidth: appearanceTab.compactLayout ? 64 : 90
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.fontPixelSize - 7) / 9
            stepSize: 1 / 9
            accessibleMinimumValue: 7
            accessibleMaximumValue: 16
            accessibleUnit: "px"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Font size"
            accessibleDescription: "Adjust global font size"
            onChanged: function(val) {
              Settings.fontPixelSize = Math.round(7 + val * 9)
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: Settings.fontPixelSize + "px"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: 11
            Layout.preferredWidth: 34
          }
        }

        // Icon size
        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingMedium

          Text {
            text: "Icon Size"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.textBodySize
            Layout.preferredWidth: appearanceTab.compactLayout ? 64 : 90
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.iconSize - 12) / 16
            stepSize: 1 / 16
            accessibleMinimumValue: 12
            accessibleMaximumValue: 28
            accessibleUnit: "px"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Icon size"
            accessibleDescription: "Adjust global icon size"
            onChanged: function(val) {
              Settings.iconSize = Math.round(12 + val * 16)
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: Settings.iconSize + "px"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: 11
            Layout.preferredWidth: 34
          }
        }

        // Spacing
        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingMedium

          Text {
            text: "Spacing"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.textBodySize
            Layout.preferredWidth: appearanceTab.compactLayout ? 64 : 90
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.spacingScale - 0.75) / 0.75
            stepSize: 0.05 / 0.75
            accessibleMinimumValue: 75
            accessibleMaximumValue: 150
            accessibleUnit: "%"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Spacing"
            accessibleDescription: "Adjust global layout spacing"
            onChanged: function(val) {
              Settings.spacingScale = Math.round((0.75 + val * 0.75) * 20) / 20
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: Math.round(Settings.spacingScale * 100) + "%"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: 11
            Layout.preferredWidth: 34
          }
        }

        // Bar size
        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingMedium

          Text {
            text: "Bar Size"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.textBodySize
            Layout.preferredWidth: appearanceTab.compactLayout ? 64 : 90
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.barSize - 28) / 28
            stepSize: 2 / 28
            accessibleMinimumValue: 28
            accessibleMaximumValue: 56
            accessibleUnit: "px"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Bar size"
            accessibleDescription: "Adjust the bar's thickness and widget size"
            onChanged: function(val) {
              Settings.barSize = Math.round(28 + val * 28)
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: Settings.barSize + "px"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: 11
            Layout.preferredWidth: 34
          }
        }
      }
    }

  }
}
