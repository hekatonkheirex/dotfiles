import QtQuick
import Quickshell
import "../config"
import "settingsbar"

// Settings as a right-edge sidebar: right and bottom anchored overlay above
// the bottom bar, mirror of the left sidebar. One Settings page at a time;
// joins the bar's single-open-popup model through shell.qml (route "settings").
PopupBase {
  id: root

  surfaceWidth: Config.dp(300)
  surfaceHeight: Math.min(Config.dp(700),
    root.screenH - Config.bottomBarHeight - Config.dp(7) - Config.barWidth)
  entryOriginX: root.surfaceWidth

  signal resetAppearance()
  readonly property int currentPage: content.currentPage
  readonly property int pageCount: content.pageCount
  function showPage(n) { content.showPage(n) }

  anchors.left: false
  anchors.right: true
  anchors.top: false
  anchors.bottom: true
  margins.left: 0
  margins.top: 0
  margins.right: 0
  margins.bottom: Config.bottomBarHeight + Config.dp(7)
  surfaceColor: Colors.surface

  // Square right corners (the panel touches the screen edge), no outline.
  Binding { target: root.bg; property: "topRightRadius"; value: 0 }
  Binding { target: root.bg; property: "bottomRightRadius"; value: 0 }
  Binding { target: root.bg; property: "topLeftRadius"; value: Config.dp(20) }
  Binding { target: root.bg; property: "bottomLeftRadius"; value: Config.dp(20) }
  Binding { target: root.bg; property: "border.width"; value: 0 }

  SettingsSidebarContent {
    id: content
    anchors.fill: parent
    active: root.visible
    onEscaped: root.dismissed()
    onResetAppearance: root.resetAppearance()
  }

  // Middle click on the surface hides it, as on the left sidebar.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.MiddleButton
    onClicked: root.dismissed()
  }
}
