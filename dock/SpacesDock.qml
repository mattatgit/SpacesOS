import QtQuick
import "DockProfiles.js" as DockProfiles

Item {
    id: dock

    required property DockState dockState
    required property string tooltipFont
    required property bool returnHovered
    readonly property real sizeFactor: implicitHeight / DockProfiles.dragMinimum
    readonly property SpaceNavigation navigation: dockState.navigation
    readonly property real trailingDivider: 76 + 92 * navigation.spaces.length
    readonly property var dividers: [64, trailingDivider]
    property real itemLift: returnHovered ? 4 * sizeFactor : 0

    objectName: "spacesDock"
    implicitWidth: (trailingDivider + 64) * sizeFactor
    implicitHeight: Math.max(DockProfiles.dragMinimum, dockState.profile)

    Behavior on itemLift {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
    }

    function focusSelection(reason: int): void {
        thumbnails.itemAt(navigation.activeIndex).forceActiveFocus(reason);
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
        const count = thumbnails.count + 2;
        const next = (index + step + count) % count;
        const target = next === 0 ? createButton : next === count - 1 ? binButton : thumbnails.itemAt(next - 1);
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
            model: dock.navigation.spaces

            DockButton {
                id: tile

                required property int index
                required property var modelData

                objectName: "space-" + modelData.id
                x: (70 + 92 * index) * dock.sizeFactor
                width: 92 * dock.sizeFactor
                height: dock.height
                hoverEnabled: !dock.returnHovered
                label: modelData.title
                description: modelData.access + qsTr(" Space") + (selected ? qsTr(", active") : "")
                tooltipFont: dock.tooltipFont
                tooltipLayer: tooltips
                tooltipOffset: -strip.contentX
                selected: dock.navigation.activeSpace.id === modelData.id

                onMoveFocus: step => dock.moveFocus(index + 1, step)
                onActiveFocusChanged: if (activeFocus) strip.reveal(tile)
                onClicked: dock.navigation.select(modelData.id)

                contentItem: Item {
                    SpaceThumbnail {
                        id: thumbnail

                        objectName: tile.objectName + "-artwork"
                        x: 6 * dock.sizeFactor
                        y: 12 * dock.sizeFactor - dock.itemLift
                        sizeFactor: dock.sizeFactor
                        artwork: tile.modelData.thumbnail
                        restingCrop: tile.modelData.crop
                        hoverCrop: tile.modelData.hover
                        highlighted: tile.hovered || tile.visualFocus
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
            x: (dock.trailingDivider + 6) * dock.sizeFactor
            width: 52 * dock.sizeFactor
            height: dock.height
            hoverEnabled: !dock.returnHovered
            label: "Bin"
            description: dock.dockState.binFull ? "Full" : "Empty"
            tooltipFont: dock.tooltipFont
            tooltipLayer: tooltips
            tooltipOffset: -strip.contentX

            onMoveFocus: step => dock.moveFocus(thumbnails.count + 1, step)
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
