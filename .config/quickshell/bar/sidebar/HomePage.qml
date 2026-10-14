import QtQuick
import Quickshell
import "../../config"

// Page 0: time, the Sunday-first week strip, weather pill, the 3x3 slider
// tiles and the hostname chip. `testValues` (render check only) replaces the
// service inputs so the page renders the same on every machine.
Item {
  id: root
  property bool active: false
  property date now: new Date()
  property var testValues: null

  function pick(key, live) { return root.testValues ? root.testValues[key] : live }

  SystemClock { id: clock; precision: SystemClock.Minutes; enabled: root.active }
  Binding { target: root; property: "now"; value: clock.date; when: root.active }
  Binding { target: SystemMetricsService; property: "active"; value: root.active }
  Binding { target: WeatherService; property: "sidebarActive"; value: root.active }
  Binding { target: AudioService; property: "sidebarActive"; value: root.active }
  Binding { target: BrightnessService; property: "sidebarActive"; value: root.active }

  readonly property var days: {
    var out = []
    var start = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate() - root.now.getDay())
    var letters = ["S", "M", "T", "W", "T", "F", "S"]
    for (var i = 0; i < 7; i++) {
      var d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
      out.push({ letter: letters[i], number: d.getDate(), today: i === root.now.getDay() })
    }
    return out
  }

  readonly property real volume: root.pick("volume", AudioService.volume * 100)
  readonly property bool charging: root.pick("charging", BatteryService.charging)
  readonly property string hostname: root.pick("hostname", SystemMetricsService.hostname)
  readonly property string uptime: root.pick("uptime", SystemMetricsService.uptime)
  readonly property string weatherStatus: root.pick("weatherStatus", WeatherService.status)
  readonly property string weatherTemp: root.pick("weatherTemp", WeatherService.temp)
  readonly property string weatherDesc: root.pick("weatherDesc", WeatherService.desc)

  // Glyphs: icomoon codepoints (ElenaIcons1 = feather, 2 = remix; see the
  // task-3 report for the table). Fill accents follow the spec's tile table.
  readonly property var tiles: [
    { name: "volume", value: root.volume, accent: 5, glyph: "", interactive: true,
      muted: root.pick("muted", AudioService.muted) },
    { name: "battery", value: root.pick("battery", BatteryService.pct), accent: 6,
      glyph: root.charging ? "" : "" },
    { name: "cpu", value: root.pick("cpu", SystemMetricsService.cpu), accent: 2, glyph: "" },
    { name: "brightness", value: root.pick("brightness", BrightnessService.pct), accent: 1, glyph: "", interactive: true },
    { name: "temperature", value: root.pick("temp", SystemMetricsService.temp), accent: 1, glyph: "" },
    { name: "ram", value: root.pick("ram", SystemMetricsService.ram), accent: 3, glyph: "" },
    { name: "swap", value: root.pick("swap", SystemMetricsService.swap), accent: 4, glyph: "" },
    { name: "disk", value: root.pick("disk", SystemMetricsService.disk), accent: 5, glyph: "" },
    { name: "network", value: root.pick("net", SystemMetricsService.netPercent), accent: 4, glyph: "",
      label: root.pick("netLabel", SystemMetricsService.netLabel) }
  ]

  Column {
    anchors.top: parent.top
    anchors.topMargin: Config.dp(40)
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Config.dp(10)

    Row {   // time: HH + mm
      anchors.horizontalCenter: parent.horizontalCenter
      Text {
        text: ("0" + root.now.getHours()).slice(-2)
        color: Colors.fgSurface
        font.family: BottomBarFonts.clockFamily
        font.pixelSize: Math.round(44 * 4 / 3 * Config.elenaScale)
      }
      Text {
        text: ("0" + root.now.getMinutes()).slice(-2)
        color: Colors.elenaAccent(1)
        font.family: BottomBarFonts.clockMinutesFamily
        font.pixelSize: Math.round(44 * 4 / 3 * Config.elenaScale)
      }
    }

    Row {   // weekday strip, Sunday-first
      objectName: "weekStrip"
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.dp(8)
      Repeater {
        model: root.days
        Rectangle {
          required property var modelData
          width: Config.dp(36)
          height: Config.dp(52)
          radius: Config.dp(14)
          color: modelData.today ? Colors.surfaceContainerHighest : "transparent"
          Column {
            anchors.centerIn: parent
            spacing: Config.dp(4)
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: modelData.letter
              color: modelData.today ? Colors.elenaAccent(1) : Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.dp(11)
              font.weight: Font.Bold
            }
            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: modelData.number
              color: modelData.today ? Colors.fgSurface : Colors.outline
              font.family: Config.fontFamily
              font.pixelSize: Config.dp(10)
            }
          }
        }
      }
    }

    Rectangle {   // weather pill
      anchors.horizontalCenter: parent.horizontalCenter
      width: weatherRow.implicitWidth + Config.dp(20)
      height: Config.dp(28)
      radius: height / 2
      color: Colors.surfaceContainerHighest
      Row {
        id: weatherRow
        anchors.centerIn: parent
        spacing: Config.dp(6)
        readonly property bool loading: root.weatherStatus === "loading"
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.weatherStatus === "ok" ? Colors.weatherIcon(root.weatherDesc) : "cloud_off"
          visible: !weatherRow.loading
          color: Colors.elenaAccent(3)
          font.family: Config.iconFont
          font.pixelSize: Config.dp(13)
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: weatherRow.loading ? "Loading weather" : root.weatherTemp
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.dp(10)
          font.weight: Font.Bold
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: !weatherRow.loading && root.weatherDesc !== ""
          text: "·"
          color: Colors.outline
          font.family: Config.fontFamily
          font.pixelSize: Config.dp(10)
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: !weatherRow.loading && root.weatherDesc !== ""
          text: root.weatherDesc
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.dp(10)
        }
      }
    }

    Grid {   // 3 rows of 3 slider tiles
      anchors.horizontalCenter: parent.horizontalCenter
      columns: 3
      Repeater {
        // A count model, not root.tiles: a new array every metrics tick must
        // update the tiles in place, not recreate them (keeps the fill animation).
        model: 9
        SliderTile {
          required property int index
          readonly property var t: root.tiles[index]
          objectName: "tile_" + t.name
          value: t.value
          accent: Colors.elenaAccent(t.accent)
          glyph: t.glyph
          interactive: t.interactive === true
          muted: t.muted === true
          valueText: t.label !== undefined ? t.label : (t.value < 0 ? "--" : String(Math.round(t.value)))
          onMoved: function(v) {
            if (t.name === "volume") AudioService.setVolume(v / 100)
            else if (t.name === "brightness") BrightnessService.setBrightness(v)
          }
        }
      }
    }

    Rectangle {   // hostname chip
      anchors.horizontalCenter: parent.horizontalCenter
      width: hostRow.implicitWidth + Config.dp(20)
      height: Config.dp(28)
      radius: height / 2
      color: Colors.surfaceContainerHighest
      Row {
        id: hostRow
        anchors.centerIn: parent
        spacing: Config.dp(6)
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: ""
          color: Colors.elenaAccent(4)
          font.family: BottomBarFonts.family
          font.pixelSize: Config.dp(12)
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: root.hostname !== ""
          text: root.hostname
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.dp(10)
          font.weight: Font.Bold
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: root.hostname !== ""
          text: "·"
          color: Colors.outline
          font.family: Config.fontFamily
          font.pixelSize: Config.dp(10)
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.uptime
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.dp(10)
        }
      }
    }
  }
}
