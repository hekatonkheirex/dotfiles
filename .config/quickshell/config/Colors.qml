// Material 3 semantic palette for the elena style.
//
// Roles read the active two-mode Matugen cache. Live palettes come from the
// wallpaper; fixed palettes are exported here before Matugen renders the
// external outputs.
pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "PaletteCatalog.js" as PaletteCatalog
import "AccentPalette.js" as AccentPalette

QtObject {
  id: colors

  // A fixed palette is also the input for the external Matugen consumers.
  // Keep the write asynchronous, then let the Appearance tab start the
  // generator only after the cache is durable.
  signal fixedPaletteSaved()
  signal fixedPaletteSaveFailed(var error)

  // Start from the active Matugen cache instead of waiting for a later file
  // change notification. The palette activation helper selects the Live or
  // Fixed cache before the shared desktop synchronizer runs.
  property var initialMatugenLoad: Timer {
    interval: 1
    running: true
    repeat: false
    onTriggered: colors.reloadMatugenPalette()
  }

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
  // 0 = auto, 1 = light, 2 = dark. Settings is the persisted owner; this
  // compatibility property keeps existing color bindings stable.
  property int themePreference: Settings.themePreference
  property bool systemDark: false
  property bool darkMode: themePreference === 1 ? false : (themePreference === 2 ? true : systemDark)

  // Collapsed shim kept while bar/settings/AppearanceTab.qml still reads it.
  readonly property bool paletteSourceSelectable: true
  readonly property bool fixedPaletteActive: Settings.colorSource === "fixed"
  readonly property string resolvedPaletteVariant: PaletteCatalog.resolveVariant(
    Settings.colorPalette,
    Settings.colorVariant,
    darkMode
  )
  readonly property string paletteFamilyLabel: PaletteCatalog.familyLabel(Settings.colorPalette)
  readonly property string paletteVariantLabel: PaletteCatalog.variantLabel(
    Settings.colorPalette,
    resolvedPaletteVariant
  )
  readonly property string paletteSource: Settings.colorSource === "fixed"
    ? ("Fixed · " + paletteFamilyLabel + " · " + paletteVariantLabel)
    : (dynamicPaletteLoaded ? "Live (wallpaper)" : "Live (fallback)")

  // Ghost colors kept only while bar/ call sites still read them (dead
  // branches behind Config.ghostTheme; removed in Task 9).
  readonly property color ghostHairline: darkMode
    ? Qt.rgba(120/255, 220/255, 208/255, 0.16)
    : Qt.rgba(0/255, 107/255, 99/255, 0.16)
  readonly property color ghostHairlineStrong: darkMode
    ? Qt.rgba(120/255, 220/255, 208/255, 0.32)
    : Qt.rgba(0/255, 107/255, 99/255, 0.32)
  readonly property color ghostCyan: darkMode ? "#57d9cc" : "#006d67"
  readonly property color ghostMuted: darkMode ? "#678984" : "#4f6260"

  function authoredMaterialPalette(mode) {
    var dark = mode === "dark"
    return {
      background: dark ? d_background : l_background,
      surface: dark ? d_surface : l_surface,
      surface_dim: dark ? d_surfaceDim : l_surfaceDim,
      surface_bright: dark ? d_surfaceBright : l_surfaceBright,
      surface_container_lowest: dark ? d_surfaceContainerLowest : l_surfaceContainerLowest,
      surface_container_low: dark ? d_surfaceContainerLow : l_surfaceContainerLow,
      surface_container: dark ? d_surfaceContainer : l_surfaceContainer,
      surface_container_high: dark ? d_surfaceContainerHigh : l_surfaceContainerHigh,
      surface_container_highest: dark ? d_surfaceContainerHighest : l_surfaceContainerHighest,
      surface_variant: dark ? d_surfaceVariant : l_surfaceVariant,
      primary: dark ? d_primary : l_primary,
      on_primary: dark ? d_onPrimary : l_onPrimary,
      primary_container: dark ? d_primaryContainer : l_primaryContainer,
      on_primary_container: dark ? d_onPrimaryContainer : l_onPrimaryContainer,
      secondary: dark ? d_secondary : l_secondary,
      on_secondary: dark ? d_onSecondary : l_onSecondary,
      secondary_container: dark ? d_secondaryContainer : l_secondaryContainer,
      on_secondary_container: dark ? d_onSecondaryContainer : l_onSecondaryContainer,
      tertiary: dark ? d_tertiary : l_tertiary,
      on_tertiary: dark ? d_onTertiary : l_onTertiary,
      tertiary_container: dark ? d_tertiaryContainer : l_tertiaryContainer,
      on_tertiary_container: dark ? d_onTertiaryContainer : l_onTertiaryContainer,
      error: dark ? d_error : l_error,
      on_error: dark ? d_onError : l_onError,
      error_container: dark ? d_errorContainer : l_errorContainer,
      on_error_container: dark ? d_onErrorContainer : l_onErrorContainer,
      on_background: dark ? d_onSurface : l_onSurface,
      on_surface: dark ? d_onSurface : l_onSurface,
      on_surface_variant: dark ? d_onSurfaceVariant : l_onSurfaceVariant,
      outline: dark ? d_outline : l_outline,
      outline_variant: dark ? d_outlineVariant : l_outlineVariant,
      inverse_surface: dark ? d_inverseSurface : l_inverseSurface,
      inverse_on_surface: dark ? d_inverseOnSurface : l_inverseOnSurface,
      inverse_primary: dark ? d_inversePrimary : l_inversePrimary,
      source_color: dark ? d_primary : l_primary,
      surface_tint: dark ? d_primary : l_primary,
      shadow: dark ? d_shadow : l_shadow,
      scrim: dark ? d_scrim : l_scrim,
      // Material 3 fixed roles are shared by the light and dark schemes.
      // Use the authored light/dark tone pair instead of switching the fixed
      // roles with the active mode.
      primary_fixed: l_primaryContainer,
      primary_fixed_dim: d_primary,
      on_primary_fixed: l_onPrimaryContainer,
      on_primary_fixed_variant: d_primaryContainer,
      secondary_fixed: l_secondaryContainer,
      secondary_fixed_dim: d_secondary,
      on_secondary_fixed: l_onSecondaryContainer,
      on_secondary_fixed_variant: d_secondaryContainer,
      tertiary_fixed: l_tertiaryContainer,
      tertiary_fixed_dim: d_tertiary,
      on_tertiary_fixed: l_onTertiaryContainer,
      on_tertiary_fixed_variant: d_tertiaryContainer
    }
  }

  function applyContrast(palette) {
    if (!palette || !palette.on_surface || Settings.colorContrast === "standard") return palette

    var adjusted = {}
    for (var key in palette) adjusted[key] = palette[key]

    if (Settings.colorContrast === "medium" || Settings.colorContrast === "high") {
      adjusted.on_surface_variant = palette.on_surface
      adjusted.outline = palette.on_surface_variant
      adjusted.outline_variant = palette.outline
    }
    if (Settings.colorContrast === "high") {
      adjusted.outline = palette.on_surface
      adjusted.outline_variant = palette.on_surface_variant
    }
    return adjusted
  }

  function colorChannelHex(channel) {
    var value = Math.round(Math.max(0, Math.min(1, Number(channel))) * 255)
    var encoded = value.toString(16)
    return encoded.length === 1 ? "0" + encoded : encoded
  }

  // QML promotes palette strings to color values when they pass through a
  // QObject. Keep the shared Matugen cache a portable hex-color document so
  // shell scripts and other generators do not receive QML's expanded color
  // object representation.
  function serializePaletteColor(value) {
    if (typeof value === "string") return value
    if (value && value.r !== undefined && value.g !== undefined && value.b !== undefined) {
      var hex = "#" + colorChannelHex(value.r)
        + colorChannelHex(value.g) + colorChannelHex(value.b)
      if (value.a !== undefined && Number(value.a) < 0.999) {
        hex += colorChannelHex(value.a)
      }
      return hex
    }
    return value
  }

  function selectedPalette(mode) {
    var palette
    if (Settings.colorSource === "fixed") {
      palette = Settings.colorPalette === "material3"
        ? authoredMaterialPalette(mode)
        : PaletteCatalog.palette(Settings.colorPalette, Settings.colorVariant, mode === "dark")
    } else {
      palette = mode === "dark" ? darkPalette : lightPalette
    }
    return applyContrast(palette)
  }

  // Matugen's JSON renderer consumes the same two-mode semantic role maps
  // that the shared desktop generators read. The source_color marker is
  // required by Matugen even though fixed palettes already contain every
  // resolved role.
  function matugenPaletteForMode(mode) {
    var palette = selectedPalette(mode)
    if (!palette) return null

    var normalized = {}
    for (var key in palette) normalized[key] = serializePaletteColor(palette[key])
    if (!normalized.source_color) normalized.source_color = normalized.primary
    return normalized
  }

  function fixedPaletteDocument() {
    if (!fixedPaletteActive) return ""

    var light = matugenPaletteForMode("light")
    var dark = matugenPaletteForMode("dark")
    if (!light || !dark || !light.source_color || !dark.source_color) return ""

    return JSON.stringify({
      _seed: "fixed:" + Settings.colorPalette + ":" + resolvedPaletteVariant
        + ":" + Settings.colorContrast,
      "scheme-expressive": {
        light: light,
        dark: dark
      }
    })
  }

  function writeFixedMatugenPalette() {
    var document = fixedPaletteDocument()
    if (!document) return false

    fixedMatugenPalette.setText(document)
    return true
  }

  function paletteRole(mode, key, fallback) {
    var palette = selectedPalette(mode)
    var value = palette ? palette[key] : null
    return value !== undefined && value !== null && value !== "" ? value : fallback
  }

  function loadMatugenPalette() {
    var raw = matugenPalette.text()
    if (!raw) return

    try {
      var document = JSON.parse(raw)
      var scheme = document["scheme-expressive"] || document
      if (!scheme.light || !scheme.dark) {
        lightPalette = ({})
        darkPalette = ({})
        return
      }

      // Copy the role maps before publishing them. This keeps the resolved
      // bindings dependent on one complete light/dark snapshot instead of a
      // partially updated FileView object while Matugen is writing its cache.
      lightPalette = Object.assign({}, scheme.light)
      darkPalette = Object.assign({}, scheme.dark)
    } catch (error) {
      lightPalette = ({})
      darkPalette = ({})
    }
  }

  function reloadMatugenPalette() {
    matugenPalette.reload()
  }

  property var matugenPalette: FileView {
    path: Quickshell.env("HOME") + "/.cache/matugen/current_palette.json"
    watchChanges: true
    preload: true
    printErrors: false
    onLoaded: colors.loadMatugenPalette()
    onTextChanged: colors.loadMatugenPalette()
    onFileChanged: colors.loadMatugenPalette()
  }

  property var fixedMatugenPalette: FileView {
    path: Quickshell.env("HOME") + "/.cache/matugen/fixed_palette.json"
    atomicWrites: true
    printErrors: false
    onSaved: {
      colors.fixedPaletteSaved()
    }
    onSaveFailed: function(error) {
      colors.fixedPaletteSaveFailed(error)
    }
  }

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

  // Resolved surface and content roles: Matugen or the fixed palette, with
  // authored fallbacks.
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
  // User-picked accent: swaps the primary pair for another Matugen role.
  // Authored palettes lacking the role fall back to their own primary.
  readonly property string accentRole: AccentPalette.resolve(Settings.accentPalette, Settings.accentActive)
  function accentRoleColor(role) {
    var mode = darkMode ? "dark" : "light"
    return paletteRole(mode, role, paletteRole(mode, "primary", darkMode ? d_primary : l_primary))
  }
  property color primary:                   accentRole === "" ? paletteRole(darkMode ? "dark" : "light", "primary", darkMode ? d_primary : l_primary) : accentRoleColor(accentRole)
  property color fgPrimary:                 paletteRole(darkMode ? "dark" : "light", AccentPalette.onRole(accentRole), darkMode ? d_onPrimary : l_onPrimary)
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
  property color primaryFixed:              paletteRole(darkMode ? "dark" : "light", "primary_fixed", primary)
  property color primaryFixedDim:           paletteRole(darkMode ? "dark" : "light", "primary_fixed_dim", primaryContainer)
  property color fgPrimaryFixed:            paletteRole(darkMode ? "dark" : "light", "on_primary_fixed", fgPrimary)
  property color fgPrimaryFixedVariant:     paletteRole(darkMode ? "dark" : "light", "on_primary_fixed_variant", fgPrimaryContainer)
  property color secondaryFixed:            paletteRole(darkMode ? "dark" : "light", "secondary_fixed", secondary)
  property color secondaryFixedDim:         paletteRole(darkMode ? "dark" : "light", "secondary_fixed_dim", secondaryContainer)
  property color fgSecondaryFixed:          paletteRole(darkMode ? "dark" : "light", "on_secondary_fixed", fgSecondary)
  property color fgSecondaryFixedVariant:   paletteRole(darkMode ? "dark" : "light", "on_secondary_fixed_variant", fgSecondaryContainer)
  property color tertiaryFixed:             paletteRole(darkMode ? "dark" : "light", "tertiary_fixed", tertiary)
  property color tertiaryFixedDim:          paletteRole(darkMode ? "dark" : "light", "tertiary_fixed_dim", tertiaryContainer)
  property color fgTertiaryFixed:           paletteRole(darkMode ? "dark" : "light", "on_tertiary_fixed", fgTertiary)
  property color fgTertiaryFixedVariant:    paletteRole(darkMode ? "dark" : "light", "on_tertiary_fixed_variant", fgTertiaryContainer)
  property color surfaceTint:              paletteRole(darkMode ? "dark" : "light", "surface_tint", primary)
  property color shadow:                  paletteRole(darkMode ? "dark" : "light", "shadow", darkMode ? d_shadow : l_shadow)
  property color scrim:                   paletteRole(darkMode ? "dark" : "light", "scrim", darkMode ? d_scrim : l_scrim)

  // Liquid Glass roles kept only while bar/ call sites still read them,
  // collapsed to the non-glass values (removed in Task 9).
  readonly property bool liquidGlassOpaque: false
  // Monochrome bar foregrounds, separate from the palette: pure white in dark
  // mode and pure black in light mode.
  readonly property color barForeground: darkMode ? "#ffffff" : "#000000"
  readonly property color barForegroundMuted: Qt.rgba(
    darkMode ? 1 : 0,
    darkMode ? 1 : 0,
    darkMode ? 1 : 0,
    darkMode ? 0.72 : 0.68
  )
  readonly property color liquidGlassRegular: Qt.rgba(surfaceContainerLow.r, surfaceContainerLow.g, surfaceContainerLow.b,
        // Retain glass while keeping text readable over black wallpaper.
        darkMode ? 0.55 : 0.60)
  readonly property color liquidGlassClear: Qt.rgba(surfaceContainerLow.r, surfaceContainerLow.g, surfaceContainerLow.b,
        darkMode ? 0.45 : 0.50)
  readonly property color liquidGlassRaised: Qt.rgba(surfaceContainer.r, surfaceContainer.g, surfaceContainer.b,
        darkMode ? 0.60 : 0.65)
  readonly property color liquidGlassControl: Qt.rgba(surfaceContainerHigh.r, surfaceContainerHigh.g, surfaceContainerHigh.b,
        darkMode ? 0.95 : 0.85)
  // macOS-style controls use neutral inactive chrome and a light control
  // thumb; active controls supply their own semantic accent color.
  readonly property color liquidGlassControlTrack: Qt.rgba(barForeground.r, barForeground.g, barForeground.b, darkMode ? 0.30 : 0.22)
  readonly property color liquidGlassControlThumb: Qt.rgba(1, 1, 1, darkMode ? 0.90 : 0.94)
  readonly property color liquidGlassHighlight: Qt.rgba(1, 1, 1, darkMode ? 0.14 : 0.34)
  readonly property color liquidGlassShade: Qt.rgba(0, 0, 0, darkMode ? 0.16 : 0.05)
  readonly property color liquidGlassEdge: Qt.rgba(1, 1, 1, darkMode ? 0.18 : 0.30)
  readonly property color liquidGlassEdgeStrong: Qt.rgba(fgSurface.r, fgSurface.g, fgSurface.b, darkMode ? 0.30 : 0.22)
  readonly property color liquidGlassShadow: Qt.rgba(0, 0, 0, darkMode ? 0.34 : 0.18)

  // Style helpers collapsed to the elena (Material) roles. Kept while bar/
  // call sites still read them; Tasks 5 to 8 switch the readers to the roles.
  readonly property color styleInk: outline
  readonly property color styleOutline: outlineVariant
  readonly property color styleOutlineStrong: outline
  readonly property color styleShadow: "transparent"
  readonly property color styleSurface: surfaceContainerHigh
  readonly property color chromeSurface: styleSurface
  readonly property color readingSurface: chromeSurface
  readonly property color styleSurfaceRaised: surfaceContainerHigh
  readonly property color styleControl: surfaceContainerHigh
  readonly property color styleAccent: primary
  readonly property color styleAccentText: fgPrimary
  // Fixed palette families intentionally reuse their source palette's surface
  // tones for M3 containers. Some families therefore have the same value for
  // secondaryContainer and the surrounding settings surface. Keep navigation
  // selection visible with a restrained fixed-accent wash while preserving
  // the normal M3 secondary container for Live palettes.
  readonly property color navigationContainer: fixedPaletteActive
    ? Qt.tint(surfaceContainerLow, Qt.rgba(primaryFixed.r, primaryFixed.g, primaryFixed.b, darkMode ? 0.22 : 0.12))
    : secondaryContainer
  readonly property color navigationContent: fixedPaletteActive ? fgSurface : fgSecondaryContainer
  readonly property color styleSelectedText: styleAccentText

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
