import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Effects
import "../primitives"
import "../../config"

Flickable {
  id: wallpaperTab

  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  anchors.fill: parent
  visible: root.currentTab === 3
  clip: true
  contentWidth: width
  contentHeight: mainColumn.height + wallpaperTab.neoShadowAllowance
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
      getWallpaperProc.running = false
      getWallpaperProc.running = true
    }
  }

  Process {
    id: listWallpapersProc
    command: ["sh", "-c", "find " + Quickshell.env("HOME") + "/Pictures/Walls -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \\) -printf '%f\\n' | sort"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var list = text.trim().split("\n")
        var arr = []
        for (var i = 0; i < list.length; i++) {
          var line = list[i].trim()
          if (line) arr.push(line)
        }
        wallpaperTab.wallpapersList = arr
      }
    }
  }

  Process {
    id: genWallpapersThumbsProc
    command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/generate-thumbnails.sh"]
    running: false
  }

  Process {
    id: getWallpaperProc
    command: ["sh", "-c", "awww query | grep -o 'image: .*' | cut -d' ' -f2 | xargs basename"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        wallpaperTab.currentWallpaper = text.trim()
        if (root.currentTab === 3) scrollTimer.start()
      }
    }
  }

  Timer {
    id: scrollTimer
    interval: 150
    running: false
    repeat: false
    onTriggered: {
      if (wallpaperTab.currentWallpaper && wallpaperTab.wallpapersList.length > 0) {
        var idx = wallpaperTab.wallpapersList.indexOf(wallpaperTab.currentWallpaper)
        if (idx >= 0) {
          wallpaperGrid.currentIndex = idx
          wallpaperGrid.positionViewAtIndex(idx, GridView.Center)
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
    width: Math.max(0, wallpaperTab.width - wallpaperTab.neoShadowAllowance)
    height: Math.max(wallpaperTab.height, implicitHeight)
    spacing: Config.spacingLarge + wallpaperTab.neoShadowAllowance

    RowLayout {
      Layout.fillWidth: true
      spacing: Config.spacingMedium

      Text {
        text: "Wallpaper (" + wallpaperTab.wallpapersList.length + " found) • Active: " + (wallpaperTab.currentWallpaper || "None")
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.textBodySize
        font.weight: Font.Medium
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      ActionButton {
        Layout.preferredWidth: 80
        Layout.preferredHeight: Config.neoBrutalism ? 52 : (Config.nothingDesign ? 44 : 40)
        iconLabel: "shuffle"
        iconSize: Config.iconSizeSmall
        labelText: "Randomize"
        accessibleName: "Randomize wallpaper"
        tooltipText: "Pick a random wallpaper"
        onActivated: wallpaperTab.randomizeWallpaper()
      }
    }

    StyledSurface {
      id: wallpaperSurface
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumHeight: 340
      Layout.preferredHeight: 340
      // Keep the lower outline and Neo offset inside the clipped tab viewport.
      Layout.bottomMargin: Config.spacingSmall + wallpaperTab.neoShadowAllowance
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth
      clipContent: true

        GridView {
        id: wallpaperGrid
        anchors.fill: parent
        anchors.margins: 16
        cellWidth: wallpaperTab.compactLayout
          ? Math.max(120, wallpaperTab.width - 32)
          : Math.max(160, Math.floor(width / 3))
        cellHeight: wallpaperTab.compactLayout
          ? Math.round(cellWidth * 0.68)
          : 120
        model: wallpaperTab.wallpapersList
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        activeFocusOnTab: true

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (currentItem) currentItem.applyWallpaper()
            event.accepted = true
          }
        }

        delegate: Item {
          id: wallDelegate
          width: wallpaperGrid.cellWidth - 8 - wallpaperTab.neoShadowAllowance
          height: wallpaperGrid.cellHeight - 8 - wallpaperTab.neoShadowAllowance
          property real cornerRadius: Config.shapeMedium
          readonly property bool isKeyboardSelected: GridView.isCurrentItem && wallpaperGrid.activeFocus

          readonly property bool isCurrent: modelData === wallpaperTab.currentWallpaper

          Accessible.role: Accessible.Button
          Accessible.name: modelData
          Accessible.description: isCurrent ? "Current wallpaper" : "Apply wallpaper"

          function applyWallpaper() {
            Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh", modelData])
            wallpaperTab.currentWallpaper = modelData
          }

          Rectangle {
            id: wallSurface
            anchors.fill: parent
            radius: wallDelegate.cornerRadius
            color: Config.neoBrutalism || Config.nothingDesign
              ? Colors.styleSurface
              : Colors.surfaceContainerHigh
            clip: true

            Image {
              id: wallThumb
              source: "file://" + Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-thumbs/" + modelData
              sourceSize.width: 200
              sourceSize.height: 130
              anchors.fill: parent
              fillMode: Image.PreserveAspectCrop
              visible: false

              onStatusChanged: {
                if (status === Image.Error && source !== "file://" + Quickshell.env("HOME") + "/Pictures/Walls/" + modelData) {
                  source = "file://" + Quickshell.env("HOME") + "/Pictures/Walls/" + modelData
                }
              }
            }

            // Rectangle.clip only clips to the rectangular item bounds. Mask
            // the image itself so every thumbnail follows the same corners as
            // its frame, including bright pixels at the four corners.
            Rectangle {
              id: wallMask
              anchors.fill: parent
              radius: wallDelegate.cornerRadius
              color: "black"
              visible: false
              layer.enabled: true
            }

            MultiEffect {
              id: wallThumbEffect
              anchors.fill: parent
              source: wallThumb
              maskEnabled: true
              maskSource: wallMask
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
              border.width: wallDelegate.isCurrent
                ? 3
                : (wallDelegate.isKeyboardSelected || wallDelegateMouse.containsMouse
                  ? Config.themeFocusBorderWidth
                  : Config.themeBorderWidth)
              border.color: wallDelegate.isCurrent || wallDelegate.isKeyboardSelected || wallDelegateMouse.containsMouse
                ? Colors.primary : Colors.styleOutline

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
              radius: width / 2
              color: Colors.primary
              anchors.top: parent.top
              anchors.right: parent.right
              anchors.margins: 6
              visible: wallDelegate.isCurrent

              Text {
                anchors.centerIn: parent
                text: "check"
                font.family: Config.iconFont
                font.pixelSize: Config.iconSizeSmall
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
}
