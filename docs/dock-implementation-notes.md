# Dock icon refresh and size profiles — implementation notes

**Status:** Reviewed design evidence; technical sizing proposal; final default remains unapproved.

**Source:** `Spaces OS 2026` → `Spaces OS` board → `Dock + app icons` section, Figma node **`4299:127357`**.

This newer section complements the earlier `Dock + tool tips` designs (node `2515:6104`). It shows refreshed 3D/white-clay icon art, three main-dock height variants and individual high-resolution icon images.

## Inspected native UI references

| Size preset | Frame ID | Figma dock size | Sample icon dimensions |
| --- | --- | --- | --- |
| Compact | `4299:127386` | 384 × **56** logical px | 36–40px |
| Standard | `4299:127365` | 424 × **64** logical px | 36–40px |
| Large | `4299:127408` | 500 × **80** logical px | 48px |

Each is shown within a 1920×1280 desktop frame including a top bar, widgets and Sidebar. Do **not** use hard-coded artboard coordinates to place the dock on real screens. Centre relative to the current output's usable geometry, respecting scaling, edges, safe areas and other shell surfaces.

The dimensions above are **design reference sizes**, not proof that the completed shell's width should be fixed; width should adapt to icon count and grouping.

## Assets and order

The refreshed dock follows this order:

1. Bot / agent (orange-eyed clay robot)
2. Spaces (moon / space-time grid)
3. People (astronaut bust with glass visor)
4. Tools (crossed hammer and fountain pen with subtle accents)
5. Files (rocket-blueprint sheet)
6. Settings (two slider controls)
7. Bin (translucent bin; see state handling below)

There are visual dividers after Bot and before Bin. The separate Figma artwork/source images are placed on `1024×1024` image-filled nodes for the named icons. Colour accent experiments also appear in the section; the in-dock references are the appropriate source for each size preset.

**Asset extraction:** obtain original exported/static artwork through the Figma asset workflow with explicit rights reviewed, rather than cropping icons from a desktop screenshot. Preserve alpha edges and visual padding, and QA at their actual render sizes.

## Bin state

Figma includes **two distinct `1024×1024` image assets**:
- Full bin: `4299:127363`
- Empty bin: `4299:127364`

In the running UI these should be two states of **one dock action**, not two separate dock items. Switching between states must keep the same visual slot, dimensions, alignment and interaction target. For the initial version, state can follow whether Spaces OS's supported bin contains items; the backing data source and behavior need explicit definition.

All three mockups currently show the full bin; support the empty asset even though it is not shown as a separate dock mockup.

## Sizing decision to test

The designer notes that existing sub-dock prototypes are primarily **64px high**, while the new **80px** mockup improves visibility and may become the preferred default. **56px** remains a useful compact option.

Suggested engineering approach:
- Implement **64px** first as the fidelity baseline because the existing sub-dock designs and interaction states were mainly authored for it.
- Expose **56 / 64 / 80** as discrete dock size profiles from the outset (not a post-hoc image magnification), with profile-owned padding, gaps, icon render sizes and hit targets.
- Treat **80px as the leading default candidate**, but decide after side-by-side review on the actual Framework screen, including sub-dock transitions and Sidebar coexistence.
- Maintain logically defined sizes independent of operating-system display scaling and fractional DPI; make room for future accessibility scaling.
- When a sub-dock opens, preserve alignment, visual hierarchy and an understandable relationship between parent and child docks. The decision whether child docks inherit the selected size or maintain a different density is **open**.

## Acceptance checks for the native prototype

- All seven item categories appear in the correct order, with the expected dividers.
- Assets are sharp at 36, 40 and 48 logical pixel slots on both 1× and HiDPI outputs.
- Bin switches full ↔ empty without moving or resizing adjacent items.
- Profile switching preserves dock position, focus/hover semantics, keyboard access and reasonable pointer hit targets.
- Sub-docks work at the 64px baseline; the 80px preset is reviewed in context rather than only as a static icon strip.
- Visual regression comparisons are made against **each relevant Figma frame**, not one interpolated screenshot.

## Still to decide

- Default size: 64 baseline or 80 preferred default after testing?
- Should the user's dock-size preference apply to every sub-dock, and do their positions/gaps change?
- Whether to use a fixed-position centered dock or vary position for alternate viewport ratios and small screens.
- Exact hover magnification/animation, tooltip geometry and state transitions, which should be taken from the wider dock flows.
- Empty-bin action when there are no contents; persistence and access/permissions for shared vs personal bin contents.
