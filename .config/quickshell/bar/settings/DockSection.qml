import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../primitives"
import "../../config"
import "../../config/DockModel.js" as DockModel

// Pinned-apps editor for the Elena dock. Every edit writes the CSV through
// DockModel.pinnedToCsv (Settings only normalizes on file load).
ColumnLayout {
  id: root
  objectName: "Dock pinned apps"
  Layout.fillWidth: true
  spacing: Config.spacingCompact

  readonly property var pinned: DockModel.normalizePinned(Settings.dockPinned)
  readonly property string query: addField.text.trim().toLowerCase()
  readonly property int maxResults: 6

  // Reading .values.length re-runs this when the desktop database finishes loading.
  readonly property var apps: DesktopEntries.applications.values.length >= 0
    ? DesktopEntries.applications.values : []

  function lookup(appId) {
    return DesktopEntries.applications.values.length >= 0
      ? DesktopEntries.heuristicLookup(appId) : null
  }

  function write(list) {
    Settings.dockPinned = DockModel.pinnedToCsv(list)
    Settings.save()
  }

  function move(index, delta) {
    var list = root.pinned.slice()
    var to = index + delta
    if (to < 0 || to >= list.length) return
    var item = list.splice(index, 1)[0]
    list.splice(to, 0, item)
    root.write(list)
  }

  function remove(index) {
    var list = root.pinned.slice()
    list.splice(index, 1)
    root.write(list)
  }

  function guessAppId(entry) {
    // Reverse-DNS ids (com.obsproject.Studio) are the app_id themselves.
    if (entry.id.indexOf(".") >= 0) return entry.id
    return entry.startupClass !== "" ? entry.startupClass : entry.id
  }

  function isPinned(appId) {
    var k = String(appId).toLowerCase()
    return root.pinned.some(function(p) { return p.toLowerCase() === k })
  }

  function candidates() {
    if (root.query === "") return []
    var out = []
    var list = root.apps
    for (var i = 0; i < list.length && out.length < root.maxResults; i++) {
      var e = list[i]
      if (!e || e.noDisplay) continue
      var appId = root.guessAppId(e)
      if (root.isPinned(appId) || root.isPinned(e.id)) continue
      if (String(e.name).toLowerCase().indexOf(root.query) < 0
          && String(e.id).toLowerCase().indexOf(root.query) < 0) continue
      out.push(e)
    }
    return out
  }

  function add(entry) {
    var list = root.pinned.slice()
    list.push(root.guessAppId(entry))
    root.write(list)
    addField.text = ""
  }

  SettingsSectionLabel {
    text: "Dock"
    Layout.leftMargin: Config.spacingCompact
  }

  Text {
    text: "The dock lives in the Elena bottom bar: pinned apps always appear there, and running apps follow."
    color: Colors.fgSurfaceVariant
    font.family: Config.fontFamily
    font.pixelSize: Config.typeLabelMediumSize
    font.letterSpacing: Config.typeLabelTracking
    lineHeight: Config.typeLabelMediumLineHeight
    lineHeightMode: Text.FixedHeight
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Layout.leftMargin: Config.spacingCompact
    Layout.rightMargin: Config.spacingCompact
  }

  SettingsCard {
    Layout.fillWidth: true
    Layout.preferredHeight: enableRow.implicitHeight + Config.spacingSmall * 2

    ListItem {
      id: enableRow
      anchors.fill: parent
      anchors.margins: Config.spacingSmall
      leadingIcon: "dock_to_bottom"
      title: "Show dock"
      subtitle: Settings.dockEnabled ? "Pinned and running apps in the bottom bar" : "Hidden"
      toggleControl: dockSwitch
      SwitchControl {
        id: dockSwitch
        checked: Settings.dockEnabled
        activeColor: Colors.primary
        surfaceContainerHigh: Colors.surfaceContainerHigh
        surfaceContainerHighest: Colors.surfaceContainerHighest
        outline: Colors.outline
        motionDuration: Config.motionMedium
        reducedMotion: Config.reducedMotion
        accessibleName: "Show dock"
        onToggled: { Settings.dockEnabled = !Settings.dockEnabled; Settings.save() }
      }
    }
  }

  SettingsCard {
    Layout.fillWidth: true
    opacity: Settings.dockEnabled ? 1 : 0.5
    Layout.preferredHeight: cardCol.implicitHeight + Config.spacingSmall * 2

    ColumnLayout {
      id: cardCol
      anchors.fill: parent
      anchors.margins: Config.spacingSmall
      spacing: Config.spacingCompact

      Repeater {
        model: root.pinned
        delegate: ListItem {
          id: pinRow
          required property string modelData
          required property int index
          readonly property var entry: root.lookup(modelData)
          readonly property string iconPath: entry && entry.icon !== ""
            ? Quickshell.iconPath(entry.icon, true) : ""
          Layout.fillWidth: true
          title: entry ? entry.name : modelData
          subtitle: entry ? modelData : "Not installed or unknown app id"
          leadingImageSource: iconPath
          leadingFallbackText: modelData.charAt(0).toUpperCase()

          ActionButton {
            iconLabel: "arrow_upward"
            iconSize: 18
            variant: "text"
            width: Config.controlHitSize
            height: Config.controlHitSize
            enabled: pinRow.index > 0
            accessibleName: "Move " + pinRow.title + " earlier"
            tooltipText: accessibleName
            onActivated: root.move(pinRow.index, -1)
          }
          ActionButton {
            iconLabel: "arrow_downward"
            iconSize: 18
            variant: "text"
            width: Config.controlHitSize
            height: Config.controlHitSize
            enabled: pinRow.index < root.pinned.length - 1
            accessibleName: "Move " + pinRow.title + " later"
            tooltipText: accessibleName
            onActivated: root.move(pinRow.index, 1)
          }
          ActionButton {
            iconLabel: "close"
            iconSize: 18
            variant: "text"
            width: Config.controlHitSize
            height: Config.controlHitSize
            accessibleName: "Unpin " + pinRow.title
            tooltipText: accessibleName
            onActivated: root.remove(pinRow.index)
          }
        }
      }

      Text {
        visible: root.pinned.length === 0
        text: "No pinned apps. Running apps still appear in the dock."
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelMediumSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.leftMargin: Config.spacingSmall
      }

      TextFieldControl {
        id: addField
        Layout.fillWidth: true
        leadingIcon: "search"
        placeholder: "Add app"
        accessibleName: "Add app"
        accessibleDescription: "Search installed apps to pin to the dock"
      }

      Repeater {
        model: root.candidates()
        delegate: ListItem {
          id: result
          required property var modelData
          readonly property string iconPath: modelData.icon !== ""
            ? Quickshell.iconPath(modelData.icon, true) : ""
          Layout.fillWidth: true
          title: modelData.name
          subtitle: modelData.id
          leadingImageSource: iconPath
          leadingFallbackText: String(modelData.name).charAt(0).toUpperCase()
          accessibleName: "Pin " + modelData.name
          onClicked: root.add(modelData)
        }
      }
    }
  }
}
