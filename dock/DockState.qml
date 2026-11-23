import QtQml
import "DockProfiles.js" as DockProfiles

QtObject {
    id: state

    property int profile: 64
    property bool binFull: true
    property bool spacesOpen: false
    readonly property SpaceNavigation navigation: SpaceNavigation {}

    signal filesRequested()
    signal createSpaceRequested()

    function setProfile(height: int): bool {
        if (!DockProfiles.supportsHeight(height))
            return false;

        state.profile = height;
        return true;
    }

    function activate(id: string): void {
        switch (id) {
        case "spaces":
            state.spacesOpen = true;
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
