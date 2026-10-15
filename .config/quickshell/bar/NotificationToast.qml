import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import "../config"
import "../config/ToastModel.js" as ToastModel
import "primitives"

// Her dunst notifications (R6b): a stack of up to five cards at the top
// right. Each card is `xbg` in a solid frame, a glyph then the summary on the
// first row and a muted glyph then the body on the second, colored by urgency
// (low x6, normal x2, critical x1). Same text twice stacks with a count.
// Left click closes, middle click runs the default action then closes, right
// click closes every card. App actions keep their buttons. Delivery, history,
// DND and quiet hours stay in shell.qml; there is no history store.
PanelWindow {
  id: root

  property QtObject notificationServer: null
  property int displayMs: Settings.notificationToastDurationMs   // normal urgency
  property int nextUid: 1
  property var objs: ({})        // uid -> Notification

  readonly property int pad: Config.dp(22)
  readonly property int textPx: Math.round(12 * 4 / 3 * Config.elenaScale)
  readonly property int glyphPx: Math.round(21 / 18 * root.textPx)
  readonly property int count: stack.count

  implicitWidth: Math.min(Config.dp(700), Math.max(Config.dp(280), column.implicitWidth))
  implicitHeight: column.implicitHeight
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: Config.layerNamespace("toast")
  WlrLayershell.layer: WlrLayer.Top
  anchors.right: true
  anchors.top: Settings.notificationToastPosition !== "bottom-right"
  anchors.bottom: Settings.notificationToastPosition === "bottom-right"
  margins.right: Config.dp(20)
  margins.top: Settings.notificationToastPosition === "bottom-right" ? 0 : Config.dp(20)
  // Bottom placement clears the elena bottom bar's right cluster.
  margins.bottom: Settings.notificationToastPosition === "bottom-right"
    ? Config.spacingLarge + Config.bottomBarHeight
    : 0
  visible: stack.count > 0

  ListModel { id: stack }
  readonly property alias stackColumn: column   // render checks grab this

  function keys() {
    var out = []
    for (var i = 0; i < stack.count; i++) out.push(stack.get(i).key)
    return out
  }

  function indexOfUid(uid) {
    for (var i = 0; i < stack.count; i++) if (stack.get(i).uid === uid) return i
    return -1
  }

  // `release`: the card goes without a user action (timeout, overflow, DND),
  // so the notification is expired and untracked; there is no history store.
  function removeUid(uid, release) {
    var i = root.indexOfUid(uid)
    if (i < 0) return
    var n = root.objs[uid]
    stack.remove(i)
    delete root.objs[uid]
    if (release && n) n.expire()
  }

  function expiryFor(n) {
    var ms = ToastModel.timeoutMs(n.urgency, n.expireTimeout, root.displayMs)
    return ms > 0 ? Date.now() + ms : 0
  }

  // Called by shell.qml for every notification that is not suppressed.
  function show(n) {
    if (Settings.doNotDisturb
        && !(Settings.notificationCriticalBypass && n && n.urgency === NotificationUrgency.Critical)) return
    var key = ToastModel.keyFor(n.appName || "", n.summary || "", n.body || "")
    var p = ToastModel.plan(root.keys(), key, ToastModel.LIMIT)
    if (p.action === "bump") {
      var row = stack.get(p.index)
      root.objs[row.uid] = n
      stack.setProperty(p.index, "count", row.count + 1)
      stack.setProperty(p.index, "urgency", n.urgency)
      stack.setProperty(p.index, "expiresAt", root.expiryFor(n))
      root.watch(n, row.uid)
      return
    }
    for (var d = 0; d < p.drop; d++) {
      root.removeUid(stack.get(0).uid, true)
    }
    var uid = root.nextUid++
    root.objs[uid] = n
    stack.append({
      uid: uid, key: key, count: 1, appName: n.appName || "", summary: n.summary || "",
      body: n.body || "", urgency: n.urgency, expiresAt: root.expiryFor(n)
    })
    root.watch(n, uid)
  }

  function watch(n, uid) {
    n.closed.connect(function() {
      var i = root.indexOfUid(uid)
      if (i >= 0 && root.objs[uid] === n) root.removeUid(uid)
    })
  }

  // DND hides the toast surface without dismissing the notifications; they
  // remain available in the history popup.
  function suppress() {
    var uids = []
    for (var i = 0; i < stack.count; i++) uids.push(stack.get(i).uid)
    for (var j = 0; j < uids.length; j++) root.removeUid(uids[j], true)
  }

  function dismissUid(uid) {
    var n = root.objs[uid]
    root.removeUid(uid)
    if (n) n.dismiss()
  }

  function activateUid(uid) {
    var n = root.objs[uid]
    var list = n && n.actions ? n.actions : []
    var action = null
    for (var i = 0; i < list.length; i++) if (list[i].identifier === "default") action = list[i]
    root.removeUid(uid)
    if (action) action.invoke()
    else if (n) n.dismiss()
  }

  function closeAll() {
    var uids = []
    for (var i = 0; i < stack.count; i++) uids.push(stack.get(i).uid)
    for (var j = 0; j < uids.length; j++) root.dismissUid(uids[j])
  }

  Timer {
    interval: 250
    repeat: true
    running: stack.count > 0
    onTriggered: {
      var now = Date.now()
      for (var i = stack.count - 1; i >= 0; i--) {
        var at = stack.get(i).expiresAt
        if (at > 0 && at <= now) root.removeUid(stack.get(i).uid, true)
      }
    }
  }

  Column {
    id: column
    width: parent.width
    spacing: Config.dp(10)

    Repeater {
      model: stack
      delegate: Rectangle {
        id: card
        required property int uid
        required property int count
        required property string summary
        required property string body
        required property string appName
        required property int urgency

        readonly property color tint: Colors.elenaAccent(ToastModel.urgencySlot(card.urgency))
        readonly property var actionList: {
          var n = root.objs[card.uid]
          var out = []
          var list = n && n.actions ? n.actions : []
          for (var i = 0; i < list.length && out.length < 3; i++)
            if (list[i].identifier !== "default") out.push(list[i])
          return out
        }

        objectName: "toast_" + uid
        width: column.width
        implicitWidth: Math.max(summaryRow.implicitWidth, bodyRow.implicitWidth) + 2 * (root.pad + Config.dp(8))
        height: content.implicitHeight + 2 * (root.pad + Config.dp(8))
        radius: Config.dp(18)
        color: Colors.surface
        border.width: Config.dp(8)
        border.color: Colors.surfaceContainer

        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity {
          enabled: !Config.reducedMotion
          NumberAnimation { duration: 150 }
        }

        Accessible.role: Accessible.Button
        Accessible.name: card.appName + ": " + card.summary
        Accessible.description: "Dismiss notification"

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onClicked: function(m) {
            if (m.button === Qt.RightButton) root.closeAll()
            else if (m.button === Qt.MiddleButton) root.activateUid(card.uid)
            else root.dismissUid(card.uid)
          }
        }

        Column {
          id: content
          x: root.pad + Config.dp(8)
          y: root.pad + Config.dp(8)
          width: card.width - 2 * (root.pad + Config.dp(8))
          spacing: Config.dp(6)

          Row {
            id: summaryRow
            width: parent.width
            spacing: Config.dp(10)
            Text {
              id: summaryGlyph
              objectName: "summaryGlyph"
              text: "\ue944"
              color: card.tint
              font.family: BottomBarFonts.family
              font.pixelSize: root.glyphPx
            }
            Text {
              objectName: "summaryText"
              width: parent.width - summaryGlyph.width - parent.spacing
              text: ToastModel.title(card.summary, card.count)
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: root.textPx
              elide: Text.ElideMiddle
              maximumLineCount: 1
            }
          }

          Row {
            id: bodyRow
            width: parent.width
            spacing: Config.dp(10)
            visible: card.body !== ""
            Text {
              id: bodyGlyph
              objectName: "bodyGlyph"
              text: "\ue90d"
              color: Colors.elenaAccent(8)
              font.family: BottomBarFonts.family
              font.pixelSize: root.glyphPx
            }
            Text {
              objectName: "bodyText"
              width: parent.width - bodyGlyph.width - parent.spacing
              text: card.body
              color: Colors.fgSurface
              font.family: Config.fontFamily
              font.pixelSize: root.textPx
              wrapMode: Text.WordWrap
              maximumLineCount: 3
              elide: Text.ElideRight
            }
          }

          // App-defined actions; "default" is the middle-click action.
          Row {
            id: actionRow
            width: parent.width
            spacing: Config.spacingSmall
            visible: card.actionList.length > 0
            Repeater {
              model: card.actionList
              delegate: ActionButton {
                required property var modelData
                height: implicitHeight
                width: Math.max(72, (actionRow.width - actionRow.spacing * (card.actionList.length - 1)) / card.actionList.length)
                labelText: modelData.text
                horizontalContent: true
                variant: "tonal"
                accessibleName: modelData.text
                accessibleDescription: "Notification action"
                onActivated: {
                  // invoke() can synchronously close the notification and destroy this delegate.
                  var toast = root
                  var uid = card.uid
                  modelData.invoke()
                  toast.removeUid(uid, true)
                }
              }
            }
          }
        }
      }
    }
  }
}
