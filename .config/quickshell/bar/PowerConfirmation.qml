import QtQuick
import QtQuick.Controls
import "../config"

FocusScope {
  id: root

  property bool opened: false
  property string actionLabel: ""
  property string actionDescription: ""
  property string actionIcon: ""

  property color scrimColor: Qt.rgba(0, 0, 0, 0.24)
  property color dialogColor: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme
    ? Colors.styleSurface
    : Colors.surfaceContainerHigh
  property color dialogTextColor: Colors.fgSurface
  property color dialogSecondaryTextColor: Colors.fgSurfaceVariant
  property color dialogBorderColor: Colors.styleOutline
  property color cancelColor: Colors.surfaceContainer
  property color cancelTextColor: Colors.fgSurface
  property color confirmColor: Colors.error
  property color confirmTextColor: Colors.fgError
  property int focusedButton: 0

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
    id: dialogShadow
    x: dialog.x + Config.themeShadowOffset
    y: dialog.y + Config.themeShadowOffset
    width: dialog.width
    height: dialog.height
    radius: dialog.radius
    color: Colors.styleShadow
    visible: Config.neoBrutalism
    z: -1
  }

  Rectangle {
    id: dialog
    anchors.centerIn: parent
    width: Math.min(300, Math.max(220, root.width - 32))
    height: dialogContent.implicitHeight + 32
    radius: Config.shapeLarge
    color: root.dialogColor
    border.width: Config.themeBorderWidth
    border.color: root.dialogBorderColor

    Column {
      id: dialogContent
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      Row {
        width: parent.width
        spacing: root.actionIcon !== "" ? 10 : 0

        Text {
          visible: root.actionIcon !== ""
          width: visible ? 28 : 0
          height: 28
          text: root.actionIcon
          color: root.confirmColor
          font.family: Config.iconFont
          font.pixelSize: 24
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          width: parent.width - (root.actionIcon !== "" ? 38 : 0)
          text: root.actionLabel !== "" ? "Confirm " + root.actionLabel + "?" : "Confirm power action"
          color: root.dialogTextColor
          font.family: Config.fontFamily
          font.pixelSize: Config.fontPixelSize + 6
          font.weight: Font.Bold
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
        font.pixelSize: Config.fontPixelSize + 2
        wrapMode: Text.WordWrap
      }

      Row {
        id: actionRow
        width: parent.width
        spacing: 8

        Rectangle {
          id: cancelButton
          width: (actionRow.width - actionRow.spacing) / 2
          height: 38
          radius: Config.shapeMedium
          activeFocusOnTab: true
          color: {
            var overlay = cancelMouse.pressed ? Colors.pressOverlay
              : (cancelMouse.containsMouse ? Colors.hoverOverlay
                : Qt.rgba(0, 0, 0, 0))
            return Qt.tint(root.cancelColor, overlay)
          }
          border.width: root.focusedButton === 0 ? Config.themeFocusBorderWidth : Config.themeBorderWidth
          border.color: root.focusedButton === 0 ? Colors.tertiary : root.dialogBorderColor

          Accessible.role: Accessible.Button
          Accessible.name: "Cancel"

          Keys.onPressed: function(event) {
            root.handleButtonKey(0, event)
          }

          onActiveFocusChanged: {
            if (activeFocus) root.focusedButton = 0
          }

          Text {
            anchors.centerIn: parent
            text: "Cancel"
            color: root.cancelTextColor
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize + 2
            font.weight: root.focusedButton === 0 ? Font.Bold : Font.Medium
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
          width: (actionRow.width - actionRow.spacing) / 2
          height: 38
          radius: Config.shapeMedium
          activeFocusOnTab: true
          color: {
            var overlay = confirmMouse.pressed ? Colors.pressOverlay
              : (confirmMouse.containsMouse ? Colors.hoverOverlay
                : Qt.rgba(0, 0, 0, 0))
            return Qt.tint(root.confirmColor, overlay)
          }
          border.width: root.focusedButton === 1 ? Config.themeFocusBorderWidth : Config.themeBorderWidth
          border.color: root.focusedButton === 1 ? Colors.tertiary : root.confirmColor

          Accessible.role: Accessible.Button
          Accessible.name: root.actionLabel !== "" ? root.actionLabel : "Confirm"

          Keys.onPressed: function(event) {
            root.handleButtonKey(1, event)
          }

          onActiveFocusChanged: {
            if (activeFocus) root.focusedButton = 1
          }

          Text {
            anchors.centerIn: parent
            text: root.actionLabel !== "" ? root.actionLabel : "Confirm"
            color: root.confirmTextColor
            font.family: Config.fontFamily
            font.pixelSize: Config.fontPixelSize + 2
            font.weight: root.focusedButton === 1 ? Font.Bold : Font.Medium
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
    }
  }
}
