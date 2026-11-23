import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    settings.watchFiles: false

    DockState {
        id: dockState

        Component.onCompleted: {
            setProfile(Number(Quickshell.env("SPACES_DOCK_START_PROFILE")));
            binFull = Quickshell.env("SPACES_DOCK_START_BIN") !== "empty";
        }
        onFilesRequested: Quickshell.execDetached(["xdg-open", Quickshell.env("HOME")])
    }

    FontLoader {
        id: interTight
        source: "assets/fonts/InterTight-Variable.ttf"
    }

    FloatingWindow {
        id: previewWindow

        title: "Spaces OS Dock"
        color: "transparent"
        implicitWidth: 928
        implicitHeight: dockView.implicitHeight + 12
        onWindowConnected: {
            contentItem.Window.window.flags |= Qt.FramelessWindowHint | Qt.NoDropShadowWindowHint;
        }
        onClosed: Qt.quit()

        // Leave the desktop interactive outside the dock and its two edge gestures.
        mask: Region {
            item: dockView.currentDock
            radius: 16
            Region { item: moveGrip }
            Region { item: dockState.spacesOpen ? dockView.returnTarget : null }
        }

        Item {
            id: stage
            anchors.fill: parent

            DockView {
                id: dockView

                dockState: dockState
                tooltipFont: interTight.status === FontLoader.Ready ? interTight.name : "sans-serif"
                anchors.fill: parent
                anchors.bottomMargin: 12

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

        function status(): string {
            return (dockState.spacesOpen ? "Spaces" : "Main") + " dock · "
                + dockState.profile + " px profile · "
                + (dockState.binFull ? "Bin full" : "Bin empty");
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
