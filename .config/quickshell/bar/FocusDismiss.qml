import QtQuick
import QtQuick.Window
import "../config"

Item {
  id: focusDismiss
  property var target: parent
  signal dismissed()
  readonly property var popupWindow: Window.window
  property bool focusAcquired: false
  onPopupWindowChanged: focusAcquired = false

  function focusIsInsidePopup() {
    if (!focusDismiss.popupWindow || focusDismiss.popupWindow.active === false) return false

    var activeItem = focusDismiss.popupWindow.activeFocusItem
    var popupRoot = focusDismiss.parent
    while (activeItem) {
      if (activeItem === popupRoot) return true
      activeItem = activeItem.parent
    }
    return false
  }

  function dismissIfFocusStillOutside() {
    if (focusDismiss.target && focusDismiss.target.visible
        && focusDismiss.focusAcquired && !focusDismiss.focusIsInsidePopup()) {
      focusDismiss.focusAcquired = false
      focusDismiss.dismissed()
    }
  }

  function dismissIfFocusLeft() {
    if (!focusDismiss.target || !focusDismiss.target.visible) return
    if (focusDismiss.focusIsInsidePopup()) {
      focusDismiss.focusAcquired = true
    } else if (focusDismiss.focusAcquired && (Config.isNiri || Config.isMango)) {
      // Focus can briefly be null while a popup maps or changes controls.
      Qt.callLater(focusDismiss.dismissIfFocusStillOutside)
    }
  }

  Connections {
    target: focusDismiss.target
    function onVisibleChanged() {
      if (!focusDismiss.target.visible) focusDismiss.focusAcquired = false
    }
  }

  Connections {
    target: focusDismiss.popupWindow

    function onActiveFocusItemChanged() {
      focusDismiss.dismissIfFocusLeft()
    }

    function onActiveChanged() {
      focusDismiss.dismissIfFocusLeft()
    }
  }

}
