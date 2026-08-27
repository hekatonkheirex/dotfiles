import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import QtQuick.Effects
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: accountTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  readonly property int neoShadowAllowance: Config.neoBrutalism
    ? Config.themeShadowOffset
    : 0
  anchors.fill: parent
  visible: root.currentTab === 0
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight + accountTab.neoShadowAllowance
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds
  ScrollBar.vertical: SettingsScrollBar { scrollTarget: accountTab }

  property string fullName: ""
  property string hostname: ""
  property string osName: ""
  property string kernel: ""
  property string cpuModel: ""
  property string gpuModel: ""
  property string shellName: ""
  property string niriVersion: ""
  property string quickshellVersion: ""
  property string localIp: ""
  property string localIface: ""
  property bool machineInfoLoaded: false

  Process {
    id: machineInfoProc
    command: ["sh", "-c",
      "getent passwd \"$USER\" 2>/dev/null | cut -d: -f5 | cut -d, -f1 || echo Unavailable; " +
      "uname -n 2>/dev/null || echo Unavailable; " +
      "if [ -r /etc/os-release ]; then . /etc/os-release; printf '%s\\n' \"${PRETTY_NAME:-Unavailable}\"; else echo Unavailable; fi; " +
      "uname -r 2>/dev/null || echo Unavailable; " +
      "(lscpu 2>/dev/null | grep 'Model name' | sed 's/Model name:[[:space:]]*//' | head -1) || echo Unavailable; " +
      "if command -v lspci >/dev/null 2>&1; then (lspci | grep -i vga | sed 's/^[0-9a-f:.]* VGA compatible controller: //' | head -1) || echo Unavailable; else echo Unavailable; fi; " +
      "basename \"${SHELL:-}\" 2>/dev/null || echo Unavailable; " +
      "niri --version 2>/dev/null || echo Unavailable; " +
      "quickshell --version 2>/dev/null || echo Unavailable; " +
      "(ip -o -4 addr show scope global 2>/dev/null | head -1 | awk '{print $2\" \"$4}') || echo Unavailable"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n");
        accountTab.fullName = lines[0] || "";
        accountTab.hostname = lines[1] || "";
        accountTab.osName = lines[2] || "";
        accountTab.kernel = lines[3] || "";
        accountTab.cpuModel = lines[4] || "";
        accountTab.gpuModel = lines[5] || "";
        accountTab.shellName = lines[6] || "";
        accountTab.niriVersion = (lines[7] || "").replace("niri ", "");
        accountTab.quickshellVersion = (lines[8] || "").replace("Quickshell ", "").split(" (revision")[0];
        var netParts = (lines[9] || "").split(" ");
        accountTab.localIface = netParts[0] || "";
        accountTab.localIp = netParts[1] || "";
        accountTab.machineInfoLoaded = true;
      }
    }
  }

  onVisibleChanged: {
    if (visible && !accountTab.machineInfoLoaded && !machineInfoProc.running) {
      machineInfoProc.running = true
    } else if (!visible && machineInfoProc.running) {
      machineInfoProc.running = false
    }
  }

  Component.onCompleted: {
    if (accountTab.visible && !accountTab.machineInfoLoaded) machineInfoProc.running = true
  }

  component InfoRow: RowLayout {
    id: infoRow
    property string icon: ""
    property string label: ""
    property string value: ""
    Layout.fillWidth: true
    Layout.preferredHeight: 32
    spacing: Config.spacingSmall

    Text {
      text: infoRow.icon
      font.family: Config.iconFont
      font.pixelSize: 16
      font.variableAxes: Config.iconVariableAxes(0, 16)
      color: Colors.primary
      Layout.preferredWidth: 20
    }

    Text {
      text: infoRow.label
      color: Colors.fgSurfaceVariant
      font.family: Config.fontFamily
      font.pixelSize: Config.typeBodyMediumSize
      font.letterSpacing: Config.typeBodyTracking
      lineHeight: Config.typeBodyMediumLineHeight
      lineHeightMode: Text.FixedHeight
      Layout.preferredWidth: 90
    }

    Text {
      text: infoRow.value || "—"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.typeBodyMediumSize
      font.weight: Config.typeMediumWeight
      font.letterSpacing: Config.typeBodyTracking
      lineHeight: Config.typeBodyMediumLineHeight
      lineHeightMode: Text.FixedHeight
      elide: Text.ElideRight
      Layout.fillWidth: true
    }
  }

  ColumnLayout {
    id: mainColumn
    width: Math.max(0, accountTab.width - accountTab.neoShadowAllowance - Config.settingsScrollbarGutter)
    spacing: Config.spacingLarge + accountTab.neoShadowAllowance

    SettingsPageHeader {
      pageTitle: "Account"
      subtitle: "Profile, session, and machine information."
    }

  StyledSurface {
    id: profileCard
    variant: "elevated"
    Layout.fillWidth: true
    Layout.preferredHeight: accountTab.compactLayout ? 196 : 152
    radius: Config.shapeLarge
    surfaceColor: Colors.surfaceContainer
    outlineColor: Colors.styleOutline
    outlineWidth: Config.themeBorderWidth

    Flow {
      id: profileFlow
      width: accountTab.compactLayout ? parent.width - Config.spacingLarge : 360
      height: accountTab.compactLayout ? 180 : 96
      anchors.centerIn: parent
          spacing: accountTab.compactLayout
            ? Config.spacingSmall
            : Config.spacingLarge + Config.spacingCompact
      flow: Flow.LeftToRight

      Item {
        width: accountTab.compactLayout ? profileFlow.width : 96
        height: 96

        Rectangle {
          id: profilePicContainer
          width: 96
          height: 96
          anchors.centerIn: parent
          radius: width / 2
          color: Colors.surfaceContainerHighest

          Image {
            id: profilePic
            source: "file://" + Quickshell.env("HOME") + "/.face.icon"
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            visible: false
          }

          Rectangle {
            id: profileMask
            anchors.fill: parent
            radius: parent.width / 2
            color: "black"
            visible: false
            layer.enabled: true
          }

          MultiEffect {
            anchors.fill: parent
            source: profilePic
            visible: profilePic.status === Image.Ready
            maskEnabled: true
            maskSource: profileMask
          }

          Text {
            anchors.centerIn: parent
            text: "person"
            font.family: Config.iconFont
            font.pixelSize: 48
            font.variableAxes: Config.iconVariableAxes(0, 48)
            color: Colors.fgSurfaceVariant
            visible: profilePic.status !== Image.Ready
          }
        }
      }

      Item {
        id: profileDetailsContainer
        width: accountTab.compactLayout ? profileFlow.width : 220
        height: accountTab.compactLayout ? 68 : 96

        Column {
          id: profileDetails
          width: parent.width
          anchors.verticalCenter: parent.verticalCenter
          spacing: accountTab.compactLayout
            ? Config.spacingCompact
            : Config.spacingSmall

          Text {
            id: profileName
            text: accountTab.fullName || Quickshell.env("USER") || "User"
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: accountTab.compactLayout
              ? Config.typeTitleLargeSize
              : Config.typeHeadlineMediumSize
            font.weight: Config.typeStrongWeight
            font.letterSpacing: Config.typeTitleTracking
            lineHeight: accountTab.compactLayout
              ? Config.typeTitleLargeLineHeight
              : Config.typeHeadlineMediumLineHeight
            lineHeightMode: Text.FixedHeight
            width: profileDetails.width
            wrapMode: Text.NoWrap
          }

          Row {
            spacing: Config.spacingSmall
            Text {
              text: "navigation"
              font.family: Config.iconFont
              font.pixelSize: accountTab.compactLayout ? 13 : 15
              font.variableAxes: Config.iconVariableAxes(0, accountTab.compactLayout ? 13 : 15)
              color: Colors.primary
            }
            Text {
              text: "on niri"
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: accountTab.compactLayout
                ? Config.typeLabelMediumSize
                : Config.typeLabelLargeSize
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: accountTab.compactLayout
                ? Config.typeLabelMediumLineHeight
                : Config.typeLabelLargeLineHeight
              lineHeightMode: Text.FixedHeight
            }
          }

          Row {
            visible: Settings.systemShowUptime
            spacing: Config.spacingSmall
            Text {
              text: "schedule"
              font.family: Config.iconFont
              font.pixelSize: accountTab.compactLayout ? 13 : 15
              font.variableAxes: Config.iconVariableAxes(0, accountTab.compactLayout ? 13 : 15)
              color: Colors.fgSurfaceVariant
            }
            Text {
              text: root.uptimeText.replace("up ", "")
              color: Colors.fgSurfaceVariant
              font.family: Config.fontFamily
              font.pixelSize: accountTab.compactLayout
                ? Config.typeLabelMediumSize
                : Config.typeLabelLargeSize
              font.letterSpacing: Config.typeLabelTracking
              lineHeight: accountTab.compactLayout
                ? Config.typeLabelMediumLineHeight
                : Config.typeLabelLargeLineHeight
              lineHeightMode: Text.FixedHeight
              elide: Text.ElideRight
              width: Math.max(0, profileDetails.width
                - (accountTab.compactLayout ? 13 : 15)
                - Config.spacingSmall)
            }
          }
        }
      }
    }
  }

  // Machine Info card
  StyledSurface {
    variant: "filled"
    Layout.fillWidth: true
    Layout.preferredHeight: machineInfoCol.implicitHeight + Config.spacingMedium * 2
    radius: Config.shapeLarge
    surfaceColor: Colors.surfaceContainer
    outlineColor: Colors.styleOutline
    outlineWidth: Config.themeBorderWidth

    ColumnLayout {
      id: machineInfoCol
      anchors.fill: parent
      anchors.margins: Config.spacingMedium
      spacing: Config.spacingSmall

      Text {
        text: "Machine"
        color: Colors.fgSurfaceVariant
        font.family: Config.fontFamily
        font.pixelSize: Config.typeLabelSmallSize
        font.weight: Config.typeMediumWeight
        font.letterSpacing: Config.typeLabelTracking
        lineHeight: Config.typeLabelSmallLineHeight
        lineHeightMode: Text.FixedHeight
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        InfoRow { icon: "dns"; label: "Hostname"; value: accountTab.hostname }
        InfoRow { icon: "terminal"; label: "OS"; value: accountTab.osName }
        InfoRow { icon: "settings_suggest"; label: "Kernel"; value: accountTab.kernel }
        InfoRow { icon: "memory"; label: "CPU"; value: accountTab.cpuModel }
        InfoRow { icon: "sports_esports"; label: "GPU"; value: accountTab.gpuModel }
        InfoRow { icon: "code"; label: "Shell"; value: accountTab.shellName }
        InfoRow { icon: "grid_view"; label: "Niri"; value: accountTab.niriVersion }
        InfoRow { icon: "dashboard"; label: "Quickshell"; value: accountTab.quickshellVersion }
        InfoRow {
          icon: "lan"
          label: "Network"
          value: accountTab.localIp ? (accountTab.localIp + " (" + accountTab.localIface + ")") : ""
        }
      }
    }
  }

  // Quick actions
  GridLayout {
    Layout.fillWidth: true
    columns: accountTab.compactLayout ? 1 : 2
    // Neo controls carry a hard offset shadow; keep that footprint out of
    // the inter-button gap so the two outlines remain visually separate.
    columnSpacing: Config.spacingMedium + accountTab.neoShadowAllowance
    rowSpacing: Config.spacingMedium + accountTab.neoShadowAllowance

    ActionButton {
      Layout.fillWidth: true
      Layout.preferredHeight: Config.themeLabeledActionButtonHeight
      iconLabel: "lock"
      labelText: "Lock Screen"
      variant: "elevated"
      accessibleName: "Lock screen"
      accessibleDescription: "Locks the session"
      onActivated: {
        root.lockRequested()
        root.dismissed()
      }
    }

    ActionButton {
      Layout.fillWidth: true
      Layout.preferredHeight: Config.themeLabeledActionButtonHeight
      iconLabel: "restart_alt"
      labelText: "Restart Shell"
      variant: "elevated"
      accessibleName: "Restart Quickshell"
      accessibleDescription: "Restarts the quickshell.service unit"
      onActivated: {
        Quickshell.execDetached(["systemctl", "--user", "restart", "quickshell.service"])
      }
    }
  }
  }
}
