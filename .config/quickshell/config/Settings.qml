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
  property alias ccShowBattery: adapter.ccShowBattery
  property alias ccShowDisplay: adapter.ccShowDisplay
  property alias ccShowFocusedWindow: adapter.ccShowFocusedWindow
  property alias ccShowLauncher: adapter.ccShowLauncher
  property alias ccShowMedia: adapter.ccShowMedia
  property alias ccShowNotifications: adapter.ccShowNotifications
  property alias ccShowClock: adapter.ccShowClock
  property alias ccShowTray: adapter.ccShowTray
  property alias ccShowWeather: adapter.ccShowWeather
  property alias ccShowWorkspaces: adapter.ccShowWorkspaces
  property alias clock24h: adapter.clock24h
  property alias clockShowSeconds: adapter.clockShowSeconds
  property alias doNotDisturb: adapter.doNotDisturb
  property alias fontPixelSize: adapter.fontPixelSize
  property alias fullBar: adapter.fullBar
  property alias iconSize: adapter.iconSize
  property alias idleLockTimeoutSeconds: adapter.idleLockTimeoutSeconds
  property alias idleSuspendTimeoutSeconds: adapter.idleSuspendTimeoutSeconds
  property alias lastSettingsTab: adapter.lastSettingsTab
  property alias lockClockSize: adapter.lockClockSize
  property alias lockShowMedia: adapter.lockShowMedia
  property alias lockUseWallpaper: adapter.lockUseWallpaper
  property alias mediaControlsAlwaysVisible: adapter.mediaControlsAlwaysVisible
  property alias mediaShowAlbumArt: adapter.mediaShowAlbumArt
  property alias mediaShowProgressBar: adapter.mediaShowProgressBar
  property alias notificationCriticalBypass: adapter.notificationCriticalBypass
  property alias notificationHistoryLimit: adapter.notificationHistoryLimit
  property alias notificationQuietHoursEnabled: adapter.notificationQuietHoursEnabled
  property alias notificationQuietHoursEnd: adapter.notificationQuietHoursEnd
  property alias notificationQuietHoursStart: adapter.notificationQuietHoursStart
  property alias notificationToastPosition: adapter.notificationToastPosition
  property alias notificationToastDurationMs: adapter.notificationToastDurationMs
  property alias reduceMotion: adapter.reduceMotion
  property alias spacingScale: adapter.spacingScale
  property alias systemShowUptime: adapter.systemShowUptime
  property alias themePreference: adapter.themePreference
  property alias timezone: adapter.timezone
  property alias weatherAllowIpGeolocation: adapter.weatherAllowIpGeolocation
  property alias weatherLocation: adapter.weatherLocation
  property alias weatherRefreshIntervalMinutes: adapter.weatherRefreshIntervalMinutes
  property alias weatherUnits: adapter.weatherUnits

  function save() {
    root.writeAdapter()
  }

  function resetToDefaults() {
    barSize = 36
    calendarWeekStartsMonday = false
    ccShowAudio = true
    ccShowBattery = true
    ccShowDisplay = true
    ccShowFocusedWindow = true
    ccShowLauncher = true
    ccShowMedia = false
    ccShowNotifications = true
    ccShowClock = true
    ccShowTray = true
    ccShowWeather = false
    ccShowWorkspaces = true
    clock24h = true
    clockShowSeconds = false
    doNotDisturb = false
    fontPixelSize = 9
    fullBar = false
    iconSize = 16
    idleLockTimeoutSeconds = 300
    idleSuspendTimeoutSeconds = 900
    lastSettingsTab = 0
    lockClockSize = 72
    lockShowMedia = true
    lockUseWallpaper = false
    mediaControlsAlwaysVisible = false
    mediaShowAlbumArt = true
    mediaShowProgressBar = true
    notificationCriticalBypass = true
    notificationHistoryLimit = 50
    notificationQuietHoursEnabled = false
    notificationQuietHoursEnd = 420
    notificationQuietHoursStart = 1320
    notificationToastPosition = "top-right"
    notificationToastDurationMs = 5000
    reduceMotion = false
    spacingScale = 1.0
    systemShowUptime = true
    themePreference = 0
    timezone = ""
    weatherAllowIpGeolocation = false
    weatherLocation = ""
    weatherRefreshIntervalMinutes = 15
    weatherUnits = "metric"
    root.save()
  }

  JsonAdapter {
    id: adapter

    // Persisted format marker. Increment before a breaking key rename/removal
    // and migrate the stored data before writing the new schema.
    property int schemaVersion: 1
    property int barSize: 36
    property bool calendarWeekStartsMonday: false
    property bool ccShowAudio: true
    property bool ccShowBattery: true
    property bool ccShowDisplay: true
    property bool ccShowFocusedWindow: true
    property bool ccShowLauncher: true
    property bool ccShowMedia: false
    property bool ccShowNotifications: true
    property bool ccShowClock: true
    property bool ccShowTray: true
    property bool ccShowWeather: false
    property bool ccShowWorkspaces: true
    property bool clock24h: true
    property bool clockShowSeconds: false
    property bool doNotDisturb: false
    property int fontPixelSize: 9
    property bool fullBar: false
    property int iconSize: 16
    property int idleLockTimeoutSeconds: 300
    property int idleSuspendTimeoutSeconds: 900
    property int lastSettingsTab: 0
    property real lockClockSize: 72
    property bool lockShowMedia: true
    property bool lockUseWallpaper: false
    property bool mediaControlsAlwaysVisible: false
    property bool mediaShowAlbumArt: true
    property bool mediaShowProgressBar: true
    property bool notificationCriticalBypass: true
    property int notificationHistoryLimit: 50
    property bool notificationQuietHoursEnabled: false
    property int notificationQuietHoursEnd: 420
    property int notificationQuietHoursStart: 1320
    property string notificationToastPosition: "top-right"
    property real notificationToastDurationMs: 5000
    property bool reduceMotion: false
    property real spacingScale: 1.0
    property bool systemShowUptime: true
    // 0 = auto, 1 = light, 2 = dark.
    property int themePreference: 0
    property string timezone: ""
    property bool weatherAllowIpGeolocation: false
    property string weatherLocation: ""
    property int weatherRefreshIntervalMinutes: 15
    property string weatherUnits: "metric"
  }
}
