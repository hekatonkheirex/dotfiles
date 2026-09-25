pragma Singleton
import QtQml
import QtQuick
import Quickshell

QtObject {
  // Keep Niri as the compatibility default, but detect Mango when the shell
  // is started from the Mango session or its user service environment.
  readonly property string wmType: {
    var desktop = String(Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase()
    var sessionDesktop = String(Quickshell.env("XDG_SESSION_DESKTOP") || "").toLowerCase()
    return desktop.indexOf("mango") === 0 || sessionDesktop.indexOf("mango") === 0
      ? "mango"
      : "niri"
  }
  readonly property bool isNiri: wmType === "niri"
  readonly property bool isMango: wmType === "mango"
  // UI style is separate from the desktop palette. Material 3 and Liquid
  // Glass consume Matugen roles; Nothing Classic and Ghost use authored
  // palettes, while Nothing Evolution uses the adaptive cache.
  readonly property bool nothingDesign: Settings.themeStyle === "nothing"
  readonly property bool nothingEvolution: nothingDesign && Settings.nothingVariant === "evolution"
  readonly property bool ghostTheme: Settings.themeStyle === "ghost"
  readonly property bool liquidGlassTheme: Settings.themeStyle === "liquid-glass"
  readonly property bool material3Theme: !nothingDesign && !ghostTheme && !liquidGlassTheme

  // Niri's layer rule already enables background effects for unknown
  // quickshell namespaces when the user has compositor blur enabled. Keep
  // transient Liquid Glass surfaces on that path, but leave the persistent
  // bar open and transparent at rest. The lock surface owns its own
  // full-screen wallpaper blur.
  function layerNamespace(kind) {
    return liquidGlassTheme && kind !== "panel"
      ? "quickshell-liquid-glass-" + kind
      : "quickshell-" + kind
  }

  // Compact X390 geometry and shared spacing used by active surfaces.
  // Live-adjustable via the Appearance settings tab's Bar Size slider.
  // Ghost keeps the recovered 34px HUD rail; the shared slider can still make
  // it smaller, while Material, Neo, and Nothing retain the selected size.
  readonly property int barWidth: ghostTheme
    ? Math.min(Settings.barSize, 34)
    : Settings.barSize
  readonly property int widgetSize: barWidth
  // Live-adjustable via the Appearance settings tab (single density scale);
  // mirrors Settings the same way reducedMotion below does, so every binding
  // that reads these updates immediately without touching the consuming file.
  property real spacingScale: Settings.spacingScale
  property int spacingCompact: Math.round(4 * spacingScale)
  property int spacingSmall: Math.round(8 * spacingScale)
  property int spacingMedium: Math.round(12 * spacingScale)
  property int spacingLarge: Math.round(16 * spacingScale)
  property int spacingExtraLarge: Math.round(24 * spacingScale)
  property int spacingPage: Math.round(32 * spacingScale)
  // Reserve visual breathing room between tab content and the outer settings
  // scrollbar, which is intentionally overlaid on the Flickable edge.
  readonly property int settingsScrollbarGutter: spacingMedium

  // Classic keeps its NType display and mono labels, but uses a readable
  // sans for dense settings copy instead of setting paragraphs in display type.
  readonly property string fontFamily: nothingEvolution
    ? "Geist"
    : (nothingDesign ? "Noto Sans" : (ghostTheme ? "JetBrains Mono" : "Roboto Flex"))
  readonly property string monoFontFamily: nothingEvolution
    ? "Geist Mono"
    : (nothingDesign ? "NType 82 Mono" : (ghostTheme ? "JetBrains Mono" : "Roboto Flex"))
  readonly property string displayFontFamily: nothingEvolution
    ? "Geist"
    : (nothingDesign ? "NType 82 Headline" : fontFamily)
  // Evolution dials dot-matrix typography back to intentional accent areas;
  // compact clocks and numeric readouts use Geist Mono instead.
  readonly property string dotFontFamily: nothingEvolution
    ? "Geist Mono"
    : (nothingDesign ? "Ndot 57" : displayFontFamily)
  // Material 3 and Ghost use outlined icons; Nothing uses rounded symbols.
  // Liquid Glass resolves labels through the desktop symbolic icon theme.
  readonly property string iconFont: nothingDesign ? "Material Symbols Rounded" : "Material Symbols Outlined"
  readonly property int iconWeight: 400
  readonly property int iconGrade: 0
  function iconVariableAxes(fill, pixelSize) {
    var normalizedFill = Math.max(0, Math.min(1, fill))
    var opticalSize = Math.max(20, Math.min(48, pixelSize))
    return {
      "FILL": normalizedFill,
      "GRAD": iconGrade,
      "opsz": opticalSize,
      "wght": iconWeight
    }
  }

  // Existing callers use Material-style names because those labels are also
  // used by the non-Liquid themes. Keep that API stable and translate it once
  // for Liquid Glass to the symbolic names provided by the active icon theme.
  // The mapping deliberately uses freedesktop names rather than shipping
  // Apple's proprietary font/assets, which Qt on Linux cannot address by SF
  // Symbol name at runtime.
  function liquidGlassIconName(icon) {
    var name = icon === undefined || icon === null ? "" : String(icon)
    var symbols = {
      "apps": "view-app-grid-symbolic",
      "application": "application-x-executable-symbolic",
      "123": "view-list-symbolic",
      "air": "weather-windy-symbolic",
      "airplanemode_active": "airplane-mode-symbolic",
      "airplanemode_inactive": "airplane-mode-disabled-symbolic",
      "aspect_ratio": "resize-to-fit-content-symbolic",
      "auto_awesome": "sparkleshare-symbolic",
      "balance": "power-profile-balanced-symbolic",
      "balanced": "power-profile-balanced-symbolic",
      "battery_1_bar": "battery-level-10-symbolic",
      "battery_2_bar": "battery-level-20-symbolic",
      "battery_3_bar": "battery-level-30-symbolic",
      "battery_4_bar": "battery-level-50-symbolic",
      "battery_5_bar": "battery-level-70-symbolic",
      "battery_6_bar": "battery-level-90-symbolic",
      "battery_alert": "battery-caution-symbolic",
      "battery_charging_full": "battery-full-charging-symbolic",
      "battery_full": "battery-full-symbolic",
      "battery_saver": "power-profile-power-saver-symbolic",
      "battery_unknown": "battery-missing-symbolic",
      "bedtime": "system-suspend-symbolic",
      "bluetooth": "bluetooth-symbolic",
      "bluetooth_connected": "bluetooth-active-symbolic",
      "bluetooth_disabled": "bluetooth-disabled-symbolic",
      "bluetooth_searching": "bluetooth-acquiring-symbolic",
      "blur_on": "preferences-desktop-display-symbolic",
      "bolt": "bolt-symbolic",
      "brightness_auto": "display-brightness-symbolic",
      "brightness_empty": "display-brightness-off-symbolic",
      "brightness_high": "display-brightness-symbolic",
      "brightness_low": "display-brightness-low-symbolic",
      "brightness_medium": "display-brightness-medium-symbolic",
      "brightness_2": "weather-clear-night-symbolic",
      "bubble_chart": "workspacelistentryicon-nature-symbolic",
      "calendar_view_week": "calendar-week-symbolic",
      "check": "checkmark-symbolic",
      "chevron_left": "go-previous-symbolic",
      "chevron_right": "go-next-symbolic",
      "circle": "radio-checked-symbolic",
      "close": "window-close-symbolic",
      "cloud": "weather-cloudy-symbolic",
      "cloud_off": "weather-none-available-symbolic",
      "coffee": "workspacelistentryicon-drinks-symbolic",
      "code": "workspacelistentryicon-code-symbolic",
      "compress": "view-compact-symbolic",
      "content_copy": "edit-copy-symbolic",
      "content_paste": "edit-paste-symbolic",
      "contrast": "image-adjust-contrast-symbolic",
      "crop": "image-crop-symbolic",
      "crop_din": "image-crop-symbolic",
      "crop_free": "image-crop-symbolic",
      "dark_mode": "night-light-symbolic",
      "data_object": "workspacelistentryicon-code-symbolic",
      "dns": "network-server-symbolic",
      "dashboard": "view-tasks-all-symbolic",
      "database": "network-server-database-symbolic",
      "delete": "edit-delete-symbolic",
      "delete_sweep": "trash-symbolic",
      "device_thermostat": "temperature-symbolic",
      "do_not_disturb_on": "notification-disabled-symbolic",
      "dock_to_bottom": "dock-symbolic",
      "dock_to_left": "dock-symbolic",
      "dock_to_right": "dock-symbolic",
      "dynamic_feed": "view-list-symbolic",
      "edit": "document-edit-symbolic",
      "expressive": "sparkleshare-symbolic",
      "extension": "application-x-addon-symbolic",
      "filter_9_plus": "view-list-symbolic",
      "foggy": "weather-fog-symbolic",
      "format_size": "format-text-larger-symbolic",
      "grid_3x3": "view-app-grid-symbolic",
      "grid_view": "view-grid-symbolic",
      "health_and_safety": "security-high-symbolic",
      "height": "resize-to-fit-content-symbolic",
      "history": "view-restore-symbolic",
      "horizontal_rule": "format-linear-symbolic",
      "image": "image-x-generic-symbolic",
      "keyboard": "input-keyboard-symbolic",
      "lan": "network-wired-symbolic",
      "language": "workspacelistentryicon-language-symbolic",
      "layers": "dialog-layers-symbolic",
      "lens_blur": "image-filter-symbolic",
      "light_mode": "weather-clear-symbolic",
      "linear_scale": "format-linear-symbolic",
      "link": "link-symbolic",
      "link_off": "edit-clone-unlink-symbolic",
      "location_on": "mark-location-symbolic",
      "lock": "lock-small-symbolic",
      "looks_5": "view-list-symbolic",
      "memory": "am-memory-symbolic",
      "mic": "microphone-symbolic",
      "mic_off": "microphone-hardware-disabled-symbolic",
      "mode_fan": "am-fan-symbolic",
      "monitor": "video-display-symbolic",
      "monitor_heart": "utilities-system-monitor-symbolic",
      "motion_photos_off": "view-refresh-symbolic",
      "mouse": "input-mouse-symbolic",
      "music_note": "music-note-symbolic",
      "my_location": "find-location-symbolic",
      "navigation": "find-location-symbolic",
      "network_intelligence": "am-network-symbolic",
      "nights_stay": "weather-clear-night-symbolic",
      "notifications": "notification-symbolic",
      "notifications_active": "notification-alert-symbolic",
      "open_in_new": "external-link-symbolic",
      "pause": "media-playback-pause-symbolic",
      "palette": "applications-graphics-symbolic",
      "partly_cloudy_day": "weather-few-clouds-symbolic",
      "performance": "power-profile-performance-symbolic",
      "person": "workspacelistentryicon-person-symbolic",
      "photo_size_select_small": "resize-to-fit-content-symbolic",
      "play_arrow": "media-playback-start-symbolic",
      "play_circle": "media-playback-start-symbolic",
      "power_off": "system-shutdown-symbolic",
      "power_settings_new": "system-shutdown-symbolic",
      "priority_high": "dialog-warning-symbolic",
      "queue_music": "view-list-symbolic",
      "radio_button_checked": "radio-checked-symbolic",
      "radio_button_unchecked": "radio-symbolic",
      "rainy": "weather-showers-symbolic",
      "refresh": "view-refresh-symbolic",
      "repeat": "media-playlist-repeat-symbolic",
      "restart_alt": "system-reboot-symbolic",
      "rounded_corner": "resize-to-fit-content-symbolic",
      "schedule": "clock-app-symbolic",
      "screen_rotation": "rotation-allowed-symbolic",
      "screenshot_monitor": "screenshot-ui-display-symbolic",
      "search": "edit-find-symbolic",
      "select_window": "window-symbolic",
      "settings": "preferences-system-symbolic",
      "settings_backup_restore": "reset-settings-symbolic",
      "settings_suggest": "preferences-system-symbolic",
      "shapes": "applications-other-symbolic",
      "shuffle": "media-playlist-shuffle-symbolic",
      "skip_next": "media-skip-forward-symbolic",
      "skip_previous": "media-skip-backward-symbolic",
      "snowing": "weather-snow-symbolic",
      "space_bar": "input-keyboard-symbolic",
      "speed": "speedometer-symbolic",
      "sports_esports": "applications-games-symbolic",
      "square": "object-select-symbolic",
      "storage": "drive-harddisk-symbolic",
      "stop": "media-playback-stop-symbolic",
      "sunny": "weather-clear-symbolic",
      "swap_horiz": "view-refresh-symbolic",
      "swap_vert": "view-sort-ascending-symbolic",
      "swipe": "touch-two-finger-long-press-symbolic",
      "swipe_vertical": "touch-two-finger-long-press-symbolic",
      "sync": "view-refresh-symbolic",
      "sync_alt": "view-refresh-symbolic",
      "terminal": "utilities-terminal-symbolic",
      "thermostat": "temperature-symbolic",
      "thunderstorm": "weather-storm-symbolic",
      "timer": "timer-symbolic",
      "tonality": "image-adjust-colors-symbolic",
      "touch_app": "input-touchpad-symbolic",
      "touchpad_mouse": "input-touchpad-symbolic",
      "trending_up": "view-sort-ascending-symbolic",
      "tune": "preferences-system-symbolic",
      "umbrella": "weather-showers-symbolic",
      "update": "system-update-symbolic",
      "vertical_align_bottom": "view-bottom-pane-symbolic",
      "vertical_align_top": "view-top-pane-symbolic",
      "view_quilt": "view-grid-symbolic",
      "view_week": "view-column-symbolic",
      "visibility": "object-visible-symbolic",
      "volume_down": "audio-volume-low-symbolic",
      "volume_mute": "audio-volume-muted-symbolic",
      "volume_off": "audio-volume-muted-symbolic",
      "volume_up": "audio-volume-high-symbolic",
      "wallpaper": "preferences-desktop-wallpaper-symbolic",
      "warning": "dialog-warning-symbolic",
      "water_drop": "weather-showers-symbolic",
      "wifi": "network-wireless-symbolic",
      "wifi_find": "network-wireless-acquiring-symbolic",
      "wifi_off": "network-wireless-disabled-symbolic",
      "window": "window-symbolic",
      "workspaces": "workspace-switcher-symbolic",
      "zoom_in": "zoom-in-symbolic"
    }
    if (name === "") return "application-x-executable-symbolic"
    return symbols[name] || name.replace(/_/g, "-") + "-symbolic"
  }

  // The MacTahoe symbolic set uses a shared 16px canvas, but its individual
  // paths have different optical footprints. Keep the layout box stable and
  // tune the centered drawing frame so a dot grid does not look undersized
  // next to a full-width speaker or battery glyph.
  function liquidGlassIconScale(icon) {
    var symbol = liquidGlassIconName(icon)
    var compactSymbols = {
      "checkmark-symbolic": 1.08,
      "edit-find-symbolic": 1.02,
      "external-link-symbolic": 1.10,
      "go-next-symbolic": 1.06,
      "go-previous-symbolic": 1.06,
      "link-symbolic": 1.02,
      "lock-small-symbolic": 1.26,
      "media-playback-pause-symbolic": 1.26,
      "media-playback-start-symbolic": 1.18,
      "media-skip-backward-symbolic": 1.10,
      "media-skip-forward-symbolic": 1.10,
      "radio-checked-symbolic": 0.98,
      "radio-symbolic": 0.86,
      "view-app-grid-symbolic": 1.24,
      "view-grid-symbolic": 1.02,
      "view-list-symbolic": 1.20,
      "workspace-switcher-symbolic": 1.02,
      "window-close-symbolic": 1.30
    }
    if (compactSymbols[symbol] !== undefined) return compactSymbols[symbol]

    var denseSymbols = {
      "audio-volume-high-symbolic": 0.84,
      "audio-volume-low-symbolic": 0.84,
      "audio-volume-muted-symbolic": 0.84,
      "battery-caution-symbolic": 0.84,
      "battery-full-charging-symbolic": 0.84,
      "battery-full-symbolic": 0.84,
      "battery-level-10-symbolic": 0.84,
      "battery-level-20-symbolic": 0.84,
      "battery-level-30-symbolic": 0.84,
      "battery-level-50-symbolic": 0.84,
      "battery-level-70-symbolic": 0.84,
      "battery-level-90-symbolic": 0.84,
      "battery-missing-symbolic": 0.84,
      "display-brightness-low-symbolic": 0.90,
      "display-brightness-medium-symbolic": 0.90,
      "display-brightness-off-symbolic": 0.90,
      "display-brightness-symbolic": 0.90,
      "network-wireless-acquiring-symbolic": 0.90,
      "network-wireless-disabled-symbolic": 0.90,
      "network-wireless-symbolic": 0.84,
      "preferences-system-symbolic": 0.86,
      "weather-clear-night-symbolic": 0.96,
      "weather-clear-symbolic": 0.96,
      "weather-cloudy-symbolic": 0.84,
      "weather-few-clouds-symbolic": 0.96,
      "weather-fog-symbolic": 0.96,
      "weather-none-available-symbolic": 0.96,
      "weather-showers-symbolic": 0.96,
      "weather-snow-symbolic": 0.96,
      "weather-storm-symbolic": 0.96,
      "weather-windy-symbolic": 0.96
    }
    if (denseSymbols[symbol] !== undefined) return denseSymbols[symbol]

    // Most symbols sit between the two groups above. This slight inset also
    // prevents unfamiliar fallback symbols from touching adjacent controls.
    return 0.90
  }

  property int iconSize: Settings.iconSize
  property int fontPixelSize: Settings.fontPixelSize

  // Compact Material 3 type roles. The shell is a resizable desktop surface,
  // so these keep the current laptop density while preserving the hierarchy
  // and naming of the M3 type scale. Use weight and line height to express
  // emphasis; do not make every setting row compete with its page heading.
  readonly property int typeLabelSmallSize: nothingDesign && !nothingEvolution
    ? Math.max(12, fontPixelSize) : Math.max(8, fontPixelSize - 1)
  readonly property int typeLabelMediumSize: fontPixelSize
  readonly property int typeLabelLargeSize: fontPixelSize + 2
  readonly property int typeBodySmallSize: nothingDesign && !nothingEvolution
    ? Math.max(12, fontPixelSize) : Math.max(10, fontPixelSize - 1)
  readonly property int typeBodyMediumSize: fontPixelSize + 1
  readonly property int typeBodyLargeSize: fontPixelSize + 3
  readonly property int typeTitleSmallSize: fontPixelSize + 2
  readonly property int typeTitleMediumSize: fontPixelSize + 3
  readonly property int typeTitleLargeSize: fontPixelSize + 5
  readonly property int typeHeadlineSmallSize: fontPixelSize + 8
  readonly property int typeHeadlineMediumSize: fontPixelSize + 12
  readonly property int typeHeadlineLargeSize: fontPixelSize + 16
  readonly property int typeDisplaySmallSize: fontPixelSize + 20
  readonly property int typeDisplayMediumSize: fontPixelSize + 28
  readonly property int typeDisplayLargeSize: fontPixelSize + 36

  readonly property int typeLabelSmallLineHeight: 16
  readonly property int typeLabelMediumLineHeight: 18
  readonly property int typeLabelLargeLineHeight: 20
  readonly property int typeBodySmallLineHeight: 16
  readonly property int typeBodyMediumLineHeight: 19
  readonly property int typeBodyLargeLineHeight: 22
  readonly property int typeTitleSmallLineHeight: 18
  readonly property int typeTitleMediumLineHeight: 20
  readonly property int typeTitleLargeLineHeight: 22
  readonly property int typeHeadlineSmallLineHeight: 24
  readonly property int typeHeadlineMediumLineHeight: 28
  readonly property int typeHeadlineLargeLineHeight: 32
  readonly property int typeDisplaySmallLineHeight: 36
  readonly property int typeDisplayMediumLineHeight: 44
  readonly property int typeDisplayLargeLineHeight: 52

  // Qt expresses tracking in pixels. Keep display/headline tracking slightly
  // tight, leave body copy neutral, and give labels only a subtle separation.
  readonly property real typeDisplayTracking: -0.4
  readonly property real typeHeadlineTracking: -0.2
  readonly property real typeTitleTracking: 0
  readonly property real typeBodyTracking: 0
  readonly property real typeLabelTracking: 0.1
  readonly property real typeMonoTracking: 0.8
  readonly property int typeRegularWeight: Font.Normal
  readonly property int typeMediumWeight: Font.Medium
  readonly property int typeStrongWeight: Font.Bold

  // Backward-compatible aliases used by older delegates. New UI should use
  // the named type roles above so hierarchy remains explicit at call sites.
  readonly property int textCaptionSize: typeLabelSmallSize
  readonly property int textBodySize: typeBodyMediumSize
  readonly property int textBodyLargeSize: typeBodyLargeSize
  readonly property int textTitleSize: typeTitleLargeSize
  readonly property int textHeadlineSize: typeHeadlineSmallSize
  readonly property int iconSizeSmall: Math.max(12, iconSize - 2)

  // Bar clock typography is independently adjustable from global UI sizing.
  readonly property int labelSmallSize: typeLabelMediumSize
  readonly property int clockPrimarySize: Settings.clockFontSize
  readonly property int clockSecondarySize: Math.max(8, Settings.clockFontSize - 5)
  // Tight on purpose: the vertical bar stacks HH/MM at the same clockPrimarySize
  // and should read as one digital-clock block, not two separated labels.
  readonly property int clockLineSpacing: 2
  // Sized to the stacked hour/minute content instead of a flat constant, so
  // it keeps breathing room as the clock font size changes. Both lines render
  // at clockPrimarySize in vertical mode (secondary size is horizontal-only).
  readonly property int clockVerticalHeight: Math.round(clockPrimarySize * 1.2) * 2
    + clockLineSpacing
    + spacingMedium * 2

  // Nothing uses soft corners; Liquid Glass uses restrained macOS-like
  // geometry. Ghost keeps its square HUD panels.
  readonly property int shapeCompact: ghostTheme ? 0 : (liquidGlassTheme ? 6 : (nothingEvolution ? 10 : (nothingDesign ? 8 : 8)))
  readonly property int shapeMedium: ghostTheme ? 0 : (liquidGlassTheme ? 10 : (nothingEvolution ? 18 : (nothingDesign ? 14 : 12)))
  readonly property int shapeLarge: ghostTheme ? 0 : (liquidGlassTheme ? 16 : (nothingEvolution ? 24 : (nothingDesign ? 20 : 16)))
  // Keep Settings cards nested within the Evolution window's larger corners.
  readonly property int settingsCardRadius: nothingEvolution ? shapeMedium : shapeLarge
  readonly property int borderRadius: shapeLarge
  readonly property int popupRadius: liquidGlassTheme ? 10 : borderRadius
  readonly property int barRadius: liquidGlassTheme
    ? shapeLarge
    : (nothingEvolution ? shapeMedium : ((nothingDesign || ghostTheme) ? 0 : borderRadius))
  readonly property int themeBorderWidth: 1
  readonly property int themeFocusBorderWidth: 2
  readonly property int themeLabeledActionButtonHeight: (nothingDesign || ghostTheme) ? 64 : 48
  readonly property int themeOptionGap: nothingEvolution || liquidGlassTheme ? spacingSmall : spacingCompact
  readonly property int themeFontWeight: nothingEvolution || liquidGlassTheme
    ? Font.Medium : (nothingDesign ? Font.Medium : Font.Normal)

  // Motion is centralized here. reducedMotion mirrors the persisted Settings
  // singleton directly; compatibility consumers continue using animationDuration.
  property bool reducedMotion: Settings.reduceMotion
  readonly property int motionShort: reducedMotion ? 0 : 60
  readonly property int motionMedium: reducedMotion ? 0 : 90
  readonly property int motionLong: reducedMotion ? 0 : 140
  readonly property int motionExtraLong: reducedMotion ? 0 : 220
  readonly property int animationDuration: motionMedium
  // Interactive controls and workspace indicators use the shared spatial
  // spring model. Liquid Glass keeps that direct feedback but removes the
  // decorative expressive shape morphs used by Material 3.
  readonly property bool spatialMotion: !nothingDesign && !ghostTheme
  readonly property bool expressiveMotion: spatialMotion && !liquidGlassTheme
  readonly property real motionSpatialSpring: 12.0
  readonly property real motionSpatialDamping: 1.0
  readonly property real motionSpatialMass: 1.0
  readonly property real motionSpatialEpsilon: 0.01
  // Liquid Glass follows a restrained Human Interface motion profile. The
  // other styles retain their existing entrance geometry and durations.
  readonly property real surfaceEntryScale: liquidGlassTheme ? 0.97 : 0.85
  readonly property real surfaceEntryOffset: liquidGlassTheme ? -10 : -30
  readonly property int surfaceEntryDuration: liquidGlassTheme
    ? (reducedMotion ? 0 : 160)
    : motionLong
  readonly property int surfaceOpacityDuration: liquidGlassTheme
    ? (reducedMotion ? 0 : 110)
    : motionMedium
  readonly property real toastEntryScale: liquidGlassTheme ? 0.98 : 0.8
  readonly property real toastEntryOffset: liquidGlassTheme ? 18 : 50
  readonly property int toastEntryDuration: liquidGlassTheme
    ? (reducedMotion ? 0 : 160)
    : motionLong
  // Reduced motion keeps a short opacity-only acknowledgement for Liquid
  // Glass, while removing spatial movement, scale, and decorative morphs.
  readonly property int reducedMotionFadeDuration: liquidGlassTheme && reducedMotion ? 80 : 0
  readonly property int controlMotionDuration: liquidGlassTheme
    ? (reducedMotion ? 0 : 120)
    : (reducedMotion ? 0 : 150)
  readonly property int transientFadeDuration: liquidGlassTheme
    ? (reducedMotion ? reducedMotionFadeDuration : 160)
    : (reducedMotion ? 0 : 300)
  // Surface entrances use concise, theme-aware easing; interactive controls
  // keep their own shorter motion tokens.
  readonly property int themeMotionEasing: (nothingDesign || ghostTheme || liquidGlassTheme)
    ? Easing.OutCubic
    : Easing.OutBack
  readonly property real evolutionSurfaceAlpha: 0.86
  readonly property real evolutionRaisedAlpha: 0.92
  readonly property real evolutionControlAlpha: 0.86

  readonly property int popupWidth: 340
  readonly property int popupPadding: spacingLarge
  readonly property int settingsMinWidth: 560
  readonly property int settingsMinHeight: 360
  // Shared label column for remote settings rows. Sized for the longest
  // current label while allowing larger type settings to preserve full text.
  readonly property int settingsRowLabelWidth: 200
  readonly property int settingsMaxWidth: 1100
  readonly property int settingsDefaultWidth: 1100
  readonly property int settingsDefaultHeight: 900
  readonly property int clockIntervalMs: 1000
  readonly property int volumeStep: 5
  readonly property int brightnessStep: 5
}
