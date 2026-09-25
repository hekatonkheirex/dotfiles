import QtQuick
import "../../config"

// A restrained specular layer for Liquid Glass surfaces. The compositor owns
// the actual backdrop blur; this gives translucent surfaces a soft light catch
// even when blur is disabled or unavailable. It deliberately avoids a hard
// divider so repeated glass surfaces do not become a collection of hairlines.
Item {
  id: root

  property real radius: 0
  property bool glassEnabled: true

  visible: root.glassEnabled && Config.liquidGlassTheme && !Colors.liquidGlassOpaque
  clip: true

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: "transparent"
    gradient: Gradient {
      GradientStop {
        position: 0.0
        color: Colors.liquidGlassHighlight
      }
      GradientStop {
        position: 0.42
        color: Qt.rgba(1, 1, 1, 0)
      }
      GradientStop {
        position: 1.0
        color: Colors.liquidGlassShade
      }
    }
  }

}
