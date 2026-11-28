import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: arlo
    required property bool personal
    property bool opened: false
    property bool online: false
    property int epoch: 0
    property int serial: 0
    property int draftSerial: 0
    property int threadId: 0
    property string draft: ""
    property string error: ""
    property var tasks: []
    property var threads: []
    readonly property var latest: tasks.length ? tasks[tasks.length - 1] : null
    readonly property bool busy: tasks.some(task => task.state === "working")
    signal heightConfirmed(int height)

    function send(action: string, args: var): int {
        if (!online) return 0;
        const message = Object.assign({action, epoch, thread: threadId, serial: ++serial}, args || {});
        process.write(JSON.stringify(message) + "\n");
        return serial;
    }
    function changeContext(): void {
        ++epoch;
        opened = false;
        tasks = []; threads = []; draft = ""; error = ""; threadId = 0;
        send("context", {space: personal ? "home" : "unavailable"});
    }
    onPersonalChanged: changeContext()
    function edit(text: string): void {
        draft = text;
        draftSerial = send("draft", {text});
    }
    function ask(): void {
        if (personal && draft.trim() && !busy) send("ask", {text: draft});
    }
    function reconnect(): void { if (!process.running) process.running = true; }
    function receive(line: string): void {
        const data = JSON.parse(line);
        heightConfirmed(data.height);
        if (!online) {
            online = true;
            send("context", {space: personal ? "home" : "unavailable"});
            return;
        }
        if (data.epoch !== epoch || !personal || data.thread === undefined) return;
        threadId = data.thread;
        if (data.serial >= draftSerial) draft = data.draft;
        if (JSON.stringify(tasks) !== JSON.stringify(data.tasks)) tasks = data.tasks;
        if (JSON.stringify(threads) !== JSON.stringify(data.threads)) threads = data.threads;
        error = data.error;
    }
    readonly property Process process: Process {
        command: ["python3", "-B", Quickshell.shellPath("../arlo/service.py")]
        stdinEnabled: true
        running: true
        stdout: SplitParser { onRead: line => arlo.receive(line) }
        onExited: {
            arlo.online = false;
            arlo.tasks = []; arlo.threads = []; arlo.threadId = 0;
            arlo.error = qsTr("The settings service stopped. Reconnect to recover your activity.");
        }
    }
}
