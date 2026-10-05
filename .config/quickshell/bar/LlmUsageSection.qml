import QtQuick
import QtQml
import QtQuick.Layouts
import Quickshell
import "primitives"
import "../config"

ColumnLayout {
  id: root
  required property QtObject service
  required property string providerName
  property string resetDescription: "Usage-limit reset credits"
  property string resetsTitle: "Resets available"

  readonly property var availableResets: !root.service.stale && root.service.resets
    && (!root.service.resets.next_expiry
      || Date.parse(root.service.resets.next_expiry) > root.service.now)
    ? root.service.resets : null


  ColumnLayout {
    Layout.fillWidth: true
    spacing: Config.spacingMedium

    RowLayout {
      Layout.fillWidth: true
      Text {
        text: root.providerName + " usage"
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeHeadlineSmallSize
        font.weight: Config.typeStrongWeight
      }
      Item { Layout.fillWidth: true }
      IconButton {
        size: 32
        iconSize: 20
        iconLabel: "refresh"
        enabled: !root.service.loading && !root.service.rateLimited
        accessibleName: "Refresh " + root.providerName + " usage"
        tooltipText: accessibleName
        onClicked: root.service.refresh()
      }
    }

    Text {
      Layout.fillWidth: true
      visible: root.service.loading || root.service.statusMessage !== "" || root.service.stale
      text: root.service.loading ? "Refreshing usage…"
        : (root.service.stale ? "Stale reading · " : "") + root.service.statusMessage
          + (root.service.rateLimited ? "\n" + root.service.cooldownText : "")
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      color: root.service.status === "error" ? Colors.error : Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeBodyMediumSize
      Accessible.role: Accessible.StaticText
      Accessible.name: text
    }

    Repeater {
      model: [
        { title: "Five-hour", window: root.service.fiveHour },
        { title: "Weekly", window: root.service.weekly }
      ]
      delegate: ColumnLayout {
        required property var modelData
        Layout.fillWidth: true
        spacing: Config.spacingSmall
        RowLayout {
          Layout.fillWidth: true
          Text {
            text: modelData.title
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.typeBodyMediumSize
            font.weight: Config.typeStrongWeight
          }
          Item { Layout.fillWidth: true }
          Text {
            text: modelData.window ? Math.round(modelData.window.used_percent) + "% used" : "Unavailable"
            color: Colors.fgSurfaceVariant
            font.family: Config.fontFamily
            font.pixelSize: Config.typeLabelMediumSize
          }
        }
        WaveProgressBar {
          Layout.fillWidth: true
          visible: modelData.window !== null
          progress: modelData.window ? modelData.window.used_percent / 100 : 0
          activeColor: modelData.window && modelData.window.used_percent >= 90 ? Colors.error
            : (Config.nothingDesign ? Colors.fgSurface
              : (Config.ghostTheme ? Colors.styleAccent : Colors.primary))
          Accessible.role: Accessible.ProgressBar
          Accessible.name: root.providerName + " " + modelData.title + " usage"
          Accessible.description: modelData.window ? modelData.window.used_percent + "% used" : "Unavailable"
        }
        Text {
          Layout.fillWidth: true
          text: modelData.window ? root.service.resetText(modelData.window.reset_at) : "This usage window was not reported."
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.typeLabelMediumSize
          wrapMode: Text.WordWrap
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 1
      color: Colors.outlineVariant
    }

    RowLayout {
      Layout.fillWidth: true
      Text {
        text: root.resetsTitle
        color: Colors.fgSurface
        font.family: Config.fontFamily
        font.pixelSize: Config.typeBodyMediumSize
        font.weight: Config.typeStrongWeight
      }
      Item { Layout.fillWidth: true }
      Text {
        text: root.availableResets ? root.availableResets.available.toString() : "Unavailable"
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelMediumSize
      }
    }

    Text {
      Layout.fillWidth: true
      text: root.availableResets
        ? root.resetDescription
          + (root.availableResets.next_expiry ? "\n" + root.service.expiryText(root.availableResets.next_expiry) : "")
        : (root.service.resetsMessage || "Refresh to read available reset credits.")
      textFormat: Text.PlainText
      wrapMode: Text.WordWrap
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeLabelMediumSize
    }

    Text {
      Layout.fillWidth: true
      text: root.service.updatedAt !== ""
        ? "Updated " + Qt.formatDateTime(new Date(root.service.updatedAt), "hh:mm")
          + " · Checks every 5 minutes"
        : "Uses your existing " + root.providerName + " sign-in · Read-only"
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeLabelSmallSize
      wrapMode: Text.WordWrap
    }
  }
}
