// Behaviour checks for the themed controls, run once per style by
// scripts/controls-behavior.sh (copied to a config-copy root like the golden
// harness). Prints one "PASS|FAIL <name>" line per check, then "DONE n fail".
import QtQuick
import QtQuick.Layouts
import QtTest
import Quickshell
import "config"
import "bar"
import "bar/primitives"

ShellRoot {
  FloatingWindow {
    id: win
    implicitWidth: 400
    implicitHeight: 320
    color: Colors.surface

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12
      ActionButton { id: action; labelText: "Go"; Layout.preferredWidth: 110; Layout.preferredHeight: 48; accessibleName: "Go button" }
      ActionButton { id: actionOff; labelText: "Off"; enabled: false; Layout.preferredWidth: 110; Layout.preferredHeight: 48 }
      IconButton { id: icon; iconLabel: "settings"; accessibleName: "Icon button"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
      SwitchControl { id: sw; accessibleName: "Test switch"; Layout.preferredWidth: 52; Layout.preferredHeight: 32 }
      SwitchControl { id: swOff; enabled: false; Layout.preferredWidth: 52; Layout.preferredHeight: 32 }
      SliderControl { id: slider; Layout.fillWidth: true; Layout.preferredHeight: 40; value: 0.5; accessibleName: "Test slider" }
    }

    property int actions: 0
    property int clicks: 0
    property int toggles: 0
    property int togglesOff: 0
    property real sliderValue: -1
    property int finished: 0
    property int failures: 0

    Connections { target: action; function onActivated() { win.actions++ } }
    Connections { target: icon; function onClicked() { win.clicks++ } }
    Connections { target: sw; function onToggled() { win.toggles++ } }
    Connections { target: swOff; function onToggled() { win.togglesOff++ } }
    Connections {
      target: slider
      function onChanged(v) { win.sliderValue = v }
      function onInteractionFinished() { win.finished++ }
    }

    // The facades load their implementation through a Loader; keys go to it.
    function inner(facade) {
      for (var i = 0; i < facade.children.length; i++)
        if (facade.children[i].item) return facade.children[i].item
      return facade
    }

    function check(name, ok) {
      if (!ok) failures++
      console.log((ok ? "PASS " : "FAIL ") + name)
    }

    Timer { id: quitTimer; interval: 100; onTriggered: Qt.quit() }

    Item {
    TestCase {
      id: tc
      name: "controls"
      when: true
      function test_run() {
        wait(800)
        win.inner(action).forceActiveFocus(); keyClick(Qt.Key_Space)
        win.check("action: space activates", win.actions === 1)
        keyClick(Qt.Key_Return)
        win.check("action: return activates", win.actions === 2)
        mouseClick(action)
        win.check("action: mouse click activates", win.actions === 3)
        mouseClick(actionOff)
        win.check("action: disabled ignores click", win.actions === 3)
        win.check("action: accessible name", action.accessibleName === "Go button")

        // A click focuses the implementation item inside the facade, so the
        // key checks follow a click.
        mouseClick(icon)
        win.check("icon: mouse click", win.clicks === 1)
        win.inner(icon).forceActiveFocus(); keyClick(Qt.Key_Space)
        win.check("icon: space clicks", win.clicks === 2)

        mouseClick(sw)
        win.check("switch: mouse toggles", win.toggles === 1)
        win.inner(sw).forceActiveFocus(); keyClick(Qt.Key_Space)
        win.check("switch: space toggles", win.toggles === 2)
        keyClick(Qt.Key_Return)
        win.check("switch: return toggles", win.toggles === 3)
        mouseClick(swOff)
        win.inner(swOff).forceActiveFocus(); keyClick(Qt.Key_Space)
        win.check("switch: disabled ignores input", win.togglesOff === 0)

        mouseClick(slider, slider.width * 0.5, slider.height / 2)
        win.sliderValue = -1; win.finished = 0
        win.inner(slider).forceActiveFocus(); keyClick(Qt.Key_Right)
        win.check("slider: right raises value", Math.abs(win.sliderValue - 0.55) < 0.001)
        win.check("slider: key release finishes", win.finished >= 1)
        keyClick(Qt.Key_Home)
        win.check("slider: home -> 0", win.sliderValue === 0)
        keyClick(Qt.Key_End)
        win.check("slider: end -> 1", win.sliderValue === 1)
        keyClick(Qt.Key_PageDown)
        win.check("slider: page down lowers value", win.sliderValue < 1)

        console.log("DONE " + win.failures + " fail")
        quitTimer.start()
      }
    }
    }
  }
}
