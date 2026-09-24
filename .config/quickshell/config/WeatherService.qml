pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: root

  property string city: ""
  property string temp: "--°"
  property string desc: ""
  property string status: "loading"
  property string statusMessage: "Loading weather..."
  property string updatedAt: ""
  property var forecast: []
  property var hourly: []
  property string humidity: "--%"
  property string feelsLike: "--"
  property string wind: "--"
  property string pressure: "--"
  property string uv: "--"
  property string precipChance: "--%"
  property bool indicatorActive: false
  property bool popupActive: false

  readonly property bool active: indicatorActive || popupActive
  readonly property bool loading: weatherProcess.running

  onPopupActiveChanged: {
    if (root.popupActive) root.refresh()
  }

  property bool refreshPending: false
  property int weatherExitCode: -1

  function refresh() {
    if (weatherProcess.running) {
      root.refreshPending = true
      return
    }
    root.status = "loading"
    root.statusMessage = "Loading weather..."
    root.weatherExitCode = -1
    weatherProcess.running = true
  }
  function applyWeatherOutput(output) {
    if (root.weatherExitCode !== 0 && root.weatherExitCode !== -1) return
    try {
      var info = JSON.parse(output)
      if (!info || typeof info !== "object" || Array.isArray(info)) throw new Error("Expected a JSON object")
      root.status = info.status || "ok"
      root.statusMessage = info.message || ""
      root.updatedAt = info.updated_at || ""
      root.city = info.city
      root.temp = info.current_temp
      root.desc = info.current_desc
      root.humidity = info.humidity
      root.feelsLike = info.apparent_temp
      root.wind = info.wind_speed
      root.pressure = info.pressure
      root.uv = info.uv_index
      root.precipChance = info.precipitation_chance
      root.forecast = info.forecast
      root.hourly = info.hourly
    } catch (error) {
      root.status = "error"
      root.statusMessage = "Weather command returned invalid JSON. Check the weather script and its output."
      print("WeatherService parse error:", error)
    }
  }

  property var weatherProcess: Process {
    command: [
      "python3",
      "-u",
      Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.py",
      Settings.weatherUnits,
      Settings.weatherLocation,
      Settings.weatherAllowIpGeolocation ? "1" : "0"
    ]
    running: false
    onExited: function(exitCode) {
      root.weatherExitCode = exitCode
      if (exitCode !== 0) {
        var detail = weatherError.text.trim()
        root.status = "error"
        root.statusMessage = "Weather command failed (exit code " + exitCode + ")." +
          (detail ? " " + detail : " Check the weather script and its dependencies.")
      }
      if (root.refreshPending) {
        root.refreshPending = false
        root.refresh()
      }
    }
    stdout: StdioCollector {
      onStreamFinished: root.applyWeatherOutput(text.trim())
    }
    stderr: StdioCollector { id: weatherError }
  }

  property var refreshTimer: Timer {
    interval: Math.max(5, Settings.weatherRefreshIntervalMinutes) * 60000
    running: root.indicatorActive
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  property var settingsConnections: Connections {
    target: Settings

    function onWeatherUnitsChanged() {
      if (root.active) root.refresh()
    }

    function onWeatherLocationChanged() {
      if (root.active) root.refresh()
    }

    function onWeatherAllowIpGeolocationChanged() {
      if (root.active) root.refresh()
    }

    function onWeatherRefreshIntervalMinutesChanged() {
      if (root.popupActive) root.refresh()
    }
  }
}
