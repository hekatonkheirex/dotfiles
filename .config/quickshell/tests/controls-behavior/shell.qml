// Behaviour checks for the single Elena control implementation, run by
// scripts/controls-behavior.sh in a config-copy root. Prints one
// "PASS|FAIL <name>" line per check, then "DONE n fail".
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
    implicitHeight: 650
    color: Colors.surface

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12
      ActionButton { id: action; labelText: "Go"; Layout.preferredWidth: 110; Layout.preferredHeight: 48; accessibleName: "Go button" }
      ActionButton { id: actionOff; labelText: "Off"; enabled: false; Layout.preferredWidth: 110; Layout.preferredHeight: 48 }
      IconButton { id: icon; iconLabel: "settings"; accessibleName: "Icon button"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
      IconButton { id: tonalIcon; iconLabel: "settings"; variant: "tonal"; Layout.preferredWidth: 32; Layout.preferredHeight: 32 }
      SwitchControl { id: sw; accessibleName: "Test switch"; Layout.preferredWidth: 52; Layout.preferredHeight: 32 }
      SwitchControl { id: swOff; enabled: false; Layout.preferredWidth: 52; Layout.preferredHeight: 32 }
      RowLayout {
        Layout.fillWidth: true
        SliderControl { id: slider; Layout.fillWidth: true; Layout.preferredHeight: 40; value: 0.5; accessibleName: "Test slider" }
        Text {
          id: sliderSuffix
          text: "50%"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelMediumSize
        }
      }
      ListItem {
        id: switchRow
        Layout.fillWidth: true
        title: "Toggle from label"
        toggleControl: rowSwitch
        contextMenuEnabled: true
        onContextMenuRequested: win.rowContexts++
        SwitchControl {
          id: rowSwitch
          onToggled: {
            checked = !checked
            win.rowActivations++
          }
        }
      }
    }

    property int actions: 0
    property int clicks: 0
    property int toggles: 0
    property int togglesOff: 0
    property int rowActivations: 0
    property int rowContexts: 0
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
        win.check("slider: leaves its percentage label unobscured",
          slider.x + slider.width <= sliderSuffix.x)
        action.forceActiveFocus(); keyClick(Qt.Key_Space)
        win.check("action: space activates", win.actions === 1)
        keyClick(Qt.Key_Return)
        win.check("action: return activates", win.actions === 2)
        mouseClick(action)
        win.check("action: mouse click activates", win.actions === 3)
        mouseClick(actionOff)
        win.check("action: disabled ignores click", win.actions === 3)
        mouseMove(win.contentItem, win.width - 2, win.height - 2)
        wait(300)
        mouseMove(tonalIcon, tonalIcon.width / 2, tonalIcon.height / 2)
        wait(300)
        var image = grabImage(win.contentItem)
        var sample = tonalIcon.mapToItem(win.contentItem, tonalIcon.width / 2, tonalIcon.height / 2 - 10)
        var hovered = image.pixel(sample.x, sample.y)
        var expectedHover = Qt.tint(Colors.secondaryContainer, Colors.hoverOverlay)
        win.check("tonal icon: hover preserves container tone",
          Math.abs(hovered.r - expectedHover.r) < 0.02
            && Math.abs(hovered.g - expectedHover.g) < 0.02
            && Math.abs(hovered.b - expectedHover.b) < 0.02)
        mouseMove(win.contentItem, win.width - 2, win.height - 2)
        tonalIcon.selected = true
        // Selected paints a white round behind the glyph; sample the container
        // left of it (round radius is 0.72 * 32 / 2 = 11.5, offset is 14).
        var selSample = tonalIcon.mapToItem(win.contentItem, tonalIcon.width / 2 - 14, tonalIcon.height / 2)
        var selected = grabImage(win.contentItem).pixel(selSample.x, selSample.y)
        var selectedDeadline = Date.now() + 2000
        // Assert the settled state, not a frame-time-dependent spring midpoint.
        while (Date.now() < selectedDeadline
            && (Math.abs(selected.r - Colors.primary.r) >= 0.02
              || Math.abs(selected.g - Colors.primary.g) >= 0.02
              || Math.abs(selected.b - Colors.primary.b) >= 0.02)) {
          wait(16)
          selected = grabImage(win.contentItem).pixel(selSample.x, selSample.y)
        }
        win.check("selected icon: idle is not pressed",
          Math.abs(selected.r - Colors.primary.r) < 0.02
            && Math.abs(selected.g - Colors.primary.g) < 0.02
            && Math.abs(selected.b - Colors.primary.b) < 0.02)
        // Interrupt an in-flight color effect: reduced motion must snap it.
        tonalIcon.selected = false
        Config.reducedMotion = true
        waitForRendering(tonalIcon)
        var reduced = grabImage(win.contentItem).pixel(sample.x, sample.y)
        win.check("reduced motion: interrupted color settles immediately",
          Math.abs(reduced.r - Colors.secondaryContainer.r) < 0.02
            && Math.abs(reduced.g - Colors.secondaryContainer.g) < 0.02
            && Math.abs(reduced.b - Colors.secondaryContainer.b) < 0.02)
        Config.reducedMotion = false
        win.check("icon: minimum input target", icon.width >= 48 && icon.height >= 48)
        var beforeEdgeClick = win.clicks
        mouseClick(icon, icon.width / 2, 46)
        win.check("icon: click below compact visual activates", win.clicks === beforeEdgeClick + 1)
        win.clicks = 0
        win.check("switch: minimum input target", sw.width >= 48 && sw.height >= 48)

        // A click focuses the implementation item inside the facade, so the
        // key checks follow a click.
        mouseClick(icon)
        win.check("icon: mouse click", win.clicks === 1)
        icon.forceActiveFocus(); keyClick(Qt.Key_Space)
        win.check("icon: space clicks", win.clicks === 2)

        mouseClick(sw)
        win.check("switch: mouse toggles", win.toggles === 1)
        sw.forceActiveFocus(); keyClick(Qt.Key_Space)
        win.check("switch: space toggles", win.toggles === 2)
        keyClick(Qt.Key_Return)
        win.check("switch: return toggles", win.toggles === 3)
        mouseClick(swOff)
        win.inner(swOff).forceActiveFocus(); keyClick(Qt.Key_Space)
        win.check("switch: disabled ignores input", win.togglesOff === 0)

        mouseClick(switchRow, 24, switchRow.height / 2)
        win.check("switch row: label click toggles once", rowSwitch.checked && win.rowActivations === 1)
        switchRow.forceActiveFocus(); keyClick(Qt.Key_Space)
        win.check("switch row: space toggles once", !rowSwitch.checked && win.rowActivations === 2)
        keyClick(Qt.Key_Return)
        win.check("switch row: return toggles once", rowSwitch.checked && win.rowActivations === 3)
        mouseClick(rowSwitch)
        win.check("switch row: direct switch toggles once", !rowSwitch.checked && win.rowActivations === 4)
        mouseClick(switchRow, 24, switchRow.height / 2, Qt.RightButton)
        win.check("context menu: secondary click never activates the row",
          win.rowContexts === 1 && !rowSwitch.checked && win.rowActivations === 4)
        rowSwitch.enabled = false
        mouseClick(switchRow, 24, switchRow.height / 2)
        switchRow.forceActiveFocus(); keyClick(Qt.Key_Space)
        win.check("switch row: disabled control ignores row input", !rowSwitch.checked && win.rowActivations === 4)

        mouseClick(slider, slider.width * 0.5, slider.height / 2)
        win.sliderValue = -1; win.finished = 0
        sw.forceActiveFocus(); keyClick(Qt.Key_Tab); keyClick(Qt.Key_Right)
        win.check("slider: right raises value", Math.abs(win.sliderValue - 0.55) < 0.001)
        win.check("slider: key release finishes", win.finished >= 1)
        keyClick(Qt.Key_Home)
        win.check("slider: home -> 0", win.sliderValue === 0)
        keyClick(Qt.Key_End)
        win.check("slider: end -> 1", win.sliderValue === 1)
        keyClick(Qt.Key_PageDown)
        win.check("slider: page down lowers value", win.sliderValue < 1)

        var beforeEdgeClick = win.clicks
        mouseClick(icon, icon.width / 2, icon.height - 1)
        win.check("hit target: entire 48px target is interactive",
          icon.width === Config.controlHitSize && win.clicks === beforeEdgeClick + 1)

        icon.tooltipText = "Tooltip visibility check"
        mouseMove(icon, icon.width / 2, icon.height / 2)
        wait(700)
        var iconTip = null
        var iconResources = win.inner(icon).resources
        for (var resourceIndex = 0; resourceIndex < iconResources.length; resourceIndex++) {
          if (iconResources[resourceIndex].text === icon.tooltipText) {
            iconTip = iconResources[resourceIndex]
            break
          }
        }
        win.check("tooltip: hovered control shows its hint", iconTip !== null && iconTip.visible)
        icon.visible = false
        wait(250)
        win.check("tooltip: hidden control removes its hint", iconTip !== null && !iconTip.visible)
        icon.visible = true

        console.log("DONE " + win.failures + " fail")
        quitTimer.start()
      }
    }
    }
  }
}
