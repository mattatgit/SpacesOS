import QtQuick

Item {
    id: dock

    required property DockState dockState
    required property string tooltipFont
    readonly property var spaces: [
        { label: "Home", crop: Qt.rect(-4, -17, 87, 87), hover: Qt.rect(-12.7, -25.7, 104.4, 104.4) },
        { label: "Private", crop: Qt.rect(-1, -7, 82, 55), hover: Qt.rect(-9, -13, 99, 66) },
        { label: "Shared", crop: Qt.rect(0, -6, 80, 53), hover: Qt.rect(-8, -12, 97, 65) },
        { label: "Shared", crop: Qt.rect(0, -8, 80, 54), hover: Qt.rect(-8, -13.4, 97.2, 64.8) },
        { label: "Community", crop: Qt.rect(0, -7, 80, 53), hover: Qt.rect(-8, -12, 97, 65) },
        { label: "Community", crop: Qt.rect(0, -8, 84, 56), hover: Qt.rect(-8.4, -13.6, 100.8, 67.2) }
    ]

    objectName: "spacesDock"
    implicitWidth: 692
    implicitHeight: 64

    function focusSelection(reason: int): void {
        thumbnails.itemAt(dockState.selectedSpace).forceActiveFocus(reason);
    }

    function moveFocus(index: int, step: int): void {
        const next = (index + step + 8) % 8;
        const target = next === 0 ? createButton : next === 7 ? binButton : thumbnails.itemAt(next - 1);
        target.forceActiveFocus(step > 0 ? Qt.TabFocusReason : Qt.BacktabFocusReason);
    }

    DockSurface {
        anchors.fill: parent
        tint: "#4dffffff"
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
            model: [64, 628]

            DockDivider {
                required property int modelData
                x: modelData - width / 2
                y: (dock.height - height) / 2
                source: "assets/space-divider.svg"
            }
        }

        DockButton {
            id: createButton

            objectName: "createSpace"
            x: 6
            width: 52
            height: dock.height
            label: "Create a space"
            tooltipFont: dock.tooltipFont
            tooltipLayer: tooltips
            tooltipOffset: -strip.contentX

            onMoveFocus: step => dock.moveFocus(0, step)
            onActiveFocusChanged: if (activeFocus) strip.reveal(createButton)
            onClicked: dock.dockState.createSpaceRequested()

            contentItem: Item {
                Image {
                    anchors.centerIn: parent
                    width: 56.873
                    height: width
                    source: createButton.highlighted ? "assets/space-create-hover.svg" : "assets/space-create.svg"
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
                x: 70 + 92 * index
                width: 92
                height: dock.height
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
                        x: 6
                        y: 12
                        artwork: "assets/space-" + (tile.index + 1) + ".png"
                        restingCrop: tile.modelData.crop
                        hoverCrop: tile.modelData.hover
                        highlighted: tile.hovered || tile.visualFocus
                        artworkOpacity: tile.index === 3 ? 0.9 : 1
                    }

                    Rectangle {
                        x: 6
                        y: 12
                        width: 80
                        height: 40
                        radius: 8
                        color: "transparent"
                        border.color: "#eeffffff"
                        visible: tile.visualFocus
                    }

                    Rectangle {
                        objectName: tile.objectName + "-indicator"
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 56
                        width: 8
                        height: 4
                        radius: 2
                        color: "white"
                        visible: tile.selected
                    }
                }
            }
        }

        DockButton {
            id: binButton

            objectName: "spacesBin"
            x: 634
            width: 52
            height: dock.height
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
                    anchors.centerIn: parent
                    width: 36
                    height: width
                    source: "assets/bin-full.png"
                    fillMode: Image.PreserveAspectFit
                    visible: dock.dockState.binFull
                    mipmap: true
                }
                Image {
                    anchors.centerIn: parent
                    width: 36
                    height: width
                    source: "assets/bin-empty.png"
                    fillMode: Image.PreserveAspectFit
                    visible: !dock.dockState.binFull
                    mipmap: true
                }
            }
        }
    }
}
