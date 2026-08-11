import QtQuick
import QtQuick.Layouts
import "../"
import "../../config"

Flickable {
  id: bluetoothTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 5
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  onVisibleChanged: if (visible) btPanel.refresh()
  Component.onCompleted: if (visible) btPanel.refresh()

  ColumnLayout {
    id: mainColumn
    width: bluetoothTab.width
    spacing: Config.spacingLarge

    BtPanel {
      id: btPanel
      Layout.fillWidth: true
    }
  }
}
