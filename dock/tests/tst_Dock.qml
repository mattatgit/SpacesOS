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
            state.spacesOpen = false;
            state.selectedSpace = 0;
            view.forceActiveFocus(Qt.OtherFocusReason);
            mouseMove(view, 8, 8);
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

        function test_hoverClearsAfterClick() {
            const dock = findChild(view, "mainDock");
            const tools = findChild(dock, "tools");
            const highlight = findChild(tools, "tools-hover");
            const artwork = findChild(tools, "tools-artwork");
            mouseMove(tools, tools.width / 2, tools.height / 2);
            tryCompare(highlight, "opacity", 1);
            tryCompare(artwork, "scale", 0.96);
            verify(findChild(dock, "tooltip-tools") !== null);
            mouseClick(tools);
            mouseMove(view, 8, 8);
            tryCompare(highlight, "opacity", 0);
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
            keyClick(Qt.Key_Return);
            verify(state.spacesOpen);
            const subdock = findChild(view, "spacesDock");
            const first = findChild(subdock, "space-1");
            const second = findChild(subdock, "space-2");
            tryVerify(() => first.activeFocus);
            keyClick(Qt.Key_Right);
            verify(second.activeFocus);
            keyClick(Qt.Key_Space);
            compare(state.selectedSpace, 1);
            verify(findChild(second, "space-2-indicator").visible);
            verify(!findChild(first, "space-1-indicator").visible);
            keyClick(Qt.Key_Escape);
            verify(!state.spacesOpen);
            verify(spaces.activeFocus);
        }

        function test_pointerSpaces() {
            const main = findChild(view, "mainDock");
            mouseClick(findChild(main, "spaces"));
            verify(state.spacesOpen);
            const subdock = findChild(view, "spacesDock");
            compare(subdock.width, 692);
            compare(subdock.height, 64);
            mouseClick(findChild(subdock, "space-6"));
            compare(state.selectedSpace, 5);
            mouseClick(findChild(subdock, "spacesBin"));
            compare(state.binFull, false);
            const returnArea = findChild(view, "spacesReturn");
            const selected = findChild(subdock, "space-6");
            const artwork = findChild(selected, "space-6-artwork");
            const marker = findChild(selected, "space-6-indicator");
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
            compare(dock.width, data.spaces ? 865 : 500);
            mouseMove(view, start.x, start.y + 12);
            compare(state.profile, 64);
            mouseRelease(view, start.x, start.y + 12);
            verify(state.spacesOpen === data.spaces);
        }
    }
}
