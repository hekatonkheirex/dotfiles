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
  anchors.fill: parent
  visible: root.currentTab === 1
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  property var wallpapersList: []
  property string currentWallpaper: ""
  property bool discoveryStarted: false

  onVisibleChanged: {
    if (visible && !discoveryStarted) {
      discoveryStarted = true
      listWallpapersProc.running = true
      genWallpapersThumbsProc.running = true
    }
    if (visible) {
      ccGetWallpaper.running = false
      ccGetWallpaper.running = true
    }
  }

  Process {
    id: listWallpapersProc
    command: ["sh", "-c", "find " + Quickshell.env("HOME") + "/Pictures/Walls -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \\) -printf '%f\\n' | sort"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var list = text.trim().split("\n");
        var arr = [];
        for (var i = 0; i < list.length; i++) {
          var line = list[i].trim();
          if (line) arr.push(line);
        }
        appearanceTab.wallpapersList = arr;
      }
    }
  }

  // Pre-generate wallpaper thumbnails the first time this tab is opened,
  // rather than unconditionally at shell startup.
  Process {
    id: genWallpapersThumbsProc
    command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/generate-thumbnails.sh"]
    running: false
  }

  Process {
    id: ccGetWallpaper
    command: ["sh", "-c", "awww query | grep -o 'image: .*' | cut -d' ' -f2 | xargs basename"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        appearanceTab.currentWallpaper = text.trim()
        if (root.currentTab === 1) scrollTimer.start()
      }
    }
  }

  Timer {
    id: scrollTimer
    interval: 150
    running: false
    repeat: false
    onTriggered: {
      if (appearanceTab.currentWallpaper && appearanceTab.wallpapersList.length > 0) {
        var idx = appearanceTab.wallpapersList.indexOf(appearanceTab.currentWallpaper);
        if (idx >= 0) {
          wallpaperGrid.currentIndex = idx;
          wallpaperGrid.positionViewAtIndex(idx, GridView.Center);
        }
      }
    }
  }

  function randomizeWallpaper() {
    Quickshell.execDetached(["sh", "-c",
      "wall_dir=\"$HOME/Pictures/Walls\"; " +
      "selected=$(find \"$wall_dir\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | shuf -n 1); " +
      "[ -n \"$selected\" ] && exec bash \"$HOME/.config/quickshell/scripts/apply-wallpaper.sh\" \"${selected##*/}\""])
  }

  ColumnLayout {
    id: mainColumn
    width: appearanceTab.width
    spacing: 16

    RowLayout {
      Layout.fillWidth: true
      spacing: 16

      // Theme card
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
                  selected: Colors.themePreference === modelData.value
                  accessibleName: modelData.label + " theme"
                  onActivated: {
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
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 16

      // Full bar toggle
      Rectangle {
        Layout.preferredWidth: 280
        Layout.preferredHeight: 64
        radius: Config.shapeLarge
        color: Colors.surfaceContainer
        border.color: Colors.outlineVariant
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: 12
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
      }

      Item { Layout.fillWidth: true }
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
        spacing: 10

        Text {
          text: "Sizing"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: 14
          font.weight: Font.Bold
        }

        // Font size
        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Text {
            text: "Font Size"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: 12
            Layout.preferredWidth: 90
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.fontPixelSize - 7) / 9
            stepSize: 1 / 9
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
              Settings.save()
            }
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
          spacing: 12

          Text {
            text: "Icon Size"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: 12
            Layout.preferredWidth: 90
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.iconSize - 12) / 16
            stepSize: 1 / 16
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
              Settings.save()
            }
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
          spacing: 12

          Text {
            text: "Spacing"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: 12
            Layout.preferredWidth: 90
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.spacingScale - 0.75) / 0.75
            stepSize: 0.05 / 0.75
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
              Settings.save()
            }
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
          spacing: 12

          Text {
            text: "Bar Size"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: 12
            Layout.preferredWidth: 90
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.barSize - 28) / 28
            stepSize: 2 / 28
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
              Settings.save()
            }
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

    // Wallpaper picker
    RowLayout {
      Layout.fillWidth: true
      spacing: 12

      Text {
        text: "Wallpaper (" + appearanceTab.wallpapersList.length + " found) • Active: " + (appearanceTab.currentWallpaper || "None")
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
        Layout.fillWidth: true
      }

      ActionButton {
        Layout.preferredWidth: 80
        Layout.preferredHeight: 40
        iconLabel: "shuffle"
        iconSize: 18
        labelText: "Randomize"
        accessibleName: "Randomize wallpaper"
        tooltipText: "Pick a random wallpaper"
        onActivated: appearanceTab.randomizeWallpaper()
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 340
      radius: Config.shapeLarge
      color: Colors.surfaceContainer
      border.color: Colors.outlineVariant
      border.width: 1
      clip: true

      GridView {
        id: wallpaperGrid
        anchors.fill: parent
        anchors.margins: 16
        cellWidth: 180
        cellHeight: 120
        model: appearanceTab.wallpapersList
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        activeFocusOnTab: true

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (currentItem) currentItem.applyWallpaper()
            event.accepted = true
          }
        }

        delegate: Rectangle {
          id: wallDelegate
          width: 160
          height: 104
          radius: Config.shapeMedium
          readonly property bool isKeyboardSelected: GridView.isCurrentItem && wallpaperGrid.activeFocus
          color: Colors.surfaceContainerHigh
          clip: true

          readonly property bool isCurrent: modelData === appearanceTab.currentWallpaper

          Accessible.role: Accessible.Button
          Accessible.name: modelData
          Accessible.description: isCurrent ? "Current wallpaper" : "Apply wallpaper"

          function applyWallpaper() {
            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh", modelData])
            appearanceTab.currentWallpaper = modelData
          }

          Image {
            id: wallThumb
            source: "file://" + Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-thumbs/" + modelData
            sourceSize.width: 200
            sourceSize.height: 130
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop

            onStatusChanged: {
              if (status === Image.Error && source !== "file://" + Quickshell.env("HOME") + "/Pictures/Walls/" + modelData) {
                source = "file://" + Quickshell.env("HOME") + "/Pictures/Walls/" + modelData;
              }
            }
          }

          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: {
              if (wallDelegateMouse.pressed) return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
              if (wallDelegate.isKeyboardSelected) return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.20)
              if (wallDelegateMouse.containsMouse) return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)
              return "transparent"
            }
            border.width: wallDelegate.isCurrent ? 3 : (wallDelegate.isKeyboardSelected || wallDelegateMouse.containsMouse ? 2 : 1)
            border.color: wallDelegate.isCurrent || wallDelegate.isKeyboardSelected || wallDelegateMouse.containsMouse
              ? Colors.primary : Colors.outlineVariant

            Behavior on color {
              ColorAnimation { duration: Config.animationDuration }
            }
            Behavior on border.width {
              NumberAnimation { duration: Config.animationDuration }
            }
          }

          Rectangle {
            width: 20
            height: 20
            radius: 10
            color: Colors.primary
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 6
            visible: wallDelegate.isCurrent

            Text {
              anchors.centerIn: parent
              text: "check"
              font.family: Config.iconFont
              font.pixelSize: 12
              font.weight: Font.Bold
              color: Colors.fgPrimary
            }
          }

          MouseArea {
            id: wallDelegateMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              wallpaperGrid.currentIndex = index
              wallpaperGrid.forceActiveFocus()
              wallDelegate.applyWallpaper()
            }
          }
        }
      }
    }
  }
}
