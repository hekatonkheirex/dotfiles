## Commits
c3cc6b4e Fork IconButton, ListItem, TextFieldControl, ActionButton into pill/components/

## Diffstat
 .../quickshell/pill/components/ActionButton.qml    | 101 ++++++++++++++
 .config/quickshell/pill/components/IconButton.qml  |  90 +++++++++++++
 .config/quickshell/pill/components/ListItem.qml    | 146 +++++++++++++++++++++
 .../pill/components/TextFieldControl.qml           | 106 +++++++++++++++
 4 files changed, 443 insertions(+)

## Full diff
diff --git a/.config/quickshell/pill/components/ActionButton.qml b/.config/quickshell/pill/components/ActionButton.qml
new file mode 100644
index 00000000..43940091
--- /dev/null
+++ b/.config/quickshell/pill/components/ActionButton.qml
@@ -0,0 +1,101 @@
+// Forked from bar/primitives/ActionButton.qml (identical apart from import
+// paths). Cross-root import is impossible under 'qs -p'; see
+// docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in sync
+// until bar/ is retired.
+import QtQuick
+import QtQuick.Controls
+import "../config"
+
+Rectangle {
+  id: root
+
+  property string iconLabel: ""
+  property bool selected: false
+  property string labelText: ""
+  property string variant: "tonal"
+  property string accessibleName: ""
+  property string accessibleDescription: ""
+  property string tooltipText: ""
+  readonly property bool filled: root.selected || root.variant === "filled"
+  property real iconSize: Config.iconSize + 4
+  property color iconColor: root.filled ? Colors.fgPrimary : Colors.fgSurfaceVariant
+
+  signal activated()
+
+  radius: 20
+  activeFocusOnTab: true
+  opacity: root.enabled ? 1.0 : 0.38
+
+  readonly property bool hovered: mouseArea.containsMouse
+  readonly property bool pressed: mouseArea.pressed
+
+  Accessible.role: Accessible.Button
+  Accessible.name: root.accessibleName !== ""
+    ? root.accessibleName
+    : (root.labelText !== "" ? root.labelText : (root.tooltipText !== "" ? root.tooltipText : root.iconLabel))
+  Accessible.description: root.accessibleDescription !== ""
+    ? root.accessibleDescription
+    : (root.selected ? "Selected" : "")
+
+  color: {
+    var overlay = mouseArea.pressed ? Colors.pressOverlay
+      : (mouseArea.containsMouse ? Colors.hoverOverlay
+        : (root.activeFocus ? Colors.focusOverlay : Qt.rgba(0, 0, 0, 0)))
+    var base = root.filled
+      ? Colors.primary
+      : (root.variant === "quiet" ? "transparent" : Colors.surfaceContainer)
+    return Qt.tint(base, overlay)
+  }
+  border.color: root.filled || root.variant === "quiet"
+    ? "transparent"
+    : (root.variant === "outlined"
+      ? Colors.outline
+      : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.15))
+  border.width: 1
+
+  Behavior on color {
+    ColorAnimation { duration: Config.animationDuration }
+  }
+
+  Keys.onPressed: function(event) {
+    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
+      root.activated()
+      event.accepted = true
+    }
+  }
+
+  Column {
+    anchors.centerIn: parent
+    spacing: root.labelText !== "" ? 2 : 0
+
+    Text {
+      anchors.horizontalCenter: parent.horizontalCenter
+      text: root.iconLabel
+      color: root.iconColor
+      font.family: Config.iconFont
+      font.pixelSize: root.iconSize
+    }
+
+    Text {
+      visible: root.labelText !== ""
+      anchors.horizontalCenter: parent.horizontalCenter
+      text: root.labelText
+      color: root.iconColor
+      font.family: Config.fontFamily
+      font.pixelSize: Config.fontPixelSize
+      font.weight: Font.Medium
+    }
+  }
+
+  MouseArea {
+    id: mouseArea
+    anchors.fill: parent
+    hoverEnabled: true
+    enabled: root.enabled
+    cursorShape: Qt.PointingHandCursor
+    onClicked: {
+      root.forceActiveFocus()
+      root.activated()
+    }
+  }
+}
diff --git a/.config/quickshell/pill/components/IconButton.qml b/.config/quickshell/pill/components/IconButton.qml
new file mode 100644
index 00000000..eef37c3b
--- /dev/null
+++ b/.config/quickshell/pill/components/IconButton.qml
@@ -0,0 +1,90 @@
+// Forked from bar/primitives/IconButton.qml (identical apart from import
+// paths). Cross-root import is impossible under 'qs -p'; see
+// docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in sync
+// until bar/ is retired.
+import QtQuick
+import QtQuick.Controls
+import "../config"
+
+Item {
+  id: root
+
+  property string iconLabel: ""
+  property int size: 32
+  property int iconSize: 18
+  property color iconColor: Colors.fgSurface
+  property color hoverColor: Qt.tint("transparent", Colors.hoverOverlay)
+  property color pressColor: Qt.tint("transparent", Colors.pressOverlay)
+  property color backgroundColor: "transparent"
+  property color borderColor: Colors.outlineVariant
+  property bool outlined: false
+  property bool enabled: true
+  property bool selected: false
+  property string accessibleName: ""
+  property string accessibleDescription: ""
+  property string tooltipText: ""
+
+  signal clicked(var mouse)
+  signal wheel(var wheel)
+
+  implicitWidth: size
+  implicitHeight: size
+  activeFocusOnTab: root.enabled
+  opacity: root.enabled ? 1.0 : 0.38
+
+  readonly property bool hovered: mouseArea.containsMouse
+  readonly property bool pressed: mouseArea.pressed
+
+  Accessible.role: Accessible.Button
+  Accessible.name: root.accessibleName !== ""
+    ? root.accessibleName
+    : (root.tooltipText !== "" ? root.tooltipText : root.iconLabel)
+  Accessible.description: root.accessibleDescription !== ""
+    ? root.accessibleDescription
+    : (root.selected ? "Selected" : "")
+
+  Keys.onPressed: function(event) {
+    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
+      root.clicked(null)
+      event.accepted = true
+    }
+  }
+
+  Rectangle {
+    anchors.fill: parent
+    radius: root.size / 2
+    color: !root.enabled ? "transparent"
+      : root.selected ? Qt.tint(Colors.primaryContainer, root.pressColor)
+      : (mouseArea.pressed ? root.pressColor
+        : (mouseArea.containsMouse ? root.hoverColor
+          : (root.activeFocus ? Colors.focusOverlay : root.backgroundColor)))
+    border.width: root.outlined ? 1 : 0
+    border.color: root.borderColor
+
+    Behavior on color {
+      ColorAnimation { duration: Config.animationDuration }
+    }
+  }
+
+  Text {
+    anchors.centerIn: parent
+    text: root.iconLabel
+    color: root.iconColor
+    opacity: root.enabled ? 1.0 : 0.38
+    font.family: Config.iconFont
+    font.pixelSize: root.iconSize
+  }
+
+  MouseArea {
+    id: mouseArea
+    anchors.fill: parent
+    hoverEnabled: true
+    enabled: root.enabled
+    cursorShape: Qt.PointingHandCursor
+    onClicked: function(mouse) {
+      root.forceActiveFocus()
+      root.clicked(mouse)
+    }
+    onWheel: function(wheelEvent) { root.wheel(wheelEvent) }
+  }
+}
diff --git a/.config/quickshell/pill/components/ListItem.qml b/.config/quickshell/pill/components/ListItem.qml
new file mode 100644
index 00000000..3ac45015
--- /dev/null
+++ b/.config/quickshell/pill/components/ListItem.qml
@@ -0,0 +1,146 @@
+// Forked from bar/primitives/ListItem.qml (identical apart from import
+// paths). Cross-root import is impossible under 'qs -p'; see
+// docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in sync
+// until bar/ is retired.
+import QtQuick
+import QtQuick.Layouts
+import "../config"
+
+Rectangle {
+  id: root
+
+  default property alias trailingContent: trailingRow.data
+
+  property string leadingIcon: ""
+  property real leadingIconOpacity: 1.0
+  property string leadingImageSource: ""
+  property string leadingFallbackText: ""
+  property string title: ""
+  property string subtitle: ""
+  property bool selected: false
+  property color leadingIconColor: root.selected ? Colors.primary : Colors.fgSurface
+  property string accessibleName: ""
+  property string accessibleDescription: ""
+  readonly property bool hovered: itemMouse.containsMouse
+  readonly property bool pressed: itemMouse.pressed
+
+  signal clicked(var mouse)
+
+  height: 44
+  radius: Config.shapeMedium
+  activeFocusOnTab: root.enabled
+  opacity: root.enabled ? 1.0 : 0.38
+
+  Accessible.role: Accessible.ListItem
+  Accessible.name: root.accessibleName !== "" ? root.accessibleName : root.title
+  Accessible.description: root.accessibleDescription !== ""
+    ? root.accessibleDescription
+    : (root.selected ? root.subtitle + " Selected" : root.subtitle)
+
+  Keys.onPressed: function(event) {
+    if (root.enabled && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
+      root.clicked(null)
+      event.accepted = true
+    }
+  }
+  color: {
+    if (root.selected) return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
+    if (itemMouse.containsMouse) return Qt.tint("transparent", Colors.hoverOverlay)
+    return root.activeFocus ? Qt.tint("transparent", Colors.focusOverlay) : "transparent"
+  }
+  border.color: root.selected ? Colors.primary : "transparent"
+  border.width: 1
+
+  Behavior on color {
+    ColorAnimation { duration: Config.animationDuration }
+  }
+
+  MouseArea {
+    id: itemMouse
+    anchors.fill: parent
+    hoverEnabled: true
+    enabled: root.enabled
+    cursorShape: Qt.PointingHandCursor
+    onClicked: function(mouse) {
+      root.forceActiveFocus()
+      root.clicked(mouse)
+    }
+  }
+
+  RowLayout {
+    anchors.fill: parent
+    anchors.leftMargin: 8
+    anchors.rightMargin: 8
+    spacing: 10
+
+    Text {
+      visible: root.leadingIcon !== "" && root.leadingImageSource === ""
+      text: root.leadingIcon
+      color: root.leadingIconColor
+      opacity: root.leadingIconOpacity
+      font.family: Config.iconFont
+      font.pixelSize: 22
+    }
+
+    Rectangle {
+      visible: root.leadingImageSource !== "" || root.leadingFallbackText !== ""
+      width: 30
+      height: 30
+      radius: 15
+      color: Colors.surfaceContainerHigh
+
+      Image {
+        anchors.centerIn: parent
+        width: 20
+        height: 20
+        source: root.leadingImageSource
+        sourceSize.width: 20
+        sourceSize.height: 20
+        smooth: true
+        fillMode: Image.PreserveAspectFit
+        visible: root.leadingImageSource !== ""
+      }
+
+      Text {
+        anchors.centerIn: parent
+        text: root.leadingFallbackText
+        color: Colors.fgSurface
+        font.family: Config.fontFamily
+        font.pixelSize: 14
+        font.weight: Font.Medium
+        visible: root.leadingImageSource === "" && root.leadingFallbackText !== ""
+      }
+    }
+
+    ColumnLayout {
+      Layout.fillWidth: true
+      spacing: 0
+
+      Text {
+        Layout.fillWidth: true
+        text: root.title
+        color: root.selected ? Colors.primary : Colors.fgSurface
+        font.family: Config.fontFamily
+        font.pixelSize: (Config.fontPixelSize + 3)
+        font.weight: Font.Medium
+        elide: Text.ElideRight
+      }
+
+      Text {
+        Layout.fillWidth: true
+        visible: root.subtitle !== ""
+        text: root.subtitle
+        color: Colors.fgSurfaceVariant
+        font.family: Config.fontFamily
+        font.pixelSize: Config.fontPixelSize
+        elide: Text.ElideRight
+      }
+    }
+
+    Row {
+      id: trailingRow
+      spacing: 4
+      Layout.alignment: Qt.AlignVCenter
+    }
+  }
+}
diff --git a/.config/quickshell/pill/components/TextFieldControl.qml b/.config/quickshell/pill/components/TextFieldControl.qml
new file mode 100644
index 00000000..cfacee39
--- /dev/null
+++ b/.config/quickshell/pill/components/TextFieldControl.qml
@@ -0,0 +1,106 @@
+// Forked from bar/primitives/TextFieldControl.qml (identical apart from
+// import paths). Cross-root import is impossible under 'qs -p'; see
+// docs/superpowers/plans/2026-08-09-pill-shell-foundation.md. Keep in sync
+// until bar/ is retired.
+import QtQuick
+import QtQuick.Layouts
+import "../config"
+
+Rectangle {
+  id: root
+
+  property alias text: input.text
+  property string placeholder: ""
+  property int echoMode: TextInput.Normal
+  property alias input: input
+  property string accessibleName: ""
+  property string accessibleDescription: ""
+  property bool showPlaceholderOnFocus: false
+  property bool captureHorizontalArrows: false
+  property string leadingIcon: ""
+  property color leadingIconColor: Colors.fgSurfaceVariant
+  property real leadingIconSize: 22
+
+  default property alias trailingContent: trailingRow.data
+
+  signal accepted()
+  signal escapePressed()
+  signal upPressed()
+  signal downPressed()
+  signal leftPressed()
+  signal rightPressed()
+
+  height: 36
+  radius: 8
+  color: Colors.surface
+  border.color: input.activeFocus ? Colors.primary : Colors.outline
+  border.width: input.activeFocus ? 2 : 1
+
+  RowLayout {
+    anchors {
+      fill: parent
+      leftMargin: 10
+      rightMargin: 10
+    }
+    spacing: 8
+
+    Text {
+      visible: root.leadingIcon !== ""
+      text: root.leadingIcon
+      color: root.leadingIconColor
+      font.family: Config.iconFont
+      font.pixelSize: root.leadingIconSize
+      Layout.alignment: Qt.AlignVCenter
+    }
+
+    TextInput {
+      id: input
+      Layout.fillWidth: true
+      Layout.fillHeight: true
+      verticalAlignment: TextInput.AlignVCenter
+      color: Colors.fgSurface
+      font.family: Config.fontFamily
+      font.pixelSize: Config.fontPixelSize + 2
+      echoMode: root.echoMode
+      activeFocusOnTab: true
+      Accessible.role: Accessible.EditableText
+      Accessible.name: root.accessibleName !== ""
+        ? root.accessibleName
+        : (root.placeholder !== "" ? root.placeholder : "Text field")
+      Accessible.description: root.accessibleDescription
+      Keys.onPressed: function(event) {
+        if (event.key === Qt.Key_Escape) {
+          root.escapePressed()
+          event.accepted = true
+        } else if (event.key === Qt.Key_Up) {
+          root.upPressed()
+          event.accepted = true
+        } else if (event.key === Qt.Key_Down) {
+          root.downPressed()
+          event.accepted = true
+        } else if (event.key === Qt.Key_Left && root.captureHorizontalArrows) {
+          root.leftPressed()
+          event.accepted = true
+        } else if (event.key === Qt.Key_Right && root.captureHorizontalArrows) {
+          root.rightPressed()
+          event.accepted = true
+        }
+      }
+      onAccepted: root.accepted()
+
+      Text {
+        text: root.placeholder
+        color: Colors.fgSurfaceVariant
+        visible: !parent.text && (!parent.activeFocus || root.showPlaceholderOnFocus)
+        font: parent.font
+        anchors.verticalCenter: parent.verticalCenter
+      }
+    }
+
+    Row {
+      id: trailingRow
+      spacing: 4
+      Layout.alignment: Qt.AlignVCenter
+    }
+  }
+}
