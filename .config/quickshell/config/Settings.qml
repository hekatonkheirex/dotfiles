// Persisted user preferences backed by settings.json.
// Keep build-time layout and typography constants in Config.qml; this object
// owns values that should survive a Quickshell restart.
pragma Singleton
import QtQml
import Quickshell
import Quickshell.Io
import "PaletteCatalog.js" as PaletteCatalog
import "DockModel.js" as DockModel

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
    schemaVersion: 3,
    dockEnabled: true,
    dockPinned: "brave-origin,kitty",
    sidebarEdgeHover: true,
    micIndicator: true,
    powerMenuQuote: "Take a breath.",
    powerMenuQuoteAuthor: "",
    calendarWeekStartsMonday: false,
    clock24h: true,
    doNotDisturb: false,
    fontPixelSize: 12,
    iconSize: 20,
    idleLockTimeoutSeconds: 300,
    idleSuspendTimeoutSeconds: 900,
    lastSettingsTab: 0,
    notificationCriticalBypass: true,
    notificationQuietHoursEnabled: false,
    notificationQuietHoursEnd: 420,
    notificationQuietHoursStart: 1320,
    notificationToastPosition: "top-right",
    notificationToastDurationMs: 8000,
    reduceMotion: false,
    spacingScale: 1.0,
    colorSource: "live",
    colorPalette: "material3",
    colorVariant: "auto",
    colorContrast: "standard",
    themePreference: 0,
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
    var stored = JSON.parse(root.text())
    var needsSave = stored.schemaVersion !== root.defaults.schemaVersion
    if (needsSave) {
      // R6: her normal toast timeout is 8 s; only the old untouched 5 s default moves.
      if (stored.schemaVersion < 3 && stored.notificationToastDurationMs === 5000)
        notificationToastDurationMs = root.defaults.notificationToastDurationMs
      adapter.schemaVersion = root.defaults.schemaVersion
    }
    var migratedPalette = PaletteCatalog.migratePaletteId(colorPalette)
    if (migratedPalette !== colorPalette) {
      colorPalette = migratedPalette
      needsSave = true
    }
    var normalizedPins = DockModel.pinnedToCsv(dockPinned)
    if (normalizedPins !== dockPinned) {
      dockPinned = normalizedPins
      needsSave = true
    }
    if (needsSave) root.save()
    initialLoadComplete = true
  }

  onAdapterUpdated: {
    initialLoadComplete = true
  }

  // Every key here has a reader. Delete a key from this file and settings.json together.
  property alias dockEnabled: adapter.dockEnabled
  property alias dockPinned: adapter.dockPinned
  property alias sidebarEdgeHover: adapter.sidebarEdgeHover
  property alias micIndicator: adapter.micIndicator
  property alias powerMenuQuote: adapter.powerMenuQuote
  property alias powerMenuQuoteAuthor: adapter.powerMenuQuoteAuthor
  property alias calendarWeekStartsMonday: adapter.calendarWeekStartsMonday
  property alias clock24h: adapter.clock24h
  property alias doNotDisturb: adapter.doNotDisturb
  property alias fontPixelSize: adapter.fontPixelSize
  property alias iconSize: adapter.iconSize
  property alias idleLockTimeoutSeconds: adapter.idleLockTimeoutSeconds
  property alias idleSuspendTimeoutSeconds: adapter.idleSuspendTimeoutSeconds
  property alias lastSettingsTab: adapter.lastSettingsTab
  property alias notificationCriticalBypass: adapter.notificationCriticalBypass
  property alias notificationQuietHoursEnabled: adapter.notificationQuietHoursEnabled
  property alias notificationQuietHoursEnd: adapter.notificationQuietHoursEnd
  property alias notificationQuietHoursStart: adapter.notificationQuietHoursStart
  property alias notificationToastPosition: adapter.notificationToastPosition
  property alias notificationToastDurationMs: adapter.notificationToastDurationMs
  property alias reduceMotion: adapter.reduceMotion
  property alias spacingScale: adapter.spacingScale
  property alias colorSource: adapter.colorSource
  property alias colorPalette: adapter.colorPalette
  property alias colorVariant: adapter.colorVariant
  property alias colorContrast: adapter.colorContrast
  property alias themePreference: adapter.themePreference
  property alias weatherAllowIpGeolocation: adapter.weatherAllowIpGeolocation
  property alias weatherLocation: adapter.weatherLocation
  property alias weatherRefreshIntervalMinutes: adapter.weatherRefreshIntervalMinutes
  property alias weatherUnits: adapter.weatherUnits


  function save() {
    root.writeAdapter()
  }

  function resetAppearanceToDefaults() {
    fontPixelSize = root.defaults.fontPixelSize
    iconSize = root.defaults.iconSize
    spacingScale = root.defaults.spacingScale
    colorSource = root.defaults.colorSource
    colorPalette = root.defaults.colorPalette
    colorVariant = root.defaults.colorVariant
    colorContrast = root.defaults.colorContrast
    themePreference = root.defaults.themePreference
    powerMenuQuote = root.defaults.powerMenuQuote
    powerMenuQuoteAuthor = root.defaults.powerMenuQuoteAuthor
    root.save()
  }

  JsonAdapter {
    id: adapter

    // Persisted format marker. Increment before a breaking key rename/removal
    // and migrate the stored data before writing the new schema.
    property int schemaVersion: root.defaults.schemaVersion
    property bool dockEnabled: root.defaults.dockEnabled
    property string dockPinned: root.defaults.dockPinned
    property bool sidebarEdgeHover: root.defaults.sidebarEdgeHover
    property bool micIndicator: root.defaults.micIndicator
    property string powerMenuQuote: root.defaults.powerMenuQuote
    property string powerMenuQuoteAuthor: root.defaults.powerMenuQuoteAuthor
    property bool calendarWeekStartsMonday: root.defaults.calendarWeekStartsMonday
    property bool clock24h: root.defaults.clock24h
    property bool doNotDisturb: root.defaults.doNotDisturb
    property int fontPixelSize: root.defaults.fontPixelSize
    property int iconSize: root.defaults.iconSize
    property int idleLockTimeoutSeconds: root.defaults.idleLockTimeoutSeconds
    property int idleSuspendTimeoutSeconds: root.defaults.idleSuspendTimeoutSeconds
    property int lastSettingsTab: root.defaults.lastSettingsTab
    property bool notificationCriticalBypass: root.defaults.notificationCriticalBypass
    property bool notificationQuietHoursEnabled: root.defaults.notificationQuietHoursEnabled
    property int notificationQuietHoursEnd: root.defaults.notificationQuietHoursEnd
    property int notificationQuietHoursStart: root.defaults.notificationQuietHoursStart
    property string notificationToastPosition: root.defaults.notificationToastPosition
    property real notificationToastDurationMs: root.defaults.notificationToastDurationMs
    property bool reduceMotion: root.defaults.reduceMotion
    property real spacingScale: root.defaults.spacingScale
    // Live reads the wallpaper-generated Matugen roles; fixed selects a
    // curated semantic palette from PaletteCatalog.js.
    property string colorSource: root.defaults.colorSource
    property string colorPalette: root.defaults.colorPalette
    property string colorVariant: root.defaults.colorVariant
    property string colorContrast: root.defaults.colorContrast
    // 0 = auto, 1 = light, 2 = dark.
    property int themePreference: root.defaults.themePreference
    property bool weatherAllowIpGeolocation: root.defaults.weatherAllowIpGeolocation
    property string weatherLocation: root.defaults.weatherLocation
    property int weatherRefreshIntervalMinutes: root.defaults.weatherRefreshIntervalMinutes
    property string weatherUnits: root.defaults.weatherUnits
  }
}
