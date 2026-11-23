import QtQuick
import "DockProfiles.js" as DockProfiles

Item {
    id: dock

    required property DockState dockState
    required property string tooltipFont
    readonly property var profile: DockProfiles.atHeight(dockState.profile)
    readonly property var items: [
        { id: "bot", label: "Arlo" },
        { id: "spaces", label: "Spaces" },
        { id: "people", label: "People" },
        { id: "tools", label: "Tools" },
        { id: "files", label: "Files" },
        { id: "settings", label: "Settings" },
        { id: "bin", label: "Bin" }
    ]

    objectName: "mainDock"
    implicitWidth: profile.width
    implicitHeight: dockState.profile

    function focusSpaces(reason: int): void {
        buttons.itemAt(1).forceActiveFocus(reason);
    }

    DockSurface {
        anchors.fill: parent
        tint: dock.profile.tint
        outline: dock.profile.outline
        shadowColor: dock.profile.shadow
    }

    Item {
        id: tooltips
        z: 1
        width: parent.width
        anchors.bottom: parent.top
        anchors.bottomMargin: 8
    }

    Repeater {
        model: 2

        DockDivider {
            required property int index
            objectName: "main-divider-" + index
            dockState: dock.dockState
            centerX: dock.profile.dividers[index]
            source: "assets/" + dock.profile.divider
        }
    }

    Repeater {
        id: buttons
        model: dock.items

        DockButton {
            id: button
            required property int index
            required property var modelData
            readonly property var box: dock.profile.icons[index]
            readonly property bool isBin: modelData.id === "bin"

            x: box[0] - 6
            width: box[2] + 12
            height: dock.height
            objectName: modelData.id
            label: modelData.label
            description: isBin ? (dock.dockState.binFull ? "Full" : "Empty") : ""
            tooltipFont: dock.tooltipFont
            tooltipLayer: tooltips

            onMoveFocus: step => buttons.itemAt((index + step + buttons.count) % buttons.count)
                .forceActiveFocus(step > 0 ? Qt.TabFocusReason : Qt.BacktabFocusReason)
            onClicked: dock.dockState.activate(modelData.id)

            background: Item {
                x: 6
                y: button.box[1]
                width: button.box[2]
                height: width
                Rectangle {
                    objectName: button.objectName + "-hover"
                    anchors.fill: parent
                    radius: width / 2
                    opacity: button.hovered ? 1 : 0
                    gradient: Gradient {
                        GradientStop { position: 0.4125; color: "transparent" }
                        GradientStop { position: 1; color: "#4dc1c1c1" }
                    }
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: "#ccffffff"
                    visible: button.visualFocus
                }
            }

            contentItem: Item {
                Image {
                    id: artwork
                    objectName: button.objectName + "-artwork"
                    x: 6
                    y: button.box[1]
                    width: button.box[2]
                    height: width
                    fillMode: Image.PreserveAspectFit
                    source: "assets/" + (button.isBin ? "bin-full" : button.modelData.id) + ".png"
                    visible: !button.isBin || dock.dockState.binFull
                    scale: button.hovered ? 0.96 : 1
                    mipmap: true
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.InOutQuad } }
                }

                // Keep both Bin textures ready and switch visibility in the same slot.
                Image {
                    objectName: button.isBin ? "bin-empty-artwork" : ""
                    anchors.fill: artwork
                    source: button.isBin ? "assets/bin-empty.png" : ""
                    visible: button.isBin && !dock.dockState.binFull
                    fillMode: Image.PreserveAspectFit
                    scale: artwork.scale
                    mipmap: true
                }
            }
        }
    }
}
