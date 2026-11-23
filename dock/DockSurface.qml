import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: surface

    required property color tint
    property color outline: "transparent"
    property color shadowColor: "#26000000"
    readonly property int shadowMargin: 20

    // The Figma shadow falls outside the glass, leaving the tint uniform inside.
    Item {
        id: shadow
        anchors.fill: parent
        anchors.margins: -surface.shadowMargin
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskInverted: true
            maskSource: shadowMask
        }

        RectangularShadow {
            anchors.fill: parent
            anchors.margins: surface.shadowMargin
            radius: 16
            blur: 15
            color: surface.shadowColor
        }
    }

    Item {
        id: shadowMask
        anchors.fill: shadow
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: surface.shadowMargin
            radius: 16
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: surface.tint
            strokeColor: surface.outline
            strokeWidth: 0.5

            PathRectangle {
                x: 0.25
                y: 0.25
                width: surface.width - 0.5
                height: surface.height - 0.5
                radius: 16
            }
        }
    }
}
