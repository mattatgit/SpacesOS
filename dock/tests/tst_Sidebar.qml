import QtQuick
import QtTest
import ".."

Item {
    id: host
    width: 408
    height: 512
    ContextSidebar {
        id: sidebar
        anchors.fill: parent
        opened: false
        personal: true
        reducedMotion: true
        personalContent: Item {
            id: conversation
            objectName: "personalPage"
            property string draft: ""
            property string failed: ""
            property bool completed: false
            property Timer transfer: Timer {
                interval: 100
                onTriggered: conversation.completed = true
            }
        }
        sharedContent: Item { objectName: "sharedPage" }
    }
    TestCase {
        name: "ContextSidebar"
        when: windowShown
        function test_privateLifecycle() {
            verify(!findChild(sidebar, "personalPage"));
            sidebar.opened = true;
            const page = findChild(sidebar, "personalPage");
            verify(page.visible);
            page.draft = "private";
            page.failed = "retry";
            page.transfer.start();
            sidebar.opened = false;
            tryCompare(page, "visible", false);
            tryCompare(page, "completed", true);
            sidebar.personal = false;
            sidebar.opened = true;
            tryCompare(findChild(sidebar, "sharedPage"), "visible", true);
            verify(!page.visible);
            sidebar.opened = false;
            sidebar.personal = true;
            sidebar.opened = true;
            tryCompare(page, "visible", true);
            compare(findChild(sidebar, "personalPage"), page);
            compare(page.draft, "private");
            compare(page.failed, "retry");
        }
    }
}
