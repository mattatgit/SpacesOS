import QtQuick
import QtCore
import Quickshell

DockState {
    id: desktop
    property var recentIds: []
    function remember(id: string): void {
        recentIds = [id].concat(recentIds.filter(old => old !== id));
        preferences.setValue("recents", JSON.stringify(recentIds));
    }
    property bool independent: false
    property bool sidebarOpen: false
    readonly property bool personal: navigation.inside && navigation.activeSpace.id === "home"
    readonly property bool reducedMotion: Quickshell.env("SPACES_REDUCED_MOTION") === "1"
    readonly property string fontFamily: interTight.status === FontLoader.Ready ? interTight.name : "sans-serif"
    readonly property FontLoader interTight: FontLoader { source: "assets/fonts/InterTight-Variable.ttf" }
    readonly property Settings preferences: Settings {
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/SpacesOS/navigation.ini"
    }

    onPersonalChanged: sidebarOpen = false
    onFilesRequested: {
        const folder = independent && Quickshell.env("SPACES_NESTED") === "1"
            ? Quickshell.env("XDG_DATA_HOME") : Quickshell.env("HOME");
        Quickshell.execDetached(independent ? ["nautilus", "--new-window", folder] : ["xdg-open", folder]);
    }
    readonly property Connections persistence: Connections {
        target: desktop.navigation
        function onEntered(spaceId: string): void {
            desktop.remember(spaceId);
            desktop.preferences.setValue("activeSpace", spaceId);
            desktop.preferences.sync();
        }
    }
    Component.onCompleted: {
        navigation.restore(preferences.value("activeSpace", "home"));
        try {
            const ids = JSON.parse(preferences.value("recents", "[]"));
            if (Array.isArray(ids)) recentIds = ids.filter(id => navigation.spaces.some(space => space.id === id));
        } catch (_) { recentIds = []; }
        remember(navigation.activeSpace.id);
        setProfile(Number(Quickshell.env("SPACES_DOCK_START_PROFILE")));
        binFull = Quickshell.env("SPACES_DOCK_START_BIN") !== "empty";
    }
    function leave(): void {
        spacesOpen = false;
        sidebarOpen = false;
        navigation.leave();
    }
}
