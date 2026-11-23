import QtQuick
import "DockProfiles.js" as DockProfiles

MouseArea {
    id: divider

    required property DockState dockState
    required property real centerX
    required property url source
    property real length: 40.5

    property real pressSceneY
    property int pressHeight
    property bool moved: false

    x: centerX - width / 2
    width: 12
    height: parent.height
    z: 1
    hoverEnabled: true
    cursorShape: Qt.SizeVerCursor
    preventStealing: true

    onPressed: mouse => {
        pressSceneY = mapToItem(null, mouse.x, mouse.y).y;
        pressHeight = Math.max(DockProfiles.dragMinimum, dockState.profile);
        moved = false;
    }
    onPositionChanged: mouse => {
        if (!pressed)
            return;

        // The handle moves as the dock resizes. Measure against the fixed window scene.
        const offset = Math.round(pressSceneY - mapToItem(null, mouse.x, mouse.y).y);
        if (!moved && offset === 0)
            return;

        moved = true;
        dockState.setProfile(Math.max(DockProfiles.dragMinimum,
            Math.min(DockProfiles.dragMaximum, pressHeight + offset)));
    }

    Image {
        anchors.centerIn: parent
        // Figma exports the vertical line as a horizontal 40.5 × 0.5 SVG.
        width: divider.length
        height: 0.5
        source: divider.source
        sourceSize: Qt.size(81, 1)
        fillMode: Image.Stretch
        rotation: 90
        antialiasing: true
    }
}
