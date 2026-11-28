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
    property bool initialized: false
    property bool workspaceConfirmed: false
    readonly property bool loginSession: independent && Quickshell.env("SPACES_SESSION_MODE") === "login"
    readonly property var appIds: ["chatgpt", "org.gnome.Console", "org.centaur.Gtk4", "LocalSend", "org.gnome.Nautilus"]
    applications: {
        const entries = DesktopEntries.applications.values;
        const installed = appIds.map(id => entries.find(entry => entry.id === id)).filter(Boolean);
        if (!installed.some(entry => entry.id === "chatgpt")) {
            const browser = entries.find(entry => entry.id === "firefox");
            if (browser) installed.unshift(browser);
        }
        const inkpad = entries.find(entry => entry.name.toLowerCase() === "inkpad");
        if (inkpad) installed.push(inkpad);
        return installed.map(entry => ({ id: entry.id,
            name: entry.id === "firefox" ? "ChatGPT" : entry.name,
            icon: entry.icon.startsWith("/") ? "file://" + entry.icon : Quickshell.iconPath(entry.icon) }));
    }
    onApplicationRequested: desktopId => {
        if (!applications.some(app => app.id === desktopId)) return;
        if (desktopId === "chatgpt" && independent) Quickshell.execDetached(["chatgpt", "--ozone-platform=wayland"]);
        else if (desktopId === "firefox") Quickshell.execDetached(["firefox", "--new-window", "https://chatgpt.com"]);
        else Quickshell.execDetached(["gtk-launch", desktopId]);
    }
    property bool sidebarOpen: false
    readonly property bool personal: (!independent || workspaceConfirmed) && navigation.inside && navigation.activeSpace.id === "home"
    readonly property bool reducedMotion: Quickshell.env("SPACES_REDUCED_MOTION") === "1"
    readonly property string fontFamily: interTight.status === FontLoader.Ready ? interTight.name : "sans-serif"
    readonly property FontLoader interTight: FontLoader { source: "assets/fonts/InterTight-Variable.ttf" }
    readonly property Settings preferences: Settings {
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/SpacesOS/navigation.ini"
    }

    arlo: ArloController {
        personal: desktop.personal
        onHeightConfirmed: height => desktop.profile = height
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
        navigation.compositorManaged = independent;
        initialized = true;
        remember(navigation.activeSpace.id);
        binFull = Quickshell.env("SPACES_DOCK_START_BIN") !== "empty";
    }
    function leave(): void {
        spacesOpen = false;
        toolsOpen = false;
        sidebarOpen = false;
        if (independent) navigation.selectionRequested("overview");
        else navigation.leave();
    }
}
