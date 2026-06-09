import QtQml
import QtQuick

QtObject {
  id: colors

  // 0=system, 1=force-light, 2=force-dark
  property int themePreference: 0

  property bool systemDark: false

  property bool darkMode: {
    if (themePreference === 1) return false
    if (themePreference === 2) return true
    return systemDark
  }

  readonly property color l_bg: "#FFFBFE"
  readonly property color l_surface: "#FFFBFE"
  readonly property color l_surfaceDim: "#E9F3EB"
  readonly property color l_surfaceBright: "#FFFBFE"
  readonly property color l_surfaceContainer: "#E9F3EB"
  readonly property color l_surfaceContainerHigh: "#D0EADB"
  readonly property color l_surfaceContainerHighest: "#BEE8C7"
  readonly property color l_surfaceVariant: "#D0EADB"
  readonly property color l_primary: "#0F3C2C"
  readonly property color l_onPrimary: "#FFFFFF"
  readonly property color l_primaryContainer: "#1E4F3E"
  readonly property color l_onPrimaryContainer: "#BEE8C7"
  readonly property color l_secondary: "#1E4F3E"
  readonly property color l_onSecondary: "#FFFFFF"
  readonly property color l_secondaryContainer: "#D0EADB"
  readonly property color l_onSecondaryContainer: "#0F3C2C"
  readonly property color l_tertiary: "#1d3c34"
  readonly property color l_onTertiary: "#FFFFFF"
  readonly property color l_tertiaryContainer: "#E9F3EB"
  readonly property color l_onTertiaryContainer: "#0A281D"
  readonly property color l_error: "#ea1821"
  readonly property color l_onError: "#FFFFFF"
  readonly property color l_errorContainer: "#FCE4E4"
  readonly property color l_onErrorContainer: "#410E0B"
  readonly property color l_onSurface: "#0F3C2C"
  readonly property color l_onSurfaceVariant: "#1E4F3E"
  readonly property color l_outline: "#8ca090"
  readonly property color l_outlineVariant: "#D0EADB"
  readonly property color l_shadow: "#000000"
  readonly property color l_scrim: "#000000"

  readonly property color d_bg: "#1C1B1F"
  readonly property color d_surface: "#1C1B1F"
  readonly property color d_surfaceDim: "#141218"
  readonly property color d_surfaceBright: "#3B383E"
  readonly property color d_surfaceContainer: "#211F26"
  readonly property color d_surfaceContainerHigh: "#2B2930"
  readonly property color d_surfaceContainerHighest: "#36343B"
  readonly property color d_surfaceVariant: "#2B2930"
  readonly property color d_primary: "#BEE8C7"
  readonly property color d_onPrimary: "#0F3C2C"
  readonly property color d_primaryContainer: "#1E4F3E"
  readonly property color d_onPrimaryContainer: "#BEE8C7"
  readonly property color d_secondary: "#D0EADB"
  readonly property color d_onSecondary: "#0F3C2C"
  readonly property color d_secondaryContainer: "#1E4F3E"
  readonly property color d_onSecondaryContainer: "#D0EADB"
  readonly property color d_tertiary: "#8ca090"
  readonly property color d_onTertiary: "#0F3C2C"
  readonly property color d_tertiaryContainer: "#1d3c34"
  readonly property color d_onTertiaryContainer: "#E9F3EB"
  readonly property color d_error: "#F2B8B5"
  readonly property color d_onError: "#601410"
  readonly property color d_errorContainer: "#8C1D18"
  readonly property color d_onErrorContainer: "#F9DEDC"
  readonly property color d_onSurface: "#E6E1E5"
  readonly property color d_onSurfaceVariant: "#CAC4D0"
  readonly property color d_outline: "#938F99"
  readonly property color d_outlineVariant: "#49454F"
  readonly property color d_shadow: "#000000"
  readonly property color d_scrim: "#000000"

  property color bg: darkMode ? d_bg : l_bg
  property color surface: darkMode ? d_surface : l_surface
  property color surfaceDim: darkMode ? d_surfaceDim : l_surfaceDim
  property color surfaceBright: darkMode ? d_surfaceBright : l_surfaceBright
  property color surfaceContainer: darkMode ? d_surfaceContainer : l_surfaceContainer
  property color surfaceContainerHigh: darkMode ? d_surfaceContainerHigh : l_surfaceContainerHigh
  property color surfaceContainerHighest: darkMode ? d_surfaceContainerHighest : l_surfaceContainerHighest
  property color surfaceVariant: darkMode ? d_surfaceVariant : l_surfaceVariant
  property color primary: darkMode ? d_primary : l_primary
  property color onPrimary: darkMode ? d_onPrimary : l_onPrimary
  property color primaryContainer: darkMode ? d_primaryContainer : l_primaryContainer
  property color onPrimaryContainer: darkMode ? d_onPrimaryContainer : l_onPrimaryContainer
  property color secondary: darkMode ? d_secondary : l_secondary
  property color onSecondary: darkMode ? d_onSecondary : l_onSecondary
  property color secondaryContainer: darkMode ? d_secondaryContainer : l_secondaryContainer
  property color onSecondaryContainer: darkMode ? d_onSecondaryContainer : l_onSecondaryContainer
  property color tertiary: darkMode ? d_tertiary : l_tertiary
  property color onTertiary: darkMode ? d_onTertiary : l_onTertiary
  property color tertiaryContainer: darkMode ? d_tertiaryContainer : l_tertiaryContainer
  property color onTertiaryContainer: darkMode ? d_onTertiaryContainer : l_onTertiaryContainer
  property color error: darkMode ? d_error : l_error
  property color onError: darkMode ? d_onError : l_onError
  property color errorContainer: darkMode ? d_errorContainer : l_errorContainer
  property color onErrorContainer: darkMode ? d_onErrorContainer : l_onErrorContainer
  property color onSurface: darkMode ? d_onSurface : l_onSurface
  property color onSurfaceVariant: darkMode ? d_onSurfaceVariant : l_onSurfaceVariant
  property color outline: darkMode ? d_outline : l_outline
  property color outlineVariant: darkMode ? d_outlineVariant : l_outlineVariant
  property color shadow: darkMode ? d_shadow : l_shadow
  property color scrim: darkMode ? d_scrim : l_scrim
  property color hoverOverlay: Qt.rgba(1, 1, 1, darkMode ? 0.10 : 0.06)
  property color pressOverlay: Qt.rgba(1, 1, 1, darkMode ? 0.16 : 0.10)

  onDarkModeChanged: {
    bg = darkMode ? d_bg : l_bg
    surface = darkMode ? d_surface : l_surface
    surfaceDim = darkMode ? d_surfaceDim : l_surfaceDim
    surfaceBright = darkMode ? d_surfaceBright : l_surfaceBright
    surfaceContainer = darkMode ? d_surfaceContainer : l_surfaceContainer
    surfaceContainerHigh = darkMode ? d_surfaceContainerHigh : l_surfaceContainerHigh
    surfaceContainerHighest = darkMode ? d_surfaceContainerHighest : l_surfaceContainerHighest
    surfaceVariant = darkMode ? d_surfaceVariant : l_surfaceVariant
    primary = darkMode ? d_primary : l_primary
    onPrimary = darkMode ? d_onPrimary : l_onPrimary
    primaryContainer = darkMode ? d_primaryContainer : l_primaryContainer
    onPrimaryContainer = darkMode ? d_onPrimaryContainer : l_onPrimaryContainer
    secondary = darkMode ? d_secondary : l_secondary
    onSecondary = darkMode ? d_onSecondary : l_onSecondary
    secondaryContainer = darkMode ? d_secondaryContainer : l_secondaryContainer
    onSecondaryContainer = darkMode ? d_onSecondaryContainer : l_onSecondaryContainer
    tertiary = darkMode ? d_tertiary : l_tertiary
    onTertiary = darkMode ? d_onTertiary : l_onTertiary
    tertiaryContainer = darkMode ? d_tertiaryContainer : l_tertiaryContainer
    onTertiaryContainer = darkMode ? d_onTertiaryContainer : l_onTertiaryContainer
    error = darkMode ? d_error : l_error
    onError = darkMode ? d_onError : l_onError
    errorContainer = darkMode ? d_errorContainer : l_errorContainer
    onErrorContainer = darkMode ? d_onErrorContainer : l_onErrorContainer
    onSurface = darkMode ? d_onSurface : l_onSurface
    onSurfaceVariant = darkMode ? d_onSurfaceVariant : l_onSurfaceVariant
    outline = darkMode ? d_outline : l_outline
    outlineVariant = darkMode ? d_outlineVariant : l_outlineVariant
    shadow = darkMode ? d_shadow : l_shadow
    scrim = darkMode ? d_scrim : l_scrim
    hoverOverlay = Qt.rgba(1, 1, 1, darkMode ? 0.10 : 0.06)
    pressOverlay = Qt.rgba(1, 1, 1, darkMode ? 0.16 : 0.10)
  }
}
