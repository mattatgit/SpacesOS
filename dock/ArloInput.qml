import QtQuick
import QtQuick.Controls.Basic

Item {
    id: input
    required property var controller
    required property string family
    required property int profile
    readonly property real factor: profile / 64
    implicitWidth: 384 * factor
    implicitHeight: profile
    function focusInput(): void { field.forceActiveFocus(Qt.OtherFocusReason); }
    onVisibleChanged: if (visible) Qt.callLater(focusInput)

    ToolButton {
        id: mark
        x: 8 * input.factor
        anchors.verticalCenter: parent.verticalCenter
        width: 48 * input.factor; height: parent.height
        Accessible.name: qsTr("Dismiss Arlo")
        onClicked: input.controller.opened = false
        background: Rectangle { color: "transparent"; border.width: mark.visualFocus ? 1 : 0; border.color: "white"; radius: 8 }
        contentItem: Item {
            Image { anchors.centerIn: parent; width: 40 * input.factor; height: width; source: "assets/bot.png"; fillMode: Image.PreserveAspectFit; mipmap: true }
        }
    }
    TextField {
        id: field
        anchors { left: mark.right; right: send.left; verticalCenter: parent.verticalCenter; leftMargin: 8 * input.factor }
        height: parent.height
        leftPadding: 8 * input.factor; rightPadding: 2
        font.family: input.family; font.pixelSize: 14 * input.factor
        color: "white"; placeholderTextColor: "#e6ffffff"; selectionColor: "#476768"
        background: null
        text: input.controller?.draft || ""
        placeholderText: qsTr("Ask for anything or search")
        Accessible.name: qsTr("Ask Arlo")
        maximumLength: 1000
        enabled: input.controller?.online && input.controller.threadId > 0
        onTextEdited: input.controller.edit(text)
        onAccepted: input.controller.ask()
        Keys.onEscapePressed: input.controller.opened = false
    }
    ToolButton {
        id: send
        anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter
        visible: field.text.trim().length > 0
        width: visible ? 45 : 0; height: 32
        text: qsTr("Send"); enabled: !input.controller?.busy
        font.family: input.family; font.pixelSize: 12
        onClicked: input.controller.ask()
        background: Rectangle { radius: 8; color: send.hovered ? "#ddffffff" : "#b3ffffff" }
    }
}
