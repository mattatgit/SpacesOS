//@ pragma AppId org.spacesos.Shell
import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    settings.watchFiles: false
    DesktopState { id: desktop; independent: true }
    WorkspaceBridge { desktop: desktop }
    ApplicationMenu { id: appMenu }

    PanelWindow {
        id: wallpaper
        anchors { left: true; right: true; top: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "spaces-wallpaper"
        WlrLayershell.layer: WlrLayer.Background
        color: "#242725"
        SpaceScene {
            anchors.fill: parent; navigation: desktop.navigation
            visible: navigation.inside; reducedMotion: desktop.reducedMotion
        }
    }
    PanelWindow {
        screen: wallpaper.screen
        anchors { left: true; right: true; top: true }
        implicitHeight: 48
        exclusiveZone: 48
        WlrLayershell.namespace: "spaces-bar"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"
        SpaceBar {
            anchors.fill: parent
            desktop: desktop; applicationMenu: appMenu
            onLeaveSpace: desktop.leave()
            onExitSession: desktop.loginSession ? Quickshell.execDetached(["spaces-control", "logout"]) : Qt.quit()
            onLaunchNotes: Quickshell.execDetached(["gjs", Quickshell.shellPath("../session/notes.js")])
            onLaunchViewer: Quickshell.execDetached(["gtk3-icon-browser"])
        }
    }
    PanelWindow {
        screen: wallpaper.screen
        anchors { bottom: true; left: true; right: true }
        implicitHeight: dock.implicitHeight
        exclusiveZone: dock.currentDock.height + dock.edgeInset
        WlrLayershell.namespace: "spaces-dock"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        color: "transparent"
        mask: Region {
            item: dock.currentDock
            Region { item: desktop.subDockOpen ? dock.returnTarget : null }
        }
        DockView { id: dock; anchors.fill: parent; dockState: desktop; tooltipFont: desktop.fontFamily }
    }
    PanelWindow {
        screen: wallpaper.screen
        anchors { top: true; right: true }
        margins { top: 64; right: 16 }
        implicitWidth: Math.min(408, wallpaper.width - 32)
        implicitHeight: Math.min(612, Math.max(1, wallpaper.height - 80))
        exclusionMode: ExclusionMode.Ignore
        visible: desktop.sidebarOpen || sidebar.showing
        WlrLayershell.namespace: "spaces-sidebar"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        color: "transparent"
        SpaceSidebar { id: sidebar; anchors.fill: parent; desktop: desktop }
    }
}
