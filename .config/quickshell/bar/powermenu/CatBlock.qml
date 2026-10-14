import QtQuick
import QtQuick.Shapes
import "../../config"

// Stroke positions traced from the user's single-cat reference (48 x 52).
// Fixed geometry avoids mixed-script font fallback and changes only the eyes.
Item {
  id: root
  readonly property bool happy: hover.containsMouse
  implicitWidth: Config.dp(64)
  implicitHeight: implicitWidth * 52 / 48

  Shape {
    objectName: "catBody"
    width: 48
    height: 52
    preferredRendererType: Shape.CurveRenderer
    transform: Scale { xScale: root.width / 48; yScale: root.height / 52 }
    ShapePath {
      strokeColor: Colors.fgSurface
      strokeWidth: 1.3
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      fillColor: "transparent"
      PathSvg {
        path: "M31.5 6.3 L35.5 2.6 L41 7.8 "
          + "M15.4 15.8 Q11.3 18.9 12.4 21.4 Q14 21.7 16.1 20.7 "
          + "M41.2 13.8 C43.5 16.4 44 20.4 42 23.3 "
          + "M18 27.5 L14.4 34.5 M37 27.5 V36 "
          + "M2.5 38.5 C3.5 42.8 6 46 10 47 "
          + "M14 38.7 C11.8 41 11.4 45 13.5 48 "
          + "M16 48 H18 M20 46.5 L19 49 "
          + "M31 38.5 V45 C31 47.5 26 48.8 24.5 46 "
          + "M42 38.5 V45 C42 47.5 36.7 48.8 35.5 46"
      }
    }
  }
  Shape {
    objectName: "catFace"
    width: 48
    height: 52
    preferredRendererType: Shape.CurveRenderer
    transform: Scale { xScale: root.width / 48; yScale: root.height / 52 }
    ShapePath {
      strokeColor: Colors.fgSurface
      strokeWidth: 1.3
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      fillColor: "transparent"
      PathSvg {
        path: root.happy
          ? "M24.6 16.7 L28 18.4 L24.6 20.1 M38.6 16.7 L35.2 18.4 L38.6 20.1"
          : "M24.8 18.4 H28 M35.2 18.4 H38.4"
      }
    }
  }

  MouseArea {
    id: hover
    objectName: "catHover"
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
  }
}
