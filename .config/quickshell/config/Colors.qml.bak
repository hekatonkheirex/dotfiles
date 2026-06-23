import QtQml
import QtQuick

QtObject {
  id: colors

  // 0=system, 1=force-light, 2=force-dark
  property int themePreference: 0

  property bool systemDark: true

  property bool darkMode: themePreference === 1 ? false : (themePreference === 2 ? true : systemDark)

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
  readonly property color d_surfaceContainer: "#25232A"
  readonly property color d_surfaceContainerHigh: "#312F37"
  readonly property color d_surfaceContainerHighest: "#3C3A43"
  readonly property color d_surfaceVariant: "#312F37"
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
  property color fgPrimary: darkMode ? d_onPrimary : l_onPrimary
  property color primaryContainer: darkMode ? d_primaryContainer : l_primaryContainer
  property color fgPrimaryContainer: darkMode ? d_onPrimaryContainer : l_onPrimaryContainer
  property color secondary: darkMode ? d_secondary : l_secondary
  property color fgSecondary: darkMode ? d_onSecondary : l_onSecondary
  property color secondaryContainer: darkMode ? d_secondaryContainer : l_secondaryContainer
  property color fgSecondaryContainer: darkMode ? d_onSecondaryContainer : l_onSecondaryContainer
  property color tertiary: darkMode ? d_tertiary : l_tertiary
  property color fgTertiary: darkMode ? d_onTertiary : l_onTertiary
  property color tertiaryContainer: darkMode ? d_tertiaryContainer : l_tertiaryContainer
  property color fgTertiaryContainer: darkMode ? d_onTertiaryContainer : l_onTertiaryContainer
  property color error: darkMode ? d_error : l_error
  property color fgError: darkMode ? d_onError : l_onError
  property color errorContainer: darkMode ? d_errorContainer : l_errorContainer
  property color fgErrorContainer: darkMode ? d_onErrorContainer : l_onErrorContainer
  property color fgSurface: darkMode ? d_onSurface : l_onSurface
  property color fgSurfaceVariant: darkMode ? d_onSurfaceVariant : l_onSurfaceVariant
  property color outline: darkMode ? d_outline : l_outline
  property color outlineVariant: darkMode ? d_outlineVariant : l_outlineVariant
  property color shadow: darkMode ? d_shadow : l_shadow
  property color scrim: darkMode ? d_scrim : l_scrim
  property color hoverOverlay: darkMode ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.06)
  property color pressOverlay: darkMode ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.10)
}
