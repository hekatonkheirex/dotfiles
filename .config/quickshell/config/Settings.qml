// Persisted user preferences backed by settings.json.
// Keep build-time layout and typography constants in Config.qml; this object
// owns values that should survive a Quickshell restart.
pragma Singleton
import QtQml
import Quickshell
import Quickshell.Io

FileView {
  id: root

  path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
  watchChanges: true

  onLoadFailed: function(error) {
    if (error === FileViewError.FileNotFound) root.writeAdapter()
  }

  // Keep persisted aliases paired with active consumers. Remove obsolete fields
  // from this schema and settings.json together during deliberate migrations.
  property alias barSize: adapter.barSize
  property alias calendarWeekStartsMonday: adapter.calendarWeekStartsMonday
  property alias ccShowAudio: adapter.ccShowAudio
  property alias ccShowDisplay: adapter.ccShowDisplay
  property alias ccShowMedia: adapter.ccShowMedia
  property alias ccShowWeather: adapter.ccShowWeather
  property alias clock24h: adapter.clock24h
  property alias clockShowSeconds: adapter.clockShowSeconds
  property alias doNotDisturb: adapter.doNotDisturb
  property alias fontPixelSize: adapter.fontPixelSize
  property alias fullBar: adapter.fullBar
  property alias iconSize: adapter.iconSize
  property alias lockClockSize: adapter.lockClockSize
  property alias lockShowMedia: adapter.lockShowMedia
  property alias mediaControlsAlwaysVisible: adapter.mediaControlsAlwaysVisible
  property alias mediaShowAlbumArt: adapter.mediaShowAlbumArt
  property alias mediaShowProgressBar: adapter.mediaShowProgressBar
  property alias notificationToastDurationMs: adapter.notificationToastDurationMs
  property alias reduceMotion: adapter.reduceMotion
  property alias spacingScale: adapter.spacingScale
  property alias systemShowUptime: adapter.systemShowUptime
  property alias timezone: adapter.timezone
  property alias weatherCity: adapter.weatherCity
  property alias weatherUnits: adapter.weatherUnits

  function save() {
    root.writeAdapter()
  }

  JsonAdapter {
    id: adapter

    property int barSize: 36
    property bool calendarWeekStartsMonday: false
    property bool ccShowAudio: true
    property bool ccShowDisplay: true
    property bool ccShowMedia: false
    property bool ccShowWeather: false
    property bool clock24h: true
    property bool clockShowSeconds: false
    property bool doNotDisturb: false
    property int fontPixelSize: 9
    property bool fullBar: false
    property int iconSize: 16
    property real lockClockSize: 72
    property bool lockShowMedia: true
    property bool mediaControlsAlwaysVisible: false
    property bool mediaShowAlbumArt: true
    property bool mediaShowProgressBar: true
    property real notificationToastDurationMs: 5000
    property bool reduceMotion: false
    property real spacingScale: 1.0
    property bool systemShowUptime: true
    property string timezone: ""
    property string weatherCity: ""
    property string weatherUnits: "metric"
  }
}
