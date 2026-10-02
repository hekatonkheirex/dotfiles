import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../config"
import "primitives"

Item {
  id: systemTrayAreaRoot

  property var parentWindow: null
  property bool horizontal: false
  property bool integrated: false

  property int visibleCount: 0
  readonly property bool flatLiquidChrome: Config.liquidGlassTheme && !Colors.liquidGlassOpaque
  readonly property real preferredLength: visibleCount * (Config.widgetSize)

  Layout.preferredWidth: horizontal ? preferredLength : (Config.widgetSize)
  Layout.preferredHeight: horizontal ? (Config.widgetSize) : preferredLength
  visible: visibleCount > 0


  Rectangle {
    id: traySurface
    anchors {
      fill: parent
      leftMargin: horizontal ? 0 : 6
      rightMargin: horizontal ? 0 : 6
      topMargin: horizontal ? 6 : 0
      bottomMargin: horizontal ? 6 : 0
    }
    radius: Config.borderRadius
    clip: true
    color: systemTrayAreaRoot.integrated
      ? "transparent"
      : (systemTrayAreaRoot.flatLiquidChrome
        ? "transparent"
        : (Config.liquidGlassTheme
          ? Colors.liquidGlassClear
        : (Config.nothingDesign || Config.ghostTheme
          ? Colors.styleSurface
          : Colors.surfaceContainerHigh)))
    border.color: systemTrayAreaRoot.flatLiquidChrome
      ? "transparent"
      : (Config.ghostTheme || Config.liquidGlassTheme
        ? Colors.styleOutline
      : (Config.nothingDesign
        ? "transparent"
        : Qt.rgba(Colors.styleOutlineStrong.r, Colors.styleOutlineStrong.g, Colors.styleOutlineStrong.b, 0.15)))
    border.width: systemTrayAreaRoot.integrated || Config.nothingDesign || systemTrayAreaRoot.flatLiquidChrome
      ? 0
      : Config.themeBorderWidth

    GlassSheen {
      anchors.fill: parent
      radius: parent.radius
      visible: !systemTrayAreaRoot.integrated
      glassEnabled: !systemTrayAreaRoot.flatLiquidChrome
    }
  }

  GridLayout {
    id: trayLayout
    flow: systemTrayAreaRoot.horizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
    anchors.fill: parent
    columnSpacing: 0
    rowSpacing: 0

    Repeater {
      id: trayRepeater
      model: SystemTray.items

      delegate: Item {
        id: trayIconDelegate
        required property SystemTrayItem modelData

        // Filter out blueman and udiskie
        readonly property bool isIconVisible: modelData.id !== "blueman" && modelData.id !== "udiskie"
        visible: isIconVisible

        Layout.preferredWidth: visible ? (Config.widgetSize) : 0
        Layout.preferredHeight: visible ? (Config.widgetSize) : 0
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        width: visible ? (Config.widgetSize) : 0
        height: visible ? (Config.widgetSize) : 0
        activeFocusOnTab: isIconVisible

        Accessible.role: Accessible.Button
        Accessible.name: modelData.title || modelData.id || "System tray item"
        Accessible.description: modelData.hasMenu ? "Open system tray menu" : "Activate system tray item"
        Accessible.focusable: isIconVisible
        Accessible.focused: activeFocus

        Keys.onPressed: function(event) {
          if (isIconVisible && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            modelData.activate()
            event.accepted = true
          }
        }

        property bool counted: false

        function updateCount() {
          var shouldBeCounted = isIconVisible;
          if (shouldBeCounted && !counted) {
            systemTrayAreaRoot.visibleCount++;
            counted = true;
          } else if (!shouldBeCounted && counted) {
            systemTrayAreaRoot.visibleCount--;
            counted = false;
          }
        }

        Component.onCompleted: {
          updateCount()
          if (fcitx) imQuery.running = true
        }
        Component.onDestruction: {
          if (counted) {
            systemTrayAreaRoot.visibleCount--;
            counted = false;
          }
        }

        // Input-method indicators (fcitx5, ibus) ship a 16px white pixmap of
        // the layout code with a dark outline that clashes with the bar. For
        // fcitx5, draw the code as bar text instead, refreshed whenever the
        // item swaps its icon. Any failure falls back to the tinted pixmap.
        readonly property bool tintIcon: /fcitx|ibus/i.test(modelData.id + " " + modelData.title)
        readonly property bool fcitx: /fcitx/i.test(modelData.id)
        property string imName: ""
        readonly property string imLabel: {
          var n = imName.replace(/^keyboard-/, "")
          return n === "us" || n === "gb" ? "en" : n.slice(0, 3)
        }
        readonly property bool showImLabel: fcitx && imLabel !== ""

        Process {
          id: imQuery
          command: ["fcitx5-remote", "-n"]
          stdout: StdioCollector {
            onStreamFinished: trayIconDelegate.imName = text.trim()
          }
        }
        Connections {
          target: trayIconDelegate.modelData
          function onIconChanged() { if (trayIconDelegate.fcitx) imQuery.running = true }
        }

        Text {
          anchors.centerIn: parent
          visible: trayIconDelegate.showImLabel
          text: trayIconDelegate.imLabel
          color: Config.liquidGlassTheme ? Colors.barForeground : Colors.primary
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelMediumSize
          font.weight: Font.Medium
          font.letterSpacing: Config.typeLabelTracking
        }

        readonly property bool isPixmapIcon: modelData.icon.indexOf("image://qspixmap/") === 0

        IconImage {
          id: trayThemeIcon
          anchors.centerIn: parent
          source: modelData.icon
          width: (Config.iconSize + 2)
          height: width
          visible: !isPixmapIcon && !showImLabel
          layer.enabled: trayIconDelegate.tintIcon
          layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: Config.liquidGlassTheme ? Colors.barForeground : Colors.primary
          }
        }

        Image {
          id: trayPixmapIcon
          anchors.centerIn: parent
          source: modelData.icon
          width: (Config.iconSize + 2)
          height: width
          fillMode: Image.PreserveAspectFit
          visible: isPixmapIcon && !showImLabel
          layer.enabled: trayIconDelegate.tintIcon
          layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: Config.liquidGlassTheme ? Colors.barForeground : Colors.primary
          }
        }

        Rectangle {
          anchors.fill: parent
          radius: Config.shapeMedium
          color: "transparent"
          border.width: trayIconDelegate.activeFocus ? Config.themeFocusBorderWidth : 0
          border.color: Config.nothingDesign || Config.ghostTheme || Config.liquidGlassTheme
            ? Colors.styleOutline
            : Colors.primary
        }

        QsMenuAnchor {
          id: menuAnchor
          menu: modelData.menu
          anchor.window: parentWindow
          anchor.item: trayIconDelegate
          anchor.edges: systemTrayAreaRoot.horizontal ? Edges.Bottom : Edges.Right
          anchor.gravity: systemTrayAreaRoot.horizontal ? Edges.Bottom : Edges.Right
        }

        MouseArea {
          id: trayMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton && modelData.hasMenu) {
              menuAnchor.open()
            } else if (mouse.button === Qt.MiddleButton) {
              modelData.secondaryActivate()
            } else {
              modelData.activate()
            }
          }
        }
      }
    }
  }
}
