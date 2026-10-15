import QtQuick
import Quickshell
import "../../config"
import "../../config/DockSymbols.js" as DockSymbols
import "../../config/BottomBarModel.js" as BottomBarModel

// One dock item: app icon (glyph fallback) in its accent, a 5x5 dot under it while the app is
// open but unfocused, a 12x3 bar while focused, muted glyph while pinned with no window. Click focuses or
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

  // Every app shows its desktop entry icon; the glyph is the fallback when
  // no entry or icon resolves.
  // heuristicLookup is not reactive: right after a shell restart the desktop
  // entry scan has not finished and it returns null, so the glyph fallback
  // stuck until something else rebuilt the item. Reading the application
  // count re-runs the lookup when the scan completes.
  readonly property var entry: DesktopEntries.applications.values.length >= 0
    ? DesktopEntries.heuristicLookup(root.appId) : null
  readonly property string iconPath: root.entry && root.entry.icon !== ""
    ? Quickshell.iconPath(root.entry.icon, true) : ""
  readonly property bool useIcon: root.iconPath !== ""

  signal activated()
  signal closeRequested()
  signal cycled(int direction)

  implicitWidth: Config.bottomBarDp(35)
  implicitHeight: Config.bottomBarDp(26) + Config.bottomBarDp(6) + Config.bottomBarDp(3)

  Image {
    id: appIcon
    visible: root.useIcon
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    width: Config.bottomBarDp(22)
    height: width
    source: root.iconPath
    sourceSize: Qt.size(width * 2, height * 2)
    asynchronous: true
    opacity: root.running ? 1 : 0.55
  }

  Text {
    id: glyph
    visible: !root.useIcon
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
    width: root.focused ? Config.bottomBarDp(12) : Config.bottomBarDp(5)
    height: root.focused ? Config.bottomBarDp(3) : Config.bottomBarDp(5)
    radius: height / 2
    color: root.accent
    opacity: root.running ? (root.focused ? 1 : 0.7) : 0
    Behavior on width {
      enabled: !Config.reducedMotion
      NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on height {
      enabled: !Config.reducedMotion
      NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
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
