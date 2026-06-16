import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  property bool horizontal: false

  signal clicked(var mouse)

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: config ? config.widgetSize : 50

  Rectangle {
    id: bgOverlay
    anchors {
      fill: parent
      leftMargin: root.horizontal ? 0 : 6
      rightMargin: root.horizontal ? 0 : 6
      topMargin: root.horizontal ? 6 : 0
      bottomMargin: root.horizontal ? 6 : 0
    }
    radius: root.horizontal ? height / 2 : width / 2
    clip: true
    color: colors_ ? (mouseArea.containsMouse ? colors_.surfaceContainerHigh : "transparent") : "transparent"
    border.color: colors_ ? (mouseArea.containsMouse ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : "transparent") : "transparent"
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: config ? config.animationDuration : 150 }
    }
  }

  Text {
    anchors.centerIn: parent
    text: "wallpaper"
    color: {
      if (mouseArea.containsMouse) return colors_ ? colors_.primary : "#D0BCFF"
      return colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
    }
    font.family: config ? config.iconFont : "Material Symbols Outlined"
    font.pixelSize: config ? config.iconSize : 22
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      root.clicked(mouse)
    }
  }
}
