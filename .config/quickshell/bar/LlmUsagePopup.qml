import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../config"

PopupBase {
  id: root
  surfaceWidth: Math.min(720, root.screen ? root.screen.width - Config.spacingPage : 720)
  surfaceHeight: Math.min(contentColumn.implicitHeight + Config.popupPadding * 2,
    root.screen ? Math.max(120, root.screen.height - Config.barWidth * 2 - Config.spacingPage) : 700)

  Binding {
    target: CodexUsageService
    property: "popupActive"
    value: root.visible
  }
  Binding {
    target: ClaudeUsageService
    property: "popupActive"
    value: root.visible
  }

  Flickable {
    id: viewport
    anchors.fill: parent
    anchors.margins: Config.popupPadding
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar {}

    ColumnLayout {
      id: contentColumn
      width: viewport.width
      spacing: Config.spacingLarge

      Text {
        text: "LLM usage"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeHeadlineSmallSize
        font.weight: Config.typeStrongWeight
      }

      GridLayout {
        Layout.fillWidth: true
        columns: root.surfaceWidth >= 640 ? 2 : 1
        uniformCellWidths: true
        columnSpacing: Config.spacingLarge
        rowSpacing: Config.spacingLarge

        LlmUsageSection {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignTop
          service: CodexUsageService
          providerName: "Codex"
          resetsTitle: "Full resets available"
          resetDescription: "Weekly + five-hour reset"
        }

        LlmUsageSection {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignTop
          service: ClaudeUsageService
          providerName: "Claude"
        }
      }
    }
  }
}
