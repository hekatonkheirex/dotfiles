import QtQuick
import QtQuick.Window
import "../config"

Item {
  id: focusDismiss
  property var target: parent
  signal dismissed()
  readonly property var popupWindow: Window.window

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

  function dismissIfFocusLeft() {
    if (focusDismiss.target && focusDismiss.target.visible
        && !focusDismiss.focusIsInsidePopup()) {
      focusDismiss.dismissed()
    }
  }

  Connections {
    target: focusDismiss.popupWindow
    enabled: Config.isNiri || Config.isMango

    function onActiveFocusItemChanged() {
      focusDismiss.dismissIfFocusLeft()
    }

    function onActiveChanged() {
      focusDismiss.dismissIfFocusLeft()
    }
  }

}
