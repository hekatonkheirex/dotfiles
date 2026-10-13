import QtQuick
import Quickshell
import "../../config"
import "../primitives"

Card {
  id: root

  readonly property bool hasPlayer: MediaService.status !== "NoPlayer"
  readonly property string control: Quickshell.env("HOME")
    + "/.config/quickshell/scripts/mpris_control.py"

  implicitHeight: col.implicitHeight + Config.spacingLarge * 2

  Column {
    id: col
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.margins: Config.spacingLarge
    anchors.verticalCenter: parent.verticalCenter
    spacing: Config.spacingSmall

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      text: root.hasPlayer
        ? (MediaService.title !== "" ? MediaService.title : "Unknown title")
        : "Nothing playing"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.typeTitleMediumSize
      font.weight: Font.Medium
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      visible: root.hasPlayer && MediaService.artist !== ""
      text: MediaService.artist
      color: Colors.tertiary
      font.family: Config.fontFamily
      font.pixelSize: Config.typeBodyMediumSize
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Config.spacingSmall

      IconButton {
        size: 40
        iconSize: 20
        iconLabel: "skip_previous"
        accessibleName: "Previous track"
        tooltipText: "Previous track"
        onClicked: Quickshell.execDetached([root.control, "prev"])
      }
      IconButton {
        size: 48
        iconSize: 22
        iconLabel: MediaService.status === "Playing" ? "pause" : "play_arrow"
        accessibleName: MediaService.status === "Playing" ? "Pause" : "Play"
        tooltipText: MediaService.status === "Playing" ? "Pause" : "Play"
        onClicked: Quickshell.execDetached([root.control, "play"])
      }
      IconButton {
        size: 40
        iconSize: 20
        iconLabel: "skip_next"
        accessibleName: "Next track"
        tooltipText: "Next track"
        onClicked: Quickshell.execDetached([root.control, "next"])
      }
    }
  }
}
