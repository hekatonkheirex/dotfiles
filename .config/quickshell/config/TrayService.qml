pragma Singleton
import QtQml
import Quickshell.Services.SystemTray

// The StatusNotifier items the tray window shows. Referencing the module here
// also registers the StatusNotifierWatcher at startup, so tray apps can start.
// blueman and udiskie are filtered as before (the shell has its own controls).
QtObject {
  id: root

  readonly property var items: SystemTray.items.values.filter(function(item) {
    return item.id !== "blueman" && item.id !== "udiskie"
  })
  readonly property int count: root.items.length
}
