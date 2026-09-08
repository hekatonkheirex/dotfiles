import QtQuick

// Two asymmetric signal-corruption fields tear inward from the central gap.
// Sparse deterministic bursts shift selected fragments while keeping the
// field static most of the time and in one canvas texture. The irregular
// cadence reads as signal damage without random state or constant rendering.
Item {
  id: root
  clip: true
  property QtObject colors_: null
  readonly property color cyan: colors_ ? colors_.ghostCyan : "#57d9cc"
  readonly property color voidColor: colors_ ? colors_.ghostVoid : "#05080a"
  property bool motionEnabled: true
  property int currentFrame: 0
  property int sequenceIndex: 0
  readonly property int frameCount: 6
  readonly property var glitchSequence: [
    { frame: 0, wait: 3800 },
    { frame: 4, wait: 70 }, { frame: 1, wait: 55 }, { frame: 5, wait: 90 },
    { frame: 0, wait: 4700 },
    { frame: 2, wait: 65 }, { frame: 5, wait: 75 }, { frame: 3, wait: 110 }, { frame: 1, wait: 60 },
    { frame: 0, wait: 2600 },
    { frame: 3, wait: 80 }, { frame: 5, wait: 55 }, { frame: 2, wait: 100 },
    { frame: 0, wait: 5900 },
    { frame: 1, wait: 60 }, { frame: 4, wait: 85 }, { frame: 2, wait: 65 }, { frame: 5, wait: 110 }
  ]

  // Wide 136x24 pixel-debris field. Large squares cluster at the panel edge,
  // then break into smaller fragments toward the clear center of the gap.
  readonly property var streaks: [
    { t: 1,  l: 0,   s: 6, c: "cyan",  o: 1.00 },
    { t: 8,  l: 1,   s: 7, c: "void",  o: 1.00 },
    { t: 17, l: 0,   s: 6, c: "cyan",  o: 1.00 },
    { t: 3,  l: 7,   s: 5, w: 36, h: 1, k: "tear", c: "white", o: 0.82 },
    { t: 11, l: 8,   s: 7, c: "cyan",  o: 1.00 },
    { t: 20, l: 8,   s: 4, c: "void",  o: 0.95 },
    { t: 0,  l: 14,  s: 5, c: "void",  o: 0.95 },
    { t: 6,  l: 15,  s: 6, w: 28, h: 2, k: "tear", c: "cyan",  o: 0.88 },
    { t: 15, l: 16,  s: 5, c: "white", o: 0.92 },
    { t: 2,  l: 22,  s: 4, w: 43, h: 1, k: "tear", c: "cyan",  o: 0.78 },
    { t: 9,  l: 23,  s: 6, c: "void",  o: 0.92 },
    { t: 18, l: 24,  s: 5, c: "cyan",  o: 0.88 },
    { t: 0,  l: 30,  s: 3, c: "white", o: 0.86 },
    { t: 5,  l: 31,  s: 5, w: 31, h: 1, k: "tear", c: "cyan",  o: 0.76 },
    { t: 13, l: 32,  s: 4, c: "void",  o: 0.84 },
    { t: 20, l: 34,  s: 3, c: "white", o: 0.80 },
    { t: 2,  l: 39,  s: 4, c: "void",  o: 0.80 },
    { t: 9,  l: 40,  s: 5, w: 37, h: 2, k: "tear", c: "cyan",  o: 0.70 },
    { t: 17, l: 41,  s: 4, c: "cyan",  o: 0.76 },
    { t: 0,  l: 47,  s: 3, c: "cyan",  o: 0.74 },
    { t: 6,  l: 48,  s: 4, w: 26, h: 1, k: "tear", c: "white", o: 0.66 },
    { t: 14, l: 49,  s: 5, c: "void",  o: 0.70 },
    { t: 21, l: 52,  s: 2, c: "cyan",  o: 0.68 },
    { t: 3,  l: 56,  s: 4, c: "cyan",  o: 0.66 },
    { t: 11, l: 57,  s: 3, w: 34, h: 2, k: "tear", c: "void",  o: 0.62 },
    { t: 18, l: 59,  s: 3, c: "white", o: 0.62 },
    { t: 0,  l: 65,  s: 2, c: "void",  o: 0.60 },
    { t: 6,  l: 65,  s: 3, w: 24, h: 1, k: "tear", c: "cyan",  o: 0.56 },
    { t: 14, l: 67,  s: 4, c: "cyan",  o: 0.56 },
    { t: 21, l: 70,  s: 2, c: "white", o: 0.54 },
    { t: 3,  l: 74,  s: 3, c: "white", o: 0.52 },
    { t: 10, l: 76,  s: 3, w: 29, h: 1, k: "tear", c: "void",  o: 0.48 },
    { t: 18, l: 78,  s: 2, c: "cyan",  o: 0.48 },
    { t: 1,  l: 84,  s: 2, c: "cyan",  o: 0.44 },
    { t: 7,  l: 86,  s: 3, w: 22, h: 2, k: "tear", c: "void",  o: 0.40 },
    { t: 15, l: 88,  s: 2, c: "white", o: 0.40 },
    { t: 21, l: 92,  s: 2, c: "cyan",  o: 0.36 },
    { t: 4,  l: 97,  s: 2, c: "void",  o: 0.34 },
    { t: 11, l: 100, s: 3, w: 27, h: 1, k: "tear", c: "cyan",  o: 0.30 },
    { t: 18, l: 104, s: 2, c: "white", o: 0.28 },
    { t: 1,  l: 109, s: 2, c: "cyan",  o: 0.24 },
    { t: 8,  l: 113, s: 2, c: "void",  o: 0.21 },
    { t: 16, l: 117, s: 2, c: "cyan",  o: 0.18 },
    { t: 4,  l: 122, s: 2, w: 12, h: 1, k: "tear", c: "white", o: 0.15 },
    { t: 12, l: 127, s: 2, c: "cyan",  o: 0.12 },
    { t: 20, l: 132, s: 2, c: "void",  o: 0.10 }
  ]
  // The right edge keeps the same 46-fragment density and falloff, but its
  // positions, sizes, and color cadence are independently composed. Avoiding
  // a literal mirror makes the break feel like signal damage, not ornament.
  readonly property var rightStreaks: [
    { t: 4,  l: 0,   s: 7, c: "cyan",  o: 1.00 },
    { t: 14, l: 1,   s: 6, c: "void",  o: 1.00 },
    { t: 20, l: 2,   s: 4, c: "white", o: 0.98 },
    { t: 0,  l: 8,   s: 5, c: "void",  o: 0.96 },
    { t: 9,  l: 9,   s: 7, c: "cyan",  o: 1.00 },
    { t: 18, l: 11,  s: 5, c: "cyan",  o: 0.96 },
    { t: 3,  l: 17,  s: 6, w: 40, h: 1, k: "tear", c: "white", o: 0.82 },
    { t: 13, l: 18,  s: 5, c: "void",  o: 0.94 },
    { t: 21, l: 20,  s: 3, c: "cyan",  o: 0.91 },
    { t: 1,  l: 25,  s: 5, w: 34, h: 2, k: "tear", c: "cyan",  o: 0.80 },
    { t: 10, l: 27,  s: 6, c: "void",  o: 0.90 },
    { t: 18, l: 29,  s: 4, c: "white", o: 0.87 },
    { t: 5,  l: 34,  s: 5, w: 39, h: 1, k: "tear", c: "cyan",  o: 0.76 },
    { t: 15, l: 35,  s: 4, c: "void",  o: 0.83 },
    { t: 0,  l: 38,  s: 3, c: "white", o: 0.82 },
    { t: 9,  l: 42,  s: 5, w: 28, h: 2, k: "tear", c: "cyan",  o: 0.72 },
    { t: 19, l: 43,  s: 4, c: "void",  o: 0.77 },
    { t: 3,  l: 48,  s: 4, w: 35, h: 1, k: "tear", c: "cyan",  o: 0.68 },
    { t: 12, l: 50,  s: 5, c: "white", o: 0.72 },
    { t: 21, l: 53,  s: 2, c: "void",  o: 0.69 },
    { t: 0,  l: 57,  s: 3, c: "cyan",  o: 0.67 },
    { t: 7,  l: 59,  s: 4, w: 31, h: 2, k: "tear", c: "void",  o: 0.62 },
    { t: 16, l: 61,  s: 3, c: "white", o: 0.63 },
    { t: 4,  l: 66,  s: 4, w: 25, h: 1, k: "tear", c: "cyan",  o: 0.57 },
    { t: 13, l: 68,  s: 3, c: "cyan",  o: 0.58 },
    { t: 21, l: 71,  s: 2, c: "void",  o: 0.55 },
    { t: 1,  l: 75,  s: 3, c: "white", o: 0.53 },
    { t: 9,  l: 78,  s: 3, w: 30, h: 1, k: "tear", c: "cyan",  o: 0.49 },
    { t: 18, l: 80,  s: 2, c: "void",  o: 0.48 },
    { t: 5,  l: 85,  s: 3, w: 23, h: 2, k: "tear", c: "cyan",  o: 0.43 },
    { t: 14, l: 87,  s: 2, c: "white", o: 0.43 },
    { t: 22, l: 90,  s: 2, c: "void",  o: 0.40 },
    { t: 2,  l: 94,  s: 3, c: "cyan",  o: 0.37 },
    { t: 11, l: 97,  s: 2, w: 28, h: 1, k: "tear", c: "void",  o: 0.34 },
    { t: 19, l: 99,  s: 3, c: "white", o: 0.32 },
    { t: 6,  l: 104, s: 2, w: 19, h: 1, k: "tear", c: "cyan",  o: 0.29 },
    { t: 15, l: 106, s: 2, c: "void",  o: 0.27 },
    { t: 1,  l: 110, s: 3, c: "cyan",  o: 0.24 },
    { t: 9,  l: 114, s: 2, c: "white", o: 0.21 },
    { t: 18, l: 116, s: 2, c: "cyan",  o: 0.19 },
    { t: 4,  l: 120, s: 2, w: 14, h: 1, k: "tear", c: "void",  o: 0.17 },
    { t: 13, l: 123, s: 2, c: "cyan",  o: 0.15 },
    { t: 21, l: 126, s: 2, c: "white", o: 0.13 },
    { t: 1,  l: 129, s: 2, c: "void",  o: 0.11 },
    { t: 10, l: 128, s: 2, w: 8, h: 1, k: "tear", c: "cyan",  o: 0.09 },
    { t: 18, l: 134, s: 2, c: "white", o: 0.08 }
  ]

  // Cross-axis carriers fill the underused middle and lower bands. These are
  // independent from the square field so their cadence stays intentionally
  // irregular instead of forming a decorative grid.
  readonly property var leftLineAccents: [
    { t: 13, l: 2,   w: 42, h: 1, a: "h", c: "cyan",  o: 0.62 },
    { t: 15, l: 18,  w: 55, h: 1, a: "h", c: "white", o: 0.54 },
    { t: 17, l: 6,   w: 31, h: 2, a: "h", c: "void",  o: 0.74 },
    { t: 19, l: 40,  w: 48, h: 1, a: "h", c: "cyan",  o: 0.48 },
    { t: 21, l: 12,  w: 66, h: 1, a: "h", c: "white", o: 0.42 },
    { t: 22, l: 75,  w: 28, h: 1, a: "h", c: "cyan",  o: 0.30 },
    { t: 14, l: 92,  w: 20, h: 1, a: "h", c: "void",  o: 0.34 },
    { t: 18, l: 112, w: 17, h: 1, a: "h", c: "cyan",  o: 0.19 },
    { t: 1,  l: 9,   w: 1,  h: 19, a: "v", c: "white", o: 0.72 },
    { t: 4,  l: 25,  w: 2,  h: 14, a: "v", c: "cyan",  o: 0.64 },
    { t: 8,  l: 39,  w: 1,  h: 15, a: "v", c: "void",  o: 0.78 },
    { t: 0,  l: 54,  w: 1,  h: 18, a: "v", c: "cyan",  o: 0.50 },
    { t: 10, l: 72,  w: 2,  h: 13, a: "v", c: "white", o: 0.38 },
    { t: 3,  l: 96,  w: 1,  h: 15, a: "v", c: "cyan",  o: 0.28 },
    { t: 12, l: 119, w: 1,  h: 10, a: "v", c: "white", o: 0.17 }
  ]
  readonly property var rightLineAccents: [
    { t: 14, l: 4,   w: 51, h: 1, a: "h", c: "white", o: 0.64 },
    { t: 16, l: 22,  w: 43, h: 2, a: "h", c: "cyan",  o: 0.58 },
    { t: 19, l: 8,   w: 34, h: 1, a: "h", c: "void",  o: 0.76 },
    { t: 21, l: 37,  w: 58, h: 1, a: "h", c: "cyan",  o: 0.46 },
    { t: 13, l: 61,  w: 38, h: 1, a: "h", c: "white", o: 0.40 },
    { t: 22, l: 81,  w: 33, h: 1, a: "h", c: "void",  o: 0.36 },
    { t: 17, l: 101, w: 25, h: 1, a: "h", c: "cyan",  o: 0.27 },
    { t: 20, l: 121, w: 13, h: 1, a: "h", c: "white", o: 0.16 },
    { t: 2,  l: 13,  w: 2,  h: 17, a: "v", c: "cyan",  o: 0.74 },
    { t: 6,  l: 31,  w: 1,  h: 16, a: "v", c: "white", o: 0.66 },
    { t: 0,  l: 47,  w: 1,  h: 19, a: "v", c: "void",  o: 0.80 },
    { t: 9,  l: 64,  w: 2,  h: 14, a: "v", c: "cyan",  o: 0.48 },
    { t: 4,  l: 83,  w: 1,  h: 16, a: "v", c: "white", o: 0.36 },
    { t: 11, l: 103, w: 1,  h: 12, a: "v", c: "cyan",  o: 0.26 },
    { t: 5,  l: 124, w: 1,  h: 13, a: "v", c: "white", o: 0.14 }
  ]
  readonly property int burstW: 136
  readonly property int burstH: 24
  // On narrow outputs, scale each burst to at most half the available gap so
  // the paired fields never overlap or escape into the bar content.
  readonly property real burstScale: Math.min(1, width / (2 * burstW))

  // Monochrome on purpose: a white fragment against the void reads as a dead
  // pixel, which breaks the "data dissolving toward center" read no matter
  // which way frameShift is pulling it. Cyan/void only keeps every fragment
  // legible as signal, never as display damage.
  function streakColor(c) { return c === "void" ? root.voidColor : root.cyan }
  function splitColor(c) { return c === "void" ? root.cyan : root.voidColor }

  function frameShift(index, mirrored) {
    if (!root.motionEnabled || root.currentFrame === 0)
      return 0
    const phase = (index * 3 + root.currentFrame * 5 + (mirrored ? 2 : 0)) % 11
    return phase < 2 ? (mirrored ? -1 : 1) * (1 + root.currentFrame % 3) : 0
  }

  function frameOpacity(index) {
    if (!root.motionEnabled || root.currentFrame === 0)
      return 1
    return (index + root.currentFrame * 2) % 13 === 0 ? 0.28 : 1
  }

  function paintRect(context, x, y, width, height, color, opacity) {
    context.globalAlpha = opacity
    context.fillStyle = color
    context.fillRect(x, y, width, height)
  }

  // Paint a complete burst into one cached scene-graph texture. Frame changes
  // are deterministic, bounded, and never allocate per-fragment QML objects.
  function paintBurst(context, fragments, mirrored) {
    for (let index = 0; index < fragments.length; index++) {
      const fragment = fragments[index]
      const fragmentWidth = fragment.w === undefined ? fragment.s : fragment.w
      const fragmentHeight = fragment.h === undefined ? fragment.s : fragment.h
      const baseX = mirrored ? root.burstW - fragment.l - fragmentWidth : fragment.l
      const fragmentX = baseX + root.frameShift(index, mirrored)
      const direction = ((index + (mirrored ? 1 : 0)) % 2 === 0) ? 1 : -1
      const frameOpacity = root.frameOpacity(index)
      const baseColor = root.streakColor(fragment.c)
      const echoColor = root.splitColor(fragment.c)

      if (fragment.k === "tear") {
        // A faint displaced carrier beneath each primary tear thickens the
        // cluster while keeping its hard horizontal cadence.
        root.paintRect(context, fragmentX + direction * (2 + index % 3), fragment.t + (index % 2),
                       Math.max(3, fragmentWidth - 4), 1, echoColor, fragment.o * frameOpacity * 0.42)
        root.paintRect(context, fragmentX, fragment.t, fragmentWidth, fragmentHeight,
                       baseColor, fragment.o * frameOpacity)
        continue
      }

      // Fixed signal split: a displaced one-pixel copy peels off every square.
      const sliceWidth = Math.max(2, fragmentWidth - 1)
      const sliceY = fragment.t + (index % Math.max(1, fragmentHeight))
      root.paintRect(context, fragmentX + direction * (2 + index % 3), sliceY,
                     sliceWidth, 1, echoColor, fragment.o * frameOpacity * 0.78)

      // The base block remains legible, then a void scan dropout removes a
      // middle strip and breaks the formerly pristine square silhouette.
      root.paintRect(context, fragmentX, fragment.t, fragmentWidth, fragmentHeight,
                     baseColor, fragment.o * frameOpacity)
      if (fragmentHeight >= 3) {
        const dropoutWidth = Math.max(2, Math.ceil(fragmentWidth * 0.62))
        const dropoutX = direction > 0 ? fragmentX : fragmentX + fragmentWidth - dropoutWidth
        root.paintRect(context, dropoutX, fragment.t + Math.floor(fragmentHeight / 2),
                       dropoutWidth, 1, root.voidColor, Math.min(1, fragment.o + 0.12))
      }

      // A detached carrier pixel binds nearby blocks into small glitch packets.
      const satelliteSize = fragment.s >= 5 && index % 3 === 0 ? 2 : 1
      root.paintRect(context,
                     fragmentX + direction * (fragmentWidth + 1 + index % 2),
                     fragment.t + ((index * 3) % Math.max(1, fragmentHeight)),
                     satelliteSize, 1, echoColor, fragment.o * frameOpacity * 0.66)
    }
    context.globalAlpha = 1
  }

  function paintAccents(context, accents, mirrored) {
    for (let index = 0; index < accents.length; index++) {
      const accent = accents[index]
      const baseX = mirrored ? root.burstW - accent.l - accent.w : accent.l
      const accentX = baseX + root.frameShift(index + 97, mirrored)
      const direction = ((index + (mirrored ? 1 : 0)) % 2 === 0) ? 1 : -1
      const frameOpacity = root.frameOpacity(index + 97)
      const baseColor = root.streakColor(accent.c)
      const echoColor = root.splitColor(accent.c)

      if (accent.a === "v") {
        root.paintRect(context, accentX + direction * 2, accent.t + 1, 1,
                       Math.max(2, accent.h - 3), echoColor, accent.o * frameOpacity * 0.40)
        root.paintRect(context, accentX, accent.t, accent.w, accent.h,
                       baseColor, accent.o * frameOpacity)
        root.paintRect(context, accentX - 1, accent.t + Math.floor(accent.h / 2),
                       accent.w + 2, 1, root.voidColor, Math.min(1, accent.o + 0.16))
      } else {
        root.paintRect(context, accentX + direction * 3, accent.t + 1,
                       Math.max(4, accent.w - 3), 1, echoColor, accent.o * frameOpacity * 0.38)
        root.paintRect(context, accentX, accent.t, accent.w, accent.h,
                       baseColor, accent.o * frameOpacity)
      }
    }
    context.globalAlpha = 1
  }

  Timer {
    interval: root.glitchSequence[root.sequenceIndex].wait
    repeat: true
    running: root.visible && root.motionEnabled && root.width > 0 && root.height > 0
    onTriggered: {
      root.sequenceIndex = (root.sequenceIndex + 1) % root.glitchSequence.length
      root.currentFrame = root.glitchSequence[root.sequenceIndex].frame
    }
  }

  onMotionEnabledChanged: {
    if (!motionEnabled) {
      sequenceIndex = 0
      currentFrame = 0
    }
  }

  Canvas {
    id: signalCanvas
    anchors.fill: parent
    antialiasing: false

    // Geometry, palette, and the bounded frame key are the only repaint inputs.
    property real scaleKey: root.burstScale
    property color cyanKey: root.cyan
    property color voidKey: root.voidColor
    property int frameKey: root.currentFrame
    onScaleKeyChanged: requestPaint()
    onCyanKeyChanged: requestPaint()
    onVoidKeyChanged: requestPaint()
    onFrameKeyChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
      const context = getContext("2d")
      context.clearRect(0, 0, width, height)
      const burstY = (height - root.burstH * root.burstScale) / 2

      context.save()
      context.translate(0, burstY)
      context.scale(root.burstScale, root.burstScale)
      root.paintBurst(context, root.streaks, false)
      root.paintAccents(context, root.leftLineAccents, false)
      context.restore()

      context.save()
      context.translate(width - root.burstW * root.burstScale, burstY)
      context.scale(root.burstScale, root.burstScale)
      root.paintBurst(context, root.rightStreaks, true)
      root.paintAccents(context, root.rightLineAccents, true)
      context.restore()
    }
  }
}
