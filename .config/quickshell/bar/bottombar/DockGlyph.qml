import QtQuick
import "../../config"
import "../../config/DockSymbols.js" as DockSymbols
import "../../config/BottomBarModel.js" as BottomBarModel

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

  implicitWidth: Config.bottomBarDp(35)
  implicitHeight: Config.bottomBarDp(26) + Config.bottomBarDp(6) + Config.bottomBarDp(3)

  Text {
    id: glyph
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    text: root.sym.symbol
    color: root.glyphColor
    font.family: root.sym.font === "material" ? BottomBarFonts.materialFamily : BottomBarFonts.family
    font.pixelSize: Math.round(16 * 4 / 3 * Config.bottomBarScale)   // 16pt * scale
    Behavior on color {
      enabled: !Config.reducedMotion
      ColorAnimation { duration: 200 }
    }
  }

  Rectangle {
    objectName: "focusIndicator"
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    width: Config.bottomBarDp(6)
    height: Config.bottomBarDp(3)
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
    // One cycle per full 120 notch so a touchpad swipe of many small deltas
    // does not skip through every window. Wheel up (positive) cycles back.
    onWheel: function(wheel) {
      const r = BottomBarModel.notchSteps(root.wheelAccum, wheel.angleDelta.y)
      root.wheelAccum = r.accum
      for (let i = 0; i < Math.abs(r.steps); i++) root.cycled(r.steps > 0 ? -1 : 1)
    }
  }
}
