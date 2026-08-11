import QtQuick
import QtQuick.Layouts
import "../"
import "../../config"

Flickable {
  id: networkTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 4
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  onVisibleChanged: if (visible) wifiPanel.refresh()
  Component.onCompleted: if (visible) wifiPanel.refresh()

  ColumnLayout {
    id: mainColumn
    width: networkTab.width
    spacing: Config.spacingLarge

    WifiPanel {
      id: wifiPanel
      Layout.fillWidth: true
    }
  }
}
