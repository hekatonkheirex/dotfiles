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

  property alias calendarWeekStartsMonday: adapter.calendarWeekStartsMonday
  property alias ccShowAudio: adapter.ccShowAudio
  property alias ccShowBluetooth: adapter.ccShowBluetooth
  property alias ccShowDisplay: adapter.ccShowDisplay
  property alias ccShowNightLight: adapter.ccShowNightLight
  property alias ccShowWifi: adapter.ccShowWifi
  property alias clock24h: adapter.clock24h
  property alias clockShowSeconds: adapter.clockShowSeconds
  property alias doNotDisturb: adapter.doNotDisturb
  property alias fullBar: adapter.fullBar
  property alias lockClockSize: adapter.lockClockSize
  property alias lockShowMedia: adapter.lockShowMedia
  property alias mediaControlsAlwaysVisible: adapter.mediaControlsAlwaysVisible
  property alias mediaShowAlbumArt: adapter.mediaShowAlbumArt
  property alias mediaShowProgressBar: adapter.mediaShowProgressBar
  property alias notificationToastDurationMs: adapter.notificationToastDurationMs
  property alias reduceMotion: adapter.reduceMotion
  property alias systemShowUptime: adapter.systemShowUptime
  property alias weatherCity: adapter.weatherCity

  function save() {
    root.writeAdapter()
  }

  JsonAdapter {
    id: adapter

    property bool calendarWeekStartsMonday: false
    property bool ccShowAudio: true
    property bool ccShowBluetooth: true
    property bool ccShowDisplay: true
    property bool ccShowNightLight: true
    property bool ccShowWifi: true
    property bool clock24h: true
    property bool clockShowSeconds: false
    property bool doNotDisturb: false
    property bool fullBar: false
    property real lockClockSize: 72
    property bool lockShowMedia: true
    property bool mediaControlsAlwaysVisible: false
    property bool mediaShowAlbumArt: true
    property bool mediaShowProgressBar: true
    property real notificationToastDurationMs: 5000
    property bool reduceMotion: false
    property bool systemShowUptime: true
    property string weatherCity: ""
  }
}
