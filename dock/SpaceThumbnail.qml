import QtQuick
import QtQuick.Effects

Item {
    id: thumbnail

    required property url artwork
    required property rect restingCrop
    required property rect hoverCrop
    property bool highlighted: false
    property real artworkOpacity: 1
    readonly property rect crop: highlighted ? hoverCrop : restingCrop

    width: 80
    height: 40
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: shapeMask
    }

    Rectangle {
        id: shapeMask
        anchors.fill: parent
        radius: 8
        visible: false
        layer.enabled: true
    }

    Image {
        x: thumbnail.crop.x
        y: thumbnail.crop.y
        width: thumbnail.crop.width
        height: thumbnail.crop.height
        source: thumbnail.artwork
        opacity: thumbnail.artworkOpacity
        fillMode: Image.PreserveAspectCrop
        mipmap: true

        Behavior on x { NumberAnimation { duration: 100 } }
        Behavior on y { NumberAnimation { duration: 100 } }
        Behavior on width { NumberAnimation { duration: 100 } }
        Behavior on height { NumberAnimation { duration: 100 } }
    }
}
