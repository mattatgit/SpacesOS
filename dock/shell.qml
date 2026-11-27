//@ pragma AppId org.spacesos.Spaces
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    settings.watchFiles: false

    DesktopState { id: dockState }

    FloatingWindow {
        id: previewWindow

        title: "Spaces"
        color: "transparent"
        implicitWidth: 928
        implicitHeight: 616
        minimumSize: Qt.size(440, 260)
        onWindowConnected: {
            contentItem.Window.window.flags |= Qt.FramelessWindowHint | Qt.NoDropShadowWindowHint;
        }
        onClosed: Qt.quit()

        // Leave the desktop interactive outside the dock and its two edge gestures.
        mask: Region {
            item: dockState.navigation.inside ? stage : dockView.currentDock
            radius: dockState.navigation.inside ? 0 : 16
            Region { item: moveGrip }
            Region { item: dockState.subDockOpen ? dockView.returnTarget : null }
        }

        Item {
            id: stage
            anchors.fill: parent
            SpaceScene {
                anchors.fill: parent
                navigation: dockState.navigation
                visible: navigation.inside
                reducedMotion: dockState.reducedMotion
            }

            SpaceBar {
                id: bar
                anchors.top: parent.top
                width: parent.width
                visible: dockState.navigation.inside
                desktop: dockState
                fullscreen: previewWindow.fullscreen
                onToggleFullscreen: previewWindow.fullscreen = !previewWindow.fullscreen
                onMoveWindow: if (!previewWindow.fullscreen) previewWindow.startSystemMove()
                onLeaveSpace: {
                    previewWindow.fullscreen = false;
                    dockState.leave();
                    dockView.focusSpaces(Qt.TabFocusReason);
                }
                onExitSession: Qt.quit()
            }

            SpaceSidebar {
                anchors { right: parent.right; rightMargin: 16; top: bar.bottom; topMargin: 16 }
                width: Math.min(408, parent.width - 32)
                readonly property bool overlapsDock: width + 16 > (parent.width - dockView.currentDock.width) / 2
                height: Math.min(612, parent.height - y - 16 - (overlapsDock ? dockView.currentDock.height + 8 : 0))
                desktop: dockState
                z: 1
            }

            Shortcut {
                sequence: "F11"
                context: Qt.ApplicationShortcut
                onActivated: {
                    dockState.navigation.inside = true;
                    previewWindow.fullscreen = !previewWindow.fullscreen;
                }
            }
            Shortcut { context: Qt.ApplicationShortcut; sequence: "Ctrl+Q"; onActivated: Qt.quit() }

            DockView {
                id: dockView

                dockState: dockState
                tooltipFont: dockState.fontFamily
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: dockState.navigation.inside ? 0 : 12

                MouseArea {
                    id: moveGrip

                    anchors.left: dockView.currentDock.left
                    anchors.right: dockView.currentDock.right
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.verticalCenter: dockView.currentDock.top
                    height: 16
                    hoverEnabled: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onPressed: previewWindow.startSystemMove()
                }

                Shortcut { sequence: "Ctrl+1"; onActivated: dockState.setProfile(56) }
                Shortcut { sequence: "Ctrl+2"; onActivated: dockState.setProfile(64) }
                Shortcut { sequence: "Ctrl+3"; onActivated: dockState.setProfile(80) }
            }
        }
    }

    IpcHandler {
        target: "dock"

        function activate(full: bool): void {
            dockState.navigation.inside = true;
            previewWindow.minimized = false;
            if (full) previewWindow.fullscreen = true;
            previewWindow.contentItem.Window.window.requestActivate();
        }

        function isFullscreen(): bool { return previewWindow.fullscreen; }

        function status(): string {
            return (dockState.spacesOpen ? "Spaces" : "Main") + " dock · "
                + dockState.profile + " px profile · "
                + (dockState.binFull ? "Bin full" : "Bin empty");
        }

        function currentSpace(): string {
            return dockState.navigation.activeSpace.id;
        }

        function profile(height: int): bool {
            return dockState.setProfile(height);
        }

        function bin(full: bool): void {
            dockState.binFull = full;
        }

        function spaces(open: bool): void {
            if (open)
                dockState.spacesOpen = true;
            else
                dockView.closeSpaces(Qt.OtherFocusReason);
        }

        function capture(path: string): bool {
            return stage.grabToImage(result => {
                if (!result.saveToFile(path))
                    console.warn("Could not save dock screenshot to " + path);
            });
        }

    }
}
