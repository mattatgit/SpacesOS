import QtQuick
import "DockProfiles.js" as DockProfiles

Item {
    id: dock

    required property DockState dockState
    required property string tooltipFont
    required property bool returnHovered
    readonly property real sizeFactor: implicitHeight / DockProfiles.dragMinimum
    readonly property var dividers: [64, 628]
    property real itemLift: returnHovered ? 4 * sizeFactor : 0
    readonly property var spaces: [
        { label: "Home", crop: Qt.rect(-4, -17, 87, 87), hover: Qt.rect(-12.7, -25.7, 104.4, 104.4) },
        { label: "Private", crop: Qt.rect(-1, -7, 82, 55), hover: Qt.rect(-9, -13, 99, 66) },
        { label: "Shared", crop: Qt.rect(0, -6, 80, 53), hover: Qt.rect(-8, -12, 97, 65) },
        { label: "Shared", crop: Qt.rect(0, -8, 80, 54), hover: Qt.rect(-8, -13.4, 97.2, 64.8) },
        { label: "Community", crop: Qt.rect(0, -7, 80, 53), hover: Qt.rect(-8, -12, 97, 65) },
        { label: "Community", crop: Qt.rect(0, -8, 84, 56), hover: Qt.rect(-8.4, -13.6, 100.8, 67.2) }
    ]

    objectName: "spacesDock"
    implicitWidth: 692 * sizeFactor
    implicitHeight: Math.max(DockProfiles.dragMinimum, dockState.profile)

    Behavior on itemLift {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
    }

    function focusSelection(reason: int): void {
        thumbnails.itemAt(dockState.selectedSpace).forceActiveFocus(reason);
    }

    Timer {
        id: createNotice
        interval: 2400
    }

    Connections {
        target: dock.dockState
        function onCreateSpaceRequested(): void { createNotice.restart(); }
    }

    function moveFocus(index: int, step: int): void {
        const next = (index + step + 8) % 8;
        const target = next === 0 ? createButton : next === 7 ? binButton : thumbnails.itemAt(next - 1);
        target.forceActiveFocus(step > 0 ? Qt.TabFocusReason : Qt.BacktabFocusReason);
    }

    Item {
        id: tooltips
        z: 1
        width: parent.width
        anchors.bottom: parent.top
        anchors.bottomMargin: 8
    }

    Flickable {
        id: strip

        anchors.fill: parent
        contentWidth: dock.implicitWidth
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        interactive: width < contentWidth
        clip: true

        function reveal(button: Item): void {
            if (button.x < contentX)
                contentX = button.x;
            else if (button.x + button.width > contentX + width)
                contentX = button.x + button.width - width;
        }

        Repeater {
            model: dock.dividers

            DockDivider {
                required property int index
                required property int modelData
                objectName: "spaces-divider-" + index
                dockState: dock.dockState
                centerX: modelData * dock.sizeFactor
                length: 40.5 * dock.sizeFactor
                source: "assets/space-divider.svg"
            }
        }

        DockButton {
            id: createButton

            objectName: "createSpace"
            x: 6 * dock.sizeFactor
            width: 52 * dock.sizeFactor
            height: dock.height
            hoverEnabled: !dock.returnHovered
            label: "Create a space"
            notice: createNotice.running ? "Space creation is simulated" : ""
            tooltipFont: dock.tooltipFont
            tooltipLayer: tooltips
            tooltipOffset: -strip.contentX

            onMoveFocus: step => dock.moveFocus(0, step)
            onActiveFocusChanged: if (activeFocus) strip.reveal(createButton)
            onClicked: dock.dockState.createSpaceRequested()

            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -dock.itemLift
                    width: 56.873 * dock.sizeFactor
                    height: width
                    source: createButton.hovered || createButton.visualFocus
                        ? "assets/space-create-hover.svg" : "assets/space-create.svg"
                }
            }
        }

        Repeater {
            id: thumbnails
            model: dock.spaces

            DockButton {
                id: tile

                required property int index
                required property var modelData

                objectName: "space-" + (index + 1)
                x: (70 + 92 * index) * dock.sizeFactor
                width: 92 * dock.sizeFactor
                height: dock.height
                hoverEnabled: !dock.returnHovered
                label: modelData.label
                description: "Space " + (index + 1) + (selected ? ", selected" : "")
                tooltipFont: dock.tooltipFont
                tooltipLayer: tooltips
                tooltipOffset: -strip.contentX
                selected: dock.dockState.selectedSpace === index

                onMoveFocus: step => dock.moveFocus(index + 1, step)
                onActiveFocusChanged: if (activeFocus) strip.reveal(tile)
                onClicked: dock.dockState.selectedSpace = index

                contentItem: Item {
                    SpaceThumbnail {
                        id: thumbnail

                        objectName: tile.objectName + "-artwork"
                        x: 6 * dock.sizeFactor
                        y: 12 * dock.sizeFactor - dock.itemLift
                        sizeFactor: dock.sizeFactor
                        artwork: "assets/space-" + (tile.index + 1) + ".png"
                        restingCrop: tile.modelData.crop
                        hoverCrop: tile.modelData.hover
                        highlighted: tile.hovered || tile.visualFocus
                        artworkOpacity: tile.index === 3 ? 0.9 : 1
                    }

                    Rectangle {
                        anchors.fill: thumbnail
                        radius: 8 * dock.sizeFactor
                        color: "transparent"
                        border.color: "#eeffffff"
                        visible: tile.visualFocus
                    }

                    Rectangle {
                        objectName: tile.objectName + "-indicator"
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 56 * dock.sizeFactor - dock.itemLift
                        width: 8 * dock.sizeFactor
                        height: 4 * dock.sizeFactor
                        radius: height / 2
                        color: "white"
                        visible: tile.selected
                    }
                }
            }
        }

        DockButton {
            id: binButton

            objectName: "spacesBin"
            x: 634 * dock.sizeFactor
            width: 52 * dock.sizeFactor
            height: dock.height
            hoverEnabled: !dock.returnHovered
            label: "Bin"
            description: dock.dockState.binFull ? "Full" : "Empty"
            tooltipFont: dock.tooltipFont
            tooltipLayer: tooltips
            tooltipOffset: -strip.contentX

            onMoveFocus: step => dock.moveFocus(7, step)
            onActiveFocusChanged: if (activeFocus) strip.reveal(binButton)
            onClicked: dock.dockState.activate("bin")

            contentItem: Item {
                Image {
                    id: fullBin

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -dock.itemLift
                    width: 36 * dock.sizeFactor
                    height: width
                    source: "assets/bin-full.png"
                    fillMode: Image.PreserveAspectFit
                    visible: dock.dockState.binFull
                    mipmap: true
                }
                Image {
                    anchors.fill: fullBin
                    source: "assets/bin-empty.png"
                    fillMode: Image.PreserveAspectFit
                    visible: !dock.dockState.binFull
                    mipmap: true
                }
            }
        }
    }
}
