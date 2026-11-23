import QtQml
import "DockProfiles.js" as DockProfiles

QtObject {
    id: state

    property int profile: 64
    property bool binFull: true
    property bool spacesOpen: false
    property string selectedItem: ""
    property int selectedSpace: 0

    signal filesRequested()
    signal createSpaceRequested()

    function setProfile(height: int): bool {
        if (!DockProfiles.profiles[height])
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
            state.selectedItem = id;
            state.filesRequested();
            break;
        default:
            state.selectedItem = state.selectedItem === id ? "" : id;
            break;
        }
    }
}
