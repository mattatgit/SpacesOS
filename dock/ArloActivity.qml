import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: card
    required property var controller
    required property string family
    property real maximumListHeight: 202
    readonly property bool expanded: controller?.opened ?? false
    readonly property bool hasActivity: !!controller?.latest
    readonly property real titleHeight: 38
    implicitHeight: expanded ? header.height + scope.height + list.height + errorRow.height + 13 : 32
    radius: expanded ? 16 : 10
    color: "#f2fafafa"
    border.color: "#66ffffff"; border.width: 1
    function status(state: string): string {
        return ({working:"Working…",completed:"Completed",undone:"Undone",failed:"Failed",
                 cancelled:"Cancelled",interrupted:"Interrupted"})[state] || state;
    }
    onVisibleChanged: if (!visible) history?.close()
    onExpandedChanged: if (!expanded) history?.close()
    component Link: Button {
        id: link
        font.family: card.family; font.pixelSize: 12; font.weight: Font.Medium
        leftPadding: 7; rightPadding: 7; topPadding: 2; bottomPadding: 2
        implicitHeight: 28
        contentItem: Text { text: link.text; font: link.font; color: link.enabled ? "#323232" : "#777f78"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter }
        background: Rectangle { radius: 6; color: link.hovered ? "#e4e8e4" : "transparent"; border.color: "#777f78"; border.width: link.visualFocus ? 1 : 0 }
    }
    Link {
        anchors.fill: parent; visible: !card.expanded
        text: card.hasActivity ? "Arlo · " + card.status(card.controller.latest.state) + "  ›" : "Arlo"
        Accessible.name: qsTr("Reopen Arlo activity")
        onClicked: card.controller.opened = true
    }
    Column {
        visible: card.expanded
        x: 12; width: parent.width - 24; y: 5
        RowLayout {
            id: header
            width: parent.width; height: card.titleHeight; spacing: 0
            Text { text: "Arlo"; Layout.leftMargin: 4; Layout.fillWidth: true; font.family: card.family; font.pixelSize: 16; font.bold: true; color: "#171717" }
            Link {
                text: qsTr("History"); visible: (card.controller?.threads.length || 0) > 1
                onClicked: history.open()
                Menu {
                    id: history
                    y: parent.height
                    Instantiator {
                        model: card.controller?.threads || []
                        MenuItem {
                            required property var modelData
                            text: modelData.title
                            onTriggered: card.controller.send("open", {thread:modelData.id})
                        }
                        onObjectAdded: (i,obj) => history.insertItem(i,obj)
                        onObjectRemoved: (i,obj) => history.removeItem(obj)
                    }
                }
            }
            Link { text: qsTr("New"); enabled: !!card.controller?.threadId; onClicked: card.controller.send("new") }
            Link { text: qsTr("Hide"); onClicked: card.controller.opened = false }
        }
        Text {
            id: scope
            x: 4; height: 23; text: qsTr("Home  ·  Personal shell preference")
            font.family: card.family; font.pixelSize: 12; color: "#525b53"
        }
        ListView {
            id: list
            width: parent.width; height: Math.min(contentHeight, card.maximumListHeight)
            clip: true; spacing: 4; model: card.controller?.tasks || []
            onCountChanged: Qt.callLater(positionViewAtEnd)
            onContentHeightChanged: if (atYEnd || count <= 2) Qt.callLater(positionViewAtEnd)
            ScrollBar.vertical: ScrollBar {}
            delegate: Rectangle {
                id: row
                required property var modelData
                width: list.width; height: body.implicitHeight + 12; radius: 8; color: "#e9ede9"
                Column {
                    id: body
                    x: 10; y: 6; width: parent.width - 20; spacing: 3
                    Text { width: parent.width; text: row.modelData.request; textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere; font.family: card.family; font.weight: Font.DemiBold; font.pixelSize: 14; color: "#171717" }
                    Text { width: parent.width; visible: text.length > 0; text: row.modelData.result; textFormat: Text.PlainText; wrapMode: Text.WordWrap; font.family: card.family; font.pixelSize: 14; color: "#323232" }
                    RowLayout {
                        width: parent.width; height: 26
                        Text { Layout.fillWidth: true; text: card.status(row.modelData.state); font.family: card.family; font.pixelSize: 12; color: "#596159" }
                        Link { text: qsTr("Undo"); visible: !!row.modelData.canUndo; onClicked: card.controller.send("undo",{id:row.modelData.id}) }
                        Link { text: qsTr("Retry"); visible: ["failed","cancelled","interrupted"].includes(row.modelData.state); enabled: !card.controller?.busy; onClicked: card.controller.send("retry",{id:row.modelData.id}) }
                        Link { text: qsTr("Cancel"); visible: row.modelData.state === "working"; onClicked: card.controller.send("cancel",{id:row.modelData.id}) }
                    }
                }
            }
        }
        RowLayout {
            id: errorRow
            width: parent.width; height: visible ? implicitHeight : 0; visible: !!card.controller?.error
            Text { Layout.fillWidth: true; text: card.controller?.error || ""; wrapMode: Text.WordWrap; textFormat: Text.PlainText; font.family: card.family; font.pixelSize: 12; color: "#80382c" }
            Link { visible: !card.controller?.online; text: qsTr("Reconnect"); onClicked: card.controller.reconnect() }
        }
    }
}
