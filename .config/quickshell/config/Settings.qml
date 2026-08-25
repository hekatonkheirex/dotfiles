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
  property alias clockFontSize: adapter.clockFontSize
  property alias doNotDisturb: adapter.doNotDisturb
  property alias fontPixelSize: adapter.fontPixelSize
  property alias fullBar: adapter.fullBar
  property alias iconSize: adapter.iconSize
  property alias idleLockTimeoutSeconds: adapter.idleLockTimeoutSeconds
  property alias idleSuspendTimeoutSeconds: adapter.idleSuspendTimeoutSeconds
  property alias lastSettingsTab: adapter.lastSettingsTab
  property alias settingsPanelWidth: adapter.settingsPanelWidth
  property alias settingsPanelHeight: adapter.settingsPanelHeight
  property alias lockClockSize: adapter.lockClockSize
  property alias lockClockFace: adapter.lockClockFace
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
  property alias nothingVariant: adapter.nothingVariant
  property alias themeStyle: adapter.themeStyle
  property alias themePreference: adapter.themePreference
  property alias timezone: adapter.timezone
  property alias weatherAllowIpGeolocation: adapter.weatherAllowIpGeolocation
  property alias weatherLocation: adapter.weatherLocation
  property alias weatherRefreshIntervalMinutes: adapter.weatherRefreshIntervalMinutes
  property alias weatherUnits: adapter.weatherUnits

  function save() {
    root.writeAdapter()
  }

  function resetAppearanceDefaults() {
    barSize = 44
    clockFontSize = 18
    fontPixelSize = 12
    fullBar = false
    iconSize = 20
    spacingScale = 1.0
    themeStyle = "nothing"
    nothingVariant = "evolution"
    lockClockFace = "micrographics"
    themePreference = 0
  }

  function resetAppearanceToDefaults() {
    resetAppearanceDefaults()
    root.save()
  }

  function resetToDefaults() {
    resetAppearanceDefaults()
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
    idleLockTimeoutSeconds = 300
    idleSuspendTimeoutSeconds = 900
    lastSettingsTab = 0
    lockClockSize = 72
    lockClockFace = "micrographics"
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
    systemShowUptime = true
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
    property int barSize: 44
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
    property int clockFontSize: 18
    property bool doNotDisturb: false
    property int fontPixelSize: 12
    property bool fullBar: false
    property int iconSize: 20
    property int idleLockTimeoutSeconds: 300
    property int idleSuspendTimeoutSeconds: 900
    property int lastSettingsTab: 0
    // -1 = user hasn't resized the settings panel yet; fall back to Config's default size.
    property int settingsPanelWidth: -1
    property int settingsPanelHeight: -1
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
    // UI style; Nothing Classic and Ghost select fixed Quickshell palettes,
    // while Nothing Evolution and the other styles can use Matugen roles.
    property string themeStyle: "nothing"
    // Classic Nothing remains available as a fallback while Evolution uses
    // the wallpaper-aware Nothing OS 5 visual language.
    property string nothingVariant: "evolution"
    property string lockClockFace: "micrographics"
    // 0 = auto, 1 = light, 2 = dark.
    property int themePreference: 0
    property string timezone: ""
    property bool weatherAllowIpGeolocation: false
    property string weatherLocation: ""
    property int weatherRefreshIntervalMinutes: 15
    property string weatherUnits: "metric"
  }
}
