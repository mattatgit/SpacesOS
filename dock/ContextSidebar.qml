import QtQuick

Item {
    id: sidebar
    required property bool opened
    required property bool personal
    required property Component personalContent
    required property Component sharedContent
    property bool reducedMotion: false
    property real reveal: opened ? 1 : 0
    readonly property bool showing: reveal > 0
    implicitWidth: 408
    implicitHeight: 612
    clip: true

    onOpenedChanged: if (opened && personal) personalPage.active = true
    Component.onCompleted: if (opened && personal) personalPage.active = true
    onPersonalChanged: if (opened && personal) personalPage.active = true
    Behavior on reveal {
        NumberAnimation {
            duration: sidebar.reducedMotion ? 0 : 100
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0, 0, 0.58, 1, 1, 1]
        }
    }

    Item {
        x: (1 - sidebar.reveal) * 36
        width: parent.width
        height: parent.height
        opacity: sidebar.reveal
        visible: sidebar.showing
        enabled: sidebar.opened
        Loader {
            id: personalPage
            anchors.fill: parent
            // Once opened, this page owns the draft, retry and running transfer
            // until shell exit. Cut its visibility immediately at a Space change.
            active: false
            visible: sidebar.personal
            sourceComponent: sidebar.personalContent
        }
        Loader {
            anchors.fill: parent
            active: (sidebar.opened || sidebar.showing) && !sidebar.personal
            sourceComponent: sidebar.sharedContent
        }
    }
}
