import QtQuick
import QtQuick.Controls.Basic

Rectangle {
    id: bar

    required property var space
    required property string fontFamily
    required property bool pickerOpen
    property bool chatOpen: false
    signal toggleChat()
    signal togglePicker()
    signal leaveSpace()
    signal moveWindow()

    implicitHeight: 48
    color: "#bf202323"

    MouseArea {
        anchors.fill: parent
        onPressed: bar.moveWindow()
    }

    component BarButton: Button {
        hoverEnabled: true
        font.family: bar.fontFamily
        font.pixelSize: 14
        leftPadding: 12
        rightPadding: 12
        verticalPadding: 4
        contentItem: Text {
            text: parent.text
            font: parent.font
            color: "white"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
        background: Rectangle {
            radius: 6
            color: parent.hovered || parent.down || parent.checked ? "#33ffffff" : "transparent"
            border.width: parent.visualFocus ? 1 : 0
            border.color: "white"
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        BarButton {
            objectName: "toggleSpaces"
            text: qsTr("Spaces")
            checked: bar.pickerOpen
            Accessible.description: qsTr("Show or hide the Space picker")
            onClicked: bar.togglePicker()
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1; height: 16; color: "#52ffffff"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.space.title
            font.family: bar.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: "white"
        }
        BarButton {
            visible: bar.space.id === "home"
            text: qsTr("Chats")
            checked: bar.chatOpen
            onClicked: bar.toggleChat()
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 8; height: width; radius: width / 2
            color: bar.space.accent
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: bar.space.access
            font.family: bar.fontFamily
            font.pixelSize: 14
            color: "white"
        }

        BarButton {
            objectName: "leaveSpace"
            text: qsTr("Leave Space")
            onClicked: bar.leaveSpace()
        }
    }
}
