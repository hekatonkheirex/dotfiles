import QtQuick
import QtQuick.Layouts
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: mediaTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 6
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  ColumnLayout {
    id: mainColumn
    width: mediaTab.width
    spacing: Config.spacingLarge

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: mediaCol.implicitHeight + 16
      radius: Config.shapeLarge
      color: Colors.surfaceContainer
      border.color: Colors.outlineVariant
      border.width: 1

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
          Layout.leftMargin: 8
          Layout.topMargin: 4
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
            outline: Colors.outline
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
            outline: Colors.outline
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
            outline: Colors.outline
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
