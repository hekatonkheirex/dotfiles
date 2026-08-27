import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: mediaTab
  property QtObject root: null
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  anchors.fill: parent
  visible: root.currentTab === 7
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + mediaTab.neoShadowAllowance
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: mediaTab }

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, mediaTab.width - mediaTab.neoShadowAllowance - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge + mediaTab.neoShadowAllowance

    SettingsPageHeader {
      pageTitle: "Media"
      subtitle: "Configure media playback controls and the media popup."
    }

    StyledSurface {
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: mediaCol.implicitHeight + Config.spacingSmall * 2
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: mediaCol
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingSmall

        Text {
          text: "Media"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          Layout.leftMargin: Config.spacingSmall
          Layout.topMargin: Config.spacingCompact
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "image"
          title: "Show album art"
          subtitle: "Display cover art in the media popup"
          SwitchControl {
            checked: Settings.mediaShowAlbumArt
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Show album art"
            onToggled: { Settings.mediaShowAlbumArt = !Settings.mediaShowAlbumArt; Settings.save() }
          }
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "linear_scale"
          title: "Show progress bar"
          subtitle: "Display the playback progress bar"
          SwitchControl {
            checked: Settings.mediaShowProgressBar
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Show progress bar"
            onToggled: { Settings.mediaShowProgressBar = !Settings.mediaShowProgressBar; Settings.save() }
          }
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "touch_app"
          title: "Controls always visible"
          subtitle: "Bar icon toggles play/pause directly, instead of opening the popup"
          SwitchControl {
            checked: Settings.mediaControlsAlwaysVisible
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.styleOutlineStrong
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Media controls always visible"
            onToggled: { Settings.mediaControlsAlwaysVisible = !Settings.mediaControlsAlwaysVisible; Settings.save() }
          }
        }
      }
    }

    Item { Layout.fillHeight: true }
  }
}
