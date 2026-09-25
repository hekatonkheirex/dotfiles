import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: bluetoothTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 6
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: bluetoothTab }

  onVisibleChanged: if (visible) btPanel.refresh()
  Component.onCompleted: if (visible) btPanel.refresh()

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, bluetoothTab.width - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge

    SettingsPageHeader {
      pageTitle: "Bluetooth"
      subtitle: "Pair and manage nearby Bluetooth devices."
    }

    SettingsSectionLabel { text: "Devices" }

    SettingsCard {
      Layout.fillWidth: true
      Layout.preferredHeight: btPanel.implicitHeight + Config.spacingLarge * 2

      BtPanel {
        id: btPanel
        anchors.fill: parent
        anchors.margins: Config.spacingLarge
      }
    }
  }
}
