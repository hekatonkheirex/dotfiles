pragma Singleton
import QtQuick
import Quickshell
import "../config"

QtObject {
    readonly property real mult: Settings.reduceMotion ? 0.4 : 1
    readonly property int fast: Math.round(140 * mult)
    readonly property int standard: Math.round(300 * mult)
    readonly property int morph: Math.round(420 * mult)
    readonly property int easeMorph: Easing.BezierSpline
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]
}
