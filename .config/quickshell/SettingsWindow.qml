import "."
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var settings
    property var notificationService
    property var targetScreen
    property string activePage: "Appearance"
    property string searchQuery: ""
    property bool advancedEnabled: true
    property bool overriddenOnly: false
    property string statusMessage: ""
    readonly property var categories: [{
        "name": "Appearance",
        "icon": "tune"
    }, {
        "name": "Wallpaper",
        "icon": "wallpaper"
    }, {
        "name": "Templates",
        "icon": "code"
    }, {
        "name": "Desktop",
        "icon": "desktop_windows"
    }, {
        "name": "Dock",
        "icon": "dock_to_bottom"
    }, {
        "name": "Panels",
        "icon": "view_sidebar"
    }, {
        "name": "Launcher",
        "icon": "search"
    }, {
        "name": "Control Center",
        "icon": "tune"
    }, {
        "name": "Notifications",
        "icon": "notifications"
    }, {
        "name": "OSD",
        "icon": "chat_bubble_outline"
    }, {
        "name": "Shell",
        "icon": "terminal"
    }, {
        "name": "Keybinds",
        "icon": "keyboard"
    }, {
        "name": "Security",
        "icon": "shield"
    }, {
        "name": "System",
        "icon": "monitor_heart"
    }, {
        "name": "Services",
        "icon": "device_hub"
    }, {
        "name": "Location",
        "icon": "location_on"
    }, {
        "name": "Power",
        "icon": "bolt"
    }, {
        "name": "Hooks",
        "icon": "link"
    }, {
        "name": "Plugins",
        "icon": "extension"
    }, {
        "name": "Bar: default",
        "icon": "web_asset"
    }, {
        "name": "New Bar",
        "icon": "add"
    }]
    readonly property var placeholderDetails: ({
        "Wallpaper": ["Wallpaper source", "Wallpaper transitions", "Per-monitor wallpaper"],
        "Templates": ["Template directory", "Apply templates", "Template preview"],
        "Desktop": ["Desktop widgets", "Widget editor", "Widget visibility"],
        "Dock": ["Dock visibility", "Dock position", "Pinned applications"],
        "Panels": ["Panel layout", "Panel shortcuts", "Panel behavior"],
        "Launcher": ["Search providers", "Launcher appearance", "Application actions"],
        "Control Center": ["Quick toggles", "Network controls", "Media controls"],
        "Notifications": ["Notification history", "Do not disturb", "Notification sounds"],
        "OSD": ["Volume OSD", "Brightness OSD", "OSD position"],
        "Shell": ["Shell behavior", "Animations", "Layer surfaces"],
        "Keybinds": ["Global shortcuts", "Launcher shortcut", "Panel shortcuts"],
        "Security": ["Lock screen", "Authentication", "Screen sharing"],
        "System": ["System information", "Updates", "Diagnostics"],
        "Services": ["Bluetooth", "Network", "Media services"],
        "Location": ["Location services", "Timezone", "Geolocation"],
        "Power": ["Power profile", "Battery warnings", "Sleep behavior"],
        "Hooks": ["Startup hooks", "Theme hooks", "Wallpaper hooks"],
        "Plugins": ["Plugin directory", "Plugin permissions", "Plugin settings"],
        "Bar: default": ["Bar widgets", "Bar placement", "Bar visibility"],
        "New Bar": ["Create a bar", "Monitor assignment", "Bar preset"]
    })
    readonly property var filteredCategories: {
        var needle = root.searchQuery.trim().toLowerCase();
        if (needle.length === 0)
            return root.categories;

        return root.categories.filter(function(category) {
            return category.name.toLowerCase().indexOf(needle) !== -1;
        });
    }

    function toggle() {
        root.visible = !root.visible;
    }

    function close() {
        root.visible = false;
    }

    function resetPage() {
        if (root.activePage === "Appearance" && root.settings) {
            root.settings.resetAppearance();
            root.statusMessage = "Appearance reset";
        } else if (root.activePage === "Wallpaper") {
            wallpaperService.refresh();
        } else if (root.activePage === "Notifications" && root.settings) {
            root.settings.notificationsEnabled = true;
            root.settings.notificationsDoNotDisturb = false;
            root.settings.notificationToastDuration = 5;
            root.statusMessage = "Notifications reset";
        } else {
            root.statusMessage = "This page is a placeholder";
        }
        statusTimer.restart();
    }

    screen: root.targetScreen
    visible: false
    color: "transparent"
    focusable: true
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-hyprland-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    onActivePageChanged: {
        if (root.activePage === "Wallpaper")
            wallpaperService.refresh();

    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Timer {
        id: statusTimer

        interval: 2200
        repeat: false
        onTriggered: root.statusMessage = ""
    }

    WallpaperService {
        id: wallpaperService

        settings: root.settings
    }

    Connections {
        function onStatus(message) {
            root.statusMessage = message;
            statusTimer.restart();
        }

        target: wallpaperService
    }

    Item {
        id: keyboardTarget

        anchors.fill: parent
        focus: root.visible
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            }
        }
    }

    Rectangle {
        id: card

        width: Math.min(1080, Math.max(700, parent.width - 48))
        height: Math.min(920, Math.max(560, parent.height - 48))
        anchors.centerIn: parent
        radius: Theme.shapeExtraLarge
        color: Theme.surfaceContainer
        border.width: 1
        border.color: Theme.outlineVariant
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: mouse.accepted = true
        }

        Text {
            x: 18
            y: 17
            text: "Settings"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.titleMediumSize
            font.weight: Font.DemiBold
        }

        Text {
            anchors.right: closeButton.left
            anchors.rightMargin: 20
            y: 20
            text: "more_vert"
            color: Theme.muted
            font.family: "Material Symbols Rounded"
            font.pixelSize: 20
        }

        Rectangle {
            id: closeButton

            width: 34
            height: 34
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: 10
            radius: Theme.shapeMedium
            color: closeMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
            border.width: 1
            border.color: Theme.outlineVariant

            Text {
                anchors.centerIn: parent
                text: "close"
                color: Theme.text
                font.family: "Material Symbols Rounded"
                font.pixelSize: 19
            }

            MouseArea {
                id: closeMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
            }

        }

        Rectangle {
            id: searchBox

            x: 16
            y: 58
            width: 340
            height: 38
            radius: Theme.shapeMedium
            color: Theme.surfaceContainerHigh
            border.width: searchField.activeFocus ? 2 : 1
            border.color: searchField.activeFocus ? Theme.accent : Theme.outlineVariant

            TextInput {
                id: searchField

                anchors.fill: parent
                anchors.leftMargin: 42
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                text: root.searchQuery
                color: Theme.text
                selectionColor: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelMediumSize
                clip: true
                onTextChanged: root.searchQuery = text

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    visible: searchField.text.length === 0
                    text: "Search settings..."
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelMediumSize
                }

            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                color: searchField.activeFocus ? Theme.accent : Theme.muted
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
            }

        }

        Row {
            id: headerControls

            anchors.right: resetPageButton.left
            anchors.rightMargin: 20
            y: 67
            spacing: 10

            Text {
                text: "Advanced"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelMediumSize
                anchors.verticalCenter: parent.verticalCenter
            }

            SettingsToggle {
                checked: root.advancedEnabled
                anchors.verticalCenter: parent.verticalCenter
                onToggled: root.advancedEnabled = checked
            }

            Text {
                text: "Overridden"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelMediumSize
                anchors.verticalCenter: parent.verticalCenter
            }

            SettingsToggle {
                checked: root.overriddenOnly
                anchors.verticalCenter: parent.verticalCenter
                onToggled: root.overriddenOnly = checked
            }

        }

        Text {
            id: resetPageButton

            anchors.right: parent.right
            anchors.rightMargin: 52
            anchors.verticalCenter: headerControls.verticalCenter
            text: "Reset Page"
            color: resetMouse.containsMouse ? Theme.text : Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSmallSize

            MouseArea {
                id: resetMouse

                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.resetPage()
            }

        }

        Item {
            id: body

            anchors.top: searchBox.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Rectangle {
                id: sidebar

                width: 228
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                color: Theme.surfaceContainerLowest
                border.color: Theme.outlineVariant
                border.width: 1

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 10
                    contentWidth: width
                    contentHeight: sidebarColumn.implicitHeight
                    clip: true

                    Column {
                        id: sidebarColumn

                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: root.filteredCategories

                            delegate: Rectangle {
                                required property var modelData

                                width: sidebarColumn.width
                                height: 34
                                radius: Theme.shapeFull
                                color: root.activePage === modelData.name ? Theme.accentSurface : (sidebarMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                                border.width: root.activePage === modelData.name ? 1 : 0
                                border.color: Theme.outlineVariant

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 10

                                    Text {
                                        text: modelData.icon
                                        color: root.activePage === modelData.name ? Theme.accent : Theme.muted
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 17
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: modelData.name
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.labelMediumSize
                                        font.weight: root.activePage === modelData.name ? Font.DemiBold : Font.Normal
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                }

                                MouseArea {
                                    id: sidebarMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activePage = modelData.name
                                }

                            }

                        }

                    }

                }

            }

            Flickable {
                id: pageFlickable

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: sidebar.right
                anchors.right: parent.right
                contentWidth: width
                contentHeight: pageLoader.height + 48
                clip: true

                Loader {
                    id: pageLoader

                    x: 24
                    y: 22
                    width: pageFlickable.width - 48
                    height: item ? item.implicitHeight : 0
                    sourceComponent: root.activePage === "Appearance" ? appearancePage : (root.activePage === "Wallpaper" ? wallpaperPage : (root.activePage === "Notifications" ? notificationsPage : placeholderPage))
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 6
                }

            }

        }

        Text {
            id: statusLabel

            visible: root.statusMessage.length > 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.statusMessage
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelMediumSize
            z: 2
        }

        Rectangle {
            visible: statusLabel.visible
            anchors.centerIn: statusLabel
            width: statusLabel.implicitWidth + 28
            height: statusLabel.implicitHeight + 14
            radius: Theme.shapeFull
            color: Theme.surfaceContainerHighest
            border.width: 1
            border.color: Theme.outlineVariant
            z: 1
        }

    }

    Component {
        id: appearancePage

        Column {
            width: pageLoader.width
            spacing: 0

            Row {
                spacing: 10

                Text {
                    text: "tune"
                    color: Theme.accent
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                }

                Text {
                    text: "Appearance"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            Text {
                text: "Theme"
                color: Theme.accentAlt
                font.family: "Roboto Flex"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                topPadding: 14
                bottomPadding: 4
            }

            SettingsRow {
                title: "Theme Mode"
                description: "Choose Dark, Light, or Auto from the current wallpaper brightness"

                SettingsSegmented {
                    anchors.verticalCenter: parent.verticalCenter
                    options: [{
                        "label": "Dark",
                        "value": "dark"
                    }, {
                        "label": "Light",
                        "value": "light"
                    }, {
                        "label": "Auto",
                        "value": "auto"
                    }]
                    value: root.settings ? root.settings.themeMode : "dark"
                    onSelected: function(value) {
                        if (root.settings)
                            root.settings.themeMode = value;

                    }
                }

            }

            SettingsRow {
                title: "Shell Theme Mode"
                description: "Follow the main theme or choose a shell-specific mode"

                SettingsSegmented {
                    anchors.verticalCenter: parent.verticalCenter
                    options: [{
                        "label": "Follow",
                        "value": "follow"
                    }, {
                        "label": "Dark",
                        "value": "dark"
                    }, {
                        "label": "Light",
                        "value": "light"
                    }, {
                        "label": "Auto",
                        "value": "auto"
                    }]
                    value: root.settings ? root.settings.shellThemeMode : "follow"
                    onSelected: function(value) {
                        if (root.settings)
                            root.settings.shellThemeMode = value;

                    }
                }

            }

            SettingsRow {
                title: "Palette Source"
                description: "Use the wallpaper palette or the stable Tokyo Night palette"

                SettingsSegmented {
                    anchors.verticalCenter: parent.verticalCenter
                    options: [{
                        "label": "Static",
                        "value": "builtin"
                    }, {
                        "label": "Wallpaper",
                        "value": "wallpaper"
                    }]
                    value: root.settings ? root.settings.paletteSource : "builtin"
                    onSelected: function(value) {
                        if (root.settings)
                            root.settings.paletteSource = value;

                        root.statusMessage = value === "wallpaper" ? "Wallpaper Matugen selected; regenerating theme" : "Static Tokyo Night selected; authorize SDDM update if prompted";
                        statusTimer.restart();
                    }
                }

            }

            SettingsRow {
                title: "Static Palette"
                description: "Tokyo Night remains available when wallpaper colors are disabled"
                badge: "Tokyo Night"

                Rectangle {
                    width: 240
                    height: 38
                    radius: Theme.shapeMedium
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Repeater {
                            model: [Theme.accent, Theme.accentAlt, Theme.positive, Theme.danger]

                            delegate: Rectangle {
                                required property color modelData

                                width: 12
                                height: 12
                                radius: 6
                                color: modelData
                            }

                        }

                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 78
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Tokyo Night"
                        color: Theme.text
                        font.family: "Roboto Flex"
                        font.pixelSize: 12
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "expand_more"
                        color: Theme.muted
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.settings)
                                root.settings.paletteSource = "builtin";

                            root.statusMessage = "Static Tokyo Night selected; authorize SDDM update if prompted";
                            statusTimer.restart();
                        }
                    }

                }

            }

            SettingsRow {
                title: "Active Palette"
                description: "The palette currently used by the Quickshell interface"

                Rectangle {
                    width: 240
                    height: 38
                    radius: Theme.shapeMedium
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Text {
                        anchors.centerIn: parent
                        text: Theme.paletteLabel + " · " + Theme.modeLabel
                        color: Theme.text
                        font.family: "Roboto Flex"
                        font.pixelSize: 12
                    }

                }

            }

            SettingsRow {
                title: "Pure Black"
                description: "Anchor dark surfaces to true black for OLED panels"

                SettingsToggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.settings ? root.settings.pureBlack : false
                    onToggled: function(value) {
                        if (root.settings)
                            root.settings.pureBlack = value;

                    }
                }

            }

            Text {
                text: "Interface"
                color: Theme.accentAlt
                font.family: "Roboto Flex"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                topPadding: 14
                bottomPadding: 4
            }

            SettingsRow {
                title: "Font Family"
                description: "Font family for the shell interface"
                badge: "Override"

                Rectangle {
                    width: 190
                    height: 38
                    radius: Theme.shapeMedium
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.settings ? root.settings.fontFamily : "Roboto Flex"
                        color: Theme.text
                        font.family: "Roboto Flex"
                        font.pixelSize: 12
                    }

                }

            }

            SettingsRow {
                title: "Language"
                description: "Override automatic locale detection"
                badge: "Advanced"

                Rectangle {
                    width: 190
                    height: 38
                    radius: Theme.shapeMedium
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.settings && root.settings.language === "auto" ? "Auto" : root.settings.language
                        color: Theme.text
                        font.family: "Roboto Flex"
                        font.pixelSize: 12
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "expand_more"
                        color: Theme.muted
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                    }

                }

            }

            SettingsRow {
                title: "Corner Radius"
                description: "Scale corner radius across shell containers and controls"

                Item {
                    anchors.fill: parent

                    MaterialSlider {
                        id: radiusSlider

                        anchors.left: parent.left
                        anchors.right: radiusValue.left
                        anchors.rightMargin: Theme.space8
                        anchors.verticalCenter: parent.verticalCenter
                        height: 48
                        from: 0
                        to: 2
                        stepSize: 0.05
                        live: true
                        value: root.settings ? root.settings.cornerRadius : 1
                        accessibleName: "Corner radius"
                        accessibleDescription: "Scale corner radius across shell containers and controls"
                        onMoved: {
                            if (root.settings) {
                                root.settings.cornerRadius = value;
                            }
                        }
                    }

                    Text {
                        id: radiusValue

                        width: 48
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.settings ? root.settings.cornerRadius.toFixed(2) : "1.00"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelMediumSize
                        horizontalAlignment: Text.AlignRight
                    }

                }

            }

            SettingsRow {
                title: "Colorize App Icons"
                description: "Recolor application icons to match the active palette"

                SettingsToggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.settings ? root.settings.colorizeIcons : false
                    onToggled: function(value) {
                        if (root.settings)
                            root.settings.colorizeIcons = value;

                    }
                }

            }

            Text {
                text: "Accessibility"
                color: Theme.accentAlt
                font.family: "Roboto Flex"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                topPadding: 14
                bottomPadding: 4
            }

            SettingsRow {
                title: "UI Scale"
                description: "Scale the entire interface up or down"

                Item {
                    anchors.fill: parent

                    MaterialSlider {
                        id: scaleSlider

                        anchors.left: parent.left
                        anchors.right: scaleValue.left
                        anchors.rightMargin: Theme.space8
                        anchors.verticalCenter: parent.verticalCenter
                        height: 48
                        from: 0.8
                        to: 1.4
                        stepSize: 0.05
                        live: true
                        value: root.settings ? root.settings.uiScale : 1
                        accessibleName: "UI scale"
                        accessibleDescription: "Scale the entire interface up or down"
                        onMoved: {
                            if (root.settings) {
                                root.settings.uiScale = value;
                            }
                        }
                    }

                    Text {
                        id: scaleValue

                        width: 48
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.settings ? root.settings.uiScale.toFixed(2) : "1.00"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.labelMediumSize
                        horizontalAlignment: Text.AlignRight
                    }

                }

            }

            SettingsRow {
                title: "High Contrast"
                description: "Increase contrast by pushing surfaces and text toward extremes"

                SettingsToggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.settings ? root.settings.highContrast : false
                    onToggled: function(value) {
                        if (root.settings)
                            root.settings.highContrast = value;

                    }
                }

            }

            Text {
                text: "Wallpaper mode generates a Matugen palette after each wallpaper change. Static mode uses the built-in Tokyo Night palette."
                color: Theme.muted
                font.family: "Roboto Flex"
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                width: parent.width
                topPadding: 16
                bottomPadding: 12
            }

        }

    }

    Component {
        id: wallpaperPage

        Column {
            id: wallpaperContent

            function commitDirectory() {
                var value = directoryField.text.trim();
                if (root.settings && value.length > 0)
                    root.settings.wallpaperDirectory = value;

                wallpaperService.refresh();
            }

            width: pageLoader.width
            spacing: 0

            Row {
                spacing: 10

                Text {
                    text: "wallpaper"
                    color: Theme.accent
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                }

                Text {
                    text: "Wallpaper"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            Text {
                text: "awww integration"
                color: Theme.accentAlt
                font.family: "Roboto Flex"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                topPadding: 16
                bottomPadding: 4
            }

            SettingsRow {
                title: "Wallpaper Directory"
                description: "Images in this directory are available to the switcher"

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        width: 236
                        height: 32
                        radius: Theme.shapeMedium
                        color: Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: Theme.outlineVariant

                        TextInput {
                            id: directoryField

                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            text: root.settings ? root.settings.wallpaperDirectory : wallpaperService.directory
                            color: Theme.text
                            selectionColor: Theme.accent
                            font.family: "Roboto Flex"
                            font.pixelSize: 11
                            clip: true
                            selectByMouse: true
                            onEditingFinished: wallpaperContent.commitDirectory()
                        }

                    }

                    SettingsActionButton {
                        text: "Scan"
                        onClicked: wallpaperContent.commitDirectory()
                    }

                }

            }

            SettingsRow {
                title: "Daemon Status"
                description: "awww-daemon must be available before an image can be applied"

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: wallpaperService.daemonAvailable ? "Ready" : "Unavailable"
                        color: wallpaperService.daemonAvailable ? Theme.positive : Theme.danger
                        font.family: "Roboto Flex"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    SettingsActionButton {
                        text: "Check"
                        onClicked: wallpaperService.refresh()
                    }

                }

            }

            SettingsRow {
                title: "Wallpaper Order"
                description: "Move through the scanned image list"

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    SettingsActionButton {
                        text: "Previous"
                        onClicked: wallpaperService.previous()
                    }

                    SettingsActionButton {
                        text: "Next"
                        onClicked: wallpaperService.next()
                    }

                }

            }

            SettingsRow {
                title: "Random Wallpaper"
                description: "Apply a random image from the scanned directory"

                SettingsActionButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Randomize"
                    emphasized: true
                    onClicked: wallpaperService.random()
                }

            }

            SettingsRow {
                title: "Transition"
                description: "awww transition effect used when applying an image"

                SettingsSegmented {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    options: [{
                        "label": "Fade",
                        "value": "fade"
                    }, {
                        "label": "Wipe",
                        "value": "wipe"
                    }, {
                        "label": "Grow",
                        "value": "grow"
                    }, {
                        "label": "Random",
                        "value": "random"
                    }]
                    value: root.settings ? root.settings.wallpaperTransition : "fade"
                    onSelected: function(value) {
                        if (root.settings)
                            root.settings.wallpaperTransition = value;

                    }
                }

            }

            SettingsRow {
                title: "Image List"
                description: wallpaperService.files.count + " image(s) found"

                SettingsActionButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Rescan"
                    onClicked: wallpaperService.refreshFiles()
                }

            }

            Rectangle {
                width: parent.width
                height: 316
                radius: Theme.shapeLarge
                color: Theme.surfaceContainerLowest
                border.width: 1
                border.color: Theme.outlineVariant

                GridView {
                    id: wallpaperGrid

                    anchors.fill: parent
                    anchors.margins: 12
                    cellWidth: 158
                    cellHeight: 112
                    clip: true
                    model: wallpaperService.files

                    delegate: Rectangle {
                        required property string path
                        required property string name

                        width: 148
                        height: 102
                        radius: Theme.shapeMedium
                        color: wallpaperService.currentPath === path ? Theme.accentSurface : Theme.surfaceVariant

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: "file://" + path
                            asynchronous: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                            clip: true
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 25
                            color: Theme.withAlpha(Theme.surfaceContainerLowest, 0.88)

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 7
                                anchors.right: parent.right
                                anchors.rightMargin: 7
                                anchors.verticalCenter: parent.verticalCenter
                                text: name
                                color: Theme.text
                                font.family: "Roboto Flex"
                                font.pixelSize: 9
                                elide: Text.ElideMiddle
                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wallpaperService.apply(path)
                        }

                    }

                }

                Text {
                    anchors.centerIn: parent
                    visible: wallpaperService.files.count === 0
                    text: "No wallpaper images found"
                    color: Theme.muted
                    font.family: "Roboto Flex"
                    font.pixelSize: 11
                }

            }

            Text {
                        text: "awww owns rendering here. Its user service starts with the shell, restores the last wallpaper, and keeps the selected directory and transition settings saved locally."
                color: Theme.muted
                font.family: "Roboto Flex"
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                width: parent.width
                topPadding: 16
                bottomPadding: 12
            }

        }

    }

    Component {
        id: notificationsPage

        Column {
            width: pageLoader.width
            spacing: 0

            Row {
                spacing: 10

                Text {
                    text: "notifications"
                    color: Theme.accent
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                }

                Text {
                    text: "Notifications"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            Text {
                text: "Quickshell notification service"
                color: Theme.accentAlt
                font.family: "Roboto Flex"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                topPadding: 16
                bottomPadding: 4
            }

            SettingsRow {
                title: "Notifications"
                description: "Accept desktop notifications through the native DBus server"
                badge: "native"

                SettingsToggle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.settings ? root.settings.notificationsEnabled : true
                    onToggled: function(value) {
                        if (root.settings)
                            root.settings.notificationsEnabled = value;

                    }
                }

            }

            SettingsRow {
                title: "Do Not Disturb"
                description: "Keep notifications in history while suppressing automatic toasts"

                SettingsToggle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    checked: root.settings ? root.settings.notificationsDoNotDisturb : false
                    onToggled: function(value) {
                        if (root.settings)
                            root.settings.notificationsDoNotDisturb = value;

                    }
                }

            }

            SettingsRow {
                title: "Toast duration"
                description: "How long a new notification stays visible at the top-right"

                SettingsSegmented {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    options: [{
                        "label": "3 s",
                        "value": "3"
                    }, {
                        "label": "5 s",
                        "value": "5"
                    }, {
                        "label": "8 s",
                        "value": "8"
                    }]
                    value: root.settings ? String(Math.round(root.settings.notificationToastDuration)) : "5"
                    onSelected: function(value) {
                        if (root.settings)
                            root.settings.notificationToastDuration = Number(value);

                    }
                }

            }

            SettingsRow {
                title: "Notification history"
                description: "Dismiss all currently tracked notifications"

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        text: root.notificationService ? root.notificationService.notificationCount + " item(s)" : "0 item(s)"
                        color: Theme.muted
                        font.family: "Roboto Flex"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    SettingsActionButton {
                        text: "Clear"
                        enabled: root.notificationService ? root.notificationService.notificationCount > 0 : false
                        onClicked: {
                            if (root.notificationService)
                                root.notificationService.clearAll();

                        }
                    }

                }

            }

            SettingsRow {
                title: "Notification sound"
                description: "Sound profiles are not wired to the shell yet"

                SettingsActionButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Placeholder"
                    enabled: false
                }

            }

            Text {
                text: "Notification history is kept in memory while Quickshell runs. Quickshell owns the desktop notification service."
                color: Theme.muted
                font.family: "Roboto Flex"
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                width: parent.width
                topPadding: 16
                bottomPadding: 12
            }

        }

    }

    Component {
        id: placeholderPage

        Column {
            width: pageLoader.width
            spacing: 0

            Row {
                spacing: 10

                Text {
                    text: {
                        for (var index = 0; index < root.categories.length; index++) {
                            if (root.categories[index].name === root.activePage)
                                return root.categories[index].icon;

                        }
                        return "settings";
                    }
                    color: Theme.accent
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                }

                Text {
                    text: root.activePage
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            Text {
                text: "Placeholder"
                color: Theme.accentAlt
                font.family: "Roboto Flex"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                topPadding: 16
                bottomPadding: 4
            }

            Rectangle {
                width: parent.width
                height: 88
                radius: Theme.shapeLarge
                color: Theme.surfaceContainerLowest
                border.width: 1
                border.color: Theme.outlineVariant

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        text: "This section is included in the settings layout."
                        color: Theme.text
                        font.family: "Roboto Flex"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "The underlying Quickshell integration is not available yet, so its controls are placeholders."
                        color: Theme.muted
                        font.family: "Roboto Flex"
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                }

            }

            Repeater {
                model: root.placeholderDetails[root.activePage] || ["Settings for this page"]

                delegate: SettingsRow {
                    required property string modelData

                    title: modelData
                    description: "Integration pending"
                    placeholder: true
                }

            }

        }

    }

}
