import QtQuick
import QtQuick.Layouts
import "../"
import "../../config"

Flickable {
  id: bluetoothTab
  property QtObject root: null
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  anchors.fill: parent
  visible: root.currentTab === 5
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + bluetoothTab.neoShadowAllowance
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  onVisibleChanged: if (visible) btPanel.refresh()
  Component.onCompleted: if (visible) btPanel.refresh()

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, bluetoothTab.width - bluetoothTab.neoShadowAllowance)
    spacing: Config.spacingLarge + bluetoothTab.neoShadowAllowance

    BtPanel {
      id: btPanel
      Layout.fillWidth: true
    }
  }
}
