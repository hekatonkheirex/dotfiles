import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: networkTab
  property QtObject root: null
  anchors.fill: parent
  visible: root.currentTab === 5
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: networkTab }

  onVisibleChanged: if (visible) wifiPanel.refresh()
  Component.onCompleted: if (visible) wifiPanel.refresh()

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, networkTab.width - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge

    SettingsPageHeader {
      pageTitle: "Network"
      subtitle: "Connect to Wi-Fi networks and manage saved connections."
    }

    WifiPanel {
      id: wifiPanel
      Layout.fillWidth: true
    }
  }
}
