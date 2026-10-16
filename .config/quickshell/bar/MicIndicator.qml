import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "../config/MicState.js" as MicState

// Her microphone tab: 12 S by 6 S, top center, square top and round bottom.
// Live mic x1 at full opacity, muted x8 at 0.4. Click toggles the default
// source's mute, middle click hides it until the mute state next changes.
PanelWindow {
  id: root

  property bool allowed: true   // shell.qml: false while locked
  readonly property var look: MicState.look(MicService.muted)

  visible: root.allowed && MicService.enabled && MicService.ready && !MicService.hidden
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("popup-mic")
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  anchors.top: true
  implicitWidth: Config.dp(12)
  implicitHeight: Config.dp(6)

  Rectangle {
    objectName: "tab"
    anchors.fill: parent
    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: height / 2
    bottomRightRadius: height / 2
    color: Colors.elenaAccent(root.look.slot)
    opacity: root.look.opacity
    Behavior on opacity {
      enabled: !Config.reducedMotion
      NumberAnimation { duration: 200 }
    }
    Behavior on color {
      enabled: !Config.reducedMotion
      ColorAnimation { duration: 200 }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(m) {
      if (m.button === Qt.MiddleButton) MicService.hide()
      else MicService.toggle()
    }
  }
}
