// Material You semantic palette backed by Matugen's wallpaper-derived cache.
//
// The hardcoded roles below remain deterministic fallbacks for first boot,
// missing cache files, and generator failures. Matugen is the active source
// whenever ~/.cache/matugen/current_palette.json contains both modes.
pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: colors

  // System dark-mode tracking lives here (rather than shell.qml) since Colors
  // owns systemDark and is now the single instance everyone reads from.
  property var systemDarkInitial: Process {
    command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: colors.systemDark = text.trim() === "'prefer-dark'"
    }
  }

  property var systemDarkMonitor: Process {
    id: darkModeMonitor
    command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
    running: true

    stdout: SplitParser {
      onRead: function(data) {
        var clean = data.trim()
        var prefix = "color-scheme:"
        var idx = clean.indexOf(prefix)
        if (idx >= 0) {
          var val = clean.substring(idx + prefix.length).trim()
          colors.systemDark = val === "'prefer-dark'"
        }
      }
    }

    onRunningChanged: {
      if (!running) darkModeMonitorRetry.start()
    }
  }

  property var darkModeMonitorRetry: Timer {
    id: darkModeMonitorRetry
    interval: 5000
    onTriggered: darkModeMonitor.running = true
  }

  property var lightPalette: ({})
  property var darkPalette: ({})
  readonly property bool dynamicPaletteLoaded: Object.keys(lightPalette).length > 0 && Object.keys(darkPalette).length > 0
  readonly property string paletteSource: dynamicPaletteLoaded ? "matugen" : "fallback"

  function paletteRole(mode, key, fallback) {
    var palette = mode === "dark" ? darkPalette : lightPalette
    var value = palette ? palette[key] : null
    return typeof value === "string" && value.length > 0 ? value : fallback
  }

  function loadMatugenPalette() {
    var raw = matugenPalette.text()
    if (!raw) return

    try {
      var document = JSON.parse(raw)
      var scheme = document["scheme-expressive"] || document
      if (!scheme.light || !scheme.dark) return
      lightPalette = scheme.light
      darkPalette = scheme.dark
    } catch (error) {
      lightPalette = ({})
      darkPalette = ({})
    }
  }

  property var matugenPalette: FileView {
    path: Quickshell.env("HOME") + "/.cache/matugen/current_palette.json"
    watchChanges: true
    preload: true
    printErrors: false
    onLoaded: colors.loadMatugenPalette()
    onFileChanged: colors.loadMatugenPalette()
  }

  // 0 = system, 1 = light, 2 = dark. This compatibility contract is used by
  // QuickMenu and Settings panel settings.
  property int themePreference: 0
  property bool systemDark: false
  property bool darkMode: themePreference === 1 ? false : (themePreference === 2 ? true : systemDark)

  // Light M3 Expressive roles.
  readonly property color l_background:                 "#fff8f7"
  readonly property color l_surface:                   "#fff8f7"
  readonly property color l_surfaceDim:                "#ead5d8"
  readonly property color l_surfaceBright:             "#fff8f7"
  readonly property color l_surfaceContainerLowest:    "#ffffff"
  readonly property color l_surfaceContainerLow:       "#fff1f2"
  readonly property color l_surfaceContainer:           "#fee9ec"
  readonly property color l_surfaceContainerHigh:       "#f9e3e6"
  readonly property color l_surfaceContainerHighest:    "#f3dde0"
  readonly property color l_surfaceVariant:            "#fadbe0"
  readonly property color l_primary:                   "#006684"
  readonly property color l_onPrimary:                 "#ffffff"
  readonly property color l_primaryContainer:          "#bee9ff"
  readonly property color l_onPrimaryContainer:        "#001f2a"
  readonly property color l_secondary:                 "#825245"
  readonly property color l_onSecondary:               "#ffffff"
  readonly property color l_secondaryContainer:        "#ffdbd1"
  readonly property color l_onSecondaryContainer:      "#321208"
  readonly property color l_tertiary:                  "#636121"
  readonly property color l_onTertiary:                "#ffffff"
  readonly property color l_tertiaryContainer:         "#eae698"
  readonly property color l_onTertiaryContainer:       "#1e1d00"
  readonly property color l_error:                     "#ba1a1a"
  readonly property color l_onError:                   "#ffffff"
  readonly property color l_errorContainer:            "#ffdad6"
  readonly property color l_onErrorContainer:          "#410002"
  readonly property color l_onSurface:                 "#24191b"
  readonly property color l_onSurfaceVariant:          "#564146"
  readonly property color l_outline:                   "#8a7175"
  readonly property color l_outlineVariant:            "#ddbfc4"
  readonly property color l_inverseSurface:            "#3a3032"
  readonly property color l_inverseOnSurface:          "#fff0f1"
  readonly property color l_inversePrimary:            "#80d1f5"
  readonly property color l_shadow:                    "#000000"
  readonly property color l_scrim:                     "#000000"

  // Dark M3 Expressive roles.
  readonly property color d_background:                 "#1b1013"
  readonly property color d_surface:                   "#1b1013"
  readonly property color d_surfaceDim:                "#1b1013"
  readonly property color d_surfaceBright:             "#433638"
  readonly property color d_surfaceContainerLowest:    "#150b0e"
  readonly property color d_surfaceContainerLow:       "#23181b"
  readonly property color d_surfaceContainer:           "#281d1f"
  readonly property color d_surfaceContainerHigh:       "#332729"
  readonly property color d_surfaceContainerHighest:    "#3f3134"
  readonly property color d_surfaceVariant:            "#564146"
  readonly property color d_primary:                   "#80d1f5"
  readonly property color d_onPrimary:                 "#003546"
  readonly property color d_primaryContainer:          "#004d64"
  readonly property color d_onPrimaryContainer:        "#bee9ff"
  readonly property color d_secondary:                 "#f5b8a8"
  readonly property color d_onSecondary:               "#4c261b"
  readonly property color d_secondaryContainer:        "#663c30"
  readonly property color d_onSecondaryContainer:      "#ffdbd1"
  readonly property color d_tertiary:                  "#ceca7e"
  readonly property color d_onTertiary:                "#343200"
  readonly property color d_tertiaryContainer:         "#4b4909"
  readonly property color d_onTertiaryContainer:       "#eae698"
  readonly property color d_error:                     "#ffb4ab"
  readonly property color d_onError:                   "#690005"
  readonly property color d_errorContainer:            "#93000a"
  readonly property color d_onErrorContainer:          "#ffdad6"
  readonly property color d_onSurface:                 "#f3dde0"
  readonly property color d_onSurfaceVariant:          "#ddbfc4"
  readonly property color d_outline:                   "#a58a8f"
  readonly property color d_outlineVariant:            "#564146"
  readonly property color d_inverseSurface:            "#f3dde0"
  readonly property color d_inverseOnSurface:          "#3a3032"
  readonly property color d_inversePrimary:            "#006684"
  readonly property color d_shadow:                    "#000000"
  readonly property color d_scrim:                     "#000000"

  // Resolved surface and content roles. Matugen supplies the active values;
  // the authored light/dark roles remain the safe fallback.
  property color background:                 paletteRole(darkMode ? "dark" : "light", "background", darkMode ? d_background : l_background)
  property color bg:                         background
  property color surface:                   paletteRole(darkMode ? "dark" : "light", "surface", darkMode ? d_surface : l_surface)
  property color surfaceDim:                paletteRole(darkMode ? "dark" : "light", "surface_dim", darkMode ? d_surfaceDim : l_surfaceDim)
  property color surfaceBright:             paletteRole(darkMode ? "dark" : "light", "surface_bright", darkMode ? d_surfaceBright : l_surfaceBright)
  property color surfaceContainerLowest:    paletteRole(darkMode ? "dark" : "light", "surface_container_lowest", darkMode ? d_surfaceContainerLowest : l_surfaceContainerLowest)
  property color surfaceContainerLow:       paletteRole(darkMode ? "dark" : "light", "surface_container_low", darkMode ? d_surfaceContainerLow : l_surfaceContainerLow)
  property color surfaceContainer:          paletteRole(darkMode ? "dark" : "light", "surface_container", darkMode ? d_surfaceContainer : l_surfaceContainer)
  property color surfaceContainerHigh:      paletteRole(darkMode ? "dark" : "light", "surface_container_high", darkMode ? d_surfaceContainerHigh : l_surfaceContainerHigh)
  property color surfaceContainerHighest:   paletteRole(darkMode ? "dark" : "light", "surface_container_highest", darkMode ? d_surfaceContainerHighest : l_surfaceContainerHighest)
  property color surfaceVariant:            paletteRole(darkMode ? "dark" : "light", "surface_variant", darkMode ? d_surfaceVariant : l_surfaceVariant)
  property color primary:                   paletteRole(darkMode ? "dark" : "light", "primary", darkMode ? d_primary : l_primary)
  property color fgPrimary:                 paletteRole(darkMode ? "dark" : "light", "on_primary", darkMode ? d_onPrimary : l_onPrimary)
  property color primaryContainer:          paletteRole(darkMode ? "dark" : "light", "primary_container", darkMode ? d_primaryContainer : l_primaryContainer)
  property color fgPrimaryContainer:        paletteRole(darkMode ? "dark" : "light", "on_primary_container", darkMode ? d_onPrimaryContainer : l_onPrimaryContainer)
  property color secondary:                 paletteRole(darkMode ? "dark" : "light", "secondary", darkMode ? d_secondary : l_secondary)
  property color fgSecondary:               paletteRole(darkMode ? "dark" : "light", "on_secondary", darkMode ? d_onSecondary : l_onSecondary)
  property color secondaryContainer:        paletteRole(darkMode ? "dark" : "light", "secondary_container", darkMode ? d_secondaryContainer : l_secondaryContainer)
  property color fgSecondaryContainer:      paletteRole(darkMode ? "dark" : "light", "on_secondary_container", darkMode ? d_onSecondaryContainer : l_onSecondaryContainer)
  property color tertiary:                  paletteRole(darkMode ? "dark" : "light", "tertiary", darkMode ? d_tertiary : l_tertiary)
  property color fgTertiary:                paletteRole(darkMode ? "dark" : "light", "on_tertiary", darkMode ? d_onTertiary : l_onTertiary)
  property color tertiaryContainer:         paletteRole(darkMode ? "dark" : "light", "tertiary_container", darkMode ? d_tertiaryContainer : l_tertiaryContainer)
  property color fgTertiaryContainer:       paletteRole(darkMode ? "dark" : "light", "on_tertiary_container", darkMode ? d_onTertiaryContainer : l_onTertiaryContainer)
  property color error:                    paletteRole(darkMode ? "dark" : "light", "error", darkMode ? d_error : l_error)
  property color fgError:                  paletteRole(darkMode ? "dark" : "light", "on_error", darkMode ? d_onError : l_onError)
  property color errorContainer:           paletteRole(darkMode ? "dark" : "light", "error_container", darkMode ? d_errorContainer : l_errorContainer)
  property color fgErrorContainer:         paletteRole(darkMode ? "dark" : "light", "on_error_container", darkMode ? d_onErrorContainer : l_onErrorContainer)
  property color fgBackground:             paletteRole(darkMode ? "dark" : "light", "on_background", darkMode ? d_onSurface : l_onSurface)
  property color fgSurface:                paletteRole(darkMode ? "dark" : "light", "on_surface", darkMode ? d_onSurface : l_onSurface)
  property color fgSurfaceVariant:         paletteRole(darkMode ? "dark" : "light", "on_surface_variant", darkMode ? d_onSurfaceVariant : l_onSurfaceVariant)
  property color outline:                 paletteRole(darkMode ? "dark" : "light", "outline", darkMode ? d_outline : l_outline)
  property color outlineVariant:          paletteRole(darkMode ? "dark" : "light", "outline_variant", darkMode ? d_outlineVariant : l_outlineVariant)
  property color inverseSurface:           paletteRole(darkMode ? "dark" : "light", "inverse_surface", darkMode ? d_inverseSurface : l_inverseSurface)
  property color inverseOnSurface:         paletteRole(darkMode ? "dark" : "light", "inverse_on_surface", darkMode ? d_inverseOnSurface : l_inverseOnSurface)
  property color inversePrimary:           paletteRole(darkMode ? "dark" : "light", "inverse_primary", darkMode ? d_inversePrimary : l_inversePrimary)
  property color surfaceTint:              paletteRole(darkMode ? "dark" : "light", "surface_tint", primary)
  property color shadow:                  paletteRole(darkMode ? "dark" : "light", "shadow", darkMode ? d_shadow : l_shadow)
  property color scrim:                   paletteRole(darkMode ? "dark" : "light", "scrim", darkMode ? d_scrim : l_scrim)

  // Semantic status roles. Components should use these aliases instead of
  // introducing local status colors.
  readonly property color l_success:                    "#356a2f"
  readonly property color l_onSuccess:                  "#ffffff"
  readonly property color l_successContainer:           "#b9f2ac"
  readonly property color l_onSuccessContainer:         "#0a2108"
  readonly property color l_warning:                    "#735c00"
  readonly property color l_onWarning:                  "#ffffff"
  readonly property color l_warningContainer:           "#ffe082"
  readonly property color l_onWarningContainer:         "#231a00"
  readonly property color d_success:                    "#9bd88d"
  readonly property color d_onSuccess:                  "#173714"
  readonly property color d_successContainer:           "#1e4f1d"
  readonly property color d_onSuccessContainer:         "#b9f2ac"
  readonly property color d_warning:                    "#e6c556"
  readonly property color d_onWarning:                  "#3b2f00"
  readonly property color d_warningContainer:           "#574500"
  readonly property color d_onWarningContainer:         "#ffe082"

  property color success:                  darkMode ? d_success                  : l_success
  property color fgSuccess:                darkMode ? d_onSuccess                : l_onSuccess
  property color successContainer:         darkMode ? d_successContainer         : l_successContainer
  property color fgSuccessContainer:       darkMode ? d_onSuccessContainer       : l_onSuccessContainer
  property color warning:                  darkMode ? d_warning                  : l_warning
  property color fgWarning:                darkMode ? d_onWarning                : l_onWarning
  property color warningContainer:         darkMode ? d_warningContainer         : l_warningContainer
  property color fgWarningContainer:       darkMode ? d_onWarningContainer       : l_onWarningContainer
  property color info:                     primary
  property color fgInfo:                   fgPrimary
  property color brightness:               primary
  property color destructive:              error
  property color fgDestructive:            fgError

  property color weatherClear:             warning
  property color weatherPartlyCloudy:       primary
  property color weatherCloud:             secondary
  property color weatherFog:               outline
  property color weatherRain:              info
  property color weatherSnow:              tertiary
  property color weatherThunder:           secondary
  property color weatherFeelsLike:         error
  property color weatherHumidity:          info
  property color weatherWind:              success
  property color weatherPressure:          tertiary
  property color weatherUv:               warning
  property color weatherPrecipitation:     info

  function weatherIcon(desc) {
    var d = (desc || "").toLowerCase();
    if (d.indexOf("clear") !== -1) return "sunny";
    if (d.indexOf("partly") !== -1 || d.indexOf("mainly") !== -1) return "partly_cloudy_day";
    if (d.indexOf("cloudy") !== -1 || d.indexOf("overcast") !== -1) return "cloud";
    if (d.indexOf("fog") !== -1) return "foggy";
    if (d.indexOf("drizzle") !== -1 || d.indexOf("shower") !== -1) return "rainy";
    if (d.indexOf("rain") !== -1) return "rainy";
    if (d.indexOf("snow") !== -1) return "snowing";
    if (d.indexOf("thunder") !== -1) return "thunderstorm";
    return "sunny";
  }

  function weatherColor(desc) {
    var d = (desc || "").toLowerCase();
    if (d.indexOf("clear") !== -1) return weatherClear;
    if (d.indexOf("partly") !== -1 || d.indexOf("mainly") !== -1) return weatherPartlyCloudy;
    if (d.indexOf("cloudy") !== -1 || d.indexOf("overcast") !== -1) return weatherCloud;
    if (d.indexOf("fog") !== -1) return weatherFog;
    if (d.indexOf("drizzle") !== -1 || d.indexOf("shower") !== -1) return weatherRain;
    if (d.indexOf("rain") !== -1) return weatherRain;
    if (d.indexOf("snow") !== -1) return weatherSnow;
    if (d.indexOf("thunder") !== -1) return weatherThunder;
    return weatherClear;
  }

  // M3 state layers. These are intentionally expressed from the active
  // semantic colors so light/dark behavior stays coherent.
  property color hoverOverlay:             Qt.rgba(fgSurface.r, fgSurface.g, fgSurface.b, darkMode ? 0.08 : 0.08)
  property color pressOverlay:             Qt.rgba(fgSurface.r, fgSurface.g, fgSurface.b, darkMode ? 0.12 : 0.12)
  property color focusOverlay:             Qt.rgba(primary.r, primary.g, primary.b, 0.12)
  property color disabledContainer:       Qt.rgba(fgSurface.r, fgSurface.g, fgSurface.b, 0.12)
  property color disabledContent:          Qt.rgba(fgSurface.r, fgSurface.g, fgSurface.b, 0.38)
}
