import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
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
        onCreateSpaceRequested: createNotice.restart()
    }

    FontLoader {
        id: interTight
        source: "assets/fonts/InterTight-Variable.ttf"
    }

    Window {
        id: previewWindow

        title: "Spaces OS Dock"
        visible: true
        width: 928
        height: 308
        minimumWidth: 540
        minimumHeight: 212
        color: "#f6f6f5"
        onClosing: Qt.quit()

        // The dock and toolbar controls receive their presses above this area.
        MouseArea {
            anchors.fill: parent
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            onPressed: previewWindow.startSystemMove()
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.preferredHeight: 48

                Label { text: "Dock height · " + dockState.profile + " px" }

                ButtonGroup { id: profiles }
                Repeater {
                    model: [56, 64, 80]

                    Button {
                        required property int modelData
                        text: modelData + " px"
                        checkable: true
                        checked: dockState.profile === modelData
                        ButtonGroup.group: profiles
                        onClicked: dockState.setProfile(modelData)
                    }
                }

                Item { Layout.fillWidth: true }

                Label {
                    visible: createNotice.running
                    text: "Space creation is simulated"
                }

                Button {
                    visible: dockState.spacesOpen
                    text: "Main dock"
                    onClicked: dockView.closeSpaces(visualFocus ? Qt.TabFocusReason : Qt.MouseFocusReason)
                }
            }

            Rectangle {
                id: stage

                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#ebebeb"

                DockView {
                    id: dockView

                    dockState: dockState
                    tooltipFont: interTight.status === FontLoader.Ready ? interTight.name : "sans-serif"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                }
            }
        }

        Shortcut { sequence: "Ctrl+1"; onActivated: dockState.setProfile(56) }
        Shortcut { sequence: "Ctrl+2"; onActivated: dockState.setProfile(64) }
        Shortcut { sequence: "Ctrl+3"; onActivated: dockState.setProfile(80) }
    }

    Timer {
        id: createNotice
        interval: 2400
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
