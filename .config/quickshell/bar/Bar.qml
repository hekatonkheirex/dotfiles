import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "../config/BarForm.js" as BarForm
import "../config/BarOrder.js" as BarOrder
import "../config/ClockTiming.js" as ClockTiming
import "primitives"

PanelWindow {
  id: root

  property int notificationCount: 0
  property string barPosition: "top"
  // PanelWindow's Wayland surface is not safe to reuse across a reload when
  // the theme-dependent namespace may have changed. The shell enables this
  // after one event-loop turn so a reloaded instance drops the old surface
  // before creating the new one.
  property bool surfaceReady: false
  // Set by shell.qml: the lock screen covers the bar.
  property bool sessionLocked: false
  // Decorative motion pauses on battery, while locked and under a fullscreen
  // window; the bar repaints at 60fps otherwise. Fullscreen comes from the
  // workspace widget's focused-window stream, so it is unknown (animating)
  // while that widget is hidden.
  readonly property bool ambientMotion: !UPower.onBattery && !root.sessionLocked
    && !wsIndicator.focusedWindowFullscreen
  // The pill form's signal wave reacts to the music: cava runs only while one
  // is on screen, motion is allowed, and a player reports Playing.
  readonly property bool waveWanted: root.pillsBar && root.horizontal && root.ambientMotion
    && !Config.reducedMotion
  Binding { target: AudioLevelService; property: "wanted"; value: root.waveWanted }
  Binding { target: MediaService; property: "waveActive"; value: root.waveWanted }
  readonly property bool horizontal: barPosition === "top" || barPosition === "bottom"
  readonly property bool dockedTop: barPosition === "top"
  readonly property bool dockedBottom: barPosition === "bottom"
  readonly property bool dockedLeft: barPosition === "left"
  readonly property bool dockedRight: barPosition === "right"
  readonly property bool themeClockCentered: !Settings.barClockInFlow
  readonly property var normalizedOrder: BarOrder.normalize(Settings.barWidgetOrder)
  readonly property var activeWidgets: ({
    launcher: Settings.ccShowLauncher,
    workspaces: Settings.ccShowWorkspaces,
    layout: layoutWrapper.layoutAvailable,
    focused: root.focusedShown && focusedWindowWrapper.hasWindowInfo,
    audio: Settings.ccShowAudio,
    display: Settings.ccShowDisplay,
    media: Settings.ccShowMedia,
    weather: Settings.ccShowWeather,
    llm: Settings.ccShowLlm,
    battery: Settings.ccShowBattery,
    tray: Settings.ccShowTray && systemTray.visibleCount > 0,
    notifications: Settings.ccShowNotifications,
    clock: Settings.ccShowClock
  })
  readonly property var barSlots: {
    var slots = BarOrder.edgeOrder(Settings.barWidgetOrder, root.activeWidgets)
    if (!Settings.barClockInFlow) {
      slots = slots.filter(function(id) { return id !== "clock" })
    }
    return slots
  }
  readonly property var middleSlots: {
    var slots = BarOrder.middleOrder(Settings.barWidgetOrder, root.activeWidgets)
    if (!Settings.barClockInFlow) {
      slots = slots.filter(function(id) { return id !== "clock" })
      if (root.themeClockCentered && Settings.ccShowClock) slots.unshift("clock")
    }
    return slots
  }
  function inMiddle(id) {
    if (id === "clock" && !Settings.barClockInFlow) return root.themeClockCentered
    var at = root.normalizedOrder.indexOf(id)
    return at > root.normalizedOrder.indexOf("gap")
      && at < root.normalizedOrder.indexOf("center")
  }
  function barSlot(id) {
    var slots = root.inMiddle(id) ? root.middleSlots : root.barSlots
    return Math.max(0, slots.indexOf(id))
  }

  readonly property real wSize: Config.widgetSize
  readonly property real horizontalPillLength: root.wSize + Config.spacingSmall
  readonly property real verticalPillLength: root.wSize
  readonly property color barPanelColor: Colors.chromeSurface

  anchors {
    left: root.horizontal || root.dockedLeft
    right: root.horizontal || root.dockedRight
    top: root.horizontal ? root.dockedTop : true
    bottom: root.horizontal ? root.dockedBottom : true
  }

  visible: false
  color: "transparent"
  exclusionMode: ExclusionMode.Normal
  readonly property int niriExclusiveZone: (root.horizontal ? Config.barWidth : root.verticalPillPanelWidth)
    + root.edgeGap
  exclusiveZone: root.niriExclusiveZone
  WlrLayershell.namespace: Config.layerNamespace("panel")
  WlrLayershell.layer: WlrLayer.Top

  property date now: new Date()

  // Tick on visible clock boundaries, and resync after visibility or seconds changes.
  function rescheduleClock() {
    clockTimer.interval = ClockTiming.nextInterval(root.now, Settings.clockShowSeconds)
    if (root.visible) clockTimer.restart()
  }

  onVisibleChanged: {
    if (visible) {
      now = new Date()
      rescheduleClock()
    }
  }

  Connections {
    target: Settings
    function onClockShowSecondsChanged() {
      root.now = new Date()
      root.rescheduleClock()
    }
  }

  Timer {
    id: clockTimer
    interval: ClockTiming.nextInterval(root.now, Settings.clockShowSeconds)
    running: root.visible
    repeat: false
    onTriggered: {
      root.now = new Date()
      root.rescheduleClock()
    }
  }

  Timer {
    interval: 0
    running: true
    repeat: false
    onTriggered: root.surfaceReady = true
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
    return getMenuIndicatorX()
  }

  function getSettingsY() {
    return getMenuIndicatorY()
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
        popupAnchorY = root.height - Config.spacingLarge // sit exactly at the bottom of the barBg
      } else {
        popupAnchorY = y
      }
      openPopup = name
    }
  }

  // IPC entry point: open (or toggle closed) a bar popup by name, anchored to
  // its indicator exactly as a click would. Returns false for unknown names.
  function togglePopupByName(name) {
    // The sidebar and the networks window have no anchor widget.
    if (name === "sidebar" || name === "networks") {
      openPopup = openPopup === name ? "" : name
      return true
    }
    var widgets = {
      audio: audioIndicator, brightness: brightnessIndicator, media: mediaIndicator,
      weather: weatherIndicator, battery: batteryIndicator, notification: notifIndicator,
      llm: llmUsageIndicator,
      calendar: clockWidget, quickmenu: menuIndicator, launcher: launcherWidget
    }
    if (!(name in widgets)) return false
    togglePopup(name, widgets[name])
    return true
  }

  readonly property bool pillsBar: Config.barFormMetrics.pills
  readonly property bool continuousBar: !root.pillsBar
  readonly property bool groupedPills: root.pillsBar && root.horizontal
  // Geometry for the selected form (see config/BarForm.js).
  readonly property int edgeGap: Config.barFormMetrics.edgeGap
  readonly property int sideInset: Config.barFormMetrics.sideInset
  readonly property int shoulder: Config.barFormMetrics.shoulder
  readonly property bool flat: Config.barFormMetrics.flat

  readonly property bool packed: root.shoulder > 0
  readonly property real packedLength: root.horizontal
    ? layout.implicitWidth + root.horizontalPillInset * 2
    : layout.implicitHeight + root.verticalPillInset * 2
  readonly property bool roundNear: Config.barFormMetrics.roundNear
  readonly property bool horizontalPillMode: root.horizontal && root.pillsBar

  readonly property bool focusedShown: Settings.ccShowFocusedWindow
  // The horizontal full bar follows the Hyprland layout's compact icon-plus
  // label controls. Vertical bars and stacked clock content stay unchanged.
  readonly property bool horizontalInlineContent: root.horizontalPillMode
    || (root.horizontal && root.continuousBar)

  readonly property int verticalPillPanelWidth: Config.barWidth
  readonly property int horizontalPillInset: 6
  readonly property int verticalPillInset: 6
  readonly property int verticalWindowEdgeMargin: 0
  // elena: the surface is exactly the 8 px block row (barWidth is forced to
  // tagStripHeight in Config); no panel padding below it.
  readonly property int normalPanelExtent: Config.barWidth
  readonly property int verticalClockHeight: Math.max(Config.clockVerticalHeight, root.verticalPillLength)

  implicitHeight: root.normalPanelExtent
  implicitWidth: root.normalPanelExtent

  mask: Region { item: barBg }

  Item {
    anchors.fill: parent

    // Notch form: concave shoulders flow from the screen edge into the body.
    Shape {
      anchors.fill: parent
      // Above the body so its edge stroke is not half covered by the fill.
      z: 1
      visible: root.shoulder > 0
      ShapePath {
        fillColor: barBg.color
        strokeColor: "transparent"
        strokeWidth: 0
        PathSvg {
          path: BarForm.shoulderPath(root.shoulder, {
            edge: root.barPosition, x: barBg.x, y: barBg.y, w: barBg.width, h: barBg.height
          })
        }
      }
      // The body's own border would cut a line across each shoulder joint, so
      // the notch strokes one continuous outline around body and shoulders.
      ShapePath {
        fillColor: "transparent"
        strokeColor: "transparent"
        strokeWidth: Config.themeBorderWidth
        PathSvg {
          path: BarForm.outlinePath(root.shoulder, Config.barRadius, {
            edge: root.barPosition, x: barBg.x, y: barBg.y, w: barBg.width, h: barBg.height
          })
        }
      }
    }

    Rectangle {
      id: barBg
      x: root.horizontal
        ? (parent.width - width) / 2
        : (root.dockedRight ? parent.width - root.verticalPillPanelWidth - root.edgeGap : root.edgeGap)
      y: root.horizontal
        ? (root.dockedBottom ? parent.height - Config.barWidth - root.edgeGap : root.edgeGap)
        : (parent.height - height) / 2
      width: root.horizontal
        ? (root.packed
          ? Math.min(root.packedLength, parent.width - root.sideInset * 2)
          : parent.width - root.sideInset * 2)
        : root.verticalPillPanelWidth
      height: root.horizontal
        ? Config.barWidth
        : (root.packed
          ? Math.min(root.packedLength, parent.height - root.sideInset * 2)
          : parent.height - root.sideInset * 2)
      radius: (root.flat ? 0 : Config.barRadius)

      color: "transparent"
      border.width: 0
      border.color: Colors.outlineVariant

      // Square-off helper for the docked edge's near corner
      Rectangle {
        width: barBg.radius
        height: barBg.radius
        x: root.dockedRight ? barBg.width - width : 0
        y: root.dockedBottom ? barBg.height - height : 0
        color: barBg.color
        visible: width > 0 && !root.roundNear
      }

      // Square-off helper for the docked edge's far corner
      Rectangle {
        width: barBg.radius
        height: barBg.radius
        x: root.horizontal
          ? barBg.width - width
          : (root.dockedRight ? barBg.width - width : 0)
        y: root.horizontal
          ? (root.dockedBottom ? barBg.height - height : 0)
          : barBg.height - height
        color: barBg.color
        visible: width > 0 && !root.roundNear
      }

      MouseArea {
        id: barMouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.openPopup = ""
        enabled: !root.openPopup
      }

      // Pill form, horizontal: an outlined capsule around each widget group
      // (start, middle, end) and a signal wave across the open space between
      // them. Geometry follows the layouts, so hidden widgets collapse a group.
      Item {
        id: groupChrome
        anchors.fill: parent
        visible: root.groupedPills
        z: -2

        readonly property real pad: Config.spacingCompact
        readonly property real startW: Math.max(0, gapSpacer.x - layout.columnSpacing)
        readonly property real endX: gapSpacer.x + gapSpacer.width + layout.columnSpacing
        readonly property real endW: Math.max(0, layout.width - endX)
        readonly property real midW: middleLayout.implicitWidth
        readonly property real startRight: startW > 0 ? layout.x + startW + pad : layout.x
        readonly property real endLeft: endW > 0 ? layout.x + endX - pad : layout.x + layout.width
        readonly property real midLeft: middleLayout.x - pad
        readonly property real midRight: middleLayout.x + midW + pad

        GroupCapsule {
          visible: groupChrome.startW > 0
          x: layout.x - groupChrome.pad
          width: groupChrome.startW + groupChrome.pad * 2
        }
        GroupCapsule {
          visible: groupChrome.midW > 0
          x: groupChrome.midLeft
          width: groupChrome.midW + groupChrome.pad * 2
        }
        GroupCapsule {
          visible: groupChrome.endW > 0
          x: groupChrome.endLeft
          width: groupChrome.endW + groupChrome.pad * 2
        }

        SignalWave {
          readonly property real from: groupChrome.startRight + Config.spacingSmall
          readonly property real to: (groupChrome.midW > 0 ? groupChrome.midLeft : groupChrome.endLeft)
            - Config.spacingSmall
          x: from
          width: Math.max(0, to - from)
          height: parent.height
          visible: width > Config.spacingLarge * 2
          running: root.ambientMotion
          active: AudioLevelService.active
          color: Colors.primary
        }
        SignalWave {
          readonly property real from: groupChrome.midW > 0
            ? groupChrome.midRight + Config.spacingSmall
            : groupChrome.startRight + Config.spacingSmall
          readonly property real to: groupChrome.endLeft - Config.spacingSmall
          x: from
          width: groupChrome.midW > 0 ? Math.max(0, to - from) : 0
          height: parent.height
          visible: width > Config.spacingLarge * 2
          running: root.ambientMotion
          active: AudioLevelService.active
          color: Colors.primary
        }
      }

      // elena: the whole bar is the workspace block row. Everything else is
      // hidden with opacity/enabled (not visible: wsIndicator's refreshers are
      // gated on root.visible) until the sidebar phase. The mask below is
      // barBg, so clicks reach only these blocks.
      TagStripBlocks {
        anchors.fill: parent
        visible: true
        z: 10
        workspaces: wsIndicator.visibleWorkspaces
        onActivated: function(idx) { wsIndicator.focusWorkspace(idx) }
      }

      GridLayout {
        id: layout
        opacity: 0
        enabled: false
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
        columnSpacing: Config.spacingCompact
        rowSpacing: Config.spacingCompact

        Item {
          id: launcherWrapper
          parent: root.inMiddle("launcher") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("launcher") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("launcher")
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize)
              * (Settings.ccShowLauncher ? 1 : 0)
            : parent.width * (Settings.ccShowLauncher ? 1 : 0)
          Layout.preferredHeight: root.horizontal
            ? parent.height * (Settings.ccShowLauncher ? 1 : 0)
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                launcherWidget.verticalLayoutHeight
              ) * (Settings.ccShowLauncher ? 1 : 0)
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowLauncher
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          Launcher {
            id: launcherWidget
            anchors.fill: parent
            active: root.openPopup === "launcher"
            horizontal: root.horizontal
            integrated: root.continuousBar
            onClicked: function(mouse) {
              root.togglePopup("launcher", launcherWidget)
            }
          }
        }

        WorkspaceIndicator {
          id: wsIndicator
          screenWidth: root.screen ? root.screen.width : 0
          screenHeight: root.screen ? root.screen.height : 0
          parent: root.inMiddle("workspaces") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("workspaces") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("workspaces")
          horizontal: root.horizontal
          integrated: root.continuousBar
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
          visible: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }
        }

        Item {
          id: layoutWrapper
          parent: root.inMiddle("layout") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("layout") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("layout")
          readonly property bool layoutAvailable: Config.isMango
            && Settings.ccShowLayout
            && wsIndicator.mangoLayoutSymbol !== ""
          Layout.preferredWidth: root.horizontal
            ? (layoutAvailable
              ? Math.max(root.horizontalPillLength, layoutIndicator.horizontalContentWidth)
              : 0)
            : (layoutAvailable ? parent.width : 0)
          Layout.preferredHeight: root.horizontal
            ? (layoutAvailable ? parent.height : 0)
            : (layoutAvailable
              ? Math.max(
                  root.pillsBar ? root.verticalPillLength : 0,
                  layoutIndicator.verticalLayoutHeight
                )
              : 0)
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: layoutAvailable
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          StatusIndicator {
            id: layoutIndicator
            anchors.fill: parent
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.continuousBar
            iconLabel: "view_quilt"
            labelText: wsIndicator.mangoLayoutName !== ""
              ? wsIndicator.mangoLayoutName
              : wsIndicator.mangoLayoutSymbol
            accentColor: (Colors.primary)
            accessibleName: "Layout"
            accessibleDescription: labelText !== ""
              ? labelText + " layout"
              : "Mango layout"
            tooltipText: labelText !== ""
              ? labelText + " layout"
              : "Mango layout"
          }
        }

        Item {
          id: focusedWindowWrapper
          parent: root.inMiddle("focused") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("focused") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("focused")
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

          readonly property int verticalInfoPadding: (Config.spacingSmall + Config.spacingCompact)
          readonly property real verticalInfoHeight: Math.min(
            320,
            Math.max(root.verticalPillPanelWidth, windowInfoTextWidth + verticalInfoPadding)
          )
          Layout.preferredWidth: root.horizontal
            ? (hasWindowInfo
              ? Math.min(Math.max(320, root.width * 0.28), Math.max(140, windowInfoTextWidth + Config.spacingLarge))
              : 0) * (root.focusedShown ? 1 : 0)
            : (hasWindowInfo ? parent.width : 0) * (root.focusedShown ? 1 : 0)
          Layout.preferredHeight: (root.horizontal
            ? parent.height
            : (hasWindowInfo ? verticalInfoHeight : 0))
            * (root.focusedShown ? 1 : 0)
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: hasWindowInfo && root.focusedShown
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
            fitContent: !root.horizontal
            contentWidth: Math.max(0, parent.width)
            contentHeight: focusedWindowWrapper.verticalInfoHeight
          }

          GridLayout {
            id: focusedWindowContent
            anchors.centerIn: parent
            // Keep the rotated window info slightly inside the screen edge.
            anchors.horizontalCenterOffset: root.horizontal
              ? 0
              : (root.dockedLeft
                ? Config.spacingCompact
                : (root.dockedRight ? -Config.spacingCompact : 0))
            columns: root.horizontalInlineContent ? 2 : 1
            rows: root.horizontalInlineContent ? 1 : 2
            flow: root.horizontalInlineContent
              ? GridLayout.LeftToRight
              : GridLayout.TopToBottom
            width: root.horizontal
              ? Math.max(0, parent.width - Config.spacingLarge)
              : Math.max(0, Math.min(
                  parent.height - focusedWindowWrapper.verticalInfoPadding,
                  focusedWindowWrapper.verticalInfoHeight
                    - focusedWindowWrapper.verticalInfoPadding
                ))
            height: root.horizontal
            ? Math.max(0, parent.height - Config.spacingSmall)
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
              color: Colors.primary
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelMediumSize
              font.weight: Config.typeStrongWeight
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: Config.typeLabelMediumLineHeight
              lineHeightMode: Text.FixedHeight
              elide: Text.ElideRight
              maximumLineCount: 1
              // In the vertical layout, left alignment becomes the top edge
              // after the 90-degree rotation. Keep the program label anchored
              // there while the longer detail label gets its own clearance.
              horizontalAlignment: Text.AlignLeft
              verticalAlignment: Text.AlignVCenter
              Layout.fillHeight: root.horizontalInlineContent
              Layout.fillWidth: true
            }

            Text {
              id: focusedWindowDetailText
              text: focusedWindowWrapper.detailText
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: Config.typeLabelMediumSize
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: Config.typeLabelMediumLineHeight
              lineHeightMode: Text.FixedHeight
              elide: Text.ElideRight
              maximumLineCount: 1
              horizontalAlignment: root.horizontal ? Text.AlignLeft : Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              Layout.fillHeight: root.horizontalInlineContent
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
          Layout.column: root.horizontal ? root.barSlot("gap") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("gap")

          Layout.fillWidth: true
          Layout.fillHeight: true
          // Packed (notch): the spacer is exactly the middle group, so only
          // the regular column gap separates start, middle and end.
          readonly property real pad: root.packed ? 0 : Config.spacingLarge * 2
          Layout.minimumWidth: root.horizontal
            ? middleLayout.implicitWidth + pad : 0
          Layout.minimumHeight: root.horizontal ? 0
            : middleLayout.implicitHeight + pad
          Layout.preferredWidth: root.horizontal ? 0 : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : 0
          clip: true
        }

        Item {
          id: audioWrapper
          parent: root.inMiddle("audio") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("audio") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("audio")
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, audioIndicator.horizontalContentWidth)
              : root.wSize)
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                audioIndicator.verticalLayoutHeight
              )
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowAudio
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          AudioIndicator {
            id: audioIndicator
            anchors.fill: parent
            visible: audioWrapper.visible
            active: root.openPopup === "audio"
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.continuousBar
            onClicked: function(mouse) {
              root.togglePopup("audio", audioIndicator)
            }
          }
        }

        Item {
          id: brightnessWrapper
          parent: root.inMiddle("display") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("display") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("display")
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, brightnessIndicator.horizontalContentWidth)
              : root.wSize)
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                brightnessIndicator.verticalLayoutHeight
              )
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowDisplay
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          BrightnessIndicator {
            id: brightnessIndicator
            anchors.fill: parent
            visible: brightnessWrapper.visible
            active: root.openPopup === "brightness"
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.continuousBar
            onClicked: function(mouse) {
              root.togglePopup("brightness", brightnessIndicator)
            }
          }
        }

        Item {
          id: mediaWrapper
          parent: root.inMiddle("media") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("media") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("media")
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, mediaIndicator.horizontalContentWidth)
              : root.wSize)
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                mediaIndicator.verticalLayoutHeight
              )
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowMedia
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          MediaIndicator {
            id: mediaIndicator
            anchors.fill: parent
            visible: mediaWrapper.visible
            active: root.openPopup === "media"
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.continuousBar
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
          parent: root.inMiddle("weather") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("weather") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("weather")
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, weatherIndicator.horizontalContentWidth)
              : root.wSize)
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                weatherIndicator.verticalLayoutHeight
              )
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowWeather
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          WeatherIndicator {
            id: weatherIndicator
            anchors.fill: parent
            visible: weatherWrapper.visible
            active: root.openPopup === "weather"
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.continuousBar
            onClicked: function(mouse) {
              root.togglePopup("weather", weatherIndicator)
            }
          }
        }

        Item {
          id: llmUsageWrapper
          parent: root.inMiddle("llm") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("llm") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("llm")
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, llmUsageIndicator.horizontalContentWidth)
              : root.wSize)
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                llmUsageIndicator.verticalLayoutHeight
              )
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowLlm
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          LlmUsageIndicator {
            id: llmUsageIndicator
            anchors.fill: parent
            visible: llmUsageWrapper.visible
            active: root.openPopup === "llm"
            horizontal: root.horizontal
            inlineContent: root.horizontalInlineContent
            integrated: root.continuousBar
            onClicked: function(mouse) {
              root.togglePopup("llm", llmUsageIndicator)
            }
          }
        }

        Item {
          id: batteryWrapper
          parent: root.inMiddle("battery") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("battery") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("battery")
          Layout.preferredWidth: root.horizontal
            ? (root.horizontalInlineContent
              ? Math.max(root.horizontalPillLength, batteryIndicator.horizontalContentWidth)
              : root.wSize)
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                batteryIndicator.verticalLayoutHeight
              )
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowBattery
          clip: true

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
            integrated: root.continuousBar
            onClicked: function(mouse) {
              root.togglePopup("battery", batteryIndicator)
            }
          }
        }

        Item {
          id: systemTrayWrapper
          parent: root.inMiddle("tray") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("tray") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("tray")
          Layout.preferredWidth: root.horizontal
            ? Math.max(
                systemTray.preferredLength,
                root.pillsBar ? root.horizontalPillLength : 0
              )
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                systemTray.preferredLength,
                root.pillsBar ? root.verticalPillLength : 0
              )
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowTray && systemTray.visibleCount > 0
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          SystemTrayArea {
            id: systemTray
            horizontal: root.horizontal
            integrated: root.continuousBar
            anchors.fill: parent
            parentWindow: root
          }
        }

        Item {
          id: notifWrapper
          parent: root.inMiddle("notifications") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("notifications") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("notifications")
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize)
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                notifIndicator.verticalLayoutHeight
              )
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          visible: Settings.ccShowNotifications
          clip: true

          PillSurface {
            horizontal: root.horizontal
            visible: root.pillsBar
          }

          NotificationIndicator {
            id: notifIndicator
            anchors.fill: parent
            notificationCount: root.notificationCount
            active: root.openPopup === "notification" || (root.notificationCount > 0)
            horizontal: root.horizontal
            integrated: root.continuousBar
            onClicked: function(mouse) {
              root.togglePopup("notification", notifIndicator)
            }
          }
        }

        Item {
          id: clockSlot
          parent: root.inMiddle("clock") ? middleLayout : layout
          Layout.column: root.horizontal ? root.barSlot("clock") : 0
          Layout.row: root.horizontal ? 0 : root.barSlot("clock")
          Layout.preferredWidth: root.horizontal ? clockWrapper.width : parent.width
          Layout.preferredHeight: root.horizontal ? parent.height : clockWrapper.height
          Layout.fillHeight: root.horizontal
          visible: Settings.ccShowClock
        }

        Item {
          id: menuWrapper
          Layout.column: root.horizontal ? root.barSlots.length : 0
          Layout.row: root.horizontal ? 0 : root.barSlots.length
          Layout.preferredWidth: root.horizontal
            ? (root.pillsBar ? root.horizontalPillLength : root.wSize)
            : parent.width
          Layout.preferredHeight: root.horizontal
            ? parent.height
            : Math.max(
                root.pillsBar ? root.verticalPillLength : 0,
                menuIndicator.verticalLayoutHeight
              )
          Layout.fillHeight: root.horizontal
          Layout.alignment: root.horizontal ? Qt.AlignVCenter : Qt.AlignTop
          clip: true

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
            integrated: root.continuousBar
            onClicked: function(mouse) {
              root.togglePopup("quickmenu", menuIndicator)
            }
          }
        }
      }

      // Independently centered on the bar axis: unequal start/end groups
      // cannot pull middle widgets away from the screen midpoint.
      GridLayout {
        id: middleLayout
        opacity: 0
        enabled: false
        flow: root.horizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom
        // Packed (notch): sit in the spacer, not at the screen midpoint.
        x: root.horizontal
          ? (root.packed
            ? layout.x + gapSpacer.x + (gapSpacer.width - width) / 2
            : (parent.width - width) / 2)
          : 0
        y: root.horizontal ? 0
          : (root.packed
            ? layout.y + gapSpacer.y + (gapSpacer.height - height) / 2
            : (parent.height - height) / 2)
        width: root.horizontal ? implicitWidth : parent.width
        height: root.horizontal ? parent.height : implicitHeight
        columnSpacing: Config.spacingCompact
        rowSpacing: Config.spacingCompact
        z: 2
      }

      Item {
        id: clockWrapper
        opacity: 0
        enabled: false
        // The clock stays outside both layouts to preserve its popup anchor,
        // but its slot participates in whichever region owns it.
        width: root.horizontal
          ? (Math.max(
                112,
                root.wSize * 2.5,
                root.pillsBar ? root.horizontalPillLength : 0
              ))
          : parent.width
        height: root.horizontal
          ? parent.height
          : Math.max(
              root.verticalClockHeight,
              root.pillsBar ? root.verticalPillLength : 0
            )
        x: (root.inMiddle("clock") ? middleLayout.x : layout.x)
          + clockSlot.x + (clockSlot.width - width) / 2
        y: root.horizontal ? 0
          : (root.inMiddle("clock") ? middleLayout.y : layout.y)
            + clockSlot.y + (clockSlot.height - height) / 2
        z: 2
        visible: Settings.ccShowClock
        clip: true

        PillSurface {
          horizontal: root.horizontal
          visible: root.pillsBar
          verticalInset: root.horizontal
            ? Math.max(2, Math.min(6, Math.floor((parent.height - clockContent.implicitHeight - Config.spacingCompact) / 2)))
            : 6
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
            columns: 1
            rows: 2
            flow: GridLayout.TopToBottom
            columnSpacing: 0
            rowSpacing: Config.clockLineSpacing

            Text {
              text: root.horizontal
                ? root.displayNow().toLocaleString(Qt.locale(), root.clockFormat())
                : root.displayNow().toLocaleString(Qt.locale(), Settings.clock24h ? "HH" : "h")
              color: Colors.primary
              font.family: Config.fontFamily
              font.pixelSize: Config.clockPrimarySize
              font.weight: Font.Bold
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }

            Text {
              visible: true
              text: root.horizontal
                ? root.displayNow().toLocaleDateString(Qt.locale(), "ddd, d MMM")
                : root.displayNow().toLocaleString(Qt.locale(), "mm")
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: root.horizontal
                ? Config.clockSecondarySize
                : Config.clockPrimarySize
              font.weight: (root.horizontal ? Font.Medium : Font.Bold)
              Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
          }

          Rectangle {
            anchors.fill: parent
            radius: Config.shapeMedium
            color: "transparent"
            border.width: clockWidget.activeFocus ? Config.themeFocusBorderWidth : 0
            border.color: (Colors.primary)
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
    }
  }
}
