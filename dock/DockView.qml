import QtQuick
import "DockProfiles.js" as DockProfiles

Item {
    id: view

    required property DockState dockState
    property string tooltipFont: "Inter Tight"
    property int edgeInset: 8
    readonly property var profile: DockProfiles.atHeight(dockState.profile)
    readonly property Item currentDock: dockState.spacesOpen ? spaces : dockState.toolsOpen ? tools : main
    readonly property alias returnTarget: returnArea
    implicitWidth: Math.max(main.implicitWidth, spaces.implicitWidth, tools.implicitWidth)
    implicitHeight: 120 + edgeInset

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

    MainDock {
        id: main

        dockState: view.dockState
        profile: view.profile
        tooltipFont: view.tooltipFont
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: view.edgeInset
        visible: !view.dockState.subDockOpen
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
            if (view.dockState.spacesOpen)
                spaces.focusSelection(Qt.OtherFocusReason);
        }
    }
}
