import QtQuick
import "../../config"
import "../../config/Alarms.js" as Alarms

// Window-less body of her alarms window: the two expanding "ring in" / "ring
// at" buttons with the cancel/confirm row on the left, the time-step buttons,
// and the label/time/label info block. States as hers: select-type (browse),
// select-time-quick, select-time-standard. The host feeds `alarmsModel`
// ([{at, label}], sorted) and acts on the signals; the render stage drives it.
Item {
  id: root
  property var alarmsModel: []
  property string state: "select-type"
  property var input: Alarms.emptyState()
  property int index: 0

  signal confirmed(string mode, var input)
  signal deleteRequested(int index)
  signal dismissRequested()

  readonly property int count: root.alarmsModel ? root.alarmsModel.length : 0
  readonly property bool selecting: root.state === "select-time-quick" || root.state === "select-time-standard"
  readonly property var current: root.count > 0 && root.index < root.count ? root.alarmsModel[root.index] : null
  readonly property bool field_hours: root.selecting && root.input.field === "hours"
  readonly property bool field_minutes: root.selecting && root.input.field === "minutes"
  readonly property bool field_label: root.selecting && root.input.field === "label"
  readonly property bool noAlarms: root.count === 0 && !root.selecting

  function reset() {
    root.state = "select-type"
    root.input = Alarms.emptyState()
    root.index = 0
  }

  function begin(newState) {
    root.input = Alarms.emptyState()
    root.state = newState
  }

  function cancel() { root.state = "select-type" }

  function confirm() {
    if (!root.selecting) return
    var mode = root.state === "select-time-quick" ? "quick" : "standard"
    if (mode === "quick" && Alarms.totalMinutes(root.input) === 0) return
    root.confirmed(mode, root.input)
    root.state = "select-type"
    root.index = 0
  }

  function step(delta) {
    if (root.selecting) root.input = Alarms.stepMinutes(root.input, delta)
  }

  // Clicking a field selects it and puts the keyboard on the content.
  function selectField(f) {
    if (!root.selecting) return
    root.input = { field: f, hours: root.input.hours, minutes: root.input.minutes, label: root.input.label }
    root.forceActiveFocus()
  }

  function key(k) { root.input = Alarms.applyKey(root.input, k) }

  // Her list returns to the first alarm whenever it changes.
  onCountChanged: root.index = 0

  implicitWidth: Config.dp(300)
  implicitHeight: Config.dp(14) * 2 + Config.dp(112)
  focus: true

  Keys.onPressed: function(e) {
    if (e.key === Qt.Key_Escape) {
      if (root.selecting) root.cancel()
      else root.dismissRequested()
      e.accepted = true
      return
    }
    if (!root.selecting) return
    e.accepted = true
    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.confirm()
    else if (e.key === Qt.Key_Tab) root.key("tab")
    else if (e.key === Qt.Key_Backtab) root.key("s-tab")
    else if (e.key === Qt.Key_Backspace) root.key((e.modifiers & Qt.ControlModifier) ? "c-backspace" : "backspace")
    else if (e.text.length === 1) root.key(e.text)
    else e.accepted = false
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.MiddleButton
    onClicked: root.dismissRequested()
  }

  Row {
    id: body
    x: Config.dp(14)
    y: Config.dp(14)
    width: parent.width - Config.dp(14)
    height: parent.height - 2 * Config.dp(14)
    spacing: Config.dp(14)

    // Left column: quick, cancel/confirm, standard.
    Column {
      id: controls
      width: Config.dp(48)
      height: parent.height

      AlarmButton {
        objectName: "btn_quick"
        width: parent.width
        height: (parent.height - expander.height) / 2
        glyph: "\ue9a0"
        accent: 3
        glyphPt: 12
        dim: root.state === "select-time-standard"
        onClicked: root.begin("select-time-quick")
      }

      Item {
        id: expander
        objectName: "expander"
        width: parent.width
        height: root.selecting ? Config.dp(32) : Config.dp(19)
        Behavior on height {
          enabled: !Config.reducedMotion
          NumberAnimation { duration: 200 }
        }
        Row {
          anchors.centerIn: parent
          spacing: Config.dp(6)
          AlarmButton {
            objectName: "btn_cancel"
            width: (controls.width - Config.dp(6)) / 2
            height: root.selecting ? Config.dp(20) : Config.dp(7)
            enabled: root.selecting
            glyph: "\uea47"
            glyphPt: root.selecting ? 11 : 1
            fill: root.selecting ? Colors.elenaAccent(1) : Colors.elenaAccent(8)
            opacity: 1
            Behavior on height {
              enabled: !Config.reducedMotion
              NumberAnimation { duration: 200 }
            }
            label.color: root.selecting ? Colors.surface : "transparent"
            onClicked: root.cancel()
          }
          AlarmButton {
            objectName: "btn_confirm"
            width: (controls.width - Config.dp(6)) / 2
            height: root.selecting ? Config.dp(20) : Config.dp(7)
            enabled: root.selecting
            glyph: "\uea37"
            glyphPt: root.selecting ? 11 : 1
            fill: root.selecting ? Colors.elenaAccent(2) : Colors.elenaAccent(8)
            Behavior on height {
              enabled: !Config.reducedMotion
              NumberAnimation { duration: 200 }
            }
            label.color: root.selecting ? Colors.surface : "transparent"
            onClicked: root.confirm()
          }
        }
      }

      AlarmButton {
        objectName: "btn_standard"
        width: parent.width
        height: (parent.height - expander.height) / 2
        glyph: "\uef07"
        accent: 3
        glyphPt: 12
        dim: root.state === "select-time-quick"
        onClicked: root.begin("select-time-standard")
      }
    }

    // Right: side buttons and info block.
    Row {
      width: parent.width - controls.width - parent.spacing
      height: parent.height

      Item {
        id: side
        width: Config.dp(34) + Config.dp(10)
        height: parent.height

        Column {   // browse: previous, delete, next
          objectName: "nav"
          visible: root.state === "select-type"
          width: Config.dp(34)
          height: parent.height
          spacing: Config.dp(4)
          readonly property real h: (height - 2 * spacing) / 3
          AlarmButton {
            objectName: "btn_prev"
            width: parent.width; height: parent.h
            glyph: "\ue923"
            accent: 6
            dim: root.count <= 1 || root.index === 0
            onClicked: if (!dim) root.index = root.index - 1
          }
          AlarmButton {
            objectName: "btn_delete"
            width: parent.width; height: parent.h
            glyph: "\ueecb"
            accent: 1
            dim: root.count === 0
            onClicked: if (!dim) root.deleteRequested(root.index)
          }
          AlarmButton {
            objectName: "btn_next"
            width: parent.width; height: parent.h
            glyph: "\ue920"
            accent: 6
            dim: root.count <= 1 || root.index === root.count - 1
            onClicked: if (!dim) root.index = root.index + 1
          }
        }

        Column {   // ring in: +1 +5 +10 +60
          objectName: "quickSteps"
          visible: root.state === "select-time-quick"
          width: Config.dp(34)
          height: parent.height
          spacing: Config.dp(6)
          Repeater {
            model: [1, 5, 10, 60]
            AlarmButton {
              required property int modelData
              objectName: "step_plus_" + modelData
              width: parent.width
              height: (parent.height - 3 * parent.spacing) / 4
              text: "+" + modelData
              accent: 6
              onClicked: root.step(modelData)
            }
          }
        }

        Column {   // ring at: -h +h -m +m
          objectName: "standardSteps"
          visible: root.state === "select-time-standard"
          width: Config.dp(34)
          height: parent.height
          spacing: Config.dp(6)
          Repeater {
            model: [{ t: "-h", d: -60 }, { t: "+h", d: 60 }, { t: "-m", d: -1 }, { t: "+m", d: 1 }]
            AlarmButton {
              required property var modelData
              objectName: "step_" + (modelData.d < 0 ? "minus_" : "plus_") + Math.abs(modelData.d)
              width: parent.width
              height: (parent.height - 3 * parent.spacing) / 4
              text: modelData.t
              accent: 6
              onClicked: root.step(modelData.d)
            }
          }
        }
      }

      Column {
        id: info
        width: parent.width - side.width
        height: parent.height
        spacing: Config.dp(6)

        Item { width: 1; height: (parent.height - topLabel.height - preview.height - bottomLabel.height - 2 * parent.spacing) / 2 }

        Text {
          id: topLabel
          objectName: "topLabel"
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.state === "select-time-standard" ? "ring at"
              : root.state === "select-time-quick" ? "ring in"
              : root.count === 0 ? "no alarms" : "next up"
          color: Colors.elenaAccent(8)
          font.family: Config.fontFamily
          font.pixelSize: Math.round(10 * 4 / 3 * Config.elenaScale)
        }

        Row {
          id: preview
          anchors.horizontalCenter: parent.horizontalCenter
          readonly property int px: Math.round(20 * 4 / 3 * Config.elenaScale)
          Text {
            objectName: "hour"
            text: root.selecting ? Alarms.previewHours(root.input)
                : root.current ? Alarms.formatHM(root.current.at).slice(0, 2) : "--"
            color: root.field_hours ? Colors.elenaAccent(3) : root.noAlarms ? Colors.elenaAccent(8) : Colors.fgSurface
            font.family: "monospace"; font.bold: true; font.pixelSize: preview.px
            MouseArea {
              anchors.fill: parent
              enabled: root.selecting
              onClicked: root.selectField("hours")
              onWheel: function(w) { root.step(w.angleDelta.y > 0 ? -60 : 60) }
            }
          }
          Text {
            objectName: "separator"
            text: root.state === "select-time-quick" ? "h" : ":"
            color: root.noAlarms ? Colors.elenaAccent(8) : Colors.elenaAccent(3)
            font.family: "monospace"; font.bold: true; font.pixelSize: preview.px
          }
          Text {
            objectName: "minute"
            text: root.selecting ? Alarms.previewMinutes(root.input)
                : root.current ? Alarms.formatHM(root.current.at).slice(3, 5) : "--"
            color: root.field_minutes ? Colors.elenaAccent(3) : root.noAlarms ? Colors.elenaAccent(8) : Colors.fgSurface
            font.family: "monospace"; font.bold: true; font.pixelSize: preview.px
            MouseArea {
              anchors.fill: parent
              enabled: root.selecting
              onClicked: root.selectField("minutes")
              onWheel: function(w) { root.step(w.angleDelta.y > 0 ? -1 : 1) }
            }
          }
        }

        Text {
          id: bottomLabel
          objectName: "bottomLabel"
          anchors.horizontalCenter: parent.horizontalCenter
          width: Math.min(implicitWidth, parent.width)
          elide: Text.ElideRight
          horizontalAlignment: Text.AlignHCenter
          readonly property bool placeholder: root.selecting && root.input.label.length === 0 && !root.field_label
          text: root.selecting ? (placeholder ? "e.g. gym" : root.input.label + (root.field_label && cursorOn ? "|" : root.field_label ? " " : ""))
              : root.current ? root.current.label : "all clear"
          property bool cursorOn: true
          color: root.field_label ? Colors.elenaAccent(3) : placeholder || root.noAlarms ? Colors.elenaAccent(8) : Colors.fgSurface
          font.family: "monospace"; font.bold: true
          font.pixelSize: Math.round(10 * 4 / 3 * Config.elenaScale)
          MouseArea {
            objectName: "labelHit"
            anchors.centerIn: parent
            width: info.width
            height: parent.height + Config.dp(10)
            enabled: root.selecting
            cursorShape: Qt.IBeamCursor
            onClicked: root.selectField("label")
          }
          Timer {
            running: root.field_label && !Config.reducedMotion
            repeat: true
            interval: 500
            onTriggered: bottomLabel.cursorOn = !bottomLabel.cursorOn
            onRunningChanged: if (!running) bottomLabel.cursorOn = true
          }
        }
      }
    }
  }
}
