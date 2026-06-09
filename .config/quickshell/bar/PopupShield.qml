import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell

PanelWindow {
  id: root

  property QtObject config: null

  signal shieldClicked()

  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  WlrLayershell.namespace: "quickshell-shield"
  WlrLayershell.layer: WlrLayer.Bottom

  anchors.left: true
  anchors.right: true
  anchors.top: true
  anchors.bottom: true

  visible: false

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onPressed: root.shieldClicked()
  }
}
