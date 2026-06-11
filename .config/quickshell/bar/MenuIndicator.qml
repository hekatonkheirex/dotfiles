import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  property bool active: false

  signal clicked(var mouse)

  Layout.preferredWidth: config ? config.widgetSize : 50
  Layout.preferredHeight: config ? config.widgetSize : 50

  Rectangle {
    id: bgOverlay
    anchors {
      fill: parent
      leftMargin: 6
      rightMargin: 6
    }
    radius: width / 2
    clip: true
    color: {
      if (root.active) return colors_ ? colors_.primary : "#D0BCFF"
      if (mouseArea.containsMouse) return colors_ ? colors_.surfaceContainerHighest : "#36343B"
      return colors_ ? colors_.surfaceContainerHigh : "#2B2930"
    }
    border.color: {
      if (root.active) return "transparent"
      return colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.15) : Qt.rgba(147/255, 143/255, 153/255, 0.15)
    }
    border.width: 1

    Behavior on color {
      ColorAnimation { duration: config ? config.animationDuration : 150 }
    }
  }

  Text {
    anchors.centerIn: parent
    text: "settings"
    color: {
      if (root.active) return colors_ ? colors_.fgPrimary : "#0F3C2C"
      return colors_ ? colors_.primary : "#D0BCFF"
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
