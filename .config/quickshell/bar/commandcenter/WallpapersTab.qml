import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"

ColumnLayout {
  anchors.fill: parent
  spacing: 8
  visible: root.currentTab === 2

  property QtObject root: null

  property var wallpapersList: []
  property string currentWallpaper: ""

  Process {
    id: listWallpapersProc
    command: ["sh", "-c", "find " + Quickshell.env("HOME") + "/Pictures/Walls -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \\) -printf '%f\\n' | sort"]
    running: true
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

  // Pre-generate wallpaper thumbnails on start
  Process {
    id: genWallpapersThumbsProc
    command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/generate-thumbnails.sh"]
    running: true
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
          wallpaperGrid.positionViewAtIndex(idx, GridView.Center);
        }
      }
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
    radius: 16
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

      delegate: Rectangle {
        id: wallDelegate
        width: 160
        height: 104
        radius: Config.shapeMedium
        activeFocusOnTab: true
        color: {
          var overlay = wallDelegateMouse.pressed ? Colors.pressOverlay
            : (wallDelegateMouse.containsMouse ? Colors.hoverOverlay
              : (wallDelegate.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
          return Qt.tint(Colors.surfaceContainerHigh, overlay)
        }
        clip: true

        Behavior on color {
          ColorAnimation { duration: Config.animationDuration }
        }

        readonly property bool isCurrent: modelData === currentWallpaper

        border.width: isCurrent ? 3 : (wallDelegate.activeFocus || wallDelegateMouse.containsMouse ? 2 : 1)
        border.color: isCurrent || wallDelegate.activeFocus || wallDelegateMouse.containsMouse
          ? (Colors.primary) : (Colors.outlineVariant)

        Accessible.role: Accessible.Button
        Accessible.name: modelData
        Accessible.description: isCurrent ? "Current wallpaper" : "Apply wallpaper"

        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            applyWallpaper()
            event.accepted = true
          }
        }

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
            wallDelegate.forceActiveFocus()
            wallDelegate.applyWallpaper()
          }
        }
      }
    }
  }
}
