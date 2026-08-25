// Material 3 semantic palette with fixed Nothing/Ghost and adaptive
// Nothing Evolution roles.
//
// Material 3 and Neo Brutalism read Matugen's wallpaper-derived cache. The
// Classic Nothing and Ghost intentionally use authored light/dark palettes.
// Nothing Evolution consumes the existing wallpaper-derived Matugen cache and
// layers translucent semantic surfaces on top.
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

  // 0 = auto, 1 = light, 2 = dark. Settings is the persisted owner; this
  // compatibility property keeps existing color bindings stable.
  property int themePreference: Settings.themePreference
  property bool systemDark: false
  property bool darkMode: themePreference === 1 ? false : (themePreference === 2 ? true : systemDark)

  readonly property bool nothingDesign: Settings.themeStyle === "nothing"
  readonly property bool nothingEvolution: nothingDesign && Settings.nothingVariant === "evolution"
  readonly property bool neoBrutalism: Settings.themeStyle === "neo-brutalism"
  readonly property bool ghostTheme: Settings.themeStyle === "ghost"
  readonly property string paletteSource: ghostTheme
    ? "ghost"
    : (nothingEvolution
      ? (dynamicPaletteLoaded ? "matugen" : "nothing-evolution-fallback")
      : (nothingDesign
        ? "nothing"
        : (dynamicPaletteLoaded ? "matugen" : "fallback")))

  // GITS ("Ghost in the Shell") palette. Recovered from the pre-Matugen
  // Section 9 theme (commit 8634528e). It is fixed and wallpaper-neutral, but
  // still has authored light and dark roles so the external Ghost suite and
  // Quickshell remain synchronized when the color-mode preference changes.
  readonly property color ghostVoid: darkMode ? "#05080a" : "#f3f7f6"
  readonly property color ghostPanel: darkMode ? "#0d1418" : "#f4fbfa"
  readonly property color ghostPanelRaised: darkMode ? "#12191d" : "#eaf5f3"
  readonly property color ghostPanelHighest: darkMode ? "#1c262a" : "#d5e3e0"
  readonly property color ghostHairline: darkMode
    ? Qt.rgba(120/255, 220/255, 208/255, 0.16)
    : Qt.rgba(0/255, 107/255, 99/255, 0.16)
  readonly property color ghostHairlineStrong: darkMode
    ? Qt.rgba(120/255, 220/255, 208/255, 0.32)
    : Qt.rgba(0/255, 107/255, 99/255, 0.32)
  readonly property color ghostCyan: darkMode ? "#57d9cc" : "#006d67"
  readonly property color ghostText: darkMode ? "#cdeeea" : "#10201f"
  readonly property color ghostMuted: darkMode ? "#678984" : "#4f6260"
  readonly property color ghostDanger: darkMode ? "#e0625a" : "#b3261e"
  readonly property color ghostAccentFill: darkMode ? "#246a63" : "#006d67"
  readonly property color ghostAccentText: darkMode ? "#05080a" : "#ffffff"
  readonly property color ghostSuccess: darkMode ? "#8fe38a" : "#287a3a"
  readonly property color ghostSuccessText: darkMode ? "#05080a" : "#ffffff"
  readonly property color ghostSuccessContainer: darkMode ? "#1e4f1d" : "#d8f3d2"
  readonly property color ghostSuccessContainerText: darkMode ? "#b9f2ac" : "#0a2108"
  readonly property color ghostWarning: darkMode ? "#e0a94a" : "#875400"
  readonly property color ghostWarningText: darkMode ? "#05080a" : "#ffffff"
  readonly property color ghostWarningContainer: darkMode ? "#574500" : "#ffe2a6"
  readonly property color ghostWarningContainerText: darkMode ? "#ffe082" : "#231a00"

  // Nothing's Quickshell palette is deliberately stable and wallpaper-neutral.
  // Red is the primary product signal; base surfaces and text stay neutral so
  // the rounded controls do not inherit a wallpaper tint.
  readonly property var nothingLightPalette: ({
    background: "#f6f6f4",
    surface: "#f6f6f4",
    surface_dim: "#d9d9d6",
    surface_bright: "#ffffff",
    surface_container_lowest: "#ffffff",
    surface_container_low: "#f0f0ee",
    surface_container: "#e8e8e5",
    surface_container_high: "#dfdfdc",
    surface_container_highest: "#d4d4d1",
    surface_variant: "#e2e2df",
    primary: "#d71920",
    on_primary: "#ffffff",
    primary_container: "#f7d9d9",
    on_primary_container: "#410006",
    secondary: "#5f6060",
    on_secondary: "#ffffff",
    secondary_container: "#ddddda",
    on_secondary_container: "#1b1b1a",
    tertiary: "#757575",
    on_tertiary: "#ffffff",
    tertiary_container: "#e5e5e2",
    on_tertiary_container: "#202020",
    error: "#d71920",
    on_error: "#ffffff",
    error_container: "#f7d9d9",
    on_error_container: "#410006",
    on_background: "#1a1a1a",
    on_surface: "#1a1a1a",
    on_surface_variant: "#616161",
    outline: "#858585",
    outline_variant: "#c9c9c6",
    inverse_surface: "#2b2b2a",
    inverse_on_surface: "#f5f5f3",
    inverse_primary: "#ffb3b3",
    surface_tint: "#d71920",
    shadow: "#000000",
    scrim: "#000000"
  })

  readonly property var nothingDarkPalette: ({
    background: "#151515",
    surface: "#151515",
    surface_dim: "#101010",
    surface_bright: "#3a3a3a",
    surface_container_lowest: "#0d0d0d",
    surface_container_low: "#1d1d1d",
    surface_container: "#252525",
    surface_container_high: "#2e2e2e",
    surface_container_highest: "#363636",
    surface_variant: "#3b3b3b",
    primary: "#d71920",
    on_primary: "#ffffff",
    primary_container: "#62131a",
    on_primary_container: "#ffdada",
    secondary: "#b8b8b5",
    on_secondary: "#282828",
    secondary_container: "#454545",
    on_secondary_container: "#e6e6e3",
    tertiary: "#a0a09d",
    on_tertiary: "#2b2b2b",
    tertiary_container: "#3f3f3d",
    on_tertiary_container: "#e5e5e2",
    error: "#d71920",
    on_error: "#ffffff",
    error_container: "#62131a",
    on_error_container: "#ffdada",
    on_background: "#f2f2f0",
    on_surface: "#f2f2f0",
    on_surface_variant: "#b8b8b5",
    outline: "#888884",
    outline_variant: "#4a4a48",
    inverse_surface: "#f2f2f0",
    inverse_on_surface: "#2a2a28",
    inverse_primary: "#a90012",
    surface_tint: "#d71920",
    shadow: "#000000",
    scrim: "#000000"
  })

  readonly property var ghostLightPalette: ({
    background: "#f3f7f6",
    surface: "#f3f7f6",
    surface_dim: "#d5e3e0",
    surface_bright: "#ffffff",
    surface_container_lowest: "#ffffff",
    surface_container_low: "#f4fbfa",
    surface_container: "#eaf5f3",
    surface_container_high: "#ddebe8",
    surface_container_highest: "#d5e3e0",
    surface_variant: "#d5e3e0",
    primary: "#006d67",
    on_primary: "#ffffff",
    primary_container: "#b8e8e3",
    on_primary_container: "#00201d",
    secondary: "#4f6260",
    on_secondary: "#ffffff",
    secondary_container: "#d5e3e0",
    on_secondary_container: "#10201f",
    tertiary: "#875400",
    on_tertiary: "#ffffff",
    tertiary_container: "#f5dfb3",
    on_tertiary_container: "#2a1700",
    error: "#b3261e",
    on_error: "#ffffff",
    error_container: "#f9dedc",
    on_error_container: "#410e0b",
    on_background: "#10201f",
    on_surface: "#10201f",
    on_surface_variant: "#4f6260",
    outline: "#607874",
    outline_variant: "#a9c4bf",
    inverse_surface: "#293331",
    inverse_on_surface: "#ecf5f2",
    inverse_primary: "#5cd9cf",
    surface_tint: "#006d67",
    shadow: "#000000",
    scrim: "#000000"
  })

  readonly property var ghostDarkPalette: ({
    background: "#05080a",
    surface: "#0d1418",
    surface_dim: "#05080a",
    surface_bright: "#1c262a",
    surface_container_lowest: "#05080a",
    surface_container_low: "#0d1418",
    surface_container: "#12191d",
    surface_container_high: "#12191d",
    surface_container_highest: "#1c262a",
    surface_variant: "#1c262a",
    primary: "#57d9cc",
    on_primary: "#05080a",
    primary_container: "#246a63",
    on_primary_container: "#cdeeea",
    secondary: "#678984",
    on_secondary: "#05080a",
    secondary_container: "#1c262a",
    on_secondary_container: "#cdeeea",
    tertiary: "#e0a94a",
    on_tertiary: "#05080a",
    tertiary_container: "#3a2d0f",
    on_tertiary_container: "#ffe2a6",
    error: "#e0625a",
    on_error: "#05080a",
    error_container: "#4a201e",
    on_error_container: "#ffd9d5",
    on_background: "#cdeeea",
    on_surface: "#cdeeea",
    on_surface_variant: "#678984",
    outline: "#2f6f68",
    outline_variant: "#1c4d48",
    inverse_surface: "#cdeeea",
    inverse_on_surface: "#05080a",
    inverse_primary: "#006d67",
    surface_tint: "#57d9cc",
    shadow: "#000000",
    scrim: "#000000"
  })

  function paletteRole(mode, key, fallback) {
    var palette = ghostTheme
      ? (mode === "dark" ? ghostDarkPalette : ghostLightPalette)
      : (nothingEvolution
        ? (mode === "dark" ? darkPalette : lightPalette)
        : (nothingDesign
          ? (mode === "dark" ? nothingDarkPalette : nothingLightPalette)
          : (mode === "dark" ? darkPalette : lightPalette)))
    var value = palette ? palette[key] : null
    return typeof value === "string" && value.length > 0 ? value : fallback
  }

  function surfaceRole(mode, key, fallback, alpha) {
    var value = paletteRole(mode, key, fallback)
    return nothingEvolution
      ? Qt.rgba(value.r, value.g, value.b, alpha)
      : value
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

  // Resolved surface and content roles. Nothing and Ghost select their fixed
  // palettes through paletteRole(); other styles use Matugen with authored
  // fallbacks.
  property color background:                 paletteRole(darkMode ? "dark" : "light", "background", darkMode ? d_background : l_background)
  property color bg:                         background
  property color surface:                   surfaceRole(darkMode ? "dark" : "light", "surface", darkMode ? d_surface : l_surface, 0.84)
  property color surfaceDim:                surfaceRole(darkMode ? "dark" : "light", "surface_dim", darkMode ? d_surfaceDim : l_surfaceDim, 0.76)
  property color surfaceBright:             surfaceRole(darkMode ? "dark" : "light", "surface_bright", darkMode ? d_surfaceBright : l_surfaceBright, 0.94)
  property color surfaceContainerLowest:    surfaceRole(darkMode ? "dark" : "light", "surface_container_lowest", darkMode ? d_surfaceContainerLowest : l_surfaceContainerLowest, 0.78)
  property color surfaceContainerLow:       surfaceRole(darkMode ? "dark" : "light", "surface_container_low", darkMode ? d_surfaceContainerLow : l_surfaceContainerLow, Config.evolutionSurfaceAlpha)
  property color surfaceContainer:          surfaceRole(darkMode ? "dark" : "light", "surface_container", darkMode ? d_surfaceContainer : l_surfaceContainer, Config.evolutionRaisedAlpha)
  property color surfaceContainerHigh:      surfaceRole(darkMode ? "dark" : "light", "surface_container_high", darkMode ? d_surfaceContainerHigh : l_surfaceContainerHigh, 0.90)
  property color surfaceContainerHighest:   surfaceRole(darkMode ? "dark" : "light", "surface_container_highest", darkMode ? d_surfaceContainerHighest : l_surfaceContainerHighest, 0.94)
  property color surfaceVariant:            surfaceRole(darkMode ? "dark" : "light", "surface_variant", darkMode ? d_surfaceVariant : l_surfaceVariant, 0.88)
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

  // UI-style accents. These select how components use the active local roles;
  // they do not replace or regenerate Matugen's external color outputs.
  // Neo and Nothing use the palette's on-surface role as their high-contrast
  // ink. Nothing softens secondary rules while keeping its primary rules crisp
  // in both light and dark modes.
  readonly property color styleInk: ghostTheme
    ? ghostText
    : ((neoBrutalism || nothingDesign) ? fgSurface : outline)
  readonly property color styleOutline: ghostTheme
    ? ghostHairline
    : (neoBrutalism
      ? styleInk
      : (nothingEvolution
        ? Qt.rgba(styleInk.r, styleInk.g, styleInk.b, 0.30)
        : (nothingDesign
          ? Qt.rgba(styleInk.r, styleInk.g, styleInk.b, 0.38)
          : outlineVariant)))
  readonly property color styleOutlineStrong: ghostTheme
    ? ghostHairlineStrong
    : (neoBrutalism
      ? styleInk
      : (nothingEvolution
        ? Qt.rgba(styleInk.r, styleInk.g, styleInk.b, 0.58)
        : (nothingDesign
          ? Qt.rgba(styleInk.r, styleInk.g, styleInk.b, 0.72)
          : outline)))
  readonly property color styleShadow: ghostTheme
    ? "transparent"
    : (neoBrutalism ? (darkMode ? fgSurface : shadow) : "transparent")
  readonly property color styleSurface: ghostTheme
    ? ghostPanel
    : (neoBrutalism
      ? surfaceContainerLow
      : (nothingEvolution
        ? Qt.rgba(surfaceContainerLow.r, surfaceContainerLow.g, surfaceContainerLow.b, Config.evolutionSurfaceAlpha)
        : (nothingDesign ? surfaceContainerLow : surfaceContainerHigh)))
  readonly property color styleSurfaceRaised: ghostTheme
    ? ghostPanelRaised
    : (neoBrutalism
      ? surfaceContainer
      : (nothingEvolution
        ? Qt.rgba(surfaceContainer.r, surfaceContainer.g, surfaceContainer.b, Config.evolutionRaisedAlpha)
        : (nothingDesign ? surfaceContainer : surfaceContainerHigh)))
  readonly property color styleControl: ghostTheme
    ? ghostPanelHighest
    : (neoBrutalism
      ? surfaceContainerHighest
      : (nothingEvolution
        ? Qt.rgba(surfaceContainerHigh.r, surfaceContainerHigh.g, surfaceContainerHigh.b, Config.evolutionControlAlpha)
        : surfaceContainerHigh))
  readonly property color styleAccent: ghostTheme
    ? ghostCyan
    : (neoBrutalism
      ? (darkMode ? primary : primaryContainer)
      : (nothingEvolution ? primary : (nothingDesign ? error : primary)))
  readonly property color styleAccentText: ghostTheme
    ? ghostAccentText
    : (neoBrutalism
      ? (darkMode ? fgPrimary : fgPrimaryContainer)
      : (nothingEvolution ? fgPrimary : (nothingDesign ? fgError : fgPrimary)))
  // Evolution list rows use a translucent accent wash rather than a solid
  // primary container. Keep their content tied to the surface foreground;
  // Matugen's on_primary role can be dark in dark mode and disappear on that
  // low-alpha wash.
  readonly property color styleSelectedText: nothingEvolution ? fgSurface : styleAccentText

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

  property color success:                  ghostTheme ? ghostSuccess : (darkMode ? d_success                  : l_success)
  property color fgSuccess:                ghostTheme ? ghostSuccessText : (darkMode ? d_onSuccess                : l_onSuccess)
  property color successContainer:         ghostTheme ? ghostSuccessContainer : (darkMode ? d_successContainer         : l_successContainer)
  property color fgSuccessContainer:       ghostTheme ? ghostSuccessContainerText : (darkMode ? d_onSuccessContainer       : l_onSuccessContainer)
  property color warning:                  ghostTheme ? ghostWarning : (darkMode ? d_warning                  : l_warning)
  property color fgWarning:                ghostTheme ? ghostWarningText : (darkMode ? d_onWarning                : l_onWarning)
  property color warningContainer:         ghostTheme ? ghostWarningContainer : (darkMode ? d_warningContainer         : l_warningContainer)
  property color fgWarningContainer:       ghostTheme ? ghostWarningContainerText : (darkMode ? d_onWarningContainer       : l_onWarningContainer)
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
