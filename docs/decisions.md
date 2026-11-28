# Spaces OS — Decision record

The categories below deliberately distinguish product decisions already expressed by the designer from technical proposals awaiting validation.

## Agreed product direction

**D-001: Native NixOS direction.** Spaces OS begins as a real Linux/NixOS desktop experience, rather than a website that visually imitates an operating system.

**D-002: Design precedence.** The *Spaces OS* board in *Spaces OS 2026* is the primary design reference. The *Spaces OS exploration* and *Spaces Agentic version* boards are optional explorations; *SpacesOS 2025* provides history.

**D-003: Multiplayer is central.** Shared Spaces may display other participants' cursors and activity. Screen size differences are a technical problem to solve, not a reason to remove the concept.

**D-004: Alternative modes deferred.** Presence/Quiet/Zen explorations are not initial requirements and should not displace the original collaborative Space model.

**D-005: Agentic ambition.** Spaces OS should eventually be agentic, but the pitch-oriented Agentic board does not establish an automatic feature commitment.

**D-006: Figma preservation.** Preserve existing design work. Track implementation decisions in the repository rather than rewriting old explorations into a false single history.

**D-007. Global application menus.** Compatible applications export their menus and actions for the focused window. The Spaces system bar presents them. The first implementation uses a GTK client on labwc. [Desktop shell investigation](desktop-shell.md).

**D-008. Space ownership.** Each running application instance and all its windows belong to its originating Space. Each Space can have its own application set. The Tools dock should eventually reflect that set. The interim compositor uses workspaces with shared processes, files and credentials. Spaces removes its window-transfer controls. Stronger isolation, potentially through microVMs, remains future work.

**D-009. Personal resources and agent authority.** Human conversations use the upper-right contextual Sidebar. Arlo has a separate conversation above the dock. An execution service grants explicit capabilities for a resource and initiating context. Personal chats, files and credentials require their own permission before a shared Space or agent can use them. The first capability is Home-initiated control of the personal shell's dock height. Other Space-specific agents remain a product direction.

**D-010. Durable activity and undo.** The shell stores the preference and outcome together. Dismissal leaves tasks running with the original permission. Undo checks the applied revision. A provider adapter and provisional activity panel can evolve independently of these semantics. [Arlo milestone](arlo.md).

## Proposed technical decisions — pending prototype/review

**P-001:** Use a Wayland-based native shell on NixOS and retain a fallback conventional desktop.

**P-002:** Test Qt Quick/QML + Quickshell first for the shell; evaluate current Wayland/compositor compatibility.

**P-003:** Separate the Space service from the UI. Keep Centaur a separately developed application.

**P-004:** Do not modify the Linux kernel or implement a new compositor for Milestone 1.

**P-005:** Build the actual Main dock and sub-docks as the first functional vertical slice.

## Open questions

- Which exact dock frames and component states from 2026 are final?
- Do current Space navigation interactions require compositor-specific window control unavailable through standard Wayland protocols?
- How should the Sidebar behave at narrow widths, on multiple displays and at non-integer scaling?
- What are the final typography families, metrics and licensing constraints?
- What is the precise local/personal/shared content visibility model?
- Which Space data belongs in a persistent system service versus application storage?
- What is the minimum supported Framework model, graphics stack and NixOS release?
- When should alternative mode explorations be revisited, if at all?

## Change control

When a proposal is accepted, record the date and rationale and promote it into the agreed section. When an exploratory Figma screen is adopted, record its canonical frame ID and associated behaviour. A PR does not by itself turn a proposal into an approved product decision.
