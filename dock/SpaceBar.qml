import QtQuick
import QtQuick.Controls.Basic
import Quickshell

Rectangle {
    id: bar
    required property DesktopState desktop
    property var applicationMenu: null
    property bool fullscreen: false
    signal toggleFullscreen()
    signal moveWindow()
    signal leaveSpace()
    signal exitSession()
    signal launchNotes()
    signal launchViewer()

    implicitHeight: 48
    color: "#40959595"

    MouseArea { anchors.fill: parent; onPressed: bar.moveWindow() }
    component BarButton: Button {
        id: button
        height: 32
        leftPadding: 8; rightPadding: 8
        font.family: bar.desktop.fontFamily; font.pixelSize: 14; font.weight: Font.Medium
        hoverEnabled: true
        contentItem: Text {
            text: button.text; font: button.font; color: "white"
            verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
        }
        background: Rectangle {
            radius: 4
            color: button.hovered || button.down || button.checked ? "#33ffffff" : "transparent"
            border.width: button.visualFocus ? 1 : 0; border.color: "white"
        }
    }
    component BarMenu: Menu {
        y: parent.height + 4
        popupType: Popup.Window
        font.family: bar.desktop.fontFamily
    }
    Row {
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        BarButton {
            width: 32
            Accessible.name: qsTr("Spaces system menu")
            contentItem: Item {
                Image { anchors.centerIn: parent; width: 18; height: 18; source: "assets/menu-spaces.svg" }
            }
            onClicked: systemMenu.open()
            BarMenu {
                id: systemMenu
                MenuItem { text: qsTr("Choose a Space"); onTriggered: bar.desktop.spacesOpen = true }
                MenuItem { text: qsTr("Leave Space"); enabled: bar.desktop.navigation.inside; onTriggered: bar.leaveSpace() }
                MenuSeparator {}
                MenuItem {
                    visible: !bar.desktop.independent; height: visible ? implicitHeight : 0
                    text: bar.fullscreen ? qsTr("Leave Fullscreen") : qsTr("Enter Fullscreen")
                    onTriggered: bar.toggleFullscreen()
                }
                MenuItem {
                    visible: bar.desktop.independent; height: visible ? implicitHeight : 0
                    text: qsTr("Open Notes"); onTriggered: bar.launchNotes()
                }
                MenuItem {
                    visible: bar.desktop.independent; height: visible ? implicitHeight : 0
                    text: qsTr("Open Icon Browser"); onTriggered: bar.launchViewer()
                }
                Menu {
                    id: controlsMenu
                    title: qsTr("System")
                    enabled: bar.desktop.loginSession
                    Instantiator {
                        model: [["Network & Wi-Fi", "wifi"], ["Sound", "audio"], ["Displays", "displays"],
                                ["Battery", "battery"], ["Lock Screen", "lock"], ["Suspend", "suspend"],
                                ["Restart…", "reboot"], ["Shut Down…", "poweroff"]]
                        MenuItem {
                            required property var modelData
                            text: modelData[0]
                            onTriggered: Quickshell.execDetached(["spaces-control", modelData[1]])
                        }
                        onObjectAdded: (index, item) => controlsMenu.insertItem(index, item)
                        onObjectRemoved: (index, item) => controlsMenu.removeItem(item)
                    }
                }
                MenuItem {
                    text: bar.desktop.loginSession ? qsTr("End Spaces Session")
                        : bar.desktop.independent ? qsTr("Return to GNOME") : qsTr("Quit Spaces")
                    onTriggered: bar.exitSession()
                }
            }
        }
        BarButton {
            text: bar.desktop.navigation.inside ? bar.desktop.navigation.activeSpace.title : qsTr("Spaces")
            font.weight: Font.DemiBold
            checked: bar.desktop.spacesOpen
            onClicked: bar.desktop.spacesOpen = !bar.desktop.spacesOpen
        }
        BarButton {
            visible: !bar.applicationMenu?.identity && bar.width > 540
            text: qsTr("Recents")
            onClicked: recents.open()
            BarMenu {
                id: recents
                Instantiator {
                    model: bar.desktop.recentIds
                    MenuItem {
                        required property string modelData
                        text: bar.desktop.navigation.spaces.find(space => space.id === modelData).title
                        onTriggered: bar.desktop.navigation.select(modelData)
                    }
                    onObjectAdded: (index, item) => recents.insertItem(index, item)
                    onObjectRemoved: (index, item) => recents.removeItem(item)
                }
            }
        }
        BarButton {
            visible: !bar.applicationMenu?.identity && bar.width > 630
            text: qsTr("Help")
            onClicked: help.open()
            BarMenu {
                id: help
                Label {
                    padding: 12
                    text: bar.desktop.independent && !bar.desktop.loginSession
                        ? qsTr("Spaces menu → Return to GNOME closes this test desktop.\nDrag a dock divider to resize.")
                        : bar.desktop.independent ? qsTr("Drag the title bar to move a window.\nDrag a window corner to resize.\nSuper + Shift + Esc ends the session.")
                        : qsTr("F11 toggles fullscreen.\nCtrl + Q quits Spaces.\nDrag a dock divider to resize.")
                }
            }
        }
        Text {
            visible: text.length && bar.width > 600
            anchors.verticalCenter: parent.verticalCenter
            text: bar.applicationMenu ? bar.applicationMenu.identity : ""
            width: Math.min(160, implicitWidth); elide: Text.ElideRight
            font.family: bar.desktop.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold
            color: "white"; textFormat: Text.PlainText
        }
        Repeater {
            model: bar.applicationMenu ? bar.applicationMenu.menus : []
            BarButton {
                id: menuButton
                required property var modelData
                text: modelData.label
                onClicked: exportedMenu.open()
                BarMenu {
                    id: exportedMenu
                    Instantiator {
                        model: menuButton.modelData.items
                        MenuItem {
                            required property var modelData
                            text: modelData.label
                            enabled: modelData.enabled
                            onTriggered: bar.applicationMenu.invoke(modelData.action)
                        }
                        onObjectAdded: (index, item) => exportedMenu.insertItem(index, item)
                        onObjectRemoved: (index, item) => exportedMenu.removeItem(item)
                    }
                }
            }
        }
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Row {
        anchors.right: parent.right; anchors.rightMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: bar.width >= 540
            width: 64; horizontalAlignment: Text.AlignHCenter
            text: Qt.formatTime(clock.date, "h:mm ap")
            font.family: bar.desktop.fontFamily; font.pixelSize: 14; color: "white"
        }
        Item {
            width: 80; height: 32
            visible: bar.desktop.navigation.inside
            Rectangle {
                x: 8; anchors.verticalCenter: parent.verticalCenter
                width: 8; height: 8; radius: 4
                color: bar.desktop.personal ? "#17b239" : "#ffb020"
            }
            Text {
                x: 24; anchors.verticalCenter: parent.verticalCenter
                text: bar.desktop.independent && !bar.desktop.workspaceConfirmed ? "…" : bar.desktop.personal ? qsTr("Private") : qsTr("Shared")
                font.family: bar.desktop.fontFamily; font.pixelSize: 14; color: "white"
            }
        }
        BarButton {
            width: 32
            objectName: "sidebarToggle"
            Accessible.name: qsTr("Toggle Sidebar")
            checked: bar.desktop.sidebarOpen
            enabled: bar.desktop.navigation.inside
            contentItem: Item {
                Image { anchors.centerIn: parent; width: 16; height: 16; mirror: true; source: "assets/menu-sidebar.svg" }
            }
            onClicked: bar.desktop.sidebarOpen = !bar.desktop.sidebarOpen
        }
    }
}
