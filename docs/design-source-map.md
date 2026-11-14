# Spaces OS design source map

**Status:** Initial inventory, based on read-only inspection of Figma page/section structure and representative screenshots. Not yet a complete frame-level audit or feature specification.

## Authority and interpretation

| File / board | Intended role | Status |
| --- | --- | --- |
| Spaces OS 2026 / **Spaces OS** | Main compilation of UI flows and behaviours | **Primary reference** |
| Spaces OS 2026 / **Spaces OS exploration** | Newer directions worth assessing individually | **Exploratory** |
| Spaces OS 2026 / **Spaces Agentic version** | Agentic possibilities, onboarding and pitch-oriented concepts | **Exploratory, not delivery commitments** |
| SpacesOS 2025 | Early iterations and design history | **Historical reference** |
| SpacesOS Design System | Reusable components, colours and effects | **Partial library to develop incrementally** |
| Spaces OS 2026 / Clan Explorer | Related network-explorer/builder application | **Out of current scope** |
| Other unrelated boards | Adjacent products and experiments | **Out of initial scope** |

The Figma links are available in the design conversation; no private file URLs or exported visual assets have been included here.

## Main 2026 board: inspected sections

The **Spaces OS** board contains 21 named sections, plus miscellaneous frames. Its sections include:

| Area | Evidence discovered | Implementation significance |
| --- | --- | --- |
| Dock and tooltips | 27 frames, 7 component sets; Main dock, Subdock Spaces, People and Services, tooltips and state variants | **First visual and interaction target** |
| Sidebar / Shelf components | 27 component sets and 1 component: Home, People, Files, communities, members and invitation lists | Persistent contextual interface |
| General components | 42 component sets and 4 instances: icons, search, tab selection, state, toggles, settings, navigation, tooltips | Reusable native controls |
| Files | 12 full 1920×1280 frames and many variants: overview, recents, shared, favourites, lists, sharing, installed apps | Later native app |
| Settings | 3 full example frames and 6 component sets | System-control shell/app work |
| Invitation to Space | A sequence of ten named receipt states | Collaboration flow |
| Create a Space to open Doc | Multi-step screen sequence and cursor/chat component sets | Space lifecycle design |
| Additional sections | Quick settings, focus modes, video call, leaving a Space, app installation, cursor modes, power off, wallet and related functions | Later scoped review |

These names and counts reflect Figma's current structure, not approved code requirements.

### New dock icon update (inspected 14 November 2026)

The new **Dock + app icons** section (Figma node `4299:127357`) provides updated 1024px clay icon artwork and three 1920×1280 desktop previews. The dock itself appears in **56px (384px wide), 64px (424px wide) and 80px (500px wide)** versions, with icon slots of 36–40px on the smaller docks and 48px on the 80px dock.

The section contains **distinct full and empty bin assets**. These are states of one dock item, not separate entries. 64px is the sub-dock prototype baseline; 80px is the preferred default candidate pending on-device review. See [Dock implementation notes](dock-implementation-notes.md).

## Exploration board

Found: transition explorations; mode explorations; sidebar/Shelf variations; multiplayer outlines and components; adding people to Spaces; onboarding; conversational installer; recent dock concepts.

**Important decision:** Presence, Quiet and Zen mode explorations arose partly from objections to other users' cursors in the OS. For now they are **deferred alternatives**, not required core modes. They should not override the primary shared-Space model.

## Agentic board

Includes agentic desktop sketches, home content such as reports and tasks, onboarding, workflow sketches, Space creation and build-queue prototypes. Agentic functionality is part of the long-term identity of Spaces OS; individual screenshots are not approved delivery commitments.

## Design System: initial component audit

The Design System file currently contains:
- **Colours:** 35 named paint styles; a light/dark neutral range and accents.
- **Effects:** 6 named effect styles, including window shadows and blur.
- **Buttons:** Light and dark component sets; size and interaction-state variations.
- **UI elements:** Toggles, checkboxes, window controls, tooltip, search, nav, modal and other component families.
- **Window examples:** Active/inactive, light/dark, document and application windows, warning modals and side navigation.
- **Additional pages:** Avatars, grids, shadows and blur.

In the inspected file there were **no local variable collections or local text styles**. Existing Figma components/styles are useful, but should not be mistaken for a complete semantic token system.

## Next design audit

1. Identify the **specific canonical frames and component variants** for the dock, its sub-docks and the top navigation.
2. Document interaction triggers, persistence, keyboard usage, focus rules, edge cases and animation/motion.
3. Identify exact typography, visual assets and design tokens required by that initial slice.
4. Compare newer alternatives with the primary designs only where the user has explicitly asked to revisit them.
5. Attach precise node references to implementation tasks after design review.

Do not edit or reorganize original Figma canvases during this initial documentation pass.
