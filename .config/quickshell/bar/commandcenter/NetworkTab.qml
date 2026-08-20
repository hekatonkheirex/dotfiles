import QtQuick
import QtQuick.Layouts
import "../"
import "../../config"

Flickable {
  id: networkTab
  property QtObject root: null
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  anchors.fill: parent
  visible: root.currentTab === 4
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + networkTab.neoShadowAllowance
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  onVisibleChanged: if (visible) wifiPanel.refresh()
  Component.onCompleted: if (visible) wifiPanel.refresh()

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, networkTab.width - networkTab.neoShadowAllowance)
    spacing: Config.spacingLarge + networkTab.neoShadowAllowance

    WifiPanel {
      id: wifiPanel
      Layout.fillWidth: true
    }
  }
}
