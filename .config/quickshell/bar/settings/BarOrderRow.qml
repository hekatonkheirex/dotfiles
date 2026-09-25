import QtQuick
import QtQuick.Layouts
import "../"
import "../primitives"
import "../../config"
import "../../config/BarOrder.js" as BarOrder

ListItem {
  id: row
  required property var modelData
  readonly property string widgetId: modelData.id
  readonly property string savedOrder: BarOrder.normalize(Settings.barWidgetOrder).join(",")
  readonly property string widgetZone: modelData.zone
  readonly property bool middleActive: widgetZone === "middle"

  Layout.fillWidth: true
  leadingIcon: modelData.icon
  title: modelData.title
  subtitle: Settings[modelData.key]
    ? (widgetId === "clock" && !Settings.barClockInFlow
      ? "Theme default" : "Shown in bar")
    : "Hidden from bar"

  function movedOrder(direction) {
    return widgetId === "clock" && !Settings.barClockInFlow
      ? BarOrder.moveClock(Settings.barWidgetOrder, direction, widgetZone)
      : BarOrder.move(Settings.barWidgetOrder, widgetId, direction,
          Settings.barClockInFlow)
  }

  function move(direction) {
    var next = movedOrder(direction)
    if (next === savedOrder) return
    Settings.barWidgetOrder = next
    if (widgetId === "clock") Settings.barClockInFlow = true
    Settings.save()
  }

  function placeMiddle() {
    var target = middleActive ? "end" : "middle"
    var next = BarOrder.moveToZone(Settings.barWidgetOrder, widgetId, target)
    Settings.barWidgetOrder = next
    if (widgetId === "clock") Settings.barClockInFlow = true
    Settings.save()
  }
  ActionButton {
    iconLabel: "arrow_upward"
    iconSize: 18
    variant: "text"
    width: 32
    height: 32
    enabled: row.movedOrder(-1) !== row.savedOrder
    accessibleName: "Move " + row.title + " toward start"
    tooltipText: accessibleName
    onActivated: row.move(-1)
  }

  ActionButton {
    iconLabel: "arrow_downward"
    iconSize: 18
    variant: "text"
    width: 32
    height: 32
    enabled: row.movedOrder(1) !== row.savedOrder
    accessibleName: "Move " + row.title + " toward end"
    tooltipText: accessibleName
    onActivated: row.move(1)
  }
  ActionButton {
    iconLabel: row.middleActive ? "east" : "center_focus_strong"
    iconSize: 18
    variant: "text"
    selected: row.middleActive
    width: 32
    height: 32
    accessibleName: row.middleActive
      ? "Move " + row.title + " to end"
      : "Move " + row.title + " to middle"
    tooltipText: accessibleName
    onActivated: row.placeMiddle()
  }

  SwitchControl {
    checked: Settings[row.modelData.key]
    activeColor: Colors.primary
    surfaceContainerHigh: Colors.surfaceContainerHigh
    surfaceContainerHighest: Colors.surfaceContainerHighest
    outline: Colors.styleOutlineStrong
    motionDuration: Config.motionMedium
    reducedMotion: Config.reducedMotion
    accessibleName: "Show " + row.title
    onToggled: {
      Settings[row.modelData.key] = !Settings[row.modelData.key]
      Settings.save()
    }
  }
}
