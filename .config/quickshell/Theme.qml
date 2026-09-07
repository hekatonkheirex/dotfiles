import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property var settings: null
    readonly property bool settingsReady: root.settings ? root.settings.ready === true : false
    property string detectedMode: "dark"
    property bool externalThemeSyncRunning: false
    property bool externalThemeSyncPending: false
    property bool externalThemeSyncPendingNotify: false
    readonly property string configHome: {
        var value = Quickshell.env("XDG_CONFIG_HOME");
        return value && value.length > 0 ? value : (Quickshell.env("HOME") || "") + "/.config";
    }
    readonly property string cacheHome: {
        var value = Quickshell.env("XDG_CACHE_HOME");
        return value && value.length > 0 ? value : (Quickshell.env("HOME") || "") + "/.cache";
    }
    readonly property string livePalettePath: root.cacheHome + "/quickshell/palettes/live.json"
    readonly property string paletteRefreshScript: root.configHome + "/quickshell/scripts/refresh-wallpaper-palette.sh"
    readonly property string externalThemeScript: root.configHome + "/quickshell/scripts/sync-material3-expressive.sh"
    readonly property string modeDetectionScript: root.configHome + "/quickshell/scripts/detect-wallpaper-mode.sh"
    readonly property string requestedMode: {
        var mainMode = root.settings ? root.settings.themeMode : "dark";
        var shellMode = root.settings ? root.settings.shellThemeMode : "follow";
        return shellMode && shellMode !== "follow" ? shellMode : mainMode;
    }
    readonly property string resolvedMode: root.requestedMode === "light" ? "light" : (root.requestedMode === "auto" ? root.detectedMode : "dark")
    readonly property bool wallpaperPaletteSelected: root.settings ? root.settings.paletteSource === "wallpaper" : false
    readonly property bool dynamicPaletteLoaded: {
        var palette = root.resolvedMode === "light" ? paletteAdapter.light : paletteAdapter.dark;
        return palette && Object.keys(palette).length > 0;
    }
    readonly property string paletteLabel: root.wallpaperPaletteSelected ? (root.dynamicPaletteLoaded ? "Wallpaper" : "Tokyo Night fallback") : "Tokyo Night"
    readonly property string modeLabel: root.resolvedMode === "light" ? "Light" : "Dark"
    property color background: root.settings && root.settings.pureBlack && root.resolvedMode === "dark" ? "#000000" : root.token("background", root.staticPaletteForMode(root.resolvedMode).background)
    property color surface: root.token("surface", root.staticPaletteForMode(root.resolvedMode).surface)
    property color surfaceVariant: root.token("surfaceVariant", root.staticPaletteForMode(root.resolvedMode).surfaceVariant)
    property color surfaceRaised: root.token("surfaceRaised", root.staticPaletteForMode(root.resolvedMode).surfaceRaised)
    property color text: root.token("text", root.staticPaletteForMode(root.resolvedMode).text)
    property color muted: root.token("muted", root.staticPaletteForMode(root.resolvedMode).muted)
    property color accent: root.token("accent", root.staticPaletteForMode(root.resolvedMode).accent)
    property color accentAlt: root.token("accentAlt", root.staticPaletteForMode(root.resolvedMode).accentAlt)
    property color positive: root.token("positive", root.staticPaletteForMode(root.resolvedMode).positive)
    property color warning: root.token("warning", root.staticPaletteForMode(root.resolvedMode).warning)
    property color danger: root.token("danger", root.staticPaletteForMode(root.resolvedMode).danger)
    property color accentSurface: root.token("accentSurface", root.surfaceToken("primary_container", root.withAlpha(root.accent, 0.2)))
    property color positiveSurface: root.token("positiveSurface", root.surfaceToken("tertiary_container", root.withAlpha(root.positive, 0.2)))
    property color dangerSurface: root.token("dangerSurface", root.surfaceToken("error_container", root.withAlpha(root.danger, 0.2)))
    // Material 3 semantic roles and component metrics.  The Tokyo Night and
    // Matugen palettes above remain the source of truth for the actual colors.
    readonly property color outline: root.token("outline", root.withAlpha(root.muted, root.resolvedMode === "light" ? 0.52 : 0.42))
    readonly property color outlineVariant: root.token("outlineVariant", root.withAlpha(root.muted, root.resolvedMode === "light" ? 0.3 : 0.2))
    readonly property color onAccent: root.token("onAccent", root.resolvedMode === "light" ? "#ffffff" : "#16161e")
    readonly property color onAccentAlt: root.token("onAccentAlt", root.resolvedMode === "light" ? "#ffffff" : "#16161e")
    readonly property color onAccentSurface: root.token("onAccentSurface", root.text)
    readonly property color onDanger: root.token("onDanger", root.resolvedMode === "light" ? "#ffffff" : "#16161e")
    readonly property color surfaceContainerLowest: root.token("surfaceContainerLowest", root.background)
    readonly property color surfaceContainerLow: root.token("surfaceContainerLow", root.surface)
    readonly property color surfaceContainer: root.token("surfaceContainer", root.surfaceVariant)
    readonly property color surfaceContainerHigh: root.token("surfaceContainerHigh", root.surfaceVariant)
    readonly property color surfaceContainerHighest: root.token("surfaceContainerHighest", root.surfaceRaised)
    readonly property string fontFamily: root.settings && root.settings.fontFamily ? root.settings.fontFamily : "Roboto Flex"
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space24: 24
    readonly property int shapeExtraSmall: 4
    readonly property int shapeSmall: 8
    readonly property int shapeMedium: 12
    readonly property int shapeLarge: 16
    readonly property int shapeExtraLarge: 28
    readonly property int shapeFull: 999
    readonly property int iconButtonSize: 48
    readonly property int iconButtonIconSize: 22
    readonly property int controlHeight: 36
    readonly property int sliderTrackHeight: 20
    readonly property int sliderThumbWidth: 4
    readonly property int sliderThumbHeight: 38
    readonly property int sliderThumbGap: 6
    readonly property int switchTrackWidth: 62
    readonly property int switchTrackHeight: 38
    readonly property int switchCheckedThumbSize: 28
    readonly property int switchUncheckedThumbSize: 20
    readonly property int switchThumbInset: 5
    readonly property int labelSmallSize: 11
    readonly property int labelMediumSize: 12
    readonly property int bodyMediumSize: 13
    readonly property int titleMediumSize: 16
    readonly property int motionShort: 140
    readonly property int motionMedium: 180

    function staticPaletteForMode(mode) {
        if (mode === "light")
            return {
            "background": "#e1e2e7",
            "surface": "#d5d6db",
            "surfaceVariant": "#c4c8da",
            "surfaceRaised": "#a8aecb",
            "text": "#1a1b26",
            "muted": "#565a6e",
            "accent": "#9854f1",
            "accentAlt": "#2e7de9",
            "positive": "#587539",
            "warning": "#8c6c3e",
            "danger": "#f52a65",
            "accentSurface": "#c4c8da",
            "positiveSurface": "#c4c8da",
            "dangerSurface": "#c4c8da",
            "outline": "#72778f",
            "outlineVariant": "#a6aabd",
            "onAccent": "#ffffff",
            "onAccentAlt": "#ffffff",
            "onAccentSurface": "#1a1b26",
            "onDanger": "#ffffff",
            "surfaceContainerLowest": "#e1e2e7",
            "surfaceContainerLow": "#dfe0e5",
            "surfaceContainer": "#d5d6db",
            "surfaceContainerHigh": "#c4c8da",
            "surfaceContainerHighest": "#a8aecb"
        };

        return {
            "background": "#16161e",
            "surface": "#1a1b26",
            "surfaceVariant": "#24283b",
            "surfaceRaised": "#2c3148",
            "text": "#c0caf5",
            "muted": "#9aa5ce",
            "accent": "#7aa2f7",
            "accentAlt": "#bb9af7",
            "positive": "#9ece6a",
            "warning": "#e0af68",
            "danger": "#f7768e",
            "accentSurface": "#337aa2f7",
            "positiveSurface": "#339ece6a",
            "dangerSurface": "#33f7768e",
            "outline": "#565f89",
            "outlineVariant": "#30364f",
            "onAccent": "#16161e",
            "onAccentAlt": "#16161e",
            "onAccentSurface": "#c0caf5",
            "onDanger": "#16161e",
            "surfaceContainerLowest": "#13131a",
            "surfaceContainerLow": "#1a1b26",
            "surfaceContainer": "#202231",
            "surfaceContainerHigh": "#24283b",
            "surfaceContainerHighest": "#2c3148"
        };
    }

    function paletteForMode(mode) {
        if (root.wallpaperPaletteSelected) {
            var dynamic = mode === "light" ? paletteAdapter.light : paletteAdapter.dark;
            if (dynamic && Object.keys(dynamic).length > 0)
                return {
                "background": dynamic.background || dynamic.surface,
                "surface": dynamic.surface_container || dynamic.surface,
                "surfaceVariant": dynamic.surface_variant || dynamic.surface_container_high || dynamic.surface_container,
                "surfaceRaised": dynamic.surface_container_high || dynamic.surface_container,
                "text": dynamic.on_surface || dynamic.on_background,
                "muted": dynamic.on_surface_variant || dynamic.on_surface,
                "accent": dynamic.primary,
                "accentAlt": dynamic.secondary || dynamic.tertiary || dynamic.primary,
                "positive": dynamic.tertiary || dynamic.secondary || dynamic.primary,
                "warning": dynamic.secondary || dynamic.tertiary || dynamic.primary,
                "danger": dynamic.error,
                "accentSurface": dynamic.primary_container || dynamic.surface_container_high,
                "positiveSurface": dynamic.tertiary_container || dynamic.secondary_container || dynamic.surface_container_high,
                "dangerSurface": dynamic.error_container || dynamic.surface_container_high,
                "outline": dynamic.outline || dynamic.outline_variant || dynamic.on_surface_variant,
                "outlineVariant": dynamic.outline_variant || dynamic.outline || dynamic.surface_variant,
                "onAccent": dynamic.on_primary || dynamic.on_primary_container || dynamic.on_surface,
                "onAccentAlt": dynamic.on_secondary || dynamic.on_secondary_container || dynamic.on_surface,
                // The shell uses a translucent accent surface for selected
                // controls, so the surface foreground is more reliable than
                // Matugen's primary-container foreground here.
                "onAccentSurface": dynamic.on_surface || dynamic.on_primary_container,
                "onDanger": dynamic.on_error || dynamic.on_error_container || dynamic.on_surface,
                "surfaceContainerLowest": dynamic.surface_container_lowest || dynamic.background || dynamic.surface,
                "surfaceContainerLow": dynamic.surface_container_low || dynamic.surface_container,
                "surfaceContainer": dynamic.surface_container || dynamic.surface,
                "surfaceContainerHigh": dynamic.surface_container_high || dynamic.surface_container,
                "surfaceContainerHighest": dynamic.surface_container_highest || dynamic.surface_container_high || dynamic.surface_container
            };

        }
        return root.staticPaletteForMode(mode);
    }

    function token(name, fallback) {
        var palette = root.paletteForMode(root.resolvedMode);
        var value = palette ? palette[name] : "";
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }

    function surfaceToken(name, fallback) {
        var palette = root.paletteForMode(root.resolvedMode);
        var value = palette ? palette[name] : "";
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }

    function withAlpha(value, alpha) {
        var color = Qt.color(value);
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    function setDetectedMode(value) {
        var mode = value.trim().split(/\s+/)[0];
        root.detectedMode = mode === "light" ? "light" : "dark";
    }

    function refreshMode() {
        if (root.requestedMode === "auto")
            modeDetector.exec([root.modeDetectionScript]);
        else
            root.detectedMode = root.requestedMode === "light" ? "light" : "dark";
    }

    function refreshPalette() {
        paletteGenerator.exec([root.paletteRefreshScript]);
    }

    function refreshExternalTheme(notify) {
        var shouldNotify = notify === true && root.settingsReady;
        if (root.externalThemeSyncRunning) {
            root.externalThemeSyncPending = true;
            root.externalThemeSyncPendingNotify = root.externalThemeSyncPendingNotify || shouldNotify;
            return ;
        }
        var command = ["/usr/bin/bash", root.externalThemeScript];
        if (shouldNotify)
            command.push("--notify");

        root.externalThemeSyncRunning = true;
        externalThemeSync.exec(command);
    }

    visible: false
    Component.onCompleted: {
        root.refreshMode();
        root.refreshPalette();
        root.refreshExternalTheme();
    }

    FileView {
        id: paletteFile

        path: root.livePalettePath
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            if (root.requestedMode === "auto")
                root.refreshMode();

        }

        JsonAdapter {
            id: paletteAdapter

            property string source: ""
            property string wallpaper: ""
            property var light: ({
            })
            property var dark: ({
            })
        }

    }

    Process {
        id: paletteGenerator

        onExited: function(exitCode) {
            if (exitCode === 0)
                paletteFile.reload();
            else
                console.warn("[theme] wallpaper palette refresh failed", exitCode);
        }
    }

    Process {
        id: modeDetector

        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.detectedMode = "dark";

        }

        stdout: StdioCollector {
            onStreamFinished: root.setDetectedMode(this.text)
        }

    }

    Process {
        id: externalThemeSync

        onExited: function(exitCode) {
            var rerun = root.externalThemeSyncPending;
            var rerunNotify = root.externalThemeSyncPendingNotify;
            root.externalThemeSyncPending = false;
            root.externalThemeSyncPendingNotify = false;
            root.externalThemeSyncRunning = false;
            if (exitCode !== 0 && exitCode !== 15)
                console.warn("[theme] external theme synchronization failed", exitCode);

            if (rerun)
                root.refreshExternalTheme(rerunNotify);

        }
    }

    Connections {
        function onThemeModeChanged() {
            root.refreshMode();
            root.refreshExternalTheme(true);
        }

        function onShellThemeModeChanged() {
            root.refreshMode();
            root.refreshExternalTheme(true);
        }

        function onPaletteSourceChanged() {
            root.refreshMode();
            root.refreshExternalTheme(true);
        }

        target: root.settings
    }

}
