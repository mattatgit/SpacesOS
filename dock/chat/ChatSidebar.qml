import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts

Rectangle {
    id: panel
    required property string fontFamily
    signal closed()
    radius: 16
    color: "#e6fafafa"
    property string attachment: ""
    property string txn: ""
    property string selectedEvent: ""
    property string openSaved: ""

    function send() {
        if (!chat.online || chat.activity || (!attachment && !draft.text.trim())) return
        if (!txn) txn = Date.now().toString(36) + Math.random().toString(36).slice(2)
        if (attachment) chat.act({op:"upload",url:attachment,txn:txn}, qsTr("Uploading…"))
        else chat.act({op:"text",body:draft.text,txn:txn}, qsTr("Sending…"))
    }
    function choose(url) {
        if (chat.activity || !url.toString().startsWith("file:")) return
        attachment = url.toString()
        txn = ""
        chat.notice = ""
    }

    Conversation {
        id: chat
        onSent: {
            if (panel.attachment) panel.attachment = ""
            else draft.clear()
            panel.txn = ""
            Qt.callLater(() => history.positionViewAtEnd())
        }
        onSaved: url => panel.openSaved = url
    }

    component LabelText: Text {
        color: "#1f231f"; font.family: panel.fontFamily; font.pixelSize: 14
        textFormat: Text.PlainText
    }
    component Action: Button {
        id: button
        font.family: panel.fontFamily; font.pixelSize: 13
        implicitHeight: 28
        contentItem: LabelText {
            text: button.text; font: button.font
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            color: button.enabled ? "#1f231f" : "#737973"
        }
        background: Rectangle {
            radius: 8; color: button.hovered || button.down ? "#e4e8e4" : "#f8f8f8"
            border.width: button.visualFocus ? 1 : 0
        }
    }

    Rectangle {
        id: header
        x: 8; y: 8; width: parent.width - 16; height: 40
        radius: 12; color: "#f9ffffff"
        Action {
            anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
            width: 24; height: 24
            contentItem: Item { Image { anchors.centerIn: parent; width: 10.1569; height: 7.5; source: "../assets/chat-back.svg" } }
            Accessible.name: qsTr("Close Chats")
            onClicked: panel.closed()
        }
        LabelText {
            anchors.centerIn: parent; text: qsTr("My Devices"); font.pixelSize: 16; font.weight: Font.DemiBold
        }
    }

    ListView {
        id: history
        anchors { top: header.bottom; topMargin: 12; bottom: statusRow.top; bottomMargin: 6; left: parent.left; right: parent.right }
        clip: true; spacing: 12
        model: chat.messages
        ScrollBar.vertical: ScrollBar {}
        header: Item {
            width: history.width; height: chat.before ? 32 : 0
            Action { visible: !!chat.before; anchors.centerIn: parent; text: qsTr("Earlier messages"); onClicked: chat.refresh(true) }
        }
        delegate: Item {
            id: row
            required property var modelData
            property string preview: ""
            width: history.width; implicitHeight: Math.max(36, details.implicitHeight) + 4
            Rectangle {
                x: 24; y: 2; width: 36; height: 36; radius: 10; color: "#c8ddd2"
                LabelText { visible: !chat.avatar; anchors.centerIn: parent; text: row.modelData.name.slice(0,1).toUpperCase() }
                Image { anchors.fill: parent; source: chat.avatar; fillMode: Image.PreserveAspectCrop }
            }
            Column {
                id: details
                x: 70; width: parent.width - x - 16; spacing: 4
                RowLayout {
                    width: parent.width; spacing: 7
                    LabelText { text: row.modelData.name; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.maximumWidth: parent.width * 0.54 }
                    LabelText { text: Qt.formatDateTime(new Date(row.modelData.time), "h:mm ap") + (row.modelData.local ? qsTr(" · this device") : ""); font.pixelSize: 10; color: "#6b6b6b"; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                LabelText { width: parent.width; wrapMode: Text.Wrap; text: row.modelData.body; color: row.modelData.kind === "locked" ? "#765a29" : "#171717" }
                LabelText {
                    visible: row.modelData.kind === "file" || row.modelData.kind === "image"
                    text: [row.modelData.mime, row.modelData.size != null ? Math.ceil(row.modelData.size/1024) + " KB" : ""].filter(Boolean).join(" · ")
                    width: parent.width; elide: Text.ElideRight; color: "#6b6b6b"; font.pixelSize: 11
                }
                Image { visible: !!row.preview; width: Math.min(240,parent.width); height: visible ? 120 : 0; source: row.preview; fillMode: Image.PreserveAspectFit; horizontalAlignment: Image.AlignLeft }
                Row {
                    visible: row.modelData.kind === "file" || row.modelData.kind === "image"; spacing: 6
                    Action {
                        visible: row.modelData.kind === "image"; enabled: chat.online && !chat.activity
                        text: qsTr("Preview"); onClicked: chat.act({op:"preview",event:row.modelData.id},qsTr("Loading image…"))
                    }
                    Action {
                        text: qsTr("Save…"); enabled: chat.online && !chat.activity
                        onClicked: { panel.selectedEvent = row.modelData.id; saveDialog.open() }
                    }
                }
            }
            Connections { target: chat; function onPreviewReady(eventId,source) { if (eventId === row.modelData.id) row.preview = source } }
        }
        LabelText {
            visible: !history.count && chat.online && !chat.refreshing
            anchors.centerIn: parent; text: qsTr("Send your first message to your devices."); color: "#6b6b6b"
        }
        property bool followTail: true
        onMovementEnded: followTail = atYEnd
        onCountChanged: if (followTail) Qt.callLater(() => history.positionViewAtEnd())
    }

    RowLayout {
        id: statusRow
        anchors { left: parent.left; leftMargin: 16; right: parent.right; rightMargin: 16; bottom: composer.top; bottomMargin: 4 }
        LabelText {
            Layout.fillWidth: true; font.pixelSize: 12; color: "#515851"; wrapMode: Text.Wrap
            text: chat.activity ? chat.activity + (chat.percent >= 0 ? " " + chat.percent + "%" : "") : !chat.online ? chat.status : chat.notice || (chat.typing ? qsTr("Typing on another device…") : chat.status)
        }
        Action { visible: chat.canRetry; text: qsTr("Retry"); onClicked: chat.refresh(false) }
        BusyIndicator { visible: !!chat.activity; running: visible; implicitWidth: 18; implicitHeight: 18 }
        Action { visible: !!panel.openSaved; text: qsTr("Show file"); onClicked: Qt.openUrlExternally(panel.openSaved.slice(0,panel.openSaved.lastIndexOf("/") + 1)) }
    }

    RowLayout {
        id: composer
        anchors { bottom: parent.bottom; bottomMargin: 16; left: parent.left; leftMargin: 16; right: parent.right; rightMargin: 16 }
        spacing: 8
        Action {
            implicitWidth: 24; Accessible.name: qsTr("Attach a file"); enabled: chat.online && !chat.activity
            contentItem: Item { Image { anchors.centerIn: parent; width: 17.5; height: 17.5; source: "../assets/chat-attach.svg" } }
            background: Item {}
            onClicked: picker.open()
        }
        TextField {
            id: draft
            Layout.fillWidth: true; implicitHeight: 40; leftPadding: 14; font.family: panel.fontFamily; font.pixelSize: 14
            visible: !panel.attachment; readOnly: !!chat.activity; placeholderText: qsTr("Message My Devices")
            color: "#171717"; background: Rectangle { radius: 16; color: "white"; border.color: draft.activeFocus ? "#9ea39e" : "#ebebeb" }
            onTextEdited: { panel.txn = ""; chat.notice = "" }
            onAccepted: panel.send()
        }
        Action {
            visible: !!panel.attachment; Layout.fillWidth: true; enabled: !chat.activity
            text: qsTr("Remove") + " · " + panel.attachment.split("/").pop().slice(-24)
            onClicked: { panel.attachment = ""; panel.txn = "" }
        }
        Action { text: qsTr("Send"); enabled: chat.online && !chat.activity && (!!panel.attachment || !!draft.text.trim()); onClicked: panel.send() }
    }
    DropArea {
        anchors.fill: parent; keys: ["text/uri-list"]
        onDropped: drop => { if (chat.online && drop.hasUrls && drop.urls.length === 1) { panel.choose(drop.urls[0]); drop.acceptProposedAction() } }
    }
    FileDialog { id: picker; title: qsTr("Attach a file"); onAccepted: panel.choose(selectedFile) }
    FileDialog { id: saveDialog; fileMode: FileDialog.SaveFile; title: qsTr("Save attachment under a new name"); onAccepted: chat.act({op:"save",event:panel.selectedEvent,url:selectedFile.toString()},qsTr("Downloading…")) }
}
