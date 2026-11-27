import QtQuick
import QtTest
import ".."

Item {
    width: 928
    height: 160

    DockState { id: state }

    DockView {
        id: view
        dockState: state
        anchors.fill: parent
    }

    TestCase {
        name: "NativeDock"
        when: windowShown

        function init() {
            state.setProfile(64);
            state.binFull = true;
            state.applications = [];
            state.toolsOpen = false;
            state.spacesOpen = false;
            state.navigation.restore("home");
            state.navigation.inside = true;
            view.forceActiveFocus(Qt.OtherFocusReason);
            mouseMove(view, 8, 8);
        }

        function test_leaveAndReenter() {
            verify(state.navigation.enter("ithos"));
            state.navigation.leave();
            verify(!state.navigation.inside);
            compare(state.navigation.activeSpace.access, "Shared");
            verify(!state.navigation.enter("missing"));
            verify(!state.navigation.inside);
            state.activate("spaces");
            const home = findChild(view.currentDock, "space-home");
            mouseClick(home);
            verify(state.navigation.inside);
            compare(state.navigation.activeSpace.id, "home");
            verify(findChild(home, "space-home-indicator").visible);
        }

        SignalSpy { id: launches; target: state; signalName: "applicationRequested" }

        function test_toolsKeyboardAndReturn() {
            state.applications = [{id: "sample", name: "Sample", icon: Qt.resolvedUrl("../assets/tools.png")}];
            const tools = findChild(view.currentDock, "tools");
            tools.forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Return);
            verify(state.toolsOpen);
            const app = findChild(view.currentDock, "launch-sample");
            tryVerify(() => app.activeFocus);
            launches.clear();
            keyClick(Qt.Key_Return);
            compare(launches.signalArguments[0][0], "sample");
            keyClick(Qt.Key_Escape);
            verify(tools.activeFocus);
            mouseClick(tools);
            mouseClick(view.returnTarget);
            verify(!state.subDockOpen);
        }

        function test_restoreUnknownId() {
            state.navigation.restore("ithos");
            compare(state.navigation.activeSpace.title, "Ithos Studio");
            state.navigation.restore("removed-space");
            compare(state.navigation.activeSpace.id, "home");
        }

        function test_profiles_data() {
            return [
                {tag: "compact", height: 56, width: 384, bot: 40, bin: 36},
                {tag: "standard", height: 64, width: 424, bot: 40, bin: 36},
                {tag: "interpolated", height: 72, width: 462, bot: 44, bin: 42},
                {tag: "large", height: 80, width: 500, bot: 48, bin: 48}
            ];
        }

        function test_profiles(profile) {
            const dock = findChild(view, "mainDock");
            const bot = findChild(dock, "bot-artwork");
            const bin = findChild(dock, "bin-artwork");
            const bottom = dock.y + dock.height;
            verify(state.setProfile(profile.height));
            compare(dock.width, profile.width);
            compare(dock.height, profile.height);
            compare(bot.width, profile.bot);
            compare(bin.width, profile.bin);
            compare(dock.y + dock.height, bottom);
            verify(!state.setProfile(63));
            verify(!state.setProfile(81));
            compare(state.profile, profile.height);
        }

        function test_mainDockHover_data() {
            return test_profiles_data();
        }

        function test_mainDockHover(profile) {
            state.setProfile(profile.height);
            const dock = findChild(view, "mainDock");
            const tools = findChild(dock, "tools");
            const artwork = findChild(tools, "tools-artwork");
            mouseMove(tools, tools.width / 2, tools.height / 2);
            tryCompare(artwork, "scale", 0.96);
            verify(!tools.background.visible);
            verify(findChild(dock, "tooltip-tools") !== null);
            mouseClick(tools);
            mouseMove(view, 8, 8);
            tryCompare(artwork, "scale", 1);
            verify(findChild(dock, "tooltip-tools") === null);
        }

        function test_pointerAndBin() {
            const dock = findChild(view, "mainDock");
            const bin = findChild(dock, "bin");
            const full = findChild(bin, "bin-artwork");
            const empty = findChild(bin, "bin-empty-artwork");
            const position = bin.mapToItem(view, 0, 0);
            mouseMove(bin, bin.width / 2, bin.height / 2);
            tryVerify(() => findChild(dock, "tooltip-bin") !== null, 1000);
            mouseClick(bin);
            compare(state.binFull, false);
            compare(full.visible, false);
            compare(empty.visible, true);
            compare(bin.mapToItem(view, 0, 0), position);
            compare(empty.width, full.width);
            compare(empty.height, full.height);
            mouseClick(bin);
            compare(state.binFull, true);
        }

        function test_keyboardSpaces() {
            const main = findChild(view, "mainDock");
            const spaces = findChild(main, "spaces");
            findChild(main, "bot").forceActiveFocus(Qt.TabFocusReason);
            keyClick(Qt.Key_Right);
            verify(spaces.activeFocus);
            verify(spaces.background.visible);
            keyClick(Qt.Key_Return);
            verify(state.spacesOpen);
            const subdock = findChild(view, "spacesDock");
            const first = findChild(subdock, "space-home");
            const second = findChild(subdock, "space-ithos");
            tryVerify(() => first.activeFocus);
            keyClick(Qt.Key_Right);
            verify(second.activeFocus);
            keyClick(Qt.Key_Space);
            compare(state.navigation.activeSpace.id, "ithos");
            verify(findChild(second, "space-ithos-indicator").visible);
            verify(!findChild(first, "space-home-indicator").visible);
            keyClick(Qt.Key_Escape);
            verify(!state.spacesOpen);
            verify(spaces.activeFocus);
        }

        function test_pointerSpaces() {
            const main = findChild(view, "mainDock");
            mouseClick(findChild(main, "spaces"));
            verify(state.spacesOpen);
            const subdock = findChild(view, "spacesDock");
            compare(subdock.width, 324);
            compare(subdock.height, 64);
            mouseClick(findChild(subdock, "space-ithos"));
            compare(state.navigation.activeSpace.id, "ithos");
            mouseClick(findChild(subdock, "spacesBin"));
            compare(state.binFull, false);
            const returnArea = findChild(view, "spacesReturn");
            const selected = findChild(subdock, "space-ithos");
            const artwork = findChild(selected, "space-ithos-artwork");
            const marker = findChild(selected, "space-ithos-indicator");
            const divider = findChild(subdock, "spaces-divider-0");
            const dividerPosition = divider.mapToItem(view, 0, 0);
            mouseMove(returnArea, returnArea.width / 2, returnArea.height / 2);
            tryCompare(artwork, "y", 8);
            compare(marker.y, 52);
            compare(divider.mapToItem(view, 0, 0), dividerPosition);
            verify(state.spacesOpen);
            mouseMove(view, 8, 8);
            tryCompare(artwork, "y", 12);
            mouseClick(returnArea);
            verify(!state.spacesOpen);
            verify(findChild(main, "bin-empty-artwork").visible);
        }

        function test_resizeFromDividers_data() {
            return [
                {tag: "main left", spaces: false, name: "main-divider-0"},
                {tag: "main right", spaces: false, name: "main-divider-1"},
                {tag: "Spaces left", spaces: true, name: "spaces-divider-0"},
                {tag: "Spaces right", spaces: true, name: "spaces-divider-1"}
            ];
        }

        function test_resizeFromDividers(data) {
            state.spacesOpen = data.spaces;
            const dock = view.currentDock;
            const bottom = dock.y + dock.height;
            const handle = findChild(dock, data.name);
            const start = handle.mapToItem(view, handle.width / 2, handle.height / 2);
            mousePress(view, start.x, start.y);
            mouseMove(view, start.x, start.y - 8);
            compare(state.profile, 72);
            compare(dock.height, 72);
            compare(dock.y + dock.height, bottom);
            mouseMove(view, start.x, start.y - 30);
            compare(state.profile, 80);
            compare(dock.width, data.spaces ? 405 : 500);
            mouseMove(view, start.x, start.y + 12);
            compare(state.profile, 64);
            mouseRelease(view, start.x, start.y + 12);
            verify(state.spacesOpen === data.spaces);
        }
    }
}
