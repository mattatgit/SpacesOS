# Spaces desktop shell

The GNOME application and the independent Wayland session share a menu bar, contextual Sidebar, wallpaper, navigation and dock. The independent session uses labwc to manage ordinary applications. The first global menu client is a small native GTK scratchpad called Notes.

## Open Spaces on the Framework

From this checkout, run the installer once. It installs a per-user desktop entry pointing to this checkout and its approved Spaces icon.

```sh
scripts/install-spaces
```

Open **Spaces** in GNOME Activities. Right-click its icon to pin it or choose **Open Fullscreen** or **Open Independent Desktop**. Keep this checkout available and rerun the installer if it moves. To remove the launcher, delete `org.spacesos.Spaces.desktop` from `$XDG_DATA_HOME/applications` (normally `~/.local/share/applications`).

| In the GNOME preview | Result |
| --- | --- |
| Reopen Spaces | Reuse its window, restore it from minimization and request activation. GNOME controls foreground placement. |
| F11 or the Spaces mark → Enter/Leave Fullscreen | Toggle real Wayland fullscreen, including the GNOME top-bar area. |
| Click the Space name or the dock’s Spaces icon | Open the Space picker. Recents lists visited Spaces. |
| Spaces mark → Leave Space | Return to the transparent draggable dock. Select a Space to re-enter. |
| Ctrl+Q or Spaces mark → Quit Spaces | End the application and return to GNOME. |
| Far-right Sidebar icon | Show or hide the current Space’s Shelf. Home opens My Devices. |

Existing development commands include `scripts/dock run`, `start`, `reload`, `stop`, `size`, `space`, `capture` and `test`. The application and developer commands address the same preview instance. [Dock controls](native-dock.md) and [Matrix setup](messaging.md).

## Review the independent desktop

Choose **Open Independent Desktop** from the GNOME launcher, or run the first command below. The second command builds the immutable session package. Executing its wrapper with the argument `nested` runs the packaged version.

```sh
scripts/spaces-session nested
nix --extra-experimental-features 'nix-command flakes' build .#session
./result/bin/spaces-session nested
```

1. Click the white Spaces mark and choose **Open Notes**. Its editable window has compositor decorations. Notes is an in-memory test application.
2. Click **Edit → Insert Timestamp** in the desktop bar. The application inserts the time at the caret and updates its window title.
3. Choose **Open Icon Browser**. Focus it, then return to Notes by clicking its window or using Alt+Tab. Only Notes exposes the test menu. Both windows retain their own controls.
4. Drag a title bar, resize from a corner and close a window with its close control. Open the Sidebar, choose a different Space, then reopen the Sidebar to inspect the privacy boundary.
5. Click **Spaces mark → End Spaces Session** or press **Super+Shift+Escape** inside the nested desktop. **Leave Space** only leaves the wallpaper context. The dock and menu bar remain available.

The preview is a single GNOME-managed window. The independent host has four Wayland surfaces on the compositor’s default output. The wallpaper occupies the background layer, the bar reserves 48 logical pixels, the bottom dock has an input mask matching its controls, and the right Sidebar takes keyboard focus on demand. A private session bus, runtime directory, Wayland socket, and temporary XDG configuration, data and cache keep nested launches separate. The nested Files button opens its temporary data directory. Accounts in the enclosing desktop stay in that session.

labwc’s session command owns the foreground shell. Closing either ends the nested desktop. The launcher cleans its temporary directory on exit. Window management remains the compositor’s responsibility. Switching Spaces changes shell context and wallpaper; application windows currently stay on the same desktop.

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
| Effects and scaling | The probe advertised KWin blur. Rendering a blurred third-party window and multi-output behavior need testing. | The prototype renders wallpaper blur and alpha. One 1280 × 720 logical nested output was tested. Mixed-DPI/monitor hotplug and the custom blur path need a separate pass. |
| Spaces integration | An adapter could map a Space to a KWin virtual desktop and observe window moves. | Desktop and window rules are possible integration points. Persistent window-to-Space assignment remains a design decision. |
| Operating cost | Stronger built-in effects and KDE integration, with more integration work for this shell. | Directly supplies the focus and capture protocols used here. No separate desktop shell or compositor fork is required. |

GTK’s `GMenuModel` supplies the live model; `GActionGroup` supplies the actions and their enabled state. The adapter renders the opted-in application’s top-level menus and ordinary, parameterless application actions. Unsupported clients remain usable. Qt applications can instead export the Canonical D-BusMenu layout/events interface through a suitable platform integration. KDE’s protocol supplies per-window discovery of that endpoint. Supporting that format, nested submenus, parameterized actions and window-scoped GTK actions would extend this first adapter. [GTK menu exporter](https://docs.gtk.org/gio/menu-exporter.html), [KDE AppMenu protocol](https://github.com/KDE/plasma-wayland-protocols/blob/master/src/protocols/appmenu.xml), [KWin scripting API](https://develop.kde.org/docs/plasma/kwin/api/), [labwc](https://labwc.github.io/).

## Optional NixOS login entry

For the installation owner, add a pinned input for this reviewed revision to the machine’s NixOS flake and include `spacesos.nixosModules.session` in the host’s `modules`. Keep the existing display manager and GNOME configuration. A typical input and module reference are shown below.

```nix
inputs.spacesos.url = "github:mattatgit/SpacesOS/feature/desktop-shell";
# In the host’s nixosSystem modules list:
# modules = [ ./configuration.nix spacesos.nixosModules.session ];
```

Review and commit the host’s lockfile before activation. First build the usual host configuration with `nixos-rebuild build`. After the installation owner approves a boot test, use the host’s normal `nixos-rebuild boot` procedure. Keep the prior generation. At GDM, choose **Spaces OS** from the session selector. End the session using the Spaces menu or the emergency shortcut, then select **GNOME** for recovery. A previous generation remains available from the boot menu. Removing the module and rebuilding removes the extra login entry.

The module appends one Wayland session package. The login entry runs labwc as the primary compositor with the session’s normal logind environment; nested-only temporary directories apply only to the desktop experiment. Login, locking, suspend/resume, portals, keyring provisioning on a physical login and multi-monitor recovery remain acceptance work. The module was evaluated alongside GNOME and its package was built and tested nested. With GNOME enabled, the evaluated session order was `gnome, spaces` and the effective automatic login session was `gnome`. Host activation requires separate approval.

## Validation and review decisions

On the Framework the Qt Quick suite passed 22 checks covering the dock, navigation and contextual Sidebar. The lifetime regression holds a pending operation through hiding, then checks retention of a draft and retry state. Both existing service integration tests passed. To repeat the checks, run the commands below.

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software scripts/dock test
scripts/test-messaging
```

The installed launcher reused one process on repeated launch. A native fullscreen capture measured 2880 × 1920 on the Framework. F11 restored the previous window. The native Notes action changed both the editable document and the title; the independent desktop was also closed with a native app open. The physical cross-device acceptance test remains outstanding.

Architecture & Design should review the focused-app identity beside the Space name, the direct Home conversation versus a future overview, the empty shared Shelf, and the materials over real client windows. The labwc experiment establishes a working baseline; choosing a production compositor, multi-output policy and window-to-Space ownership remain separate decisions.

The review branch descends from messaging commit `0778561` and targets `main`. It carries the history of PRs #3, #4 and #5. Review the desktop milestone against `0778561`, then merge one consolidated baseline after acceptance. The existing reviews can be closed as superseded after that merge.
