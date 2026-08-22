import QtQuick

Item {
  id: root
  property QtObject colors_: null
  property QtObject config: null
  property bool horizontal: true
  // The trace is a state signal, not idle decoration. The bar enables it for
  // active playback and while a shell surface is open.
  property bool active: false
  // The solid segments may trace independently while a popup is open; the
  // transparent center bridge remains reserved negative space in that state.
  property bool bridgeGap: true
  // In horizontal mode, the animated trace is clipped out of this interval.
  property real gapStart: 0
  property real gapEnd: 0
  readonly property int sweepInterval: 125
  readonly property int sweepSteps: 44
  property int horizontalStep: 0
  property int verticalStep: 0
  readonly property bool horizontalMotionEnabled: visible && active && horizontal && !(config && config.reducedMotion)
  readonly property bool verticalMotionEnabled: visible && active && !horizontal && !(config && config.reducedMotion)
  readonly property real horizontalTraceX: sweepPosition(width, horizontalStep)
  height: horizontal ? 1 : parent.height
  width: horizontal ? parent.width : 1
  anchors.bottom: horizontal ? parent.bottom : undefined
  anchors.right: horizontal ? undefined : parent.right
  clip: true

  function sweepPosition(extent, step) {
    return -extent * 0.3 + extent * 1.3 * step / (sweepSteps - 1)
  }

  onHorizontalMotionEnabledChanged: {
    if (!horizontalMotionEnabled) horizontalStep = 0
  }
  onVerticalMotionEnabledChanged: {
    if (!verticalMotionEnabled) verticalStep = 0
  }

  Timer {
    interval: root.sweepInterval
    repeat: true
    running: root.horizontalMotionEnabled
    onTriggered: root.horizontalStep = (root.horizontalStep + 1) % root.sweepSteps
  }

  Timer {
    interval: root.sweepInterval
    repeat: true
    running: root.verticalMotionEnabled
    onTriggered: root.verticalStep = (root.verticalStep + 1) % root.sweepSteps
  }

  // Vertical twin of the horizontal viewport pair below: the same global
  // trace disappears while crossing the central gap, then reappears.
  Item {
    id: topViewport
    visible: !root.horizontal
    y: 0
    width: 1
    height: Math.max(0, root.gapStart)
    clip: true
    Rectangle {
      id: topTrace
      y: root.sweepPosition(root.height, root.verticalStep)
      width: 1
      height: root.height * 0.3
      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 0.5; color: colors_ ? colors_.ghostCyan : "#57d9cc" }
        GradientStop { position: 1.0; color: "transparent" }
      }
      opacity: root.config && root.config.reducedMotion ? 0.0 : 0.85
    }
  }

  Item {
    id: bottomViewport
    visible: !root.horizontal
    y: root.gapEnd
    width: 1
    height: Math.max(0, root.height - root.gapEnd)
    clip: true
    Rectangle {
      id: bottomTrace
      y: root.sweepPosition(root.height, root.verticalStep) - bottomViewport.y
      width: 1
      height: root.height * 0.3
      gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 0.5; color: colors_ ? colors_.ghostCyan : "#57d9cc" }
        GradientStop { position: 1.0; color: "transparent" }
      }
      opacity: root.config && root.config.reducedMotion ? 0.0 : 0.85
    }
  }

  // Both segment viewports keep the carrier aligned with the solid bar.
  Item {
    id: leftViewport
    visible: root.horizontal
    x: 0
    width: Math.max(0, root.gapStart)
    height: 1
    clip: true
    Rectangle {
      id: leftTrace
      x: root.horizontalTraceX
      width: root.width * 0.3
      height: 1
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 0.5; color: colors_ ? colors_.ghostCyan : "#57d9cc" }
        GradientStop { position: 1.0; color: "transparent" }
      }
      opacity: root.config && root.config.reducedMotion ? 0.0 : 0.85
    }
  }

  // A deliberately thin carrier crosses the negative-space gap. It never
  // hosts content or fills the gap; it is only visible during an active shell
  // state and becomes static under Reduce Motion.
  Rectangle {
    visible: root.horizontal && root.active && root.bridgeGap
    x: root.gapStart
    width: Math.max(0, root.gapEnd - root.gapStart)
    height: 1
    anchors.bottom: parent.bottom
    color: colors_ ? colors_.ghostCyan : "#57d9cc"
    opacity: root.config && root.config.reducedMotion ? 0.28 : (root.horizontalStep % 9 === 0 ? 0.82 : 0.14)
  }

  Item {
    id: rightViewport
    visible: root.horizontal
    x: root.gapEnd
    width: Math.max(0, root.width - root.gapEnd)
    height: 1
    clip: true
    Rectangle {
      id: rightTrace
      x: root.horizontalTraceX - rightViewport.x
      width: root.width * 0.3
      height: 1
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 0.5; color: colors_ ? colors_.ghostCyan : "#57d9cc" }
        GradientStop { position: 1.0; color: "transparent" }
      }
      opacity: root.config && root.config.reducedMotion ? 0.0 : 0.85
    }
  }

}
