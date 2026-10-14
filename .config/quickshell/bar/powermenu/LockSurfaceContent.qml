import QtQuick
import "../../config"

// The lock surface in her look: opaque surface backdrop, PowerMenuContent in
// locked mode (ring + "[ L O C K D O W N ]" with the masked input), and a
// hidden password TextInput that keeps keyboard focus. LockScreen.qml stays
// the source of truth: it binds `password` to lockInputText, copies `typed`
// back on `edited`, and runs tryLockAuth() on `submitted`.
Item {
  id: root

  property string password: ""
  property bool authFailed: false
  property string lastAction: "clear"
  // Fade the content in once mapped; the backdrop is opaque from the first frame.
  property bool shown: false
  readonly property alias typed: input.text

  signal submitted()
  signal edited(string action)

  function focusInput() { input.forceActiveFocus() }

  Component.onCompleted: { root.shown = true; root.focusInput() }
  onVisibleChanged: if (visible) root.focusInput()

  Rectangle {
    anchors.fill: parent
    color: Colors.surface
  }

  // Swallow every pointer gesture; any press puts focus back on the input.
  PinchHandler { target: null }
  WheelHandler { target: null }
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    hoverEnabled: true
    onPressed: root.focusInput()
    onWheel: (wheel) => { wheel.accepted = true }
  }

  PowerMenuContent {
    objectName: "lockContent"
    anchors.centerIn: parent
    width: implicitWidth
    height: implicitHeight
    locked: true
    revealed: true
    inputLength: input.text.length
    lastAction: root.lastAction
    authFailed: root.authFailed
    opacity: root.shown ? 1 : 0
    Behavior on opacity {
      NumberAnimation { duration: Config.reducedMotion ? 0 : 1200; easing.type: Easing.OutCubic }
    }
  }

  // Hidden field: the terminal line shows only the mask, never the text.
  TextInput {
    id: input
    objectName: "lockInput"
    width: 1
    height: 1
    opacity: 0
    focus: true
    text: root.password
    echoMode: TextInput.Password
    cursorVisible: false
    selectByMouse: false
    property int previousLength: 0

    onTextChanged: {
      var n = text.length
      var action = n === 0 ? "clear" : n >= previousLength ? "insert" : "delete"
      previousLength = n
      root.lastAction = action
      root.edited(action)
    }

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        root.submitted()
      }
    }
  }
}
