# Spaces OS — Documentation index

These documents start the project as a **design-led native desktop effort**. They are deliberately not a claim that an architecture has already been implemented or fully approved.

- [Design source map](design-source-map.md): what the three Figma files contain and how to interpret them.
- [Desktop shell and independent session](desktop-shell.md) covers the launcher, compositor proof of concept and optional login entry.
- [Native dock preview](native-dock.md) covers launch, controls, and visual review.
- [Dock implementation notes](dock-implementation-notes.md) records the artwork refresh and profile measurements.
- [Architecture proposal](architecture-proposal.md): proposed technical boundaries and initial stack choices.
- [Roadmap](roadmap.md): first working milestone, sequencing, and acceptance criteria.
- [Decision log](decisions.md): agreed direction, working assumptions, and unresolved decisions.

## Source of truth

- **Figma** remains authoritative for visual designs and detailed interaction references.
- **This repository** is authoritative for implementation, build instructions, tests, architectural decisions and adoption status.
- When a design conflicts with an approved implementation decision, log the conflict rather than silently picking one.
- The repository is **public**: avoid copying unpublished screens, comments, personal information or full Figma assets into it without review.

## Working practices

Use feature branches and pull requests for substantial changes; do not implement a speculative feature solely because a Figma frame exists. Record explicit design approval before calling an exploration canonical. Keep a usable fallback desktop session for testing.
