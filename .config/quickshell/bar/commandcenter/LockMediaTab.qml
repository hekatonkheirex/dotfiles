import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: lockMediaTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 3
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  ColumnLayout {
    id: mainColumn
    width: lockMediaTab.width
    spacing: 16

    // Lock Screen card
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: lockCol.implicitHeight + 16
      radius: Config.shapeLarge
      color: Colors.surfaceContainer
      border.color: Colors.outlineVariant
      border.width: 1

      ColumnLayout {
        id: lockCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Text {
          text: "Lock Screen"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: 11
          font.weight: Font.Medium
          Layout.leftMargin: 8
          Layout.topMargin: 4
        }

        ListItem {
          Layout.fillWidth: true
          leadingIcon: "music_note"
          title: "Show now playing"
          subtitle: "Display current track on the lock screen"
          SwitchControl {
            checked: Settings.lockShowMedia
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Show now playing on lock screen"
            onToggled: { Settings.lockShowMedia = !Settings.lockShowMedia; Settings.save() }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: 44
          spacing: 12

          Text {
            text: "Clock Size"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: 12
            Layout.preferredWidth: 90
            Layout.leftMargin: 8
          }

          SliderControl {
            Layout.fillWidth: true
            value: (Settings.lockClockSize - 48) / 48
            stepSize: 2 / 48
            activeColor: Colors.primary
            surfaceContainerHigh: Colors.surfaceContainerHigh
            surfaceContainerHighest: Colors.surfaceContainerHighest
            outline: Colors.outline
            focusColor: Colors.primary
            motionDuration: Config.motionMedium
            reducedMotion: Config.reducedMotion
            accessibleName: "Lock screen clock size"
            accessibleDescription: "Adjust the lock screen clock size"
            onChanged: function(val) {
              Settings.lockClockSize = Math.round(48 + val * 48)
              Settings.save()
            }
          }

          Text {
            text: Math.round(Settings.lockClockSize) + "px"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: 11
            Layout.preferredWidth: 34
          }
        }
      }
    }

    // Media Popup card
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
        anchors.margins: 8
        spacing: 0

        Text {
          text: "Media"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: 11
          font.weight: Font.Medium
          Layout.leftMargin: 8
          Layout.topMargin: 4
          Layout.bottomMargin: 4
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
