import QtQuick

Item {
    id: dock
    required property DockState dockState
    required property string tooltipFont
    required property bool returnHovered
    readonly property real slotWidth: Math.min(height * 0.88, (width - 16) / Math.max(1, apps.count))
    implicitWidth: 16 + apps.count * height * 0.88
    implicitHeight: dockState.profile
    function focusFirst(): void { apps.itemAt(0)?.forceActiveFocus(Qt.OtherFocusReason); }

    Item { id: tips; z: 1; width: parent.width; anchors.bottom: parent.top; anchors.bottomMargin: 8 }
    Repeater {
        id: apps
        model: dock.dockState.applications
        DockButton {
            id: button
            required property int index
            required property var modelData
            objectName: "launch-" + modelData.id
            x: 8 + index * dock.slotWidth
            width: dock.slotWidth
            height: dock.height
            label: modelData.name
            tooltipFont: dock.tooltipFont
            tooltipLayer: tips
            onClicked: dock.dockState.applicationRequested(modelData.id)
            onMoveFocus: step => apps.itemAt((index + step + apps.count) % apps.count)
                .forceActiveFocus(step > 0 ? Qt.TabFocusReason : Qt.BacktabFocusReason)
            background: Rectangle {
                anchors.centerIn: parent; width: icon.width + 6; height: width; radius: 6
                color: "transparent"; border.color: "white"; visible: button.visualFocus
            }
            contentItem: Item {
                Image {
                    id: icon
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: dock.returnHovered ? -4 : 0
                    width: Math.min(button.width - 4, button.height * 0.625); height: width
                    source: button.modelData.icon
                    fillMode: Image.PreserveAspectFit; mipmap: true
                    scale: button.hovered ? 0.96 : 1
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 100 } }
                }
            }
        }
    }
}
