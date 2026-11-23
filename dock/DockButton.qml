import QtQuick
import QtQuick.Controls.Basic

AbstractButton {
    id: button

    property string label
    property string description
    property string tooltipFont: "Inter Tight"
    property Item tooltipLayer
    property real tooltipOffset: 0
    property bool selected: false
    readonly property bool tooltipVisible: hovered || visualFocus

    signal moveFocus(int step)

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: 0
    Accessible.name: label
    Accessible.description: description

    Keys.onLeftPressed: button.moveFocus(-1)
    Keys.onRightPressed: button.moveFocus(1)
    Keys.onReturnPressed: button.click()
    Keys.onEnterPressed: button.click()

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
    }

    Loader {
        parent: button.tooltipLayer
        active: button.tooltipLayer !== null && button.visible && button.tooltipVisible
        x: {
            if (!active)
                return 0;
            const center = button.x + button.width / 2 + button.tooltipOffset;
            return Math.max(4, Math.min(parent.width - width - 4, Math.round(center - width / 2)));
        }
        anchors.bottom: parent ? parent.bottom : undefined

        sourceComponent: Rectangle {
            objectName: "tooltip-" + button.objectName
            implicitWidth: tooltipText.implicitWidth + 16
            implicitHeight: 24
            radius: 8
            color: "#b3ffffff"

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: button.label
                color: "#171717"
                font.family: button.tooltipFont
                font.pixelSize: 10
                font.weight: Font.Medium
                textFormat: Text.PlainText
            }
        }
    }
}
