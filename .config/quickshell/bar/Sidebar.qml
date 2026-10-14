import QtQuick
import Quickshell
import "../config"
import "sidebar"

// Elena's sidebar: a left and bottom anchored overlay (no reserved space) above
// the bottom bar. It joins the bar's single-open-popup model through shell.qml.
// The pages bind the services' sidebarActive flags themselves.
PopupBase {
  id: root

  surfaceWidth: Config.dp(300)
  // Pages dp(554) plus the indicator section dp(106), capped to the free height
  // between the top strip and the bottom bar.
  surfaceHeight: Math.min(Config.dp(554) + Config.dp(106),
    root.screenH - Config.bottomBarHeight - Config.dp(7) - Config.barWidth)

  readonly property int currentPage: content.currentPage
  readonly property int pageCount: content.pageCount
  function showPage(n) {
    content.currentPage = Math.max(0, Math.min(root.pageCount - 1, Math.floor(n)))
  }

  anchors.top: false
  anchors.bottom: true
  margins.left: 0
  margins.top: 0
  margins.bottom: Config.bottomBarHeight + Config.dp(7)
  surfaceColor: Colors.surface

  // Square left corners (the panel touches the screen edge), no outline.
  Binding { target: root.bg; property: "topLeftRadius"; value: 0 }
  Binding { target: root.bg; property: "bottomLeftRadius"; value: 0 }
  Binding { target: root.bg; property: "topRightRadius"; value: Config.dp(20) }
  Binding { target: root.bg; property: "bottomRightRadius"; value: Config.dp(20) }
  Binding { target: root.bg; property: "border.width"; value: 0 }

  SidebarContent {
    id: content
    anchors.fill: parent
    active: root.visible
    onEscaped: root.dismissed()
  }

  // Middle click anywhere hides it (her eventbox onmiddleclick).
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.MiddleButton
    onClicked: root.dismissed()
  }
}
