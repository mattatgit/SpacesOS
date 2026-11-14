# Spaces OS — Initial architecture proposal

**Status: PROPOSAL — not approved or implemented.**

## Goal

Build a high-fidelity native Spaces OS desktop on NixOS, then progressively implement persistent Spaces, people, applications, agent services and trusted peer collaboration without maintaining a Linux kernel fork.

## Proposed layers

1. **Spaces desktop shell:** dock, top navigation, sub-docks, Sidebar/Shelf, system controls and visual identity.
2. **Space service:** persistent Space identity, lifecycle, membership, runtime metadata, state and permission boundaries.
3. **Collaboration/agent services:** presence, shared input and content, invitations, future Clan connectivity and scoped agent actions.
4. **Wayland compositor:** focus, window placement, visual composition, input, output scaling and desktop protocols.
5. **NixOS/Linux:** graphics, hardware integration, drivers, audio, networking, storage, package and system configuration.

Shell UI must not become the source of truth for Space data; user-facing components consume explicit services/interfaces.

## Proposed initial technology evaluation

- **NixOS** for reproducible laptop/VM development, packaging and controlled desktop-session configuration.
- **Wayland** as the display protocol.
- **KWin / Plasma** as a fallback desktop and initial compositor integration candidate; **labwc** as a lightweight alternative worth testing if integration constraints warrant it.
- **Qt Quick / QML with Quickshell** as the leading shell implementation candidate, subject to a real prototype and compatibility tests. GTK4 applications, including Centaur, should remain welcome.
- **microvm.nix / isolated runtimes** as a later research track, not prerequisite for a functioning dock or local Space.
- No kernel changes, custom compositor or bespoke filesystem in the initial milestone.

These are candidates, not locked dependencies. Validate supported protocols and behavior against current versions when implementation begins.

## Non-negotiable engineering boundaries

- **Fallback desktop:** a regular desktop session must remain available if Spaces crashes.
- **No implicit remote control:** visibility, cursor presence and control privileges are separate permissions.
- **Privacy model:** local/personal contexts should not expose private windows to remote participants.
- **Multi-display/scaling:** support different output scale factors and display sizes with logical UI coordinates; do not treat a Figma 1920×1280 artboard as fixed physical screen geometry.
- **Accessible input:** keyboard navigation, focus and text input must work alongside mouse and trackpad.
- **Reproducibility:** record Nix dependencies and keep build/test configuration in the repository.
- **Visual regression:** verify screenshots of native components against approved Figma references, while separately testing behavior.
- **System resilience:** avoid replacing login, power, networking or other critical paths before tested alternatives exist.

## Multi-user Spaces model

The agreed product direction includes multi-user Spaces and visible collaborator cursors. The alternative Quiet/Zen/Presence proposals are not initial requirements.

The first collaboration prototype should use a purposely shared canvas or application with stable **Space/content coordinates** and per-participant viewport transforms. Do not assume operating-system windows or global screen positions can be synchronized directly between different devices and display sizes.

Questions to resolve separately: app-level versus OS-level shared control; viewport mapping; independent input/focus; permissions; session ownership; lag and disconnections; and safe disclosure of local content.

## Relationship to Centaur

Centaur is an important native app and development test case, but Spaces OS should stay in a separate repository, with independent release and lifecycle. Cross-project protocols or UI conventions should be explicit rather than hidden implementation couplings.
