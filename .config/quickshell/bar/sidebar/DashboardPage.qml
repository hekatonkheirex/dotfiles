import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../primitives"

ColumnLayout {
  id: root
  property bool active: false
  readonly property string username: Quickshell.env("USER") || "user"
  readonly property bool statisticsPolling: stats.polling
  signal settingsRequested(int tab)
  spacing: Config.spacingMedium

  Card {
    Layout.fillWidth: true
    implicitHeight: profile.implicitHeight + Config.spacingMedium * 2
    RowLayout {
      id: profile
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: Config.spacingMedium }
      spacing: Config.spacingMedium
      Rectangle {
        Layout.preferredWidth: 48
        Layout.preferredHeight: 48
        radius: width / 2
        color: Colors.secondary
        Text {
          anchors.centerIn: parent
          text: root.username.substring(0, 1).toUpperCase()
          color: Colors.fgSecondary
          font.family: Config.fontFamily
          font.pixelSize: Config.typeTitleLargeSize
          font.weight: Config.typeStrongWeight
        }
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Config.spacingCompact
        Text {
          Layout.fillWidth: true
          text: root.username
          elide: Text.ElideRight
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.typeTitleLargeSize
          font.weight: Config.typeStrongWeight
        }
        Text {
          Layout.fillWidth: true
          text: Quickshell.env("XDG_CURRENT_DESKTOP") || "Desktop session"
          elide: Text.ElideRight
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelLargeSize
        }
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Config.spacingSmall
    Repeater {
      model: [
        { label: "Account", icon: "person", tab: 0 },
        { label: "Appearance", icon: "palette", tab: 2 },
        { label: "System", icon: "monitor_heart", tab: 9 }
      ]
      ActionButton {
        required property var modelData
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        horizontalContent: false
        labelText: modelData.label
        iconLabel: modelData.icon
        accessibleName: "Open " + modelData.label + " settings"
        onActivated: root.settingsRequested(modelData.tab)
      }
    }
  }

  CalendarCard { Layout.fillWidth: true; active: root.active }
  StatsCard { id: stats; Layout.fillWidth: true; active: root.active }
  Item { Layout.fillHeight: true }
}
