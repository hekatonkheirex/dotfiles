import QtQml
import Quickshell

QtObject {
  readonly property string wmType: {
    var desktop = Quickshell.env("XDG_CURRENT_DESKTOP")
    if (desktop && desktop.toLowerCase() === "niri") return "niri"
    var niriSock = Quickshell.env("NIRI_SOCKET")
    if (niriSock && niriSock.length > 0) return "niri"
    var sig = Quickshell.env("MANGO_INSTANCE_SIGNATURE")
    if (sig && sig.length > 0) return "mango"
    return "niri"
  }
  readonly property bool isNiri: wmType === "niri"
  readonly property int barWidth: 44
  readonly property int widgetSize: 44
  readonly property int padding: 6
  readonly property int iconSize: 20
  readonly property int fontPixelSize: 10
  readonly property string fontFamily: "Google Sans Flex"
  readonly property string iconFont: "Material Symbols Outlined"
  readonly property int animationDuration: 150
  readonly property int popupWidth: 340
  readonly property int popupPadding: 16
  readonly property int borderRadius: 16
  readonly property int clockIntervalMs: 1000
  readonly property int volumeStep: 5
  readonly property int brightnessStep: 5
  readonly property int notificationToastDurationMs: 5000
}
