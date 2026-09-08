import QtQuick

// Solid panel segments with a pixel-stepped silhouette at the transparent
// center gap. This is a hard alpha cut, not a fade: the wallpaper stays sharp
// while the bar and glitch field interlock instead of meeting on a ruler line.
Item {
  id: root

  property color panelColor: "#0d1418"
  property real gapStart: 0
  property real gapEnd: 0
  readonly property real transitionDepth: 20
  readonly property real gapWidth: Math.max(0, gapEnd - gapStart)
  readonly property real edgeScale: Math.min(1, gapWidth / (2 * transitionDepth))

  // Positive offsets push the panel into the gap. Negative offsets bite
  // transparent pixels back into the panel. Grouped rows keep the edge
  // blocky and intentional rather than noisy or antialiased.
  readonly property var leftProfile: [
     8,  8, 14, 14,  4,  4,  4, -3, -3, 18, 18, 10,
    10,  2,  2, 12, 12, 12, -5, -5,  6,  6, 16, 16,
     7,  7,  0,  0, 11, 11,  3,  3,  8,  8
  ]
  readonly property var rightProfile: [
     5,  5, -4, -4, 12, 12, 12,  3,  3, 17, 17,  7,
     7,  0,  0, 14, 14,  6,  6, -3, -3, 10, 10, 10,
     2,  2, 16, 16,  5,  5,  9,  9,  1,  1
  ]

  function profileOffset(profile, y) {
    const index = Math.min(profile.length - 1,
                           Math.floor(y * profile.length / Math.max(1, height)))
    return profile[index] * edgeScale
  }

  Canvas {
    id: panelCanvas
    anchors.fill: parent
    antialiasing: false

    property color colorKey: root.panelColor
    property real startKey: root.gapStart
    property real endKey: root.gapEnd
    property real scaleKey: root.edgeScale
    onColorKeyChanged: requestPaint()
    onStartKeyChanged: requestPaint()
    onEndKeyChanged: requestPaint()
    onScaleKeyChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
      const context = getContext("2d")
      context.clearRect(0, 0, width, height)
      context.fillStyle = root.panelColor

      for (let y = 0; y < height; y++) {
        const leftEdge = Math.max(0, Math.min(width,
          Math.round(root.gapStart + root.profileOffset(root.leftProfile, y))))
        const rightEdge = Math.max(0, Math.min(width,
          Math.round(root.gapEnd - root.profileOffset(root.rightProfile, y))))
        context.fillRect(0, y, leftEdge, 1)
        context.fillRect(rightEdge, y, width - rightEdge, 1)
      }
    }
  }
}
