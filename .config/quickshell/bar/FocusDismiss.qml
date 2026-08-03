import QtQuick
import "../config"

Item {
  id: focusDismiss
  property var target: parent
  signal dismissed()

  Component.onCompleted: {
    if (focusDismiss.parent && Config.isNiri) {
      focusDismiss.parent.activeFocusChanged.connect(function() {
        if (!focusDismiss.parent.activeFocus && focusDismiss.target && focusDismiss.target.visible) focusDismiss.dismissed()
      })
    }

    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && focusDismiss.target && focusDismiss.target.visible) focusDismiss.dismissed()
    })
  }
}
