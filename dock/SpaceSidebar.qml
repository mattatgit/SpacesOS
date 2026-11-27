import QtQuick
import "chat"

ContextSidebar {
    id: sidebar
    required property DesktopState desktop
    opened: desktop.sidebarOpen && desktop.navigation.inside
    personal: desktop.personal
    reducedMotion: desktop.reducedMotion

    personalContent: ChatSidebar {
        fontFamily: sidebar.desktop.fontFamily
        interactive: sidebar.opened && sidebar.personal
        onClosed: sidebar.desktop.sidebarOpen = false
    }
    sharedContent: Rectangle {
        radius: 16
        color: "#e6fafafa"
        visible: sidebar.desktop.navigation.inside
        Text {
            x: 24; y: 20
            text: sidebar.desktop.navigation.activeSpace.title
            font.family: sidebar.desktop.fontFamily; font.pixelSize: 16; font.weight: Font.DemiBold
        }
        Text {
            x: 24; y: 56
            text: qsTr("No shared Shelf content yet.")
            font.family: sidebar.desktop.fontFamily; font.pixelSize: 14; color: "#565b56"
        }
    }
}
