import QtQuick

Item {
    id: view

    required property DockState dockState
    property string tooltipFont: "Inter Tight"
    readonly property Item currentDock: dockState.spacesOpen ? spaces : main
    implicitWidth: Math.max(main.implicitWidth, spaces.implicitWidth)
    implicitHeight: 120

    function closeSpaces(reason: int): void {
        if (!dockState.spacesOpen)
            return;

        dockState.spacesOpen = false;
        main.focusSpaces(reason);
    }

    Shortcut {
        sequence: "Escape"
        enabled: view.dockState.spacesOpen
        onActivated: view.closeSpaces(Qt.BacktabFocusReason)
    }

    MainDock {
        id: main

        dockState: view.dockState
        tooltipFont: view.tooltipFont
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        visible: !view.dockState.spacesOpen
    }

    SpacesDock {
        id: spaces

        dockState: view.dockState
        tooltipFont: view.tooltipFont
        width: Math.min(implicitWidth, parent.width - 16)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        visible: view.dockState.spacesOpen
    }

    Connections {
        target: view.dockState

        function onSpacesOpenChanged(): void {
            if (view.dockState.spacesOpen)
                spaces.focusSelection(Qt.OtherFocusReason);
        }
    }
}
