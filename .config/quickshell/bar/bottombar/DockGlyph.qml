import QtQuick
import "../../config"
import "../../config/DockSymbols.js" as DockSymbols

// One dock item: app glyph in its accent, a 6x3 S indicator under it while the
// app is focused, muted glyph while pinned with no window. Click focuses or
// launches, middle click closes, wheel cycles one window per 120 notch.
Item {
  id: root

  property string appId: ""
  property bool running: false
  property bool focused: false
  property real wheelAccum: 0

  readonly property var sym: DockSymbols.symbolFor(root.appId)
  readonly property color accent: Colors.elenaAccent(root.sym.slot)
  readonly property color glyphColor: root.running ? root.accent : Colors.elenaAccent(8)

  signal activated()
  signal closeRequested()
  signal cycled(int direction)

  implicitWidth: Config.dp(35)
  implicitHeight: Config.dp(26) + Config.dp(6) + Config.dp(3)

  Text {
    id: glyph
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    text: root.sym.symbol
    color: root.glyphColor
    font.family: root.sym.font === "material" ? BottomBarFonts.materialFamily : BottomBarFonts.family
    font.pixelSize: Math.round(16 * 4 / 3 * Config.elenaScale)   // 16pt * scale
    Behavior on color {
      enabled: !Config.reducedMotion
      ColorAnimation { duration: 200 }
    }
  }

  Rectangle {
    objectName: "focusIndicator"
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    width: Config.dp(6)
    height: Config.dp(3)
    radius: height / 2
    color: root.accent
    opacity: root.focused ? 1 : 0
    Behavior on opacity {
      enabled: !Config.reducedMotion
      NumberAnimation { duration: 200 }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.MiddleButton) root.closeRequested()
      else root.activated()
    }
    onWheel: function(wheel) {
      const dy = wheel.angleDelta.y
      if (dy === 0) return
      // Reset on direction flip; one cycle per full 120 notch so a touchpad
      // swipe of many small deltas does not skip through every window.
      if ((dy > 0) !== (root.wheelAccum > 0)) root.wheelAccum = 0
      root.wheelAccum += dy
      while (Math.abs(root.wheelAccum) >= 120) {
        const dir = root.wheelAccum > 0 ? -1 : 1
        root.wheelAccum -= root.wheelAccum > 0 ? 120 : -120
        root.cycled(dir)
      }
    }
  }
}
