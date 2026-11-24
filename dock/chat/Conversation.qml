import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: chat
    property var messages: []
    property string avatar: ""
    property string before: ""
    property string status: qsTr("Connecting…")
    property string notice: ""
    property string verification: ""
    property string failedSend: ""
    property string activity: ""
    property int percent: -1
    property bool online: false
    readonly property bool canRetry: service.running && !refreshing && !online
    property bool typing: false
    property Timer typingTimeout: Timer { interval: 8000; onTriggered: chat.typing = false }
    property bool refreshing: false
    property bool dirty: false
    property int serial: 0
    property var callbacks: ({})
    property bool avatarRequested: false
    signal sent()
    signal previewReady(string eventId, string source)
    signal saved(string url)

    function request(args, done) {
        if (!service.running) return
        args.serial = ++serial
        callbacks[serial] = done
        service.write(JSON.stringify(args) + "\n")
    }

    function refresh(older) {
        if (refreshing) { dirty = true; return }
        refreshing = true
        const token = older ? before : null
        request({op: "history", before: token}, (err, data) => {
            refreshing = false
            if (err) {
                online = false
                status = verification ? qsTr("Verification required") : err
                messages = []
                before = ""
                avatar = ""
                avatarRequested = false
            } else {
                online = true
                status = qsTr("Encrypted")
                const rows = data.items
                if (older) {
                    const seen = new Set(messages.map(m => m.id))
                    messages = rows.filter(m => !seen.has(m.id)).concat(messages)
                } else if (rows.length && messages.some(m => m.id === rows[0].id)) {
                    messages = messages.slice(0, messages.findIndex(m => m.id === rows[0].id)).concat(rows)
                } else {
                    messages = rows
                    before = data.previous || ""
                }
                if (older) before = data.previous || ""
                if (!avatarRequested) {
                    avatarRequested = true
                    request({op:"avatar"}, (error, result) => { if (!error && result) avatar = result })
                }
            }
            if (dirty) { dirty = false; refresh(false) }
        })
    }

    function act(args, label) {
        if (activity || !online) return
        notice = ""
        percent = -1
        activity = label
        request(args, (err, data) => {
            activity = ""
            if (err) {
                if (args.op === "text" || args.op === "upload") failedSend = err
                else notice = err
                return
            }
            if (args.op === "preview") previewReady(args.event, data)
            else if (args.op === "save") { notice = qsTr("Saved"); saved(args.url) }
            else { failedSend = ""; verification = ""; notice = qsTr("Sent"); sent(); refresh(false) }
        })
    }

    property Process service: Process {
        command: [Quickshell.shellPath("../scripts/chat"), "serve"]
        stdinEnabled: true
        running: true
        stdout: SplitParser {
            onRead: line => {
                let msg
                try { msg = JSON.parse(line) } catch (_) { return }
                if (msg.type === "progress" && msg.total > 0) chat.percent = Math.min(100,Math.round(100 * msg.current/msg.total))
                if (msg.type === "typing") {
                    chat.typing = msg.active
                    if (msg.active) chat.typingTimeout.restart()
                }
                if (msg.type === "changed") chat.refresh(false)
                if (msg.type === "offline") { chat.online = false; chat.status = qsTr("Offline · Reconnecting…") }
                if (msg.type === "unavailable") { chat.status = msg.message; chat.online = false }
                if (msg.type === "reply" && chat.callbacks[msg.serial]) {
                    const done = chat.callbacks[msg.serial]
                    delete chat.callbacks[msg.serial]
                    if (msg.verification) chat.verification = msg.error
                    done(msg.error, msg.data)
                }
            }
        }
        onExited: {
            if (chat.online || chat.status === qsTr("Connecting…"))
                chat.status = qsTr("Messaging stopped. Close and reopen Chats to reconnect.")
            chat.online = false
            chat.refreshing = false
            if (chat.activity) chat.notice = qsTr("Delivery unconfirmed. Check history before retrying.")
            chat.activity = ""
            chat.callbacks = ({})
        }
    }
}
