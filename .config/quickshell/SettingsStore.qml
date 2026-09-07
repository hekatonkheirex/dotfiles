import QtQuick

import Quickshell
import Quickshell.Io

Item {
    id: root

    visible: false

    // Theme synchronization must not treat the initial JSON load as a user
    // change. A failed load still completes initialization because the
    // adapter defaults remain active and can be edited normally.
    property bool ready: false

    readonly property string settingsPath: {
        var configHome = Quickshell.env("XDG_CONFIG_HOME");
        if (!configHome || configHome.length === 0) {
            configHome = Quickshell.env("HOME") + "/.config";
        }
        return configHome + "/quickshell/settings.json";
    }

    property alias themeMode: adapter.themeMode
    property alias shellThemeMode: adapter.shellThemeMode
    property alias paletteSource: adapter.paletteSource
    property alias paletteName: adapter.paletteName
    property alias pureBlack: adapter.pureBlack
    property alias fontFamily: adapter.fontFamily
    property alias language: adapter.language
    property alias cornerRadius: adapter.cornerRadius
    property alias colorizeIcons: adapter.colorizeIcons
    property alias uiScale: adapter.uiScale
    property alias highContrast: adapter.highContrast
    property alias barPosition: adapter.barPosition
    property alias barAutoHide: adapter.barAutoHide
    property alias barReserveSpace: adapter.barReserveSpace
    property alias showSeconds: adapter.showSeconds
    property alias showWorkspaceNames: adapter.showWorkspaceNames
    property alias wallpaperDirectory: adapter.wallpaperDirectory
    property alias wallpaperTransition: adapter.wallpaperTransition
    property alias wallpaperTransitionStep: adapter.wallpaperTransitionStep
    property alias wallpaperTransitionDuration: adapter.wallpaperTransitionDuration
    property alias wallpaperTransitionFps: adapter.wallpaperTransitionFps
    property alias notificationsEnabled: adapter.notificationsEnabled
    property alias notificationsDoNotDisturb: adapter.notificationsDoNotDisturb
    property alias notificationToastDuration: adapter.notificationToastDuration

    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: root.ready = true
        onLoadFailed: root.ready = true
        onAdapterUpdated: writeAdapter()
        onSaveFailed: function(error) {
            console.warn("[settings] save failed", error);
        }

        JsonAdapter {
            id: adapter

            property string themeMode: "auto"
            property string shellThemeMode: "follow"
            property string paletteSource: "wallpaper"
            property string paletteName: "Tokyo-Night"
            property bool pureBlack: false
            property string fontFamily: "Roboto Flex"
            property string language: "auto"
            property real cornerRadius: 1.0
            property bool colorizeIcons: false
            property real uiScale: 1.0
            property bool highContrast: false

            property string barPosition: "top"
            property bool barAutoHide: false
            property bool barReserveSpace: true
            property bool showSeconds: false
            property bool showWorkspaceNames: false

            property string wallpaperDirectory: (Quickshell.env("HOME") || "") + "/Pictures/Walls"
            property string wallpaperTransition: "fade"
            property int wallpaperTransitionStep: 90
            property real wallpaperTransitionDuration: 1.0
            property int wallpaperTransitionFps: 30

            property bool notificationsEnabled: true
            property bool notificationsDoNotDisturb: false
            property real notificationToastDuration: 5.0
        }
    }

    function resetAppearance() {
        themeMode = "auto";
        shellThemeMode = "follow";
        paletteSource = "wallpaper";
        paletteName = "Tokyo-Night";
        pureBlack = false;
        fontFamily = "Roboto Flex";
        language = "auto";
        cornerRadius = 1.0;
        colorizeIcons = false;
        uiScale = 1.0;
        highContrast = false;
    }
}
