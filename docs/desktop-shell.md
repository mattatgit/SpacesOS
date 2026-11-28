# Opening the Spaces desktop

| Where | Open | Leave |
| --- | --- | --- |
| GNOME | Click **Spaces** in the dock or Activities. A second click returns to the same fullscreen desktop. | **Spaces menu → Return to GNOME** closes the test desktop and its clients. Applications opened in GNOME keep running. |
| GDM login screen | Choose **Spaces OS** from the gear, then sign in. | **Spaces menu → End Spaces Session** returns to the login screen after confirmation. |

The Spaces menu is the white mark at the upper left. **Leave Space** switches to the Spaces overview. Both paths run the same labwc configuration and native Quickshell desktop, including its menu bar, window management, wallpaper, Sidebar, dock and Arlo.

## GNOME launcher and profile

From the checkout, run `scripts/install-spaces` to install or refresh the per-user entry. The existing favorite keeps its name, icon and desktop ID, `org.spacesos.Spaces.desktop`. Keep the checkout at this location or rerun the installer after moving it.

GNOME supplies the fullscreen window size and preferred scale. The hosted compositor renders at the corresponding physical resolution and advertises that scale to its own clients. One nested output follows the host window. GNOME’s normal window switcher also works.

The test desktop has its own home at `$XDG_STATE_HOME/SpacesOS/nested` (normally `~/.local/state/SpacesOS/nested`). Its config, data, cache and state directories live inside that home. Dock height, navigation, Arlo conversations, drafts and activity survive closing the test desktop. Each run receives a fresh Wayland socket and private D-Bus session. The real login uses the usual user profile, keyring and system controls. Both run as the same Unix user.

## Developer checks

```sh
scripts/spaces-session nested
scripts/spaces-session nested --disposable
nix --extra-experimental-features 'nix-command flakes' build .#session
./result/bin/spaces-session nested --disposable
```

The first command uses the same profile as the GNOME icon. Each disposable run has an independent, temporary home and runtime. The standalone dock remains a [developer harness for component tests and design captures](native-dock.md).

To check a release, launch the pinned icon, resize the dock through Arlo, and open the icon again. Use **Return to GNOME**, reopen Spaces, and check the saved height and activity. In the real login, check the same shell interactions against its own profile. Coordinate the host update and physical login with Matt and SpacesOS Install. [Login and recovery](daily-session.md).

The packaged launcher regression uses a headless Wayland parent at 150% scale. Run it from the checkout after building `result`.

```sh
nix --extra-experimental-features 'nix-command flakes' shell --inputs-from . nixpkgs#sway nixpkgs#wayland-utils nixpkgs#python3 nixpkgs#dbus --command dbus-run-session -- python3 session/test_nested.py ./result
```

## Sidebar and visual comparison

The open/closed frames under `2583:77772` place the open Shelf 16 px below the 48 px bar and 16 px from the right edge. The closed frame shifts it 36 px to the right. Both click reactions specify 100 ms Smart Animate with ease-out. The native component interpolates translation and opacity together. The logical width is 408 px with a narrow-window clamp. The Home conversation uses the 612 px upper card; shorter previews make room for the dock.

The menu mark, mirrored 16 px Sidebar glyph, Inter Tight labels, status clock, Private/Shared indicator and separate system, Space and application controls follow menu bar `3569:169864`. The bar blurs the shell-owned wallpaper strip. The Sidebar and dock use translucent surfaces. Compositor blur behind arbitrary client windows remains open. Wallet, Focus, system settings and unfinished Shelf content await functioning implementations.

`ContextSidebar.qml` accepts contextual component slots. `SpaceSidebar.qml` binds them to navigation and messaging. The Home conversation starts on first open and retains its service, file operation, failed send and unsent composer while hidden. Switching to a shared Space immediately hides the personal page, closes its file dialogs and disables its input. An empty Shelf identifies the shared Space. The service can finish a private transfer in the background. Shell exit ends this in-memory UI state.

For a 1:1 comparison, inspect the reference and the running shell at 100% logical scale. Compare the right edge, bar and card insets first. The Figma overview includes Chats and Files. The current Home route opens its single available view. A second Files card will need a real source. The local review handoff contains native captures.

## Compositor investigation

| Area | KWin 6.6.6 | labwc 0.9.7 |
| --- | --- | --- |
| Nested session and layers | Ran KWin standalone inside GNOME. The client protocol probe advertised layer-shell. | Ran the full Quickshell desktop inside GNOME and exercised all four layer surfaces. |
| Floating windows and focus | KWin’s scripting API exposes window activation, geometry and virtual desktops. A dedicated focus adapter would be needed here. | Tested native GTK window creation, pointer focus, title-bar movement, border resizing, closing and switching between two clients. |
| Global menus | The probe advertised KDE AppMenu. It can associate a client surface with a D-BusMenu service and object path. The wlroots foreign-toplevel focus protocol was absent from the probe. | Quickshell receives focus through the advertised wlroots foreign-toplevel protocol. A session-local GIO adapter reads the opted-in Notes menu and dispatches enabled actions to its unique bus owner. |
| Effects and scaling | The probe advertised KWin blur. Rendering a blurred third-party window and multi-output behavior need testing. | The prototype renders wallpaper blur and alpha. The GNOME launcher follows the host window’s logical size and fractional scale. Mixed-DPI/monitor hotplug and the custom blur path need a separate pass. |
| Spaces integration | An adapter could map a Space to a KWin virtual desktop and observe window moves. | Desktop and window rules are possible integration points. Application instances and their windows belong to the originating Space. Current workspaces provide visual separation. |
| Operating cost | Stronger built-in effects and KDE integration, with more integration work for this shell. | Directly supplies the focus and capture protocols used here. The physical session uses stock labwc. The nested build adapts its Wayland output for the host window. |

GTK’s `GMenuModel` supplies the live model; `GActionGroup` supplies the actions and their enabled state. The adapter renders the opted-in application’s top-level menus and ordinary, parameterless application actions. Unsupported clients remain usable. Qt applications can instead export the Canonical D-BusMenu layout/events interface through a suitable platform integration. KDE’s protocol supplies per-window discovery of that endpoint. Supporting that format, nested submenus, parameterized actions and window-scoped GTK actions would extend this first adapter. [GTK menu exporter](https://docs.gtk.org/gio/menu-exporter.html), [KDE AppMenu protocol](https://github.com/KDE/plasma-wayland-protocols/blob/master/src/protocols/appmenu.xml), [KWin scripting API](https://develop.kde.org/docs/plasma/kwin/api/), [labwc](https://labwc.github.io/).

## NixOS login

The daily-use build extends this milestone with a selectable GDM session, an installed app launcher, per-Space windows and login services. [Installation, updates, keyboard controls and GNOME recovery](daily-session.md).

## Validation and review decisions

The Qt Quick suite covers the dock, navigation and contextual Sidebar. The lifetime regression holds a pending operation through hiding, then checks retention of a draft and retry state. Both existing service integration tests passed. To repeat the checks, run the commands below.

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software scripts/dock test
scripts/test-messaging
```

Architecture & Design should review the focused-app identity beside the Space name, the direct Home conversation versus a future overview, the empty shared Shelf, and the materials over real client windows. The labwc experiment establishes a working baseline; choosing a production compositor, multi-output policy and window-to-Space ownership remain separate decisions.
