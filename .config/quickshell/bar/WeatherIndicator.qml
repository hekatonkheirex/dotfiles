import QtQuick
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: root.status === "ok" ? Colors.weatherColor(desc) : Colors.fgSurfaceVariant
  accessibleName: "Weather"
  accessibleDescription: root.status === "ok"
    ? root.city + ", " + root.temp
    : root.statusMessage
  tooltipText: root.status === "ok"
    ? "Weather: " + root.temp
    : "Weather unavailable: " + root.statusMessage

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
          var info = JSON.parse(text.trim());
          root.status = info.status || "ok";
          root.statusMessage = info.message || "";
          root.updatedAt = info.updated_at || "";
          root.city = info.city;
          root.temp = info.current_temp;
          root.desc = info.current_desc;
          root.humidity = info.humidity;
          root.feelsLike = info.apparent_temp;
          root.wind = info.wind_speed;
          root.pressure = info.pressure;
          root.uv = info.uv_index;
          root.precipChance = info.precipitation_chance;
          root.forecast = info.forecast;
          root.hourly = info.hourly;
        } catch (e) { print("WeatherIndicator parse error:", e) }
      }
    }
  }

  function refresh() {
    weatherProc.running = false
    weatherProc.running = true
  }

  Connections {
    target: Settings
    function onWeatherUnitsChanged() { if (root.visible) root.refresh() }
    function onWeatherLocationChanged() { if (root.visible) root.refresh() }
    function onWeatherAllowIpGeolocationChanged() { if (root.visible) root.refresh() }
  }

  Timer {
    id: weatherTimer
    interval: Math.max(5, Settings.weatherRefreshIntervalMinutes) * 60000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  iconLabel: root.status === "ok" ? Colors.weatherIcon(root.desc) : "cloud_off"
  loading: root.status === "loading"
  labelText: root.status === "ok" ? root.temp : "--"
}
