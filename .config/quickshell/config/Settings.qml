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

  property alias barHeight: adapter.barHeight
  property alias calendarWeekStartsMonday: adapter.calendarWeekStartsMonday
  property alias ccShowAudio: adapter.ccShowAudio
  property alias ccShowBluetooth: adapter.ccShowBluetooth
  property alias ccShowDisplay: adapter.ccShowDisplay
  property alias ccShowNightLight: adapter.ccShowNightLight
  property alias ccShowWifi: adapter.ccShowWifi
  property alias clock24h: adapter.clock24h
  property alias clockShowSeconds: adapter.clockShowSeconds
  property alias collapsedWidth: adapter.collapsedWidth
  property alias cornerRadius: adapter.cornerRadius
  property alias doNotDisturb: adapter.doNotDisturb
  property alias expandedHeight: adapter.expandedHeight
  property alias fullBar: adapter.fullBar
  property alias gapFromScreenEdge: adapter.gapFromScreenEdge
  property alias lockClockSize: adapter.lockClockSize
  property alias lockShowMedia: adapter.lockShowMedia
  property alias mediaControlsAlwaysVisible: adapter.mediaControlsAlwaysVisible
  property alias mediaShowAlbumArt: adapter.mediaShowAlbumArt
  property alias mediaShowProgressBar: adapter.mediaShowProgressBar
  property alias motionBouncePercent: adapter.motionBouncePercent
  property alias motionFadeMs: adapter.motionFadeMs
  property alias motionHoverMs: adapter.motionHoverMs
  property alias motionMovementMs: adapter.motionMovementMs
  property alias notchFlare: adapter.notchFlare
  property alias notificationToastDurationMs: adapter.notificationToastDurationMs
  property alias reduceMotion: adapter.reduceMotion
  property alias spacingUnit: adapter.spacingUnit
  property alias systemShowUptime: adapter.systemShowUptime
  property alias weatherCity: adapter.weatherCity

  function save() {
    root.writeAdapter()
  }

  JsonAdapter {
    id: adapter

    property real barHeight: 34
    property bool calendarWeekStartsMonday: false
    property bool ccShowAudio: true
    property bool ccShowBluetooth: true
    property bool ccShowDisplay: true
    property bool ccShowNightLight: true
    property bool ccShowWifi: true
    property bool clock24h: true
    property bool clockShowSeconds: false
    property real collapsedWidth: 150
    property real cornerRadius: 10
    property bool doNotDisturb: false
    property real expandedHeight: 135
    property bool fullBar: false
    property real gapFromScreenEdge: 11
    property real lockClockSize: 72
    property bool lockShowMedia: true
    property bool mediaControlsAlwaysVisible: false
    property bool mediaShowAlbumArt: true
    property bool mediaShowProgressBar: true
    property real motionBouncePercent: 40
    property real motionFadeMs: 200
    property real motionHoverMs: 150
    property real motionMovementMs: 400
    property real notchFlare: 14
    property real notificationToastDurationMs: 5000
    property bool reduceMotion: false
    property real spacingUnit: 4
    property bool systemShowUptime: true
    property string weatherCity: ""
  }
}
