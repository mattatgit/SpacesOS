import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "chat"

ShellRoot {
    settings.watchFiles: false

    Settings {
        id: preferences
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/SpacesOS/navigation.ini"
    }

    Connections {
        target: dockState.navigation
        function onEntered(spaceId: string): void {
            preferences.setValue("activeSpace", spaceId);
            preferences.sync();
        }
    }

    DockState {
        id: dockState

        Component.onCompleted: {
            navigation.restore(preferences.value("activeSpace", "home"));
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
            Region { item: dockState.spacesOpen ? dockView.returnTarget : null }
        }

        Item {
            id: stage
            anchors.fill: parent
            property bool chatOpen: false
            readonly property bool personalHome: dockState.navigation.inside && dockState.navigation.activeSpace.id === "home"
            onPersonalHomeChanged: if (!personalHome) chatOpen = false

            SpaceScene {
                anchors.fill: parent
                navigation: dockState.navigation
                visible: navigation.inside
                reducedMotion: Quickshell.env("SPACES_REDUCED_MOTION") === "1"
            }

            SpaceBar {
                id: bar
                anchors.top: parent.top
                width: parent.width
                visible: dockState.navigation.inside
                space: dockState.navigation.activeSpace
                fontFamily: dockView.tooltipFont
                pickerOpen: dockState.spacesOpen
                chatOpen: stage.chatOpen
                onToggleChat: stage.chatOpen = !stage.chatOpen
                onMoveWindow: previewWindow.startSystemMove()
                onTogglePicker: {
                    if (dockState.spacesOpen)
                        dockView.closeSpaces(Qt.OtherFocusReason);
                    else
                        dockState.spacesOpen = true;
                }
                onLeaveSpace: {
                    dockView.closeSpaces(Qt.OtherFocusReason);
                    dockState.navigation.leave();
                    dockView.focusSpaces(Qt.TabFocusReason);
                }
            }

            Loader {
                active: stage.chatOpen && stage.personalHome
                anchors { left: parent.left; leftMargin: 8; top: bar.bottom; topMargin: 8 }
                width: Math.min(408, parent.width - 16)
                height: Math.min(612, Math.max(0, parent.height - dockView.edgeInset - dockView.currentDock.height - y - 12))
                sourceComponent: ChatSidebar { fontFamily: dockView.tooltipFont; onClosed: stage.chatOpen = false }
            }

            DockView {
                id: dockView

                dockState: dockState
                tooltipFont: interTight.status === FontLoader.Ready ? interTight.name : "sans-serif"
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
