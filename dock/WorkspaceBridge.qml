import QtQuick
import Quickshell
import Quickshell.Io

Process {
    id: bridge
    required property DesktopState desktop
    command: ["gjs", Quickshell.shellPath("../session/workspaces.js")]
    running: desktop.initialized
    stdinEnabled: true
    stdout: SplitParser {
        onRead: line => {
            if (line === "ready") {
                bridge.write(bridge.desktop.navigation.activeSpace.id + "\n");
                return;
            }
            const known = bridge.desktop.navigation.spaces.some(space => space.id === line);
            bridge.desktop.workspaceConfirmed = false;
            if (known) {
                bridge.desktop.navigation.enter(line);
                bridge.desktop.workspaceConfirmed = true;
            } else {
                bridge.desktop.navigation.leave();
            }
        }
    }
    onExited: desktop.workspaceConfirmed = false
    readonly property Connections selection: Connections {
        target: bridge.desktop.navigation
        function onSelectionRequested(id: string): void {
            bridge.desktop.workspaceConfirmed = false;
            bridge.desktop.sidebarOpen = false;
            if (bridge.running) bridge.write(id + "\n");
        }
    }
}
