import QtQuick
import Quickshell
import Quickshell.Io
import "primitives"
import "../config"

StatusIndicator {
  id: root

  accentColor: Colors.weatherColor(desc)
  accessibleName: "Weather"
  tooltipText: "Weather"

  property string city: ""
  property string temp: "--°"
  property string desc: ""
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
    command: ["python3", "-u", Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.py", Settings.weatherUnits]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var info = JSON.parse(text.trim());
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

  Timer {
    id: weatherTimer
    interval: 900000 // 15 minutes
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  iconLabel: Colors.weatherIcon(root.desc)
  labelText: root.temp
}
