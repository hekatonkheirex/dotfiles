import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: bluetoothTab
  property QtObject root: null
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  anchors.fill: parent
  visible: root.currentTab === 6
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + bluetoothTab.neoShadowAllowance
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: bluetoothTab }

  onVisibleChanged: if (visible) btPanel.refresh()
  Component.onCompleted: if (visible) btPanel.refresh()

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, bluetoothTab.width - bluetoothTab.neoShadowAllowance - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge + bluetoothTab.neoShadowAllowance

    SettingsPageHeader {
      pageTitle: "Bluetooth"
      subtitle: "Pair and manage nearby Bluetooth devices."
    }

    BtPanel {
      id: btPanel
      Layout.fillWidth: true
    }
  }
}
