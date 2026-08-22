import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "primitives"
import "themes/ghost" as Ghost

PanelWindow {
  id: root

  property int notificationCount: 0
  property QtObject notificationServer: null
  property string barPosition: "top"
  readonly property bool horizontal: barPosition === "top" || barPosition === "bottom"
  readonly property bool dockedTop: barPosition === "top"
  readonly property bool dockedBottom: barPosition === "bottom"
  readonly property bool dockedLeft: barPosition === "left"
  readonly property bool dockedRight: barPosition === "right"

  readonly property real wSize: Config.widgetSize
  readonly property real horizontalPillLength: root.wSize + Config.spacingSmall
  readonly property real verticalPillLength: root.wSize

  anchors {
    left: root.horizontal || root.dockedLeft
    right: root.horizontal || root.dockedRight
    top: root.horizontal ? root.dockedTop : true
    bottom: root.horizontal ? root.dockedBottom : true
  }

  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  // Neo's floating full bar extends past the normal 44px layer reservation:
  // reserve its inset surface and hard shadow so Niri can keep the window
  // layout gap unchanged while still clearing the complete visual footprint.
  readonly property int niriExclusiveZone: root.fullBar && Config.neoBrutalism
    ? Config.barWidth + root.fullBarInset + Config.themeShadowOffset
    : (root.horizontal ? Config.barWidth : root.verticalPillPanelWidth)
  exclusiveZone: root.niriExclusiveZone
  WlrLayershell.namespace: "quickshell-panel"
  WlrLayershell.layer: WlrLayer.Top

  property date now: new Date()

  Timer {
    interval: Config.clockIntervalMs
    running: root.visible
    repeat: true
    onTriggered: now = new Date()
  }

  // Reinterprets root.now in Settings.timezone (an IANA name) when set,
  // falling back to system-local time if the name is invalid or the JS
  // engine lacks Intl support.
  function displayNow() {
    if (!Settings.timezone) return root.now
    try {
      var parts = new Intl.DateTimeFormat("en-US", {
        timeZone: Settings.timezone, hour12: false,
        year: "numeric", month: "2-digit", day: "2-digit",
        hour: "2-digit", minute: "2-digit", second: "2-digit"
      }).formatToParts(root.now)
      var m = {}
      parts.forEach(function(p) { m[p.type] = p.value })
      return new Date(m.year, m.month - 1, m.day, m.hour, m.minute, m.second)
    } catch (e) {
      return root.now
    }
  }

  function clockFormat() {
    if (Settings.clock24h) return Settings.clockShowSeconds ? "HH:mm:ss" : "HH:mm"
    return Settings.clockShowSeconds ? "h:mm:ss AP" : "h:mm AP"
  }

  property string openPopup: ""
  property int popupAnchorX: 0
  property int popupAnchorY: 0

  function getLauncherX() {
    if (!root.horizontal) return 0
    return launcherWidget ? launcherWidget.mapToItem(null, 0, 0).x + launcherWidget.width / 2 : 0
  }

  function getMenuIndicatorX() {
    if (!root.horizontal) return 0
    return menuIndicator ? menuIndicator.mapToItem(null, 0, 0).x + menuIndicator.width / 2 : 0
  }

  function getSettingsX() {
    if (!root.horizontal) return 0
    return settingsIndicator ? settingsIndicator.mapToItem(null, 0, 0).x + settingsIndicator.width / 2 : getMenuIndicatorX()
  }

  function getSettingsY() {
    return settingsIndicator ? settingsIndicator.mapToItem(null, 0, 0).y : getMenuIndicatorY()
  }

  function getMenuIndicatorY() {
    return root.height - 6 - wSize - 6 - wSize - 6 - wSize
  }

  function togglePopup(name, widget) {
    var x = widget ? widget.mapToItem(null, 0, 0).x : 0
    var y = widget ? widget.mapToItem(null, 0, 0).y : 0
    var w = widget ? widget.width : 0
    if (openPopup === name) {
      openPopup = ""
    } else {
      if (root.horizontal) {
        popupAnchorX = x + w / 2
        popupAnchorY = root.height - 16 // sit exactly at the bottom of the barBg
      } else {
        popupAnchorY = y
      }
      openPopup = name
    }
  }

  property bool fullBar: false
  readonly property bool pillsBar: !root.fullBar
  readonly property bool horizontalPillMode: root.horizontal && root.pillsBar
  readonly property bool ghostHorizontalOneLiner: Config.ghostTheme && root.horizontal
  readonly property bool horizontalInlineContent: root.horizontalPillMode
    || root.ghostHorizontalOneLiner
  readonly property bool clockSecondaryVisible: !root.horizontalPillMode
    && !root.horizontal
  // Give vertical Neo pills a little more room for rotated labels and their
  // hard shadow without changing Material 3 or full-bar geometry. Nothing's
  // dot-matrix/mono labels (e.g. "100%") need a bit more width than the bar
  // is thick, or they clip against the pill's rounded sides.
  readonly property int verticalPillPanelWidth: !root.horizontal
    && root.pillsBar
    && (Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme)
    ? Config.barWidth + (Config.neoBrutalism ? 2 : 18)
    : Config.barWidth
  // Keep Neo pills aligned with the visible edge of focused Niri windows.
  // The 4px focus ring sits inside the 18px layout gap, leaving a 14px
  // visible inset on each side.
  readonly property int horizontalPillInset: root.horizontal
    && root.pillsBar
    && Config.neoBrutalism
    ? Config.neoFullBarInset
    : 6
  readonly property int verticalPillInset: !root.horizontal
    && root.pillsBar
    && Config.neoBrutalism
    ? Config.neoFullBarInset
    : 6
  readonly property int verticalWindowEdgeMargin: !root.horizontal
    && root.pillsBar
    && Config.neoBrutalism
    ? 2
    : 0
  readonly property real expandProgress: 1.0
  // Neo full bars need room for both the floating inset and the hard offset
  // shadow. Pills only need the normal bar-sized layer surface, so their
  // transparent coverage does not extend into the window gap.
  readonly property int fullBarInset: root.fullBar && Config.neoBrutalism
    ? Config.neoFullBarInset
    : 0
  readonly property int normalPanelExtent: root.fullBar
    ? (Config.ghostTheme ? Config.barWidth : Config.barWidth + 16)
    : (root.horizontal ? Config.barWidth : root.verticalPillPanelWidth)
  // The panel must include the Neo inset and hard shadow, otherwise the
  // shadow is clipped at the docked edge even though the surface is aligned.
  readonly property int fullBarPanelExtent: root.fullBar && Config.neoBrutalism
    ? Config.barWidth + root.fullBarInset + Config.themeShadowOffset
    : root.normalPanelExtent
  readonly property int verticalClockHeight: !root.horizontal
    && root.pillsBar
    && Config.neoBrutalism
    ? root.verticalPillPanelWidth + Config.spacingSmall
    : Math.max(Config.clockVerticalHeight, root.verticalPillLength)

  // The historical Ghost bar kept a bounded negative-space region on the
  // bar axis, centered whenever the surrounding content leaves enough room.
  // The current GridLayout still owns the content flow; these coordinates
  // only define the Ghost surface cutout and its decorative signal field.
  readonly property real ghostGapAxisLength: root.horizontal ? barBg.width : barBg.height
  readonly property real ghostGapAvailableStart: gapSpacer
    ? (root.horizontal ? layout.x + gapSpacer.x : layout.y + gapSpacer.y)
    : 0
  readonly property real ghostGapAvailableEnd: root.ghostGapAvailableStart
    + (gapSpacer ? (root.horizontal ? gapSpacer.width : gapSpacer.height) : 0)
  readonly property real ghostGapAvailableLength: Math.max(
    0,
    root.ghostGapAvailableEnd - root.ghostGapAvailableStart
  )
  readonly property real ghostGapCenter: root.ghostGapAxisLength / 2
  readonly property real ghostGapCenterClearance: Math.min(
    root.ghostGapCenter - root.ghostGapAvailableStart,
    root.ghostGapAvailableEnd - root.ghostGapCenter
  )
  readonly property real ghostGapLength: Math.max(
    0,
    Math.min(
      root.horizontal ? 600 : 300,
      root.ghostGapAvailableLength,
      2 * root.ghostGapCenterClearance
    )
  )
  readonly property real ghostGapStart: root.ghostGapCenter - root.ghostGapLength / 2
  readonly property real ghostGapEnd: root.ghostGapCenter + root.ghostGapLength / 2
  readonly property bool ghostCentralGap: root.fullBar
    && Config.ghostTheme
    && root.ghostGapLength > 0

  implicitHeight: root.horizontal ? root.fullBarPanelExtent : root.normalPanelExtent
  implicitWidth: root.horizontal ? root.normalPanelExtent : root.fullBarPanelExtent

  mask: Region { item: barBg }

  Item {
    anchors.fill: parent

    Rectangle {
      id: barShadow
      x: barBg.x + Config.themeShadowOffset
      y: barBg.y + Config.themeShadowOffset
      width: barBg.width
      height: barBg.height
      radius: barBg.radius
      color: Colors.styleShadow
      visible: Config.neoBrutalism && root.fullBar
      z: -1
    }

    Rectangle {
      id: barBg
      x: root.fullBarInset > 0
        ? root.fullBarInset
        : (root.horizontal
          ? (root.wSize + 6) * (1.0 - root.expandProgress)
          : (root.dockedRight ? parent.width - root.verticalPillPanelWidth : 8 * (1.0 - root.expandProgress)))
      y: root.fullBarInset > 0
        ? root.fullBarInset
        : (root.horizontal
          ? (root.dockedBottom ? parent.height - Config.barWidth : 8 * (1.0 - root.expandProgress))
          : (root.wSize + 6) * (1.0 - root.expandProgress))
      width: root.horizontal
        ? (root.fullBarInset > 0
          ? parent.width - root.fullBarInset * 2
          : (layout.implicitWidth + 12) + (parent.width - (layout.implicitWidth + 12)) * root.expandProgress)
        : (root.fullBarInset > 0
          ? Config.barWidth
          : root.verticalPillPanelWidth - 8 * (1.0 - root.expandProgress))
      height: root.horizontal
        ? (root.fullBarInset > 0
          ? Config.barWidth
          : (Config.barWidth) - 8 * (1.0 - root.expandProgress))
        : (root.fullBarInset > 0
          ? parent.height - root.fullBarInset * 2
          : (layout.implicitHeight + 12) + (parent.height - (layout.implicitHeight + 12)) * root.expandProgress)
      radius: (root.horizontal ? height / 2 : width / 2) * (1.0 - root.expandProgress) + Config.barRadius * root.expandProgress
      color: root.fullBar && !root.ghostCentralGap
        ? ((Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme) ? Colors.styleSurface : Colors.bg)
        : "transparent"
      border.width: root.fullBar && Config.neoBrutalism ? Config.themeBorderWidth : 0
      border.color: Colors.styleOutline

      // Historical Ghost chrome: the panel edges step into the transparent
      // center instead of ending on a straight, synthetic cut line.
      Ghost.GapTransition {
        visible: root.ghostCentralGap
        width: root.horizontal ? parent.width : parent.height
        height: root.horizontal ? parent.height : parent.width
        anchors.centerIn: parent
        rotation: root.horizontal ? 0 : 90
        panelColor: Colors.styleSurface
        gapStart: root.ghostGapStart
        gapEnd: root.ghostGapEnd
      }

      // Square-off helper for the docked edge's near corner
      Rectangle {
        width: barBg.radius * root.expandProgress
        height: barBg.radius * root.expandProgress
        x: root.dockedRight ? barBg.width - width : 0
        y: root.dockedBottom ? barBg.height - height : 0
        color: barBg.color
        visible: width > 0 && root.fullBarInset === 0
      }

      // Square-off helper for the docked edge's far corner
      Rectangle {
        width: barBg.radius * root.expandProgress
        height: barBg.radius * root.expandProgress
        x: root.horizontal
          ? barBg.width - width
          : (root.dockedRight ? barBg.width - width : 0)
        y: root.horizontal
          ? (root.dockedBottom ? barBg.height - height : 0)
          : barBg.height - height
        color: barBg.color
        visible: width > 0 && root.fullBarInset === 0
      }

      Item {
        id: ghostGapRegion
        visible: root.ghostCentralGap
        x: root.horizontal ? root.ghostGapStart : 0
        y: root.horizontal ? 0 : root.ghostGapStart
        width: root.horizontal ? root.ghostGapLength : barBg.width
        height: root.horizontal ? barBg.height : root.ghostGapLength
        clip: true

        Ghost.GapGlitch {
          width: root.horizontal ? parent.width : parent.height
          height: root.horizontal ? parent.height : parent.width
          anchors.centerIn: parent
          rotation: root.horizontal ? 0 : 90
          colors_: Colors
          motionEnabled: root.visible && !Config.reducedMotion
        }

        Ghost.GapTrace {
          visible: root.horizontal
          colors_: Colors
          config: Config
          horizontal: true
          active: root.openPopup !== "" || mediaIndicator.mprisStatus === "Playing"
          bridgeGap: root.openPopup === ""
          gapStart: 0
          gapEnd: width
        }
      }

      MouseArea {
        id: barMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.openPopup = ""
        enabled: !root.openPopup
      }

      GridLayout {
        id: layout
        flow: root.horizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          leftMargin: root.horizontal
            ? root.horizontalPillInset
            : (root.dockedRight ? root.verticalWindowEdgeMargin : 0)
          rightMargin: root.horizontal
            ? root.horizontalPillInset
            : (root.dockedLeft ? root.verticalWindowEdgeMargin : 0)
          topMargin: root.horizontal ? 0 : root.verticalPillInset
          bottomMargin: root.horizontal ? 0 : root.verticalPillInset
        }
        height: root.horizontal
          ? parent.height
          : parent.height - root.verticalPillInset * 2
        columnSpacing: (Config.neoBrutalism
          ? Math.max(Config.spacingSmall, Config.themeShadowOffset)
          : Config.spacingSmall) * root.expandProgress
        rowSpacing: (Config.neoBrutalism
          ? Math.max(Config.spacingSmall, Config.themeShadowOffset)
          : Config.spacingSmall) * root.expandProgress

        Item {
          id: launcherWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize)
              * root.expandProgress * (Settings.ccShowLauncher ? 1 : 0)
            : parent.width * (Settings.ccShowLauncher ? 1 : 0)
          Layout.preferredHeight: root.horizontal
            ? parent.height * (Settings.ccShowLauncher ? 1 : 0)
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                launcherWidget.verticalLayoutHeight
              ) * root.expandProgress * (Settings.ccShowLauncher ? 1 : 0)
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowLauncher
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          Launcher {
            id: launcherWidget
            anchors.fill: parent
            active: root.openPopup === "launcher"
            horizontal: root.horizontal
            integrated: root.fullBar
            onClicked: function(mouse) {
              root.togglePopup("launcher", launcherWidget)
            }
          }
        }

        WorkspaceIndicator {
          id: wsIndicator
          horizontal: root.horizontal
          integrated: root.fullBar
          Layout.preferredWidth: Settings.ccShowWorkspaces
            ? (root.horizontal
              ? Math.max(implicitWidth, root.pillsBar ? root.horizontalPillLength : 0)
              : parent.width)
            : 0
          Layout.preferredHeight: Settings.ccShowWorkspaces
            ? (root.horizontal
              ? parent.height
              : Math.max(implicitHeight, root.pillsBar ? root.verticalPillLength : 0))
            : 0
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowWorkspaces

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }
        }

        Item {
          id: focusedWindowWrapper
          property string programText: wsIndicator.focusedWindowProgram
          property string detailText: wsIndicator.focusedWindowInfo
          readonly property bool hasWindowInfo: programText !== "" || detailText !== ""
          readonly property real windowInfoTextWidth: root.horizontalInlineContent
            ? focusedWindowProgramText.implicitWidth
              + (programText !== "" && detailText !== "" ? Config.spacingCompact : 0)
              + focusedWindowDetailText.implicitWidth
            : Math.max(
                focusedWindowProgramText.implicitWidth,
                focusedWindowDetailText.implicitWidth
              )
          // Neo's rotated focused-window pill needs a little more room at
          // both ends of its long axis than the compact Material 3 layout.
          // Nothing matches the breathing room used for the clock/icon pills.
          readonly property int verticalInfoPadding: Config.neoBrutalism
            ? Config.spacingSmall + Config.spacingMedium
            : (Config.nothingDesign ? Config.spacingMedium * 2 : Config.spacingSmall + Config.spacingCompact)
          readonly property real verticalInfoHeight: Math.min(
            320,
            Math.max(root.verticalPillPanelWidth, windowInfoTextWidth + verticalInfoPadding)
          )
          Layout.preferredWidth: root.horizontal
            ? (hasWindowInfo
              ? Math.min(320, Math.max(140, windowInfoTextWidth + 16)) * root.expandProgress
              : 0) * (Settings.ccShowFocusedWindow ? 1 : 0)
            : (hasWindowInfo ? parent.width : 0) * (Settings.ccShowFocusedWindow ? 1 : 0)
          Layout.preferredHeight: (root.horizontal
            ? parent.height
            : (hasWindowInfo ? verticalInfoHeight * root.expandProgress : 0))
            * (Settings.ccShowFocusedWindow ? 1 : 0)
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && hasWindowInfo && Settings.ccShowFocusedWindow
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
            fitContent: !root.horizontal
            // Keep the focused-window shadow from landing directly on the
            // vertical panel edge.
            contentWidth: Math.max(
              0,
              parent.width - (Config.neoBrutalism && !root.horizontal ? 2 : 0)
            )
            contentHeight: focusedWindowWrapper.verticalInfoHeight
          }

          GridLayout {
            id: focusedWindowContent
            anchors.centerIn: parent
            columns: root.horizontalInlineContent ? 2 : 1
            rows: root.horizontalInlineContent ? 1 : 2
            flow: root.horizontalInlineContent
              ? GridLayout.LeftToRight
              : GridLayout.TopToBottom
            width: root.horizontal
              ? Math.max(0, parent.width - 16)
              : Math.max(0, Math.min(
                  parent.height - focusedWindowWrapper.verticalInfoPadding,
                  focusedWindowWrapper.verticalInfoHeight
                    - focusedWindowWrapper.verticalInfoPadding
                ))
            height: root.horizontal
              ? Math.max(0, parent.height - 8)
              : Config.labelSmallSize * 2
                + (!root.horizontal && root.pillsBar
                  && focusedWindowWrapper.detailText !== ""
                  ? Config.spacingCompact
                  : 0)
            rotation: root.horizontal ? 0 : 90
            columnSpacing: root.horizontalInlineContent ? Config.spacingCompact : 0
            rowSpacing: root.horizontalInlineContent ? 0 : 0

            Text {
              id: focusedWindowProgramText
              text: focusedWindowWrapper.programText
              color: Config.nothingDesign ? Colors.fgSurface : Colors.primary
              font.family: Config.fontFamily
              font.pixelSize: Config.labelSmallSize
              font.weight: Font.Bold
              elide: Text.ElideRight
              maximumLineCount: 1
              // In the vertical layout, left alignment becomes the top edge
              // after the 90-degree rotation. Keep the program label anchored
              // there while the longer detail label gets its own clearance.
              horizontalAlignment: Text.AlignLeft
              verticalAlignment: Text.AlignVCenter
              Layout.fillWidth: true
            }

            Text {
              id: focusedWindowDetailText
              text: focusedWindowWrapper.detailText
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.labelSmallSize
              elide: Text.ElideRight
              maximumLineCount: 1
              horizontalAlignment: root.horizontal ? Text.AlignLeft : Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              Layout.fillWidth: true
              Layout.bottomMargin: !root.horizontal && root.pillsBar
                && focusedWindowWrapper.detailText !== ""
                ? Config.spacingCompact
                : 0
            }
          }
        }

        Item {
          id: gapSpacer
          // The vertical layout also needs a full-width gap region. Without
          // this, the spacer gets a zero-width column and the rotated Ghost
          // field is clipped away even though the height gap exists.
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.preferredWidth: root.horizontal ? 0 : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : 0
          visible: root.expandProgress > 0
          clip: true

          // Restore the historical Ghost gap treatment inside the current
          // flexible spacer. The spacer remains layout-owned; the effect is
          // strictly decorative and cannot change popup geometry.
          Ghost.GapGlitch {
            id: ghostGapGlitch
            visible: Config.ghostTheme && !root.fullBar
            width: root.horizontal ? parent.width : parent.height
            height: root.horizontal ? parent.height : parent.width
            anchors.centerIn: parent
            rotation: root.horizontal ? 0 : 90
            colors_: Colors
            motionEnabled: root.visible && !Config.reducedMotion
          }

          Ghost.GapTrace {
            visible: Config.ghostTheme && !root.fullBar && root.horizontal
            colors_: Colors
            config: Config
            horizontal: true
            active: root.openPopup !== "" || mediaIndicator.mprisStatus === "Playing"
            bridgeGap: root.openPopup === ""
            gapStart: 0
            gapEnd: width
          }
        }

        Item {
          id: audioWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, audioIndicator.horizontalContentWidth)
              : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                audioIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowAudio
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          AudioIndicator {
            id: audioIndicator
            anchors.fill: parent
            active: root.openPopup === "audio"
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.fullBar
            onClicked: function(mouse) {
              root.togglePopup("audio", audioIndicator)
            }
          }
        }

        Item {
          id: brightnessWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, brightnessIndicator.horizontalContentWidth)
              : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                brightnessIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowDisplay
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          BrightnessIndicator {
            id: brightnessIndicator
            anchors.fill: parent
            active: root.openPopup === "brightness"
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.fullBar
            onClicked: function(mouse) {
              root.togglePopup("brightness", brightnessIndicator)
            }
          }
        }

        Item {
          id: mediaWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, mediaIndicator.horizontalContentWidth)
              : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                mediaIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowMedia
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          MediaIndicator {
            id: mediaIndicator
            anchors.fill: parent
            active: root.openPopup === "media"
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.fullBar
            onClicked: function(mouse) {
              if (Settings.mediaControlsAlwaysVisible) {
                Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "play"])
              } else {
                root.togglePopup("media", mediaIndicator)
              }
            }
          }
        }

        Item {
          id: weatherWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, weatherIndicator.horizontalContentWidth)
              : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                weatherIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowWeather
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          WeatherIndicator {
            id: weatherIndicator
            anchors.fill: parent
            active: root.openPopup === "weather"
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.fullBar
            onClicked: function(mouse) {
              root.togglePopup("weather", weatherIndicator)
            }
          }
        }

        Item {
          id: batteryWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, batteryIndicator.horizontalContentWidth)
              : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                batteryIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowBattery
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          BatteryIndicator {
            id: batteryIndicator
            anchors.fill: parent
            active: root.openPopup === "battery"
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.fullBar
            onClicked: function(mouse) {
              root.togglePopup("battery", batteryIndicator)
            }
          }
        }

        Item {
          id: systemTrayWrapper
          Layout.preferredWidth: root.horizontal
            ? Math.max(
                systemTray.preferredLength,
                root.pillsBar ? root.horizontalPillLength : 0
              ) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                systemTray.preferredLength,
                root.pillsBar ? root.verticalPillLength : 0
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: Settings.ccShowTray && systemTray.visibleCount > 0 && (root.expandProgress > 0)
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          SystemTrayArea {
            id: systemTray
            horizontal: root.horizontal
            integrated: root.fullBar
            anchors.fill: parent
            parentWindow: root
          }
        }

        Item {
          id: clockWrapper
          Layout.preferredWidth: root.horizontal
            ? Math.max(
                root.wSize * 1.75,
                root.pillsBar ? root.horizontalPillLength : 0,
                root.ghostHorizontalOneLiner
                  ? clockContent.implicitWidth + Config.spacingSmall * 2
                  : 0
              ) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.verticalClockHeight,
                root.pillsBar ? root.verticalPillLength : 0
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowClock
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          Item {
            id: clockWidget
            anchors.fill: parent
            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: "Calendar"
            Accessible.description: "Open calendar"
            Accessible.focusable: true
            Accessible.focused: activeFocus

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.togglePopup("calendar", clockWidget)
                event.accepted = true
              }
            }

            GridLayout {
              id: clockContent
              anchors.centerIn: parent
              columns: root.ghostHorizontalOneLiner && root.clockSecondaryVisible ? 2 : 1
              rows: root.ghostHorizontalOneLiner
                ? 1
                : (root.clockSecondaryVisible ? 2 : 1)
              flow: root.ghostHorizontalOneLiner && root.clockSecondaryVisible
                ? GridLayout.LeftToRight
                : GridLayout.TopToBottom
              // Ndot's line-height metrics reserve descent space below each
              // digit row that the visible glyphs never use, which skews
              // Qt's naive vertical centering low. Nudge up to compensate.
              anchors.verticalCenterOffset: Config.nothingDesign && !root.horizontalPillMode ? -4 : 0
              columnSpacing: root.ghostHorizontalOneLiner && root.clockSecondaryVisible
                ? Config.spacingCompact
                : 0
              rowSpacing: root.clockSecondaryVisible && !root.ghostHorizontalOneLiner
                ? Config.clockLineSpacing
                : 0

              Text {
                text: root.horizontal
                  ? root.displayNow().toLocaleString(Qt.locale(), root.clockFormat())
                  : root.displayNow().toLocaleString(Qt.locale(), Settings.clock24h ? "HH" : "h")
                color: Config.nothingDesign ? Colors.fgSurface : Colors.primary
                font.family: Config.nothingDesign ? Config.dotFontFamily : Config.fontFamily
                font.pixelSize: Config.clockPrimarySize
                font.weight: Config.nothingDesign ? Font.Normal : Font.Bold
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
              }

              Text {
                visible: root.clockSecondaryVisible
                text: root.horizontal
                  ? root.displayNow().toLocaleDateString(Qt.locale(), "MMM dd")
                  : root.displayNow().toLocaleString(Qt.locale(), "mm")
                color: Colors.fgSurfaceVariant
                font.family: Config.nothingDesign
                  ? (root.horizontal ? Config.monoFontFamily : Config.dotFontFamily)
                  : Config.fontFamily
                font.pixelSize: root.horizontal
                  ? Config.clockSecondarySize
                  : Config.clockPrimarySize
                font.weight: root.horizontal ? Font.Medium : Font.Bold
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
              }
            }

            Rectangle {
              anchors.fill: parent
              radius: Config.shapeMedium
              color: "transparent"
              border.width: clockWidget.activeFocus ? Config.themeFocusBorderWidth : 0
              border.color: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme
                ? Colors.styleOutline
                : Colors.primary
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.togglePopup("calendar", clockWidget)
              }
            }
          }
        }

        Item {
          id: notifWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                notifIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0 && Settings.ccShowNotifications
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          NotificationIndicator {
            id: notifIndicator
            anchors.fill: parent
            notificationCount: root.notificationCount
            active: root.openPopup === "notification"
            horizontal: root.horizontal
            integrated: root.fullBar
            onClicked: function(mouse) {
              root.togglePopup("notification", notifIndicator)
            }
          }
        }

        Item {
          id: settingsWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                settingsIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          MenuIndicator {
            id: settingsIndicator
            anchors.fill: parent
            iconLabel: "settings"
            accessibleName: "Settings"
            active: root.openPopup === "settings"
            horizontal: root.horizontal
            integrated: root.fullBar
            onClicked: function(mouse) {
              root.togglePopup("settings", settingsIndicator)
            }
          }
        }

        Item {
          id: menuWrapper
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize) * root.expandProgress
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                menuIndicator.verticalLayoutHeight
              ) * root.expandProgress
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          opacity: root.expandProgress
          visible: root.expandProgress > 0
          clip: !Config.neoBrutalism || root.expandProgress < 1.0

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          MenuIndicator {
            id: menuIndicator
            anchors.fill: parent
            iconLabel: "power_settings_new"
            active: root.openPopup === "quickmenu"
            horizontal: root.horizontal
            integrated: root.fullBar
            onClicked: function(mouse) {
              root.togglePopup("quickmenu", menuIndicator)
            }
          }
        }
      }
    }
  }

  Binding {
    target: root
    property: "notificationCount"
    value: notificationServer && notificationServer.trackedNotifications ? notificationServer.trackedNotifications.count : 0
  }
}
