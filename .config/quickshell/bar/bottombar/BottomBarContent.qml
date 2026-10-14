import QtQuick
import "../../config"

// The whole bar surface without a window (the render check loads it directly).
Item {
  id: root

  property var items: []
  property string clockText: "0000"
  property string dateText: "00"
  property real volume: 0
  property bool muted: false
  property real batteryPct: -1
  property bool charging: false
  property int signal: 0
  property bool connected: false
  property bool vpn: false
  property int alarmCount: 0
  property string forceHover: ""

  signal glanceClicked()
  signal glanceRightClicked()
  signal tasksClicked()
  signal mediaClicked()
  signal mediaRightClicked()
  signal mediaMiddleClicked()
  signal mediaScrolled(int delta)
  signal networkClicked()
  signal alarmsClicked()
  signal logoutClicked()
  signal itemActivated(string appId)
  signal itemClosed(string appId)
  signal itemCycled(string appId, int direction)

  implicitHeight: Config.bottomBarHeight

  readonly property int outerRadius: Config.bottomBarDp(20)

  // Left cluster
  Rectangle {
    id: left
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    width: Config.bottomBarDp(300)
    height: parent.height
    color: Colors.surface
    topRightRadius: root.outerRadius

    Row {
      anchors.fill: parent
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: ""
        accent: Colors.elenaAccent(1)
        forceHover: root.forceHover === "glance"
        onClicked: root.glanceClicked()
        onRightClicked: root.glanceRightClicked()
        ValuePill { text: root.clockText; minWidth: Config.bottomBarDp(34) }
      }
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: ""
        accent: Colors.elenaAccent(2)
        forceHover: root.forceHover === "tasks"
        onClicked: root.tasksClicked()
        ValuePill { text: root.dateText }
      }
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: ""
        accent: Colors.elenaAccent(5)
        forceHover: root.forceHover === "media"
        onClicked: root.mediaClicked()
        onRightClicked: root.mediaRightClicked()
        onMiddleClicked: root.mediaMiddleClicked()
        onWheel: function(delta) { root.mediaScrolled(delta) }
        VolumeRing { value: root.volume; muted: root.muted }
      }
    }
  }

  // Centre dock. The clip box is the free width between the clusters (plus an
  // 8 dp margin each side), so a long item list is cut off instead of painting
  // or taking input over a cluster. The row stays centred and bottom-aligned.
  Item {
    id: dockClip
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Config.bottomBarDp(6)
    width: Math.max(0, root.width - 2 * Config.bottomBarDp(300) - 2 * Config.bottomBarDp(8))
    height: Config.bottomBarDp(26) + Config.bottomBarDp(6) + Config.bottomBarDp(3)
    clip: true

    Row {
      id: dock
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      spacing: Config.bottomBarDp(4)

      Repeater {
        model: root.items
        DockGlyph {
          required property var modelData
          appId: modelData.appId
          running: modelData.count > 0
          focused: modelData.focused
          onActivated: root.itemActivated(modelData.appId)
          onCloseRequested: root.itemClosed(modelData.appId)
          onCycled: function(direction) { root.itemCycled(modelData.appId, direction) }
        }
      }
    }
  }

  // Right cluster
  Rectangle {
    id: right
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    width: Config.bottomBarDp(300)
    height: parent.height
    color: Colors.surface
    topLeftRadius: root.outerRadius

    Row {
      anchors.fill: parent
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: root.vpn ? "" : ""
        accent: Colors.elenaAccent(4)
        forceHover: root.forceHover === "network"
        onClicked: root.networkClicked()
        SignalBars { signal: root.signal; connected: root.connected }
      }
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: ""
        accent: Colors.elenaAccent(3)
        forceHover: root.forceHover === "alarms"
        onClicked: root.alarmsClicked()
        Item {
          width: Config.bottomBarDp(23)
          height: Config.bottomBarDp(23)
          ValuePill {
            anchors.centerIn: parent
            visible: root.alarmCount > 0
            text: String(root.alarmCount)
          }
          Rectangle {   // no alarms: the slashed line
            anchors.centerIn: parent
            visible: root.alarmCount === 0
            width: Config.bottomBarDp(23)
            height: Config.bottomBarDp(4)
            radius: height / 2
            rotation: 38
            color: Colors.elenaAccent(3)
          }
        }
      }
      BarButton {
        width: parent.width / 3
        height: parent.height
        symbol: root.charging ? "" : ""
        accent: Colors.elenaAccent(6)
        forceHover: root.forceHover === "logout"
        onClicked: root.logoutClicked()
        BatteryStack { pct: root.batteryPct }
      }
    }
  }
}
