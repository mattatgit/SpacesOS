# Spaces OS

Spaces OS is an experimental, design-led desktop environment and longer-term multi-user computing platform built on NixOS.

The project begins with a **native Linux desktop shell** based on the Spaces OS interface designs. Over time it aims to support persistent Spaces, people, applications, collaborative presence, and agent-assisted work.

There are two ways to open the native desktop.

- In **GNOME**, click the pinned **Spaces** icon to open or return to the fullscreen test desktop. **Spaces menu → Return to GNOME** closes it. The test profile keeps its own preferences and Arlo history. [Launcher setup and test profiles](docs/desktop-shell.md).
- At **login**, choose **Spaces OS** from the GDM gear for the real desktop. [Installation and GNOME recovery](docs/daily-session.md).

Both run the same native shell. From Home, open **Arlo** to change the dock height, reopen an activity or undo a change. [Arlo and its local model](docs/arlo.md).

Home’s right-hand Sidebar connects to an encrypted Matrix conversation shared with Element on a Mac. [Connect and test My Devices](docs/messaging.md).

## How we'll work

- Treat the **Spaces OS** board in *Spaces OS 2026* as the main design reference.
- Keep the *Spaces OS exploration* and *Spaces Agentic version* boards as proposals unless explicitly adopted.
- Preserve *SpacesOS 2025* as design history.
- Grow the incomplete *SpacesOS Design System* into a source of reusable tokens and components.
- Build incrementally on NixOS, retaining a working fallback desktop while experimenting.
- Separate agreed decisions, proposals, and unresolved questions.

The architecture, Figma inventory, design decisions, and first implementation milestones will be proposed in a review pull request.

> The GitHub repository is public. Direct private-design-file URLs and unexported Figma assets will not be added to public repository files without deliberate review.
