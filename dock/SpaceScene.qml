import QtQuick

Rectangle {
    id: scene

    required property SpaceNavigation navigation
    property bool reducedMotion: false
    property int shownIndex: 0
    property int previousIndex: 0
    property real blend: 1
    property bool ready: false

    color: "#242725"
    clip: true

    Component.onCompleted: {
        shownIndex = navigation.activeIndex;
        ready = true;
    }

    function switchBackground(): void {
        if (!ready || shownIndex === navigation.activeIndex)
            return;
        // Reversing a switch keeps the two images at their current visible weights.
        const startBlend = navigation.activeIndex === previousIndex ? 1 - blend : 0;
        transition.stop();
        previousIndex = shownIndex;
        shownIndex = navigation.activeIndex;
        if (reducedMotion || !visible) {
            blend = 1;
            canvas.scale = 1;
            return;
        }
        blend = startBlend;
        transition.start();
    }

    Connections {
        target: scene.navigation
        function onActiveIndexChanged(): void { scene.switchBackground(); }
    }

    Item {
        id: canvas
        anchors.fill: parent

        Repeater {
            model: scene.navigation.spaces

            Image {
                required property int index
                required property var modelData

                anchors.fill: parent
                source: modelData.wallpaper
                sourceClipRect: modelData.viewport
                fillMode: Image.PreserveAspectCrop
                mipmap: true
                z: index === scene.shownIndex ? 1 : 0
                opacity: index === scene.shownIndex ? scene.blend : 1
                visible: index === scene.shownIndex || (scene.blend < 1 && index === scene.previousIndex)
            }
        }
    }

    // The creation flow insets the wallpaper to 1840 / 1920, dissolves, then expands.
    SequentialAnimation {
        id: transition
        NumberAnimation { target: canvas; property: "scale"; to: 1840 / 1920; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: scene; property: "blend"; to: 1; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: canvas; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutCubic }
    }
}
