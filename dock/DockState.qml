import QtQml
import "DockProfiles.js" as DockProfiles

QtObject {
    id: state

    property var arlo: null
    readonly property bool arloOpen: !!arlo?.opened && !!arlo?.personal
    property int profile: 64
    property bool binFull: true
    property bool spacesOpen: false
    property bool toolsOpen: false
    property var applications: []
    readonly property bool subDockOpen: spacesOpen || toolsOpen
    onSpacesOpenChanged: if (spacesOpen) toolsOpen = false
    onToolsOpenChanged: if (toolsOpen) spacesOpen = false
    readonly property SpaceNavigation navigation: SpaceNavigation {}

    signal applicationRequested(string desktopId)
    signal filesRequested()
    signal createSpaceRequested()

    function setProfile(height: int): bool {
        if (!DockProfiles.supportsHeight(height))
            return false;

        if (state.arlo) return state.arlo.send("resize", {height}) !== 0;
        state.profile = height;
        return true;
    }

    function activate(id: string): void {
        switch (id) {
        case "bot":
            if (arlo?.personal) arlo.opened = true;
            break;
        case "spaces":
            if (arlo) arlo.opened = false;
            state.spacesOpen = true;
            break;
        case "tools":
            state.toolsOpen = state.applications.length > 0;
            break;
        case "bin":
            state.binFull = !state.binFull;
            break;
        case "files":
            state.filesRequested();
            break;
        }
    }
}
