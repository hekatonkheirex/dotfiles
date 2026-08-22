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
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  readonly property int neoControlAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset * 2
    : 0
  readonly property int optionButtonGap: Config.themeOptionGap
  readonly property int optionButtonHeight: Config.neoBrutalism ? 52 : (Config.nothingDesign ? 44 : 40)
  anchors.fill: parent
  visible: root.currentTab === 2
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + appearanceTab.neoShadowAllowance
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  property string themeStatus: ""
  property bool resetConfirm: false

  onVisibleChanged: {
  }

  function themeModeName() {
    return Settings.themePreference === 1 ? "light"
      : (Settings.themePreference === 2 ? "dark" : "auto")
  }

  function reloadTheme() {
    appearanceTab.themeStatus = "Reloading colors..."
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
        ? "Colors synchronized"
        : "Color synchronization failed"
    }
  }


  ColumnLayout {
    id: mainColumn
    width: Math.max(0, appearanceTab.width - appearanceTab.neoShadowAllowance)
    spacing: Config.spacingLarge + appearanceTab.neoShadowAllowance

    GridLayout {
      Layout.fillWidth: true
      columns: appearanceTab.compactLayout ? 1 : 2
      columnSpacing: Config.spacingLarge
      rowSpacing: Config.spacingLarge

      // UI Style card
      StyledSurface {
        Layout.column: 0
        Layout.row: 0
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: Math.max(184, uiStyleColumn.implicitHeight + 24)
        radius: Config.shapeLarge
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: uiStyleColumn
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.topMargin: 16
          spacing: Config.spacingSmall
          Layout.alignment: Qt.AlignHCenter

          Text {
            text: "UI Style"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textTitleSize
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignHCenter
          }

            Item {
              width: (appearanceTab.compactLayout ? 200 : 220)
                - appearanceTab.neoControlAllowance
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredHeight: appearanceTab.optionButtonHeight
              height: appearanceTab.optionButtonHeight

            Row {
              anchors.fill: parent
              spacing: appearanceTab.optionButtonGap

              Repeater {
                model: [
                  { value: "material3", icon: "auto_awesome", label: "Material" },
                  { value: "neo-brutalism", icon: "square", label: "Neo" },
                  { value: "nothing", icon: "grid_3x3", label: "Nothing" }
                ]

                delegate: ActionButton {
                  required property var modelData
                  width: (parent.width - appearanceTab.optionButtonGap * 2) / 3
                  height: parent.height
                  iconLabel: modelData.icon
                  iconSize: 15
                  labelText: modelData.label
                  selected: Settings.themeStyle === modelData.value
                  accessibleName: modelData.label + " UI style"
                  accessibleDescription: selected ? "Selected" : "Use the " + modelData.label + " UI style"
                  onActivated: {
                    Settings.themeStyle = modelData.value
                    Settings.save()
                  }
                }
              }
            }
          }

          Text {
            text: Settings.themeStyle === "neo-brutalism"
              ? "Pastel fills, bold ink borders, and hard offset shadows"
              : (Settings.themeStyle === "nothing"
                ? "Neutral surfaces, rounded controls, and signal accents"
                : "Rounded surfaces, tonal elevation, and expressive motion")
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Math.max(8, Config.fontPixelSize - 1)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.maximumWidth: appearanceTab.compactLayout ? 220 : 260
            Layout.alignment: Qt.AlignHCenter
          }
        }
      }

      // Color scheme card
      StyledSurface {
        Layout.column: appearanceTab.compactLayout ? 0 : 1
        Layout.row: appearanceTab.compactLayout ? 1 : 0
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: Math.max(184, colorSchemeColumn.implicitHeight + 24)
        radius: Config.shapeLarge
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: colorSchemeColumn
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.topMargin: 16
          spacing: Config.spacingSmall
          Layout.alignment: Qt.AlignHCenter

          Text {
            text: "Color Scheme"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textTitleSize
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignHCenter
          }

            Item {
              width: (appearanceTab.compactLayout ? 160 : 180)
                - appearanceTab.neoControlAllowance
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredHeight: appearanceTab.optionButtonHeight
              height: appearanceTab.optionButtonHeight

            Row {
              anchors.fill: parent
              spacing: appearanceTab.optionButtonGap

              Repeater {
                model: [
                  { value: 0, icon: "brightness_auto", label: "Auto" },
                  { value: 1, icon: "light_mode", label: "Light" },
                  { value: 2, icon: "dark_mode", label: "Dark" }
                ]

                delegate: ActionButton {
                  required property var modelData
                  width: (parent.width - appearanceTab.optionButtonGap * 2) / 3
                  height: parent.height
                  iconLabel: modelData.icon
                  iconSize: 15
                  labelText: modelData.label
                  selected: Settings.themePreference === modelData.value
                  accessibleName: modelData.label + " color scheme"
                  onActivated: {
                    Settings.themePreference = modelData.value
                    Settings.save()
                  }
                }
              }
            }
          }

          Text {
            text: "Color palette: " + Colors.paletteSource
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize
            Layout.alignment: Qt.AlignHCenter
          }

          ActionButton {
            Layout.preferredWidth: 140
            Layout.preferredHeight: Config.neoBrutalism
              ? appearanceTab.optionButtonHeight
              : 40
            Layout.alignment: Qt.AlignHCenter
            radius: Config.neoBrutalism ? Config.shapeCompact : height / 2
            iconLabel: "sync"
            iconSize: Config.iconSize - 2
            labelText: "Reload colors"
            accessibleName: "Reload colors"
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

      // Bar Placement card
      StyledSurface {
        Layout.column: appearanceTab.compactLayout ? 0 : 1
        Layout.row: appearanceTab.compactLayout ? 2 : 1
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: barPlacementColumn.implicitHeight + 32
        radius: Config.shapeLarge
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
        outlineWidth: Config.themeBorderWidth

          ColumnLayout {
            id: barPlacementColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 16
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: Config.spacingSmall

            Text {
              text: "Bar Placement"
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: Config.textTitleSize
              font.weight: Font.Bold
              Layout.alignment: Qt.AlignHCenter
            }

            Item {
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredHeight: appearanceTab.optionButtonHeight
              height: appearanceTab.optionButtonHeight

              Row {
                anchors.fill: parent
                spacing: appearanceTab.optionButtonGap

                Repeater {
                  model: [
                    { value: "top", icon: "vertical_align_top", label: "Top" },
                    { value: "bottom", icon: "vertical_align_bottom", label: "Bottom" },
                    { value: "left", icon: "dock_to_left", label: "Left" },
                    { value: "right", icon: "dock_to_right", label: "Right" }
                  ]

                  delegate: ActionButton {
                    required property var modelData
                    width: (parent.width - appearanceTab.optionButtonGap * 3) / 4
                    height: parent.height
                    iconLabel: modelData.icon
                    iconSize: 15
                    labelText: modelData.label
                    selected: root.barPosition === modelData.value
                    accessibleName: modelData.label + " bar"
                    accessibleDescription: selected ? "Selected" : "Switch bar to " + modelData.label.toLowerCase()
                    onActivated: root.setBarPosition(modelData.value)
                  }
                }
              }
            }
          }
      }

      // Full bar toggle
      StyledSurface {
        Layout.column: appearanceTab.compactLayout ? 0 : 0
        Layout.row: appearanceTab.compactLayout ? 3 : 1
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.preferredHeight: barPlacementColumn.implicitHeight + 32
        radius: Config.shapeLarge
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
        outlineWidth: Config.themeBorderWidth

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
                color: Colors.styleAccent

                Text {
                  anchors.centerIn: parent
                  text: "dock_to_bottom"
                  color: Colors.styleAccentText
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
                  text: root.fullBar ? "Full bar" : "Pills bar"
                  color: Colors.fgSurface
                  font.family: Config.fontFamily
                  font.pixelSize: Config.textBodyLargeSize
                  font.weight: Font.Bold
                  horizontalAlignment: Text.AlignHCenter
                }

                Text {
                  Layout.fillWidth: true
                  text: root.fullBar ? "One continuous surface" : "Floating pill per widget"
                  color: Colors.fgSurfaceVariant
                  font.family: Config.fontFamily
                  font.pixelSize: Config.fontPixelSize
                  horizontalAlignment: Text.AlignHCenter
                  wrapMode: Text.WordWrap
                  maximumLineCount: 2
                  elide: Text.ElideRight
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
                outline: Colors.styleOutlineStrong
                motionDuration: Config.motionMedium
                reducedMotion: Config.reducedMotion
                accessibleName: "Bar display style"
                accessibleDescription: root.fullBar
                  ? "All widgets share one continuous bar"
                  : "Each widget is shown as a separate floating pill"
                onToggled: root.toggleFullBar()
              }
            }
          }
      }
    }

    // Font / Icon / Spacing sliders
    StyledSurface {
      Layout.fillWidth: true
      Layout.preferredHeight: sizingColumn.implicitHeight + 24
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

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

        // UI font size
        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingMedium

          Text {
            text: "UI Font Size"
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
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "UI font size"
            accessibleDescription: "Adjust global UI font size"
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

        // Clock font size
        RowLayout {
          Layout.fillWidth: true
          spacing: Config.spacingMedium

          Text {
            text: "Clock Size"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.textBodySize
            Layout.preferredWidth: appearanceTab.compactLayout ? 64 : 90
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.clockFontSize - 12) / 12
            stepSize: 1 / 12
            accessibleMinimumValue: 12
            accessibleMaximumValue: 24
            accessibleUnit: "px"
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Clock font size"
            accessibleDescription: "Adjust the bar clock font size"
            onChanged: function(val) {
              Settings.clockFontSize = Math.round(12 + val * 12)
            }
            onInteractionFinished: Settings.save()
          }

          Text {
            text: Settings.clockFontSize + "px"
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
            outline: Colors.styleOutlineStrong
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
            outline: Colors.styleOutlineStrong
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
            outline: Colors.styleOutlineStrong
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

        ActionButton {
          Layout.fillWidth: true
          Layout.preferredHeight: 48
          iconLabel: "settings_backup_restore"
          labelText: "Reset Appearance"
          variant: "outlined"
          visible: !appearanceTab.resetConfirm
          accessibleName: "Reset appearance"
          accessibleDescription: "Show confirmation before restoring default appearance settings"
          onActivated: appearanceTab.resetConfirm = true
        }

        ActionButton {
          Layout.fillWidth: true
          Layout.preferredHeight: 48
          iconLabel: "warning"
          labelText: "Confirm Reset"
          variant: "filled"
          visible: appearanceTab.resetConfirm
          accessibleName: "Confirm appearance reset"
          accessibleDescription: "Restore default appearance settings"
          onActivated: {
            if (appearanceTab.root) appearanceTab.root.resetAppearance()
            appearanceTab.resetConfirm = false
          }
        }

        ActionButton {
          Layout.fillWidth: true
          Layout.preferredHeight: 48
          iconLabel: "close"
          labelText: "Cancel Reset"
          variant: "quiet"
          visible: appearanceTab.resetConfirm
          accessibleName: "Cancel appearance reset"
          accessibleDescription: "Keep the current appearance settings"
          onActivated: appearanceTab.resetConfirm = false
        }
      }
    }

  }
}
