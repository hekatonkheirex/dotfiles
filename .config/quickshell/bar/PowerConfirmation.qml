import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "primitives"

FocusScope {
  id: root

  property bool opened: false
  property string actionLabel: ""
  property string actionDescription: ""
  property string actionIcon: ""

  property color scrimColor: Qt.rgba(Colors.scrim.r, Colors.scrim.g, Colors.scrim.b,
    0.32)
  property color dialogColor: Colors.surface
  property color dialogTextColor: Colors.fgSurface
  property color dialogSecondaryTextColor: Colors.fgSurfaceVariant
  property color dialogBorderColor: Colors.outlineVariant
  property color cancelColor: "transparent"
  property color cancelTextColor: Colors.primary
  property color confirmColor: Colors.error
  property color confirmTextColor: Colors.fgError
  property int focusedButton: 0
  readonly property int dialogPadding: 24
  readonly property int dialogSpacing: 16
  readonly property int dialogRadius: (Config.shapeLarge + Config.spacingSmall)
  readonly property int dialogButtonHeight: Config.controlHitSize

  signal confirmed()
  signal cancelled()

  function focusButton(index) {
    root.focusedButton = index === 0 ? 0 : 1
    var button = root.focusedButton === 0 ? cancelButton : confirmButton
    button.forceActiveFocus()
  }

  function activateButton(index) {
    if (index === 0) root.cancelled()
    else root.confirmed()
  }

  function handleButtonKey(index, event) {
    if (event.key === Qt.Key_Left || event.key === Qt.Key_Right
        || event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
      root.focusButton(index === 0 ? 1 : 0)
      event.accepted = true
    } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return
        || event.key === Qt.Key_Enter) {
      root.activateButton(index)
      event.accepted = true
    } else if (event.key === Qt.Key_Escape) {
      root.cancelled()
      event.accepted = true
    }
  }

  visible: root.opened
  z: 100
  focus: root.opened
  activeFocusOnTab: root.opened

  Accessible.role: Accessible.Dialog
  Accessible.name: root.actionLabel !== "" ? "Confirm " + root.actionLabel : "Confirm power action"
  Accessible.description: root.actionDescription

  onOpenedChanged: {
    if (root.opened) {
      root.focusButton(0)
      focusRequestTimer.restart()
    } else {
      focusRequestTimer.stop()
    }
  }

  Timer {
    id: focusRequestTimer
    interval: 50
    repeat: false
    onTriggered: {
      if (root.opened) root.focusButton(root.focusedButton)
    }
  }

  Keys.priority: Keys.BeforeItem
  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Escape) {
      root.cancelled()
      event.accepted = true
    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right
        || event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
      root.focusButton(root.focusedButton === 0 ? 1 : 0)
      event.accepted = true
    } else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return
        || event.key === Qt.Key_Enter) {
      root.activateButton(root.focusedButton)
      event.accepted = true
    }
  }

  Rectangle {
    anchors.fill: parent
    color: root.scrimColor

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      onClicked: root.cancelled()
    }
  }


  Rectangle {
    id: dialog
    anchors.centerIn: parent
    width: Math.min(360,
      Math.max(280,
        root.width - (48)))
    height: dialogContent.implicitHeight + root.dialogPadding * 2
    radius: root.dialogRadius
    color: root.dialogColor
    DashedFrame {
      anchors.fill: parent
      active: root.opened
      radius: dialog.radius
      strokeColor: root.dialogBorderColor
    }
    z: 2


    Column {
      id: dialogContent
      anchors.fill: parent
      anchors.margins: root.dialogPadding
      spacing: root.dialogSpacing

      Text {
        width: parent.width
        text: "/ CONFIRM ACTION /"
        color: root.dialogSecondaryTextColor
        font.family: "monospace"
        font.pixelSize: Config.typeLabelSmallSize
        font.letterSpacing: Config.typeMonoTracking
      }

      Row {
        width: parent.width
        spacing: root.actionIcon !== "" ? 10 : 0

        IconGlyph {
          visible: root.actionIcon !== ""
          iconLabel: root.actionIcon
          iconColor: root.confirmColor
          iconSize: 24
          width: visible ? 28 : 0
          height: 28
        }

        Text {
          width: parent.width - (root.actionIcon !== "" ? 38 : 0)
          text: root.actionLabel !== "" ? "Confirm " + root.actionLabel + "?" : "Confirm power action"
          color: root.dialogTextColor
          font.family: Config.fontFamily
          font.pixelSize: Config.typeTitleLargeSize
          font.weight: Config.typeMediumWeight
          font.letterSpacing: Config.typeTitleTracking
          lineHeight: Config.typeTitleLargeLineHeight
          lineHeightMode: Text.FixedHeight
          wrapMode: Text.WordWrap
        }
      }

      Text {
        width: parent.width
        text: root.actionDescription !== ""
          ? root.actionDescription
          : "This action will take effect immediately."
        color: root.dialogSecondaryTextColor
        font.family: Config.fontFamily
        font.pixelSize: Config.typeBodyLargeSize
        font.letterSpacing: Config.typeBodyTracking
        lineHeight: Config.typeBodyLargeLineHeight
        lineHeightMode: Text.FixedHeight
        wrapMode: Text.WordWrap
      }

      RowLayout {
        id: actionRow
        width: parent.width
        spacing: Config.spacingSmall

        Item {
          visible: true
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          Layout.preferredWidth: 0
          Layout.preferredHeight: 1
        }

        Rectangle {
          id: cancelButton
          Layout.fillWidth: false
          Layout.minimumWidth: 0
          Layout.preferredWidth: Math.max(80, cancelLabel.implicitWidth + Config.spacingPage)
          implicitHeight: root.dialogButtonHeight
          height: root.dialogButtonHeight
          radius: (height / 2)
          activeFocusOnTab: true
          color: {
            var overlay = cancelMouse.pressed ? Colors.pressOverlay
              : (cancelMouse.containsMouse ? Colors.hoverOverlay
                : Qt.rgba(0, 0, 0, 0))
            return Qt.tint("transparent", overlay)
          }
          border.width: (root.focusedButton === 0 ? Config.themeFocusBorderWidth : 0)
          border.color: Colors.primary

          Accessible.role: Accessible.Button
          Accessible.name: "Cancel"

          Keys.onPressed: function(event) {
            root.handleButtonKey(0, event)
          }

          onActiveFocusChanged: {
            if (activeFocus) root.focusedButton = 0
          }

          Text {
            id: cancelLabel
            anchors.centerIn: parent
            text: "Cancel"
            color: root.cancelTextColor
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelLargeSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
          }

          MouseArea {
            id: cancelMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.focusButton(0)
              root.activateButton(0)
            }
          }
        }

        Rectangle {
          id: confirmButton
          Layout.fillWidth: false
          Layout.minimumWidth: 0
          Layout.preferredWidth: Math.max(88, confirmLabel.implicitWidth + Config.spacingPage)
          implicitHeight: root.dialogButtonHeight
          height: root.dialogButtonHeight
          radius: (height / 2)
          activeFocusOnTab: true
          color: {
            var overlay = confirmMouse.pressed ? Colors.pressOverlay
              : (confirmMouse.containsMouse ? Colors.hoverOverlay
                : Qt.rgba(0, 0, 0, 0))
            return Qt.tint(Colors.errorContainer, overlay)
          }
          border.width: (root.focusedButton === 1 ? Config.themeFocusBorderWidth : 0)
          border.color: Colors.primary

          Accessible.role: Accessible.Button
          Accessible.name: root.actionLabel !== "" ? root.actionLabel : "Confirm"

          Keys.onPressed: function(event) {
            root.handleButtonKey(1, event)
          }

          onActiveFocusChanged: {
            if (activeFocus) root.focusedButton = 1
          }

          Text {
            id: confirmLabel
            anchors.centerIn: parent
            text: root.actionLabel !== "" ? root.actionLabel : "Confirm"
            color: Colors.fgErrorContainer
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelLargeSize
            font.weight: Config.typeMediumWeight
            font.letterSpacing: Config.typeLabelTracking
            elide: Text.ElideRight
            width: parent.width - 12
            horizontalAlignment: Text.AlignHCenter
          }

          MouseArea {
            id: confirmMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.focusButton(1)
              root.activateButton(1)
            }
          }
        }
      }

      Text {
        width: parent.width
        text: "ESC CANCEL · TAB CHOOSE"
        color: root.dialogSecondaryTextColor
        font.family: "monospace"
        font.pixelSize: Config.typeLabelSmallSize
        font.letterSpacing: Config.typeMonoTracking
        wrapMode: Text.Wrap
      }
    }
  }
}
