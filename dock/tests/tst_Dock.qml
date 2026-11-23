import QtQuick
import QtTest
import ".."

Item {
    width: 784
    height: 160

    DockState { id: state }

    DockView {
        id: view
        dockState: state
        anchors.fill: parent
        anchors.bottomMargin: 8
    }

    TestCase {
        name: "NativeDock"
        when: windowShown

        function init() {
            state.setProfile(64);
            state.binFull = true;
            state.spacesOpen = false;
            state.selectedItem = "";
            state.selectedSpace = 0;
            view.forceActiveFocus(Qt.OtherFocusReason);
            mouseMove(view, 8, 8);
        }

        function test_profiles_data() {
            return [
                {tag: "compact", height: 56, width: 384, bot: 40, bin: 36},
                {tag: "standard", height: 64, width: 424, bot: 40, bin: 36},
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
            verify(!state.setProfile(72));
            compare(state.profile, profile.height);
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
            view.closeSpaces(Qt.MouseFocusReason);
            verify(!state.spacesOpen);
            verify(findChild(main, "bin-empty-artwork").visible);
        }
    }
}
