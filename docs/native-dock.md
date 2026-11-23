# Native dock preview

The pinned Nix development shell supplies Quickshell, Qt Quick with SVG support, Qt Test, and Wayland inspection tools. Run these commands from the repository root on the Framework. The launcher enters the pinned shell automatically. An interactive development shell is available with `nix --extra-experimental-features 'nix-command flakes' develop`.

```sh
scripts/dock start
scripts/dock status
scripts/dock reload
scripts/dock stop
```

Use `scripts/dock run` for foreground logs. After editing QML, use `scripts/dock reload` to reopen the preview with the current height and Bin state. Relaunching the preview recreates its Wayland surface and graphics swapchain.

## Controls

- Drag the empty background around the dock or a blank part of the toolbar to move the preview window.
- Pick **56 px**, **64 px**, or **80 px** in the preview toolbar, or press **Ctrl+1**, **Ctrl+2**, or **Ctrl+3**. The main dock starts at 64 px. Drag either divider up or down to resize both docks between 64 and 80 px. The Spaces strip uses 64 px when the compact preset is selected.
- Hover over a main dock icon to show its name and shrink the artwork by 4%. Use **Tab** or **Shift+Tab** to reach a control, **Left** and **Right** to move within the dock, and **Enter** or **Space** to activate it.
- Activate **Spaces** to open the replacement strip. Select a thumbnail to move the active Space marker. Move the pointer to the bottom edge of the strip to lift the items, then click there to return. **Escape** and the **Main dock** button also return.
- Activate **Bin** to toggle the two original assets in one slot. The state is shared between both views and has no effect on desktop Trash.
- **Files** opens the home folder in the default file manager. **Create a space** shows preview feedback. Space selection, creation, and Bin contents are local demo state.

## Compare with Figma

Keep the preview visible and move the pointer away from the dock for a resting-state capture. These commands save PNGs of the Qt Quick stage, including its local backdrop and the dock's shadow. Sizes are logical pixels.

| View | Expected dock size | Figma node |
| --- | --- | --- |
| Compact | 384 × 56 | `4299:127397` |
| Standard | 424 × 64 | `4299:127376` |
| Large | 500 × 80 | `4299:127419` |
| Spaces at 64 px | 692 × 64 at sufficient window width | `2515:8503` |
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

Export those Figma nodes at 1× and compare beside the native PNGs at 100% zoom. On a scaled display, compare in logical coordinates or normalize both renders to the same device-pixel ratio. Both dock views use the same neutral backdrop and share the active profile’s tint, outline and shadow. The sub-dock uses the updated Bin artwork from the main dock.

`scripts/dock test` runs Qt Quick tests for profile geometry, divider dragging, pointer hover and activation, the Spaces return strip, Bin layout stability, Space selection and keyboard focus. On a headless host, use `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software scripts/dock test` for the interaction checks.

The eight main icons, six Space thumbnails and small vector accents are direct Figma exports. The main icon nodes are recorded in the [dock implementation notes](dock-implementation-notes.md) and the assets directory. Inter Tight is included with its SIL Open Font License.

## Host and design review

The Framework's GNOME Wayland session exposes `xdg_wm_base` and lacks `zwlr_layer_shell_v1`. Quickshell hosts the dock in a regular Qt Quick window. The launcher defaults to Qt's Vulkan renderer on GNOME Wayland because the OpenGL path reported an EGL surface error on this Framework. Set `QSG_RHI_BACKEND` before launching to select a different backend.

The preview uses a neutral stage and reproduces the profile tints, borders and shadows. Live compositor backdrop blur, edge placement, and desktop-space reservation require a supported panel host. The shared `DockView`, state, and assets can be hosted by a Quickshell `PanelWindow` on a compatible compositor.

Review the 64 versus 80 px default on the laptop and how the hover and return motion feel at both sizes. The 56 px profile preserves the reference's distinct blue tint, icon offsets and divider placement.
