import QtQml

QtObject {
    id: navigation

    readonly property url sharedWallpaper: Qt.resolvedUrl("assets/ithos-wallpaper.jpg")

    // Stable IDs are shared by persistence, the picker, and future Shelf consumers.
    readonly property var spaces: [
        { id: "home", title: "Home", access: "Personal", accent: "#a9d78c",
          wallpaper: Qt.resolvedUrl("assets/space-1.png"),
          viewport: Qt.rect(46, 94, 1828, 1219),
          thumbnail: Qt.resolvedUrl("assets/space-1.png"),
          crop: Qt.rect(-4, -17, 87, 87), hover: Qt.rect(-12.7, -25.7, 104.4, 104.4) },
        { id: "ithos", title: "Ithos Studio", access: "Shared", accent: "#ffb020",
          wallpaper: sharedWallpaper,
          viewport: Qt.rect(0, 0, 0, 0),
          thumbnail: sharedWallpaper,
          crop: Qt.rect(0, -6, 80, 53), hover: Qt.rect(-8, -12, 97, 65) }
    ]

    property int activeIndex: 0
    readonly property var activeSpace: spaces[activeIndex]
    property bool inside: true

    signal entered(string spaceId)

    function restore(spaceId: string): void {
        const index = spaces.findIndex(space => space.id === spaceId);
        activeIndex = index < 0 ? 0 : index;
    }

    function enter(spaceId: string): bool {
        const index = spaces.findIndex(space => space.id === spaceId);
        if (index < 0)
            return false;
        activeIndex = index;
        inside = true;
        entered(spaceId);
        return true;
    }

    function leave(): void {
        inside = false;
    }
}
