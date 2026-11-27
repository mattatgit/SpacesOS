import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

QtObject {
    id: bridge
    readonly property var focused: ToplevelManager.activeToplevel
    readonly property string appId: focused ? focused.appId : ""
    readonly property string identity: appId === "org.spacesos.Notes" ? qsTr("Notes") : appId.split(".").pop()
    readonly property var menus: appId === "org.spacesos.Notes" ? exported.menus : []
    property var exported: ({ owner: "", menus: [] })

    readonly property Process watcher: Process {
        command: ["gjs", Quickshell.shellPath("../session/menu-export.js")]
        running: bridge.appId === "org.spacesos.Notes"
        stdout: SplitParser {
            onRead: line => bridge.exported = JSON.parse(line)
        }
        onExited: bridge.exported = ({ owner: "", menus: [] })
    }
    function invoke(action: string): void {
        if (!exported.owner || !menus.some(menu => menu.items.some(item => item.action === action && item.enabled))) return;
        Quickshell.execDetached(["gdbus", "call", "--session", "--dest", exported.owner,
            "--object-path", "/org/spacesos/Notes", "--method", "org.gtk.Actions.Activate", action, "[]", "{}"]);
    }
}
