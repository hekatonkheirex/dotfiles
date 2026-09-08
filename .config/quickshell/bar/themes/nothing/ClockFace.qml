import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../config"

// Small desktop translation of the Nothing OS 5 clock direction. The face is
// intentionally data-driven so the lock screen can keep one implementation
// for both the Niri session-lock path and the fallback panel path.
Item {
  id: root

  property string face: "micrographics"
  property date now: new Date()
  property real clockSize: 72
  property color primaryColor: Colors.styleAccent
  property color secondaryColor: Colors.fgSurfaceVariant
  property string eventText: ""
  property string weatherText: ""
  property string weatherCity: ""

  implicitWidth: Math.max(260, root.clockSize * 3.5)
  implicitHeight: root.face === "gooey"
    ? root.clockSize * 1.9
    : root.clockSize * 1.75
  width: implicitWidth
  height: implicitHeight

  function timeText() {
    var hours = root.now.getHours()
    var minutes = root.now.getMinutes().toString().padStart(2, "0")
    var seconds = root.now.getSeconds().toString().padStart(2, "0")
    if (Settings.clock24h) {
      return hours.toString().padStart(2, "0") + ":" + minutes
        + (Settings.clockShowSeconds ? ":" + seconds : "")
    }
    var suffix = hours >= 12 ? "PM" : "AM"
    var displayHours = hours % 12 || 12
    return displayHours + ":" + minutes
      + (Settings.clockShowSeconds ? ":" + seconds : "") + " " + suffix
  }

  function dateText() {
    var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    var months = ["January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"]
    return days[root.now.getDay()] + ", " + months[root.now.getMonth()]
      + " " + root.now.getDate() + ", " + root.now.getFullYear()
  }

  function refreshWeather() {
    if (!root.visible || root.face === "gooey") {
      weatherProc.running = false
      return
    }
    // Toggle explicitly so a settings change refreshes an already-running
    // process instead of silently replacing its binding.
    weatherProc.running = false
    weatherProc.running = true
  }

  Component.onCompleted: refreshWeather()
  onVisibleChanged: refreshWeather()

  Process {
    id: weatherProc
    command: [
      "python3",
      "-u",
      Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.py",
      Settings.weatherUnits,
      Settings.weatherLocation,
      Settings.weatherAllowIpGeolocation ? "1" : "0"
    ]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var info = JSON.parse(text.trim())
          if (info.status === "ok") {
            root.weatherText = info.current_temp || ""
            root.weatherCity = info.city || ""
          } else {
            root.weatherText = ""
            root.weatherCity = ""
          }
        } catch (e) {
          root.weatherText = ""
          root.weatherCity = ""
        }
      }
    }
  }

  Connections {
    target: Settings
    function onWeatherUnitsChanged() { root.refreshWeather() }
    function onWeatherLocationChanged() { root.refreshWeather() }
    function onWeatherAllowIpGeolocationChanged() { root.refreshWeather() }
    function onLockClockFaceChanged() { root.refreshWeather() }
  }

  Item {
    id: gooeyFace
    anchors.fill: parent
    visible: root.face === "gooey"

    Rectangle {
      width: root.clockSize * 1.45
      height: root.clockSize * 0.72
      x: root.width * 0.08
      y: root.height * 0.18
      radius: height / 2
      rotation: -7
      color: Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.22)
    }

    Rectangle {
      width: root.clockSize * 1.1
      height: root.clockSize * 0.88
      x: root.width * 0.62
      y: root.height * 0.04
      radius: width / 2
      color: Qt.rgba(root.primaryColor.r, root.primaryColor.g, root.primaryColor.b, 0.16)
    }

    Text {
      anchors.centerIn: parent
      text: root.timeText()
      color: root.primaryColor
      font.family: Config.displayFontFamily
      font.pixelSize: root.clockSize * 0.72
      font.weight: Font.Medium
      font.letterSpacing: -1.5
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      text: root.dateText()
      color: root.secondaryColor
      font.family: Config.fontFamily
      font.pixelSize: Math.max(12, Config.fontPixelSize + 4)
    }
  }

  ColumnLayout {
    id: micrographicsFace
    anchors.fill: parent
    visible: root.face !== "gooey"
    spacing: Config.spacingCompact

    RowLayout {
      Layout.fillWidth: true

      Text {
        text: "MICROGRAPHICS"
        color: root.secondaryColor
        font.family: Config.monoFontFamily
        font.pixelSize: Math.max(9, Config.fontPixelSize - 1)
        font.weight: Font.Medium
        font.letterSpacing: 1.2
      }

      Item { Layout.fillWidth: true }

      Text {
        text: root.now.toLocaleDateString(Qt.locale(), "MMM dd")
        color: root.secondaryColor
        font.family: Config.monoFontFamily
        font.pixelSize: Math.max(10, Config.fontPixelSize)
      }
    }

    Text {
      Layout.fillWidth: true
      text: root.timeText()
      color: root.primaryColor
      font.family: Config.monoFontFamily
      font.pixelSize: root.clockSize * 0.78
      font.weight: Font.Medium
      font.letterSpacing: -1.2
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Config.spacingSmall
      visible: root.weatherText !== "" || root.eventText !== ""

      Text {
        text: root.weatherText !== "" ? "WEATHER" : "NEXT"
        color: root.secondaryColor
        font.family: Config.monoFontFamily
        font.pixelSize: Math.max(9, Config.fontPixelSize - 2)
        font.letterSpacing: 0.8
      }

      Text {
        Layout.fillWidth: true
        text: root.weatherText !== ""
          ? root.weatherText + (root.weatherCity !== "" ? "  ·  " + root.weatherCity : "")
          : root.eventText
        color: root.secondaryColor
        font.family: Config.fontFamily
        font.pixelSize: Math.max(11, Config.fontPixelSize)
        elide: Text.ElideRight
      }
    }
  }
}
