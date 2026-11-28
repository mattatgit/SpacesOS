# Standalone dock developer harness

This harness supports isolated component checks and Figma comparisons. For everyday use, open **Spaces** in GNOME or choose **Spaces OS** at login. [Desktop launch guide](desktop-shell.md).

The pinned Nix development shell supplies Quickshell, Qt Quick with SVG support, Qt Test, and Wayland inspection tools. Run these commands from the repository root on the Framework. The launcher enters the pinned shell automatically. An interactive development shell is available with `nix --extra-experimental-features 'nix-command flakes' develop`.

```sh
scripts/dock start
scripts/dock status
scripts/dock space
scripts/dock reload
scripts/dock stop
```

Use `scripts/dock run` for foreground logs. After editing QML, use `scripts/dock reload` to reopen the preview with the current height and Bin state. Relaunching the preview recreates its Wayland surface and graphics swapchain.

## Entering and leaving a Space

The first launch opens Home in a regular GNOME window. Choose **Spaces** in the main dock or the current Space name in the menu bar, then click **Ithos Studio**. The background changes, the top bar shows the active Space and its access type, and the marker moves under its thumbnail. Choose **Home** to switch back. The bottom edge of the picker or **Escape** returns to the main dock in the current Space.

The Spaces mark’s **Leave Space** command takes you back to the draggable, transparent dock over GNOME. Open its Spaces picker and choose a thumbnail to re-enter. The selected Space ID is saved immediately to `$XDG_CONFIG_HOME/SpacesOS/navigation.ini` (normally `~/.config/SpacesOS/navigation.ini`). Restarting opens the saved Space. A missing or unrecognized ID selects Home. `scripts/dock space` prints its stable ID.

`SpaceNavigation.qml` owns the two sample records and exposes `activeSpace` for the next Sidebar/Shelf milestone. The dock, workspace scene and top bar consume the same record. The creation-flow frames `2515:20737` through `2515:20756` supply the inset, dissolve and expansion. Set `SPACES_REDUCED_MOTION=1` when launching for immediate switching. The launcher also reads GNOME’s animation preference.

Home uses the passage artwork. Ithos Studio uses the river-city background from the creation flow, layer `2515:20774`. Both images ship with the preview, and each Space uses its own artwork for the scene and the picker thumbnail.

## Controls

- Drag the dock’s top edge to move it. The pointer changes to a hand over the grip, which extends 8 px above and below the top edge. After leaving a Space, clicks elsewhere around the dock reach the desktop or window underneath. In a Space, the empty top bar also moves the window.
- Drag either divider up or down to resize both docks between 64 and 80 px. With the dock focused, **Ctrl+1**, **Ctrl+2**, and **Ctrl+3** select **56 px**, **64 px**, and **80 px**. You can also run `scripts/dock size 72` for an intermediate height. The main dock starts at 64 px. The Spaces strip uses 64 px when the compact preset is selected.
- Hover over a main dock icon to show its name and shrink the artwork by 4%. Use **Tab** or **Shift+Tab** to reach a control, **Left** and **Right** to move within the dock, and **Enter** or **Space** to activate it.
- Activate **Spaces** to open the replacement strip. Select a thumbnail to move the active Space marker. Move the pointer to the bottom edge of the strip to lift the items, then click there to return. **Escape** also returns to the main dock.
- Activate **Bin** to toggle the two original assets in one slot. The state is shared between both views and has no effect on desktop Trash.
- **Files** opens the home folder in the default file manager. **Create a space** shows preview feedback. Space selection, creation, and Bin contents are local demo state.

## Compare with Figma

Keep the preview visible and move the pointer away from the dock for a resting-state capture. In a Space these commands capture the native workspace and dock. After **Leave Space**, they save transparent PNGs of the dock and its shadow. Place a capture over a Figma background to compare the translucent tint at the same size. Sizes are logical pixels.

| View | Expected dock size | Figma node |
| --- | --- | --- |
| Compact | 384 × 56 | `4299:127397` |
| Standard | 424 × 64 | `4299:127376` |
| Large | 500 × 80 | `4299:127419` |
| Spaces at 64 px | 324 × 64 with two sample Spaces | `2515:8503` |
| Spaces return hover at 64 px | Items and selection marker rise 4 px | `2515:7478` in Multidock all |
| Spaces hover | 24 px tooltip above the dock | `2515:8243` |

```sh
mkdir -p /tmp/spaces-dock-review
scripts/dock spaces close
scripts/dock bin full
for height in 56 64 80; do
    scripts/dock size "$height"
    scripts/dock capture "/tmp/spaces-dock-review/native-$height.png"
done
scripts/dock size 64
scripts/dock bin empty
scripts/dock spaces open
scripts/dock capture /tmp/spaces-dock-review/native-spaces.png
```

Export those Figma nodes at 1× and compare beside the native PNGs at 100% zoom. On a scaled display, compare in logical coordinates or normalize both renders to the same device-pixel ratio. Both dock views share the active profile’s tint, outline and shadow. The sub-dock uses the updated Bin artwork from the main dock.

`scripts/dock test` runs Qt Quick tests for profile geometry, divider dragging, pointer hover and activation, the Spaces return strip, Bin layout stability, Space selection and keyboard focus. On a headless host, use `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software scripts/dock test` for the interaction checks.

The eight main icons, six Space thumbnails and small vector accents are direct Figma exports. The main icon nodes are recorded in the [dock implementation notes](dock-implementation-notes.md) and the assets directory. Inter Tight is included with its SIL Open Font License.

## Host and design review

The Framework's GNOME Wayland session exposes `xdg_wm_base` and lacks `zwlr_layer_shell_v1`. Quickshell hosts the dock in a regular Qt Quick window. The launcher defaults to Qt's Vulkan renderer on GNOME Wayland because the OpenGL path reported an EGL surface error on this Framework. Set `QSG_RHI_BACKEND` before launching to select a different backend.

The preview draws the active wallpaper inside a frameless Quickshell `FloatingWindow`. Leaving a Space makes the surrounding window transparent and restores click-through around the dock. Live compositor backdrop blur, edge placement, and desktop-space reservation require a supported panel host. The shared `DockView`, state, and assets can be hosted by a Quickshell `PanelWindow` on a compatible compositor.

Review the 64 versus 80 px default on the laptop and how the hover and return motion feel at both sizes. The 56 px profile preserves the reference's distinct blue tint, icon offsets and divider placement.
