import QtQuick
import QtQuick.Effects
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

  // Specular rim: a 1px white edge that is bright at the top and fades out
  // toward the bottom, as on Apple's Liquid Glass. Masked ring, no shader.
  Rectangle {
    id: rimFade
    anchors.fill: parent
    visible: false
    layer.enabled: true
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#ffffffff" }
      GradientStop { position: 0.5; color: "#55ffffff" }
      GradientStop { position: 1.0; color: "#22ffffff" }
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: "transparent"
    border.width: 1
    border.color: Colors.liquidGlassRim
    layer.enabled: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: rimFade
    }
  }

}
