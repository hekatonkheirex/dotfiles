//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Singletons"

ShellRoot {
    id: root

    property string openMon: ""
    property string openSurface: ""

    function toggleSurface(mon, surface) {
        if (!mon || mon.length === 0) mon = Niri.focusedOutput
        if (root.openMon === mon && root.openSurface === surface) {
            root.close()
            return
        }
        root.openMon = mon
        root.openSurface = surface
    }

    function close() {
        root.openMon = ""
        root.openSurface = ""
    }

    IpcHandler {
        target: "pill"
        function mixer(mon: string): void { root.toggleSurface(mon, "mixer") }
        function battery(mon: string): void { root.toggleSurface(mon, "battery") }
        function brightness(mon: string): void { root.toggleSurface(mon, "brightness") }
        function wifi(mon: string): void { root.toggleSurface(mon, "wifi") }
        function bluetooth(mon: string): void { root.toggleSurface(mon, "bluetooth") }
        function hide(): void { root.close() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: reserve
            required property var modelData
            readonly property real topGap: 8
            readonly property real restHeight: 38

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: restHeight + topGap
            aboveWindows: true

            anchors { top: true; left: true; right: true }
            implicitHeight: restHeight + topGap

            mask: Region {}
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: overlay
            required property var modelData
            readonly property real topGap: 8
            readonly property string surfaceName: root.openMon === modelData.name ? root.openSurface : ""
            readonly property bool surfaceOpen: surfaceName.length > 0
            readonly property bool modal: surfaceOpen || pill.held
            readonly property bool monFullscreen: !!Niri.fullscreenByOutput[modelData.name]

            onMonFullscreenChanged: if (monFullscreen && root.openMon === modelData.name) root.close()

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: surfaceOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            WlrLayershell.namespace: "pill"

            anchors { top: true; left: true; right: true; bottom: true }

            mask: monFullscreen ? hiddenRegion : (modal ? fullRegion : pillRegion)
            Region { id: hiddenRegion }
            Region {
                id: pillRegion
                x: pill.x
                y: pill.y
                width: pill.width
                height: pill.height
            }
            Region {
                id: fullRegion
                width: overlay.width
                height: overlay.height
            }

            MouseArea {
                anchors.fill: parent
                enabled: overlay.modal
                onPressed: (mouse) => {
                    var inside = mouse.x >= pillRegion.x && mouse.x <= pillRegion.x + pillRegion.width
                        && mouse.y >= pillRegion.y && mouse.y <= pillRegion.y + pillRegion.height
                    if (!inside) root.close()
                }
            }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: overlay.surfaceOpen

                Keys.onEscapePressed: root.close()

                Pill {
                    id: pill
                    anchors.top: parent.top
                    anchors.topMargin: overlay.topGap
                    anchors.horizontalCenter: parent.horizontalCenter
                    surface: overlay.surfaceName
                    opacity: overlay.monFullscreen ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.morph; easing.type: Easing.OutCubic }
                    }

                    onRequestSurface: (name) => root.toggleSurface(overlay.modelData.name, name)
                    onRequestClose: root.close()
                }
            }

            onSurfaceOpenChanged: if (surfaceOpen) focusScope.forceActiveFocus()
        }
    }
}
