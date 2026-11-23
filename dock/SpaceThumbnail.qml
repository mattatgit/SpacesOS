import QtQuick
import QtQuick.Effects

Item {
    id: thumbnail

    required property url artwork
    required property rect restingCrop
    required property rect hoverCrop
    required property real sizeFactor
    property bool highlighted: false
    property real artworkOpacity: 1
    property real hoverProgress: highlighted ? 1 : 0

    width: 80 * sizeFactor
    height: 40 * sizeFactor
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: shapeMask
    }

    Behavior on hoverProgress { NumberAnimation { duration: 100 } }

    function scaledCrop(start: real, end: real): real {
        return (start + (end - start) * hoverProgress) * sizeFactor;
    }

    Rectangle {
        id: shapeMask
        anchors.fill: parent
        radius: 8 * thumbnail.sizeFactor
        visible: false
        layer.enabled: true
    }

    Image {
        x: thumbnail.scaledCrop(thumbnail.restingCrop.x, thumbnail.hoverCrop.x)
        y: thumbnail.scaledCrop(thumbnail.restingCrop.y, thumbnail.hoverCrop.y)
        width: thumbnail.scaledCrop(thumbnail.restingCrop.width, thumbnail.hoverCrop.width)
        height: thumbnail.scaledCrop(thumbnail.restingCrop.height, thumbnail.hoverCrop.height)
        source: thumbnail.artwork
        opacity: thumbnail.artworkOpacity
        fillMode: Image.PreserveAspectCrop
        mipmap: true
    }
}
