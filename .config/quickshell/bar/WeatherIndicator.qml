import QtQuick
import QtQml
import Quickshell
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

  readonly property string city: WeatherService.city
  readonly property string temp: WeatherService.temp
  readonly property string desc: WeatherService.desc
  readonly property string status: WeatherService.status
  readonly property string statusMessage: WeatherService.statusMessage
  readonly property string updatedAt: WeatherService.updatedAt
  readonly property var forecast: WeatherService.forecast
  readonly property var hourly: WeatherService.hourly
  readonly property string humidity: WeatherService.humidity
  readonly property string feelsLike: WeatherService.feelsLike
  readonly property string wind: WeatherService.wind
  readonly property string pressure: WeatherService.pressure
  readonly property string uv: WeatherService.uv
  readonly property string precipChance: WeatherService.precipChance

  Binding {
    target: WeatherService
    property: "indicatorActive"
    value: root.visible
  }

  iconLabel: root.status === "ok" ? Colors.weatherIcon(root.desc) : "cloud_off"
  loading: root.status === "loading"
  labelText: root.status === "ok" ? root.temp : "--"
}
