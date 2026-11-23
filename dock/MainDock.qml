import QtQuick
import "DockProfiles.js" as DockProfiles

Item {
    id: dock

    required property DockState dockState
    required property string tooltipFont
    readonly property var profile: DockProfiles.profiles[dockState.profile]
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
        model: dock.profile.dividers

        DockDivider {
            required property int modelData
            x: modelData - width / 2
            y: (dock.height - height) / 2
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
            selected: dock.dockState.selectedItem === modelData.id

            onMoveFocus: step => buttons.itemAt((index + step + buttons.count) % buttons.count)
                .forceActiveFocus(step > 0 ? Qt.TabFocusReason : Qt.BacktabFocusReason)
            onClicked: dock.dockState.activate(modelData.id)

            background: Rectangle {
                x: 6
                y: button.box[1]
                width: button.box[2]
                height: width
                radius: width / 2
                opacity: button.highlighted ? 1 : 0
                gradient: Gradient {
                    GradientStop { position: 0.4125; color: button.selected ? "#28ffffff" : "transparent" }
                    GradientStop { position: 1; color: button.selected ? "#96ffffff" : "#4dc1c1c1" }
                }
                border.width: button.visualFocus ? 1 : 0
                border.color: "#ccffffff"

                Behavior on opacity { NumberAnimation { duration: 100 } }
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
                    scale: button.highlighted ? 0.9 : 1
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
