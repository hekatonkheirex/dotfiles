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
  preload: true

  // Consumers use this to distinguish the initial persisted snapshot from a
  // later user edit. JsonAdapter starts with its defaults before the file is
  // loaded, so its first value changes are not user-initiated.
  property bool initialLoadComplete: false

  // Keep persisted defaults in one place. JsonAdapter needs these values for
  // missing keys, while the reset actions reuse the same snapshot below.
  readonly property var defaults: ({
    schemaVersion: 1,
    barSize: 42,
    barWidgetOrder: "launcher,workspaces,layout,focused,gap,center,audio,display,media,weather,battery,tray,notifications,clock",
    barClockInFlow: false,
    calendarWeekStartsMonday: false,
    ccShowAudio: true,
    ccShowBattery: true,
    ccShowDisplay: true,
    ccShowFocusedWindow: true,
    ccShowLayout: true,
    ccShowLauncher: true,
    ccShowMedia: false,
    ccShowNotifications: true,
    ccShowClock: true,
    ccShowTray: true,
    ccShowWeather: false,
    ccShowWorkspaces: true,
    workspaceShape: "numbers",
    workspaceCount: "active",
    clock24h: true,
    clockShowSeconds: false,
    clockFontSize: 14,
    doNotDisturb: false,
    fontPixelSize: 12,
    fullBar: false,
    iconSize: 20,
    idleLockTimeoutSeconds: 300,
    idleSuspendTimeoutSeconds: 900,
    lastSettingsTab: 0,
    settingsPanelWidth: -1,
    settingsPanelHeight: -1,
    lockClockSize: 72,
    lockShowMedia: true,
    lockUseWallpaper: false,
    mediaControlsAlwaysVisible: false,
    mediaShowAlbumArt: true,
    mediaShowProgressBar: true,
    notificationCriticalBypass: true,
    notificationHistoryLimit: 50,
    notificationQuietHoursEnabled: false,
    notificationQuietHoursEnd: 420,
    notificationQuietHoursStart: 1320,
    notificationToastPosition: "top-right",
    notificationToastDurationMs: 5000,
    reduceMotion: false,
    reduceTransparency: false,
    spacingScale: 1.0,
    systemShowUptime: true,
    colorSource: "live",
    colorPalette: "material3",
    colorVariant: "auto",
    colorContrast: "standard",
    themeStyle: "nothing",
    nothingVariant: "evolution",
    lockClockFace: "micrographics",
    themePreference: 0,
    timezone: "",
    weatherAllowIpGeolocation: false,
    weatherLocation: "",
    weatherRefreshIntervalMinutes: 15,
    weatherUnits: "metric"
  })

  // FileView's preload flag only arms the asynchronous read. Explicitly
  // request the initial snapshot so JsonAdapter-backed preferences are
  // available before Colors and the settings UI resolve their bindings.
  property var initialLoad: Timer {
    interval: 1
    running: true
    repeat: false
    onTriggered: root.reload()
  }

  onLoadFailed: function(error) {
    if (error === FileViewError.FileNotFound) root.writeAdapter()
    initialLoadComplete = true
  }

  // adapterUpdated is emitted for adapter writes, not for the initial file
  // read. Use FileView's load signal so surfaces that depend on persisted
  // settings are created with the loaded values.
  onLoaded: {
    if (themeStyle === "neo-brutalism") {
      themeStyle = "nothing"
      nothingVariant = "evolution"
      root.save()
    }
    initialLoadComplete = true
  }

  onAdapterUpdated: {
    initialLoadComplete = true
  }

  // Keep persisted aliases paired with active consumers. Remove obsolete fields
  // from this schema and settings.json together during deliberate migrations.
  property alias barSize: adapter.barSize
  property alias barWidgetOrder: adapter.barWidgetOrder
  property alias barClockInFlow: adapter.barClockInFlow
  property alias calendarWeekStartsMonday: adapter.calendarWeekStartsMonday
  property alias ccShowAudio: adapter.ccShowAudio
  property alias ccShowBattery: adapter.ccShowBattery
  property alias ccShowDisplay: adapter.ccShowDisplay
  property alias ccShowFocusedWindow: adapter.ccShowFocusedWindow
  property alias ccShowLayout: adapter.ccShowLayout
  property alias ccShowLauncher: adapter.ccShowLauncher
  property alias ccShowMedia: adapter.ccShowMedia
  property alias ccShowNotifications: adapter.ccShowNotifications
  property alias ccShowClock: adapter.ccShowClock
  property alias ccShowTray: adapter.ccShowTray
  property alias ccShowWeather: adapter.ccShowWeather
  property alias ccShowWorkspaces: adapter.ccShowWorkspaces
  property alias workspaceShape: adapter.workspaceShape
  property alias workspaceCount: adapter.workspaceCount
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
  property alias reduceTransparency: adapter.reduceTransparency
  property alias notificationHistoryLimit: adapter.notificationHistoryLimit
  property alias notificationQuietHoursEnabled: adapter.notificationQuietHoursEnabled
  property alias notificationQuietHoursEnd: adapter.notificationQuietHoursEnd
  property alias notificationQuietHoursStart: adapter.notificationQuietHoursStart
  property alias notificationToastPosition: adapter.notificationToastPosition
  property alias notificationToastDurationMs: adapter.notificationToastDurationMs
  property alias reduceMotion: adapter.reduceMotion
  property alias spacingScale: adapter.spacingScale
  property alias systemShowUptime: adapter.systemShowUptime
  property alias colorSource: adapter.colorSource
  property alias colorPalette: adapter.colorPalette
  property alias colorVariant: adapter.colorVariant
  property alias colorContrast: adapter.colorContrast
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
    barSize = root.defaults.barSize
    clockFontSize = root.defaults.clockFontSize
    fontPixelSize = root.defaults.fontPixelSize
    fullBar = root.defaults.fullBar
    iconSize = root.defaults.iconSize
    reduceTransparency = root.defaults.reduceTransparency
    spacingScale = root.defaults.spacingScale
    workspaceShape = root.defaults.workspaceShape
    workspaceCount = root.defaults.workspaceCount
    colorSource = root.defaults.colorSource
    colorPalette = root.defaults.colorPalette
    colorVariant = root.defaults.colorVariant
    colorContrast = root.defaults.colorContrast
    themeStyle = root.defaults.themeStyle
    nothingVariant = root.defaults.nothingVariant
    lockClockFace = root.defaults.lockClockFace
    themePreference = root.defaults.themePreference
  }

  function resetAppearanceToDefaults() {
    resetAppearanceDefaults()
    root.save()
  }

  function resetToDefaults() {
    resetAppearanceDefaults()
    barWidgetOrder = root.defaults.barWidgetOrder
    barClockInFlow = root.defaults.barClockInFlow
    calendarWeekStartsMonday = root.defaults.calendarWeekStartsMonday
    ccShowAudio = root.defaults.ccShowAudio
    ccShowBattery = root.defaults.ccShowBattery
    ccShowDisplay = root.defaults.ccShowDisplay
    ccShowFocusedWindow = root.defaults.ccShowFocusedWindow
    ccShowLayout = root.defaults.ccShowLayout
    ccShowLauncher = root.defaults.ccShowLauncher
    ccShowMedia = root.defaults.ccShowMedia
    ccShowNotifications = root.defaults.ccShowNotifications
    ccShowClock = root.defaults.ccShowClock
    ccShowTray = root.defaults.ccShowTray
    ccShowWeather = root.defaults.ccShowWeather
    ccShowWorkspaces = root.defaults.ccShowWorkspaces
    clock24h = root.defaults.clock24h
    clockShowSeconds = root.defaults.clockShowSeconds
    doNotDisturb = root.defaults.doNotDisturb
    idleLockTimeoutSeconds = root.defaults.idleLockTimeoutSeconds
    idleSuspendTimeoutSeconds = root.defaults.idleSuspendTimeoutSeconds
    lastSettingsTab = root.defaults.lastSettingsTab
    settingsPanelWidth = root.defaults.settingsPanelWidth
    settingsPanelHeight = root.defaults.settingsPanelHeight
    lockClockSize = root.defaults.lockClockSize
    lockShowMedia = root.defaults.lockShowMedia
    lockUseWallpaper = root.defaults.lockUseWallpaper
    mediaControlsAlwaysVisible = root.defaults.mediaControlsAlwaysVisible
    mediaShowAlbumArt = root.defaults.mediaShowAlbumArt
    mediaShowProgressBar = root.defaults.mediaShowProgressBar
    notificationCriticalBypass = root.defaults.notificationCriticalBypass
    notificationHistoryLimit = root.defaults.notificationHistoryLimit
    notificationQuietHoursEnabled = root.defaults.notificationQuietHoursEnabled
    notificationQuietHoursEnd = root.defaults.notificationQuietHoursEnd
    notificationQuietHoursStart = root.defaults.notificationQuietHoursStart
    notificationToastPosition = root.defaults.notificationToastPosition
    notificationToastDurationMs = root.defaults.notificationToastDurationMs
    reduceMotion = root.defaults.reduceMotion
    systemShowUptime = root.defaults.systemShowUptime
    timezone = root.defaults.timezone
    weatherAllowIpGeolocation = root.defaults.weatherAllowIpGeolocation
    weatherLocation = root.defaults.weatherLocation
    weatherRefreshIntervalMinutes = root.defaults.weatherRefreshIntervalMinutes
    weatherUnits = root.defaults.weatherUnits
    root.save()
  }

  JsonAdapter {
    id: adapter

    // Persisted format marker. Increment before a breaking key rename/removal
    // and migrate the stored data before writing the new schema.
    property int schemaVersion: root.defaults.schemaVersion
    property int barSize: root.defaults.barSize
    property string barWidgetOrder: root.defaults.barWidgetOrder
    property bool barClockInFlow: root.defaults.barClockInFlow
    property bool calendarWeekStartsMonday: root.defaults.calendarWeekStartsMonday
    property bool ccShowAudio: root.defaults.ccShowAudio
    property bool ccShowBattery: root.defaults.ccShowBattery
    property bool ccShowDisplay: root.defaults.ccShowDisplay
    property bool ccShowFocusedWindow: root.defaults.ccShowFocusedWindow
    property bool ccShowLayout: root.defaults.ccShowLayout
    property bool ccShowLauncher: root.defaults.ccShowLauncher
    property bool ccShowMedia: root.defaults.ccShowMedia
    property bool ccShowNotifications: root.defaults.ccShowNotifications
    property bool ccShowClock: root.defaults.ccShowClock
    property bool ccShowTray: root.defaults.ccShowTray
    property bool ccShowWeather: root.defaults.ccShowWeather
    property bool ccShowWorkspaces: root.defaults.ccShowWorkspaces
    property string workspaceShape: root.defaults.workspaceShape
    property string workspaceCount: root.defaults.workspaceCount
    property bool clock24h: root.defaults.clock24h
    property bool clockShowSeconds: root.defaults.clockShowSeconds
    property int clockFontSize: root.defaults.clockFontSize
    property bool doNotDisturb: root.defaults.doNotDisturb
    property int fontPixelSize: root.defaults.fontPixelSize
    property bool fullBar: root.defaults.fullBar
    property int iconSize: root.defaults.iconSize
    property int idleLockTimeoutSeconds: root.defaults.idleLockTimeoutSeconds
    property int idleSuspendTimeoutSeconds: root.defaults.idleSuspendTimeoutSeconds
    property int lastSettingsTab: root.defaults.lastSettingsTab
    // -1 = user hasn't resized the settings panel yet; fall back to Config's default size.
    property int settingsPanelWidth: root.defaults.settingsPanelWidth
    property int settingsPanelHeight: root.defaults.settingsPanelHeight
    property real lockClockSize: root.defaults.lockClockSize
    property bool lockShowMedia: root.defaults.lockShowMedia
    property bool lockUseWallpaper: root.defaults.lockUseWallpaper
    property bool mediaControlsAlwaysVisible: root.defaults.mediaControlsAlwaysVisible
    property bool mediaShowAlbumArt: root.defaults.mediaShowAlbumArt
    property bool mediaShowProgressBar: root.defaults.mediaShowProgressBar
    property bool notificationCriticalBypass: root.defaults.notificationCriticalBypass
    property bool reduceTransparency: root.defaults.reduceTransparency
    property int notificationHistoryLimit: root.defaults.notificationHistoryLimit
    property bool notificationQuietHoursEnabled: root.defaults.notificationQuietHoursEnabled
    property int notificationQuietHoursEnd: root.defaults.notificationQuietHoursEnd
    property int notificationQuietHoursStart: root.defaults.notificationQuietHoursStart
    property string notificationToastPosition: root.defaults.notificationToastPosition
    property real notificationToastDurationMs: root.defaults.notificationToastDurationMs
    property bool reduceMotion: root.defaults.reduceMotion
    property real spacingScale: root.defaults.spacingScale
    property bool systemShowUptime: root.defaults.systemShowUptime
    // Live reads the wallpaper-generated Matugen roles; fixed selects a
    // curated semantic palette from PaletteCatalog.js.
    property string colorSource: root.defaults.colorSource
    property string colorPalette: root.defaults.colorPalette
    property string colorVariant: root.defaults.colorVariant
    property string colorContrast: root.defaults.colorContrast
    // Nothing Classic remains selectable until Evolution's release and review;
    // Evolution uses wallpaper-aware roles.
    property string themeStyle: root.defaults.themeStyle
    property string nothingVariant: root.defaults.nothingVariant
    property string lockClockFace: root.defaults.lockClockFace
    // 0 = auto, 1 = light, 2 = dark.
    property int themePreference: root.defaults.themePreference
    property string timezone: root.defaults.timezone
    property bool weatherAllowIpGeolocation: root.defaults.weatherAllowIpGeolocation
    property string weatherLocation: root.defaults.weatherLocation
    property int weatherRefreshIntervalMinutes: root.defaults.weatherRefreshIntervalMinutes
    property string weatherUnits: root.defaults.weatherUnits
  }
}
