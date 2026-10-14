import QtQuick
import "../../config"
import "../../config/NetworkList.js" as NetworkList

// Window-less body of her networks window: the 4-row network list (or the
// empty state), the inline passphrase or forget confirmation row, the
// bandwidth row and the toolbar. The host (NetworksWindow) feeds the model
// and texts and acts on the signals; the render stage drives it directly.
Item {
  id: root
  property var networksModel: []
  property bool scanning: false
  property string pingText: "ping"
  property bool vpnOn: false
  property string downText: ""
  property string upText: ""
  property string passphraseFor: ""
  property string forgetFor: ""

  signal connectRequested(string name, string password)
  signal disconnectRequested()
  signal forgetConfirmed(string name)
  signal scanRequested()
  signal speedtestRequested()
  signal pingRequested()
  signal vpnRequested()
  signal dismissRequested()

  readonly property int count: root.networksModel ? root.networksModel.length : 0
  readonly property int inner: width - 2 * Config.dp(14)

  // Saved or open networks connect directly; a new secured one asks first.
  function requestConnect(net) {
    root.forgetFor = ""
    if (net.secure && !net.saved) root.passphraseFor = net.name
    else { root.passphraseFor = ""; root.connectRequested(net.name, "") }
  }

  implicitWidth: Config.dp(300)
  implicitHeight: body.implicitHeight
  focus: true
  Keys.onEscapePressed: {
    if (root.forgetFor !== "") root.forgetFor = ""
    else if (root.passphraseFor !== "") root.passphraseFor = ""
    else root.dismissRequested()
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.MiddleButton
    onClicked: root.dismissRequested()
  }

  Column {
    id: body
    width: parent.width
    topPadding: Config.dp(14)
    bottomPadding: Config.dp(14)
    spacing: Config.dp(14)

    Rectangle {
      id: listFrame
      objectName: "listFrame"
      x: Config.dp(14)
      width: root.inner
      height: 4 * Config.dp(60)
      radius: Config.dp(8)
      color: Colors.surfaceContainer
      clip: true

      ListView {
        anchors.fill: parent
        model: root.networksModel
        boundsBehavior: Flickable.StopAtBounds
        delegate: NetworkRow {
          required property var modelData
          required property int index
          objectName: "row_" + index
          width: ListView.view.width
          name: modelData.name
          signal: modelData.signal
          active: modelData.active
          saved: modelData.saved
          onConnectClicked: root.requestConnect(modelData)
          onDisconnectClicked: root.disconnectRequested()
          // Hiding a focused passphrase row drops focus: take it back so Esc works.
          onForgetClicked: { root.passphraseFor = ""; root.forgetFor = modelData.name; root.forceActiveFocus() }
        }
      }

      Column {
        objectName: "emptyState"
        anchors.centerIn: parent
        visible: root.count === 0
        spacing: Config.dp(14)
        Text {
          objectName: "emptySymbol"
          anchors.horizontalCenter: parent.horizontalCenter
          text: ""
          color: Colors.elenaAccent(8)
          font.family: BottomBarFonts.family
          font.pixelSize: Math.round(50 * 4 / 3 * Config.elenaScale)   // 50pt
        }
        Text {
          objectName: "emptyText"
          anchors.horizontalCenter: parent.horizontalCenter
          text: "No networks found"
          color: Colors.elenaAccent(8)
          font.family: Config.fontFamily
          font.pixelSize: Math.round(12 * 4 / 3 * Config.elenaScale)   // 12pt
        }
      }
    }

    PassphraseRow {
      objectName: "passphraseRow"
      x: Config.dp(14)
      width: root.inner
      visible: root.passphraseFor !== ""
      name: root.passphraseFor
      onSubmitted: function(password) {
        var name = root.passphraseFor
        root.passphraseFor = ""
        root.forceActiveFocus()
        root.connectRequested(name, password)
      }
      onCancelled: { root.passphraseFor = ""; root.forceActiveFocus() }
    }

    Rectangle {
      id: forgetRow
      objectName: "forgetRow"
      x: Config.dp(14)
      width: root.inner
      height: Config.dp(44)
      radius: Config.dp(8)
      color: Colors.surfaceContainer
      visible: root.forgetFor !== ""
      Text {
        anchors.left: parent.left
        anchors.leftMargin: Config.dp(11)
        anchors.verticalCenter: parent.verticalCenter
        text: "forget " + NetworkList.shortName(root.forgetFor) + "?"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Math.round(8 * 4 / 3 * Config.elenaScale)
      }
      Row {
        anchors.right: parent.right
        anchors.rightMargin: Config.dp(6)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.dp(6)
        Repeater {
          model: ["yes", "no"]
          Rectangle {
            id: choice
            required property string modelData
            objectName: choice.modelData === "yes" ? "forgetYes" : "forgetNo"
            width: Config.dp(40)
            height: Config.dp(32)
            radius: Config.dp(14)
            color: Colors.surface
            Text {
              objectName: "label"
              anchors.centerIn: parent
              text: choice.modelData
              color: Colors.elenaAccent(choice.modelData === "yes" ? 1 : 8)
              font.family: Config.fontFamily
              font.pixelSize: Math.round(10 * 4 / 3 * Config.elenaScale)
              font.weight: Font.Bold
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                var name = root.forgetFor
                root.forgetFor = ""
                if (choice.modelData === "yes") root.forgetConfirmed(name)
              }
            }
          }
        }
      }
    }

    BandwidthRow {
      x: Config.dp(14)
      width: root.inner
      downText: root.downText
      upText: root.upText
    }

    Row {
      id: toolbar
      anchors.horizontalCenter: parent.horizontalCenter
      height: Config.dp(66)
      spacing: Config.dp(6)
      readonly property int buttonWidth: Math.min(Config.dp(64), Math.floor((root.inner - 3 * spacing) / 4))
      ToolbarButton {
        objectName: "tool_vpn"
        width: toolbar.buttonWidth; height: parent.height
        glyph: ""
        accent: root.vpnOn ? 4 : 8
        label: "vpn " + (root.vpnOn ? "on" : "off")
        onClicked: root.vpnRequested()
      }
      ToolbarButton {
        objectName: "tool_scan"
        width: toolbar.buttonWidth; height: parent.height
        glyph: ""
        accent: 2
        loading: root.scanning
        label: root.count + " net" + (root.count !== 1 ? "s" : "")
        onClicked: root.scanRequested()
      }
      ToolbarButton {
        objectName: "tool_speed"
        width: toolbar.buttonWidth; height: parent.height
        glyph: ""
        accent: 5
        label: "speedtest"
        onClicked: root.speedtestRequested()
      }
      ToolbarButton {
        objectName: "tool_ping"
        width: toolbar.buttonWidth; height: parent.height
        glyph: ""
        accent: 3
        label: root.pingText
        onClicked: root.pingRequested()
      }
    }
  }
}
