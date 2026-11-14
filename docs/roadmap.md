# Spaces OS — Initial implementation roadmap

**Status: PROPOSED.** Work is organized into independently testable milestones; no dates or time estimates are committed.

## Milestone 0 — Reproducible development foundation

- A working NixOS development environment (VM first, Framework when available).
- Safe login with standard fallback desktop session.
- Repo-based build/run instructions and basic CI checks.
- Choose compositor integration only after a small technical test.

**Done when:** a second machine can reproduce the development setup without losing access to its normal desktop.

## Milestone 1 — A real Spaces dock

- Identify and approve canonical Figma frames for the Main dock, tooltips and Spaces/People/Services sub-docks.
- Export approved static assets into a tracked, appropriately licensed asset structure.
- Implement native shell surfaces, component states, hover/focus, sub-dock navigation and an application launcher.
- Support input, keyboard, basic accessibility and logical scaling.
- Test the shell on a running Wayland session, not just in a standalone mockup.
- Produce visual comparisons between actual Figma references and rendered native output.

**Done when:** a user can start the Spaces session, operate the dock, launch at least one real application and return to a safe fallback desktop.

## Milestone 2 — Sidebar/Shelf + Space navigation

- Reproduce the selected persistent sidebar components.
- Introduce a local Space service and two or more test Spaces.
- Navigate between Spaces, retaining appropriate state and actual application associations.

**Done when:** Space switching changes meaningful application/context state, not merely wallpaper.

## Milestone 3 — Window and shell integration

- Define window treatment and native application boundaries.
- Integrate focus, placement, resizing, notifications, display scaling, system menus and key shortcuts.
- Start to evaluate Files and Settings as independent native applications.

**Done when:** everyday desktop operations work reliably for the agreed representative tasks.

## Milestone 4 — Local-to-shared Space prototype

- Invite a second participant into a deliberately collaboration-aware test app.
- Show live presence and multiple distinct cursors.
- Handle dissimilar viewport sizes, scrolling, scaling and disconnection.
- Enforce explicit permission boundaries before any remote action.

**Done when:** two users can collaborate without mirroring their entire operating-system desktops.

## Deferred areas

Kernel changes, a new compositor, arbitrary app remote control, micro-VMs for every Space, full agent automation, installer replacement, Clan Explorer and speculative agentic pitch features are **not Milestone 1 commitments**.

## Immediate next work

Implement a minimal native dock proof of concept on a feature branch after reviewing its exact Figma states/assets and testing the selected compositor/shell toolkit. Do not interpret the design audit alone as proof that native fidelity is achieved.
