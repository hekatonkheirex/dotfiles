// Copied to the root of a config copy by scripts/controls-golden.sh (Quickshell
// refuses imports outside the config dir). Renders every themed control state into one PNG and quits. Driven by
// scripts/controls-golden.sh, which fakes $HOME so settings.json picks the
// style under test. Output path comes from $GOLDEN_OUT.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "config"
import "bar"
import "bar/primitives"

ShellRoot {
  FloatingWindow {
    id: win
    implicitWidth: 760
    implicitHeight: 560
    color: Colors.surface

    Item {
      id: stage
      anchors.fill: parent

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
          spacing: 10
          ActionButton { Layout.preferredWidth: 110; Layout.preferredHeight: 48; labelText: "Tonal"; iconLabel: "check"; variant: "tonal" }
          ActionButton { Layout.preferredWidth: 110; Layout.preferredHeight: 48; labelText: "Filled"; iconLabel: "check"; variant: "filled" }
          ActionButton { Layout.preferredWidth: 110; Layout.preferredHeight: 48; labelText: "Text"; iconLabel: "check"; variant: "text" }
          ActionButton { Layout.preferredWidth: 110; Layout.preferredHeight: 48; labelText: "Selected"; iconLabel: "check"; selected: true }
          ActionButton { Layout.preferredWidth: 110; Layout.preferredHeight: 48; labelText: "Focus"; iconLabel: "check"; id: focused }
        }
        RowLayout {
          spacing: 10
          ActionButton { Layout.preferredWidth: 110; Layout.preferredHeight: 48; labelText: "Left"; grouped: true; groupPosition: "start"; selected: true }
          ActionButton { Layout.preferredWidth: 110; Layout.preferredHeight: 48; labelText: "Mid"; grouped: true; groupPosition: "middle" }
          ActionButton { Layout.preferredWidth: 110; Layout.preferredHeight: 48; labelText: "Right"; grouped: true; groupPosition: "end" }
          ActionButton { Layout.preferredWidth: 110; Layout.preferredHeight: 48; labelText: "Off"; iconLabel: "check"; enabled: false }
        }
        RowLayout {
          spacing: 10
          IconButton { iconLabel: "settings" }
          IconButton { iconLabel: "settings"; variant: "filled" }
          IconButton { iconLabel: "settings"; variant: "tonal" }
          IconButton { iconLabel: "settings"; variant: "outlined" }
          IconButton { iconLabel: "settings"; selected: true }
          IconButton { iconLabel: "settings"; enabled: false }
        }
        RowLayout {
          spacing: 16
          SwitchControl { checked: false }
          SwitchControl { checked: true }
          SwitchControl { checked: true; enabled: false }
        }
        SliderControl { Layout.fillWidth: true; value: 0.3 }
        SliderControl { Layout.fillWidth: true; value: 0.8 }
        SliderControl { Layout.fillWidth: true; value: 0.6; muted: true }
        SliderControl { Layout.fillWidth: true; value: 0.0 }
        Item { Layout.fillHeight: true }
      }
    }

    Timer {
      interval: 2500
      running: true
      onTriggered: {
        stage.grabToImage(function(r) {
          r.saveToFile(Quickshell.env("GOLDEN_OUT"))
          Qt.quit()
        })
      }
    }
    Component.onCompleted: focused.forceActiveFocus()
  }
}
