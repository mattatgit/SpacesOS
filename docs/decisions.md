# Spaces OS — Decision record

The categories below deliberately distinguish product decisions already expressed by the designer from technical proposals awaiting validation.

## Agreed product direction

**D-001: Native NixOS direction.** Spaces OS begins as a real Linux/NixOS desktop experience, rather than a website that visually imitates an operating system.

**D-002: Design precedence.** The *Spaces OS* board in *Spaces OS 2026* is the primary design reference. The *Spaces OS exploration* and *Spaces Agentic version* boards are optional explorations; *SpacesOS 2025* provides history.

**D-003: Multiplayer is central.** Shared Spaces may display other participants' cursors and activity. Screen size differences are a technical problem to solve, not a reason to remove the concept.

**D-004: Alternative modes deferred.** Presence/Quiet/Zen explorations are not initial requirements and should not displace the original collaborative Space model.

**D-005: Agentic ambition.** Spaces OS should eventually be agentic, but the pitch-oriented Agentic board does not establish an automatic feature commitment.

**D-006: Figma preservation.** Preserve existing design work. Track implementation decisions in the repository rather than rewriting old explorations into a false single history.

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
