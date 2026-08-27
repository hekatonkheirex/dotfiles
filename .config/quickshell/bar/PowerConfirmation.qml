import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"

FocusScope {
  id: root

  property bool opened: false
  property string actionLabel: ""
  property string actionDescription: ""
  property string actionIcon: ""

  readonly property bool material3Theme: !Config.nothingDesign && !Config.neoBrutalism && !Config.ghostTheme
  property color scrimColor: Qt.rgba(Colors.scrim.r, Colors.scrim.g, Colors.scrim.b,
    root.material3Theme ? 0.32 : 0.24)
  property color dialogColor: Config.neoBrutalism || Config.nothingDesign || Config.ghostTheme
    ? Colors.styleSurface
    : Colors.surfaceContainerHigh
  property color dialogTextColor: Colors.fgSurface
  property color dialogSecondaryTextColor: Colors.fgSurfaceVariant
  property color dialogBorderColor: root.material3Theme ? Colors.outlineVariant : Colors.styleOutline
  property color cancelColor: root.material3Theme ? "transparent" : Colors.surfaceContainer
  property color cancelTextColor: root.material3Theme ? Colors.primary : Colors.fgSurface
  property color confirmColor: Colors.error
  property color confirmTextColor: Colors.fgError
  property int focusedButton: 0
  readonly property int dialogPadding: root.material3Theme ? 24 : 16
  readonly property int dialogSpacing: root.material3Theme ? 16 : 12
  readonly property int dialogRadius: root.material3Theme
    ? Config.shapeLarge + Config.spacingSmall
    : Config.shapeLarge
  readonly property int dialogButtonHeight: root.material3Theme ? 40 : 38

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
    x: dialog.x + (Config.neoBrutalism ? Config.themeShadowOffset : 0)
    y: dialog.y + (Config.neoBrutalism ? Config.themeShadowOffset : 2)
    width: dialog.width
    height: dialog.height
    radius: dialog.radius
    color: root.material3Theme
      ? Qt.rgba(Colors.shadow.r, Colors.shadow.g, Colors.shadow.b, 0.18)
      : Colors.styleShadow
    visible: root.material3Theme || Config.neoBrutalism
    z: 1
  }

  Rectangle {
    id: dialog
    anchors.centerIn: parent
    width: Math.min(root.material3Theme ? 360 : 300,
      Math.max(root.material3Theme ? 280 : 220,
        root.width - (root.material3Theme ? 48 : 32)))
    height: dialogContent.implicitHeight + root.dialogPadding * 2
    radius: root.dialogRadius
    color: root.dialogColor
    border.width: Config.themeBorderWidth
    border.color: root.dialogBorderColor
    z: 2

    Column {
      id: dialogContent
      anchors.fill: parent
      anchors.margins: root.dialogPadding
      spacing: root.dialogSpacing

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
          font.variableAxes: Config.iconVariableAxes(0, 24)
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          width: parent.width - (root.actionIcon !== "" ? 38 : 0)
          text: root.actionLabel !== "" ? "Confirm " + root.actionLabel + "?" : "Confirm power action"
          color: root.dialogTextColor
          font.family: Config.fontFamily
          font.pixelSize: Config.typeTitleLargeSize
          font.weight: root.material3Theme ? Config.typeMediumWeight : Config.typeStrongWeight
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
          visible: root.material3Theme
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          Layout.preferredWidth: 0
          Layout.preferredHeight: 1
        }

        Rectangle {
          id: cancelButton
          Layout.fillWidth: !root.material3Theme
          Layout.minimumWidth: 0
          Layout.preferredWidth: root.material3Theme
            ? Math.max(80, cancelLabel.implicitWidth + Config.spacingPage)
            : 1
          implicitHeight: root.dialogButtonHeight
          height: root.dialogButtonHeight
          radius: root.material3Theme ? height / 2 : Config.shapeMedium
          activeFocusOnTab: true
          color: {
            var overlay = cancelMouse.pressed ? Colors.pressOverlay
              : (cancelMouse.containsMouse ? Colors.hoverOverlay
                : Qt.rgba(0, 0, 0, 0))
            return Qt.tint(root.material3Theme ? "transparent" : root.cancelColor, overlay)
          }
          border.width: root.material3Theme
            ? (root.focusedButton === 0 ? Config.themeFocusBorderWidth : 0)
            : (root.focusedButton === 0 ? Config.themeFocusBorderWidth : Config.themeBorderWidth)
          border.color: root.material3Theme
            ? Colors.primary
            : (root.focusedButton === 0 ? Colors.tertiary : root.dialogBorderColor)

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
            font.weight: root.material3Theme ? Config.typeMediumWeight
              : (root.focusedButton === 0 ? Config.typeStrongWeight : Config.typeMediumWeight)
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
          Layout.fillWidth: !root.material3Theme
          Layout.minimumWidth: 0
          Layout.preferredWidth: root.material3Theme
            ? Math.max(88, confirmLabel.implicitWidth + Config.spacingPage)
            : 1
          implicitHeight: root.dialogButtonHeight
          height: root.dialogButtonHeight
          radius: root.material3Theme ? height / 2 : Config.shapeMedium
          activeFocusOnTab: true
          color: {
            var overlay = confirmMouse.pressed ? Colors.pressOverlay
              : (confirmMouse.containsMouse ? Colors.hoverOverlay
                : Qt.rgba(0, 0, 0, 0))
            return Qt.tint(root.material3Theme ? Colors.errorContainer : root.confirmColor, overlay)
          }
          border.width: root.material3Theme
            ? (root.focusedButton === 1 ? Config.themeFocusBorderWidth : 0)
            : (root.focusedButton === 1 ? Config.themeFocusBorderWidth : Config.themeBorderWidth)
          border.color: root.material3Theme
            ? Colors.primary
            : (root.focusedButton === 1 ? Colors.tertiary : root.confirmColor)

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
            color: root.material3Theme ? Colors.fgErrorContainer : root.confirmTextColor
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelLargeSize
            font.weight: root.material3Theme ? Config.typeMediumWeight
              : (root.focusedButton === 1 ? Config.typeStrongWeight : Config.typeMediumWeight)
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
    }
  }
}
