import QtQuick
import "DockProfiles.js" as DockProfiles

Item {
    id: view

    required property DockState dockState
    property string tooltipFont: "Inter Tight"
    property int edgeInset: 8
    readonly property var profile: DockProfiles.atHeight(dockState.profile)
    readonly property Item currentDock: dockState.arloOpen ? commandInput : dockState.spacesOpen ? spaces : dockState.toolsOpen ? tools : main
    readonly property alias returnTarget: returnArea
    implicitWidth: Math.max(main.implicitWidth, spaces.implicitWidth, tools.implicitWidth)
    readonly property Item activityTarget: activity.visible ? activity : null
    property real availableHeight: 480
    implicitHeight: Math.max(120 + edgeInset, activity.visible ? currentDock.height + edgeInset + activity.height + 18 : 0)

    function focusSpaces(reason: int): void { main.focusSpaces(reason); }

    function closeSpaces(reason: int): void {
        if (dockState.toolsOpen) {
            dockState.toolsOpen = false;
            main.focusTools(reason);
            return;
        }
        if (!dockState.spacesOpen)
            return;

        dockState.spacesOpen = false;
        main.focusSpaces(reason);
    }

    Shortcut {
        sequence: "Escape"
        enabled: view.dockState.subDockOpen
        onActivated: view.closeSpaces(Qt.BacktabFocusReason)
    }

    DockSurface {
        anchors.fill: view.currentDock
        tint: view.profile.tint
        outline: view.profile.outline
        shadowColor: view.profile.shadow
    }

    ArloInput {
        id: commandInput
        controller: view.dockState.arlo
        profile: view.dockState.profile
        family: view.tooltipFont
        width: Math.min(implicitWidth, view.width - 16)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: view.edgeInset
        visible: view.dockState.arloOpen
    }
    ArloActivity {
        id: activity
        controller: view.dockState.arlo
        family: view.tooltipFont
        maximumListHeight: Math.max(42, Math.min(202, view.availableHeight - view.currentDock.height - 142))
        visible: !!controller?.personal && (view.dockState.arloOpen || (hasActivity && !view.dockState.subDockOpen))
        width: expanded ? Math.min(commandInput.width, 420) : 148
        anchors.horizontalCenter: view.currentDock.horizontalCenter
        anchors.bottom: view.currentDock.top
        anchors.bottomMargin: 8
    }
    Shortcut {
        sequence: "Escape"
        enabled: view.dockState.arloOpen
        onActivated: view.dockState.arlo.opened = false
    }

    MainDock {
        id: main

        dockState: view.dockState
        profile: view.profile
        tooltipFont: view.tooltipFont
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: view.edgeInset
        visible: !view.dockState.subDockOpen && !view.dockState.arloOpen
    }

    SpacesDock {
        id: spaces

        dockState: view.dockState
        tooltipFont: view.tooltipFont
        returnHovered: returnArea.containsMouse
        width: Math.min(implicitWidth, parent.width - 16)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: view.edgeInset
        visible: view.dockState.spacesOpen
    }

    ToolsDock {
        id: tools
        dockState: view.dockState
        tooltipFont: view.tooltipFont
        returnHovered: returnArea.containsMouse
        width: Math.min(implicitWidth, parent.width - 16)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: view.edgeInset
        visible: view.dockState.toolsOpen
        onVisibleChanged: if (visible) focusFirst()
    }

    MouseArea {
        id: returnArea

        objectName: "spacesReturn"
        anchors.left: view.currentDock.left
        anchors.right: view.currentDock.right
        anchors.bottom: parent.bottom
        height: view.edgeInset + 4 * spaces.sizeFactor
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        visible: view.dockState.subDockOpen

        onClicked: view.closeSpaces(Qt.MouseFocusReason)
    }

    Connections {
        target: view.dockState

        function onSpacesOpenChanged(): void {
            if (view.dockState.spacesOpen) {
                if (view.dockState.arlo) view.dockState.arlo.opened = false;
                spaces.focusSelection(Qt.OtherFocusReason);
            }
        }
    }
}
