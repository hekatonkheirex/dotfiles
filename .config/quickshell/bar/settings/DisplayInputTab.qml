// bar/settings/DisplayInputTab.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: displayInputTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  readonly property var transformOptions: [
    { value: "normal", label: "Normal" },
    { value: "90", label: "90°" },
    { value: "180", label: "180°" },
    { value: "270", label: "270°" },
    { value: "flipped", label: "Flipped" },
    { value: "flipped-90", label: "Flipped 90°" },
    { value: "flipped-180", label: "Flipped 180°" },
    { value: "flipped-270", label: "Flipped 270°" }
  ]
  readonly property var scrollMethodOptions: [
    { value: "no-scroll", label: "No scroll" },
    { value: "two-finger", label: "Two-finger" },
    { value: "edge", label: "Edge" },
    { value: "on-button-down", label: "On button down" }
  ]
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
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: displayInputTab }

  property string statusMessage: ""
  property bool outputsLoaded: false

  function onFieldFailed(message) {
    displayInputTab.statusMessage = message
  }

  onVisibleChanged: {
    if (!visible) displayInputTab.statusMessage = ""
  }

  Process {
    id: listOutputsProc
    command: ["niri", "msg", "-j", "outputs"]
    running: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          var names = Object.keys(parsed)
          names.sort()
          outputsRepeater.model = names
          displayInputTab.outputsLoaded = true
        } catch (e) {
          outputsRepeater.model = []
          displayInputTab.outputsLoaded = true
        }
      }
    }
  }

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, displayInputTab.width - displayInputTab.neoShadowAllowance - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge + displayInputTab.neoShadowAllowance

    SettingsPageHeader {
      pageTitle: "Display & Input"
      subtitle: "Tune displays, pointer behaviour, and edge gestures from one place."
    }

    StyledSurface {
      id: outputsSurface
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: outputsColumn.implicitHeight + Config.spacingMedium * 2
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: outputsColumn
        anchors.fill: parent
        anchors.margins: Config.spacingMedium
        spacing: Config.spacingSmall

        Text {
          text: "OUTPUTS"
          color: Colors.fgSurfaceVariant
          font.family: Config.monoFontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          font.letterSpacing: 0.8
        }

        Repeater {
          id: outputsRepeater
          Layout.fillWidth: true
          model: []

          delegate: ColumnLayout {
            required property string modelData
            Layout.fillWidth: true
            spacing: Config.spacingSmall

            RowLayout {
              Layout.fillWidth: true
              spacing: Config.spacingSmall

              Text {
                text: "monitor"
                color: Colors.styleAccent
                font.family: Config.iconFont
                font.pixelSize: Config.iconSize + 4
                font.variableAxes: Config.iconVariableAxes(0, Config.iconSize + 4)
                Layout.alignment: Qt.AlignVCenter
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                  Layout.fillWidth: true
                  text: modelData
                  color: Colors.fgSurface
                  font.family: Config.fontFamily
                  font.pixelSize: Config.textBodyLargeSize
                  font.weight: Config.themeFontWeight
                  elide: Text.ElideRight
                }

                Text {
                  Layout.fillWidth: true
                  text: "Output configuration"
                  color: Colors.fgSurfaceVariant
                  font.family: Config.fontFamily
                  font.pixelSize: Config.textCaptionSize
                }
              }
            }

            RemoteTextRow {
              Layout.fillWidth: true
              live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
              cliFile: "outputs"; cliField: "mode"; extraArgs: [modelData]
              label: "Mode"
              leadingIcon: "aspect_ratio"
              onWriteFailed: displayInputTab.onFieldFailed(message)
            }
            RemoteSliderRow {
              Layout.fillWidth: true
              live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
              cliFile: "outputs"; cliField: "scale"; extraArgs: [modelData]
              label: "Scale"; min: 0.5; max: 3.0; decimals: 2
              leadingIcon: "zoom_in"
              onWriteFailed: displayInputTab.onFieldFailed(message)
            }
            RemoteChoiceRow {
              Layout.fillWidth: true
              live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
              cliFile: "outputs"; cliField: "transform"; extraArgs: [modelData]
              label: "Transform"
              leadingIcon: "screen_rotation"
              optionColumns: displayInputTab.compactLayout
                ? 1
                : 3
              options: displayInputTab.transformOptions
              onWriteFailed: displayInputTab.onFieldFailed(message)
            }
          }
        }

        Text {
          visible: !displayInputTab.outputsLoaded
          Layout.fillWidth: true
          text: "Detecting displays…"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textBodySize
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          visible: displayInputTab.outputsLoaded && outputsRepeater.count === 0
          Layout.fillWidth: true
          text: "No displays detected"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textBodySize
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }

    StyledSurface {
      variant: "filled"
      Layout.fillWidth: true
      Layout.preferredHeight: inputColumn.implicitHeight + Config.spacingMedium * 2
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: inputColumn
        anchors.fill: parent
        anchors.margins: Config.spacingMedium
        spacing: Config.spacingMedium

        Text {
          text: "INPUT"
          color: Colors.fgSurfaceVariant
          font.family: Config.monoFontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          font.letterSpacing: 0.8
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          Text {
            text: "Touchpad"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textTitleSize
            font.weight: Config.themeFontWeight
          }

          RemoteSwitchRow {
            Layout.fillWidth: true
            live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
            cliFile: "inputs"; cliField: "touchpad-tap"
            leadingIcon: "touch_app"; title: "Tap to click"
            subtitle: "Use a light tap instead of pressing the pad"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
          RemoteSwitchRow {
            Layout.fillWidth: true
            live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
            cliFile: "inputs"; cliField: "touchpad-natural-scroll"
            leadingIcon: "swap_vert"; title: "Natural scrolling"
            subtitle: "Scroll content in the direction your fingers move"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
          RemoteChoiceRow {
            Layout.fillWidth: true
            live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
            cliFile: "inputs"; cliField: "touchpad-scroll-method"
            label: "Scroll method"
            leadingIcon: "swipe"
            optionColumns: displayInputTab.compactLayout ? 1 : 2
            options: displayInputTab.scrollMethodOptions
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          Text {
            text: "Mouse"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textTitleSize
            font.weight: Config.themeFontWeight
          }

          RemoteSwitchRow {
            Layout.fillWidth: true
            live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
            cliFile: "inputs"; cliField: "mouse-natural-scroll"
            leadingIcon: "mouse"; title: "Natural scrolling"
            subtitle: "Reverse the mouse wheel direction"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
          RemoteSliderRow {
            Layout.fillWidth: true
            live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
            cliFile: "inputs"; cliField: "mouse-accel-speed"
            label: "Accel speed"; min: -1.0; max: 1.0; decimals: 2
            leadingIcon: "speed"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          Text {
            text: "Trackpoint"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textTitleSize
            font.weight: Config.themeFontWeight
          }

          RemoteSwitchRow {
            Layout.fillWidth: true
            live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
            cliFile: "inputs"; cliField: "trackpoint-natural-scroll"
            leadingIcon: "mouse"; title: "Natural scrolling"
            subtitle: "Reverse the trackpoint scroll direction"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
          RemoteSliderRow {
            Layout.fillWidth: true
            live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
            cliFile: "inputs"; cliField: "trackpoint-accel-speed"
            label: "Accel speed"; min: -1.0; max: 1.0; decimals: 2
            leadingIcon: "speed"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
        }

        // ponytail: deliberately scoped out of this pass — mouse-accel-profile,
        // the dnd-edge-* trigger-width/height/delay-ms fields, and all four
        // hot-corners are left for a fast-follow once this Remote*Row pattern
        // is confirmed working end-to-end. Same mechanical shape, add rows
        // using the same three components when that follow-up lands.
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Config.spacingSmall

          Text {
            text: "Edge gestures"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textTitleSize
            font.weight: Config.themeFontWeight
          }

          RemoteSliderRow {
            Layout.fillWidth: true
            live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
            cliFile: "inputs"; cliField: "view-scroll-max-speed"
            label: "View-scroll max speed"; min: 200; max: 4000; unit: "px/s"
            leadingIcon: "swipe_vertical"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
          RemoteSliderRow {
            Layout.fillWidth: true
            live: displayInputTab.visible && displayInputTab.root && displayInputTab.root.visible
            cliFile: "inputs"; cliField: "workspace-switch-max-speed"
            label: "Workspace-switch max speed"; min: 200; max: 4000; unit: "px/s"
            leadingIcon: "workspaces"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
        }
      }
    }

    Rectangle {
      visible: displayInputTab.statusMessage !== ""
      Layout.fillWidth: true
      implicitHeight: statusText.implicitHeight + Config.spacingMedium * 2
      radius: Config.shapeMedium
      color: Colors.errorContainer
      border.width: Config.themeBorderWidth
      border.color: Colors.error

      RowLayout {
        anchors.fill: parent
        anchors.margins: Config.spacingSmall
        spacing: Config.spacingSmall

        Text {
          text: "warning"
          color: Colors.error
          font.family: Config.iconFont
          font.pixelSize: Config.iconSize
          font.variableAxes: Config.iconVariableAxes(0, Config.iconSize)
          Layout.alignment: Qt.AlignTop
        }

        Text {
          id: statusText
          Layout.fillWidth: true
          text: displayInputTab.statusMessage
          color: Colors.fgErrorContainer
          font.family: Config.fontFamily
          font.pixelSize: Config.typeBodySmallSize
          font.letterSpacing: Config.typeBodyTracking
          lineHeight: Config.typeBodySmallLineHeight
          lineHeightMode: Text.FixedHeight
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
