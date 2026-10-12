import QtQuick
import "../../config"

// Outlined capsule drawn behind a group of bar widgets (Pill form).
Rectangle {
  property real inset: 3

  y: inset
  height: parent.height - inset * 2
  radius: height / 2
  color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.55)
  border.width: 1
  border.color: Colors.styleOutline
}
