// bar/settings/DisplayInputTab.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: displayInputTab
  property QtObject root: null
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  anchors.fill: parent
  visible: root.currentTab === 4
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + displayInputTab.neoShadowAllowance
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  property string statusMessage: ""

  function onFieldFailed(message) {
    displayInputTab.statusMessage = message
  }

  Process {
    id: listOutputsProc
    command: ["niri", "msg", "-j", "outputs"]
    running: displayInputTab.visible
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          var names = Object.keys(parsed)
          outputsRepeater.model = names
        } catch (e) {
          outputsRepeater.model = ["eDP-1"]  // fallback so the UI still renders something
        }
      }
    }
  }

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, displayInputTab.width - displayInputTab.neoShadowAllowance)
    spacing: Config.spacingLarge + displayInputTab.neoShadowAllowance

    Text {
      text: "Outputs"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.textTitleSize
      font.weight: Font.Bold
    }

    Repeater {
      id: outputsRepeater
      model: []

      delegate: StyledSurface {
        required property string modelData
        Layout.fillWidth: true
        Layout.preferredHeight: outputColumn.implicitHeight + 24
        radius: Config.shapeLarge
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: outputColumn
          anchors.fill: parent
          anchors.margins: 12
          spacing: Config.spacingSmall

          Text {
            text: modelData
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textBodyLargeSize
            font.weight: Font.Medium
          }

          RemoteTextRow {
            Layout.fillWidth: true
            cliFile: "outputs"; cliField: "mode"; extraArgs: [modelData]
            label: "Mode"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
          RemoteSliderRow {
            Layout.fillWidth: true
            cliFile: "outputs"; cliField: "scale"; extraArgs: [modelData]
            label: "Scale"; min: 0.5; max: 3.0; decimals: 2
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
          RemoteTextRow {
            Layout.fillWidth: true
            cliFile: "outputs"; cliField: "transform"; extraArgs: [modelData]
            label: "Transform (normal/90/180/270)"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
        }
      }
    }

    StyledSurface {
      Layout.fillWidth: true
      Layout.preferredHeight: inputColumn.implicitHeight + 24
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: inputColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: Config.spacingSmall

        Text {
          text: "Touchpad"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
        }

        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "touchpad-tap"
          leadingIcon: "touch_app"; title: "Tap to click"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "touchpad-natural-scroll"
          leadingIcon: "swap_vert"; title: "Natural scroll"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
        RemoteTextRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "touchpad-scroll-method"
          label: "Scroll method (two-finger/edge)"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }

        Text {
          text: "Mouse"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          Layout.topMargin: 8
        }

        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "mouse-natural-scroll"
          leadingIcon: "mouse"; title: "Natural scroll"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "mouse-accel-speed"
          label: "Accel speed"; min: -1.0; max: 1.0; decimals: 2
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }

        Text {
          text: "Trackpoint"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          Layout.topMargin: 8
        }

        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "trackpoint-natural-scroll"
          leadingIcon: "mouse"; title: "Natural scroll"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "trackpoint-accel-speed"
          label: "Accel speed"; min: -1.0; max: 1.0; decimals: 2
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }

        // ponytail: deliberately scoped out of this pass — mouse-accel-profile,
        // the dnd-edge-* trigger-width/height/delay-ms fields, and all four
        // hot-corners are left for a fast-follow once this Remote*Row pattern
        // is confirmed working end-to-end. Same mechanical shape, add rows
        // using the same three components when that follow-up lands.
        Text {
          text: "Edge gestures"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          Layout.topMargin: 8
        }

        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "view-scroll-max-speed"
          label: "View-scroll max speed"; min: 200; max: 4000; unit: "px/s"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "workspace-switch-max-speed"
          label: "Workspace-switch max speed"; min: 200; max: 4000; unit: "px/s"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
      }
    }

    Text {
      visible: displayInputTab.statusMessage !== ""
      Layout.fillWidth: true
      text: displayInputTab.statusMessage
      color: Colors.destructive
      font.family: Config.fontFamily
      font.pixelSize: Config.fontPixelSize
      wrapMode: Text.WordWrap
    }
  }
}
