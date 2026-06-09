import QtQuick

Item {
  property var target: parent
  property var config: null
  signal dismissed()

  Component.onCompleted: {
    if (root.parent && config && config.isNiri) {
      root.parent.activeFocusChanged.connect(function() {
        if (!root.parent.activeFocus && root.target.visible) root.dismissed()
      })
    }

    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.target.visible) root.dismissed()
    })
  }
}
