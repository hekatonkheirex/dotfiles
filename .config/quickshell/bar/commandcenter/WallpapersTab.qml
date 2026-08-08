import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"

ColumnLayout {
  id: wallpapersTab
  anchors.fill: parent
  spacing: 8
  visible: root.currentTab === 2

  property QtObject root: null

  property var wallpapersList: []
  property string currentWallpaper: ""
  property bool discoveryStarted: false

  onVisibleChanged: {
    if (visible && !discoveryStarted) {
      discoveryStarted = true
      listWallpapersProc.running = true
      genWallpapersThumbsProc.running = true
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
        wallpapersList = arr;
      }
    }
  }

  // Pre-generate wallpaper thumbnails the first time this tab is opened,
  // rather than unconditionally at shell startup (CommandCenter and all its
  // tabs are instantiated eagerly, not lazily, so this ran even if the
  // Wallpapers tab was never viewed).
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
        currentWallpaper = text.trim()
        if (root.currentTab === 2) {
          scrollTimer.start()
        }
      }
    }
  }

  Timer {
    id: scrollTimer
    interval: 150
    running: false
    repeat: false
    onTriggered: {
      if (currentWallpaper && wallpapersList.length > 0) {
        var idx = wallpapersList.indexOf(currentWallpaper);
        if (idx >= 0) {
          wallpaperGrid.currentIndex = idx;
          wallpaperGrid.positionViewAtIndex(idx, GridView.Center);
        }
      }
      wallpaperGrid.forceActiveFocus();
    }
  }

  Connections {
    target: root
    function onVisibleChanged() {
      if (root.visible) {
        ccGetWallpaper.running = false
        ccGetWallpaper.running = true
      }
    }
    function onCurrentTabChanged() {
      if (root.currentTab === 2) {
        ccGetWallpaper.running = false
        ccGetWallpaper.running = true
        scrollTimer.start()
      }
    }
  }

  Text {
    text: "Visual Wallpaper Selector (" + wallpapersList.length + " walls found) • Active: " + (currentWallpaper || "None")
    color: Colors.fgSurfaceVariant
    font.family: Config.fontFamily
    font.pixelSize: 12
    font.weight: Font.Medium
  }

  Rectangle {
    Layout.fillWidth: true
    Layout.fillHeight: true
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
      model: wallpapersList
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

        readonly property bool isCurrent: modelData === currentWallpaper

        Accessible.role: Accessible.Button
        Accessible.name: modelData
        Accessible.description: isCurrent ? "Current wallpaper" : "Apply wallpaper"

        function applyWallpaper() {
          Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh", modelData])
          currentWallpaper = modelData
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

        // State ring/tint drawn above the thumbnail image, since the image
        // fills the full delegate bounds and would otherwise occlude a
        // border or fill painted on wallDelegate itself.
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

        // Selected checkmark badge
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
