import QtQuick
import "../../config"

// The dock's row of items. No window: Dock.qml hosts it and the render check
// loads it directly.
Row {
  id: root

  property var items: []

  signal itemActivated(string appId)
  signal itemClosed(string appId)
  signal itemCycled(string appId, int direction)

  readonly property var accents: [Colors.primary, Colors.secondary, Colors.tertiary]

  Repeater {
    model: root.items

    DockItem {
      required property var modelData
      required property int index
      appId: modelData.appId
      running: modelData.count > 0
      focused: modelData.focused
      urgent: modelData.urgent
      accent: root.accents[index % root.accents.length]
      onActivated: root.itemActivated(modelData.appId)
      onCloseRequested: root.itemClosed(modelData.appId)
      onCycled: function(direction) { root.itemCycled(modelData.appId, direction) }
    }
  }
}
