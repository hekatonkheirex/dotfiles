import QtQuick
import "../config"

// Forked from bar/PopupDivider.qml (identical apart from import paths). Cross-root
// import is impossible under `qs -p`; see docs/superpowers/plans/2026-08-09-pill-shell-foundation.md.
// Keep in sync until bar/ is retired.
Item {
  id: root

  width: parent ? parent.width : 0
  height: 1

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15)
  }
}
