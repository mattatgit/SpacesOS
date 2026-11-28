# Arlo v0.1

## Try it in Home

Open **Arlo**, the first dock item, and type **Make the dock 80 pixels high**. Press Enter. When the request completes, the dock changes and the activity shows both sizes. Press Escape or choose **Hide**. Click **Arlo · Completed** above the dock to reopen it, then **Undo** to restore the earlier height.

Try **Actually, use 64** and **What size is it now?** in the same conversation. **New** starts another conversation. **History** reopens earlier ones. A working activity can be cancelled. A failed or interrupted one can be retried. An unsent draft survives hiding the conversation and reopening it. The upper-right Sidebar still opens human messaging.

A divider drag operates on the same setting. The authored sizes are 56, 64 and 80 logical pixels, with integer interpolation from 64 through 80. If you resize the dock after a change, that activity loses its Undo action. Returning to the same number by dragging also counts as a later edit.

## Scope and persistence

Arlo operates from Home. Dock height belongs to the personal shell and applies across Spaces. When the compositor leaves Home, the shell immediately hides Arlo, the activity control and its history. A request already accepted in Home can finish against its original permission. Re-entering Home reveals its result. Other Spaces get the resulting dock height.

The shell launches a private standard-input/output service. It supplies the confirmed context on this channel, separately from the model's output. The Python service validates operations and parameters, records the initiating context and resource, and compares preference revisions before committing. The read, resize and undo operations are the entire model interface. The worker receives a bounded conversation excerpt and current height. It has no tools, shell commands, filesystem API or Matrix access.

A SQLite transaction commits the preference and activity result together. A shell restart recovers completed records, conversations, drafts and height. Pending work from an exited process becomes **Interrupted** and requires an explicit retry. A cancellation committed before the result prevents a late model response from applying anything. The service uses the user's private state directory at `$XDG_STATE_HOME/SpacesOS/arlo` (normally `~/.local/state/SpacesOS/arlo`). GNOME stores the test desktop’s corresponding files under its persistent test home. The developer option `nested --disposable` uses a temporary home. [Test profiles](desktop-shell.md).

Workspaces share a Unix user, filesystem and credentials today. Home-only controls and service validation establish the feature's permission boundary within the trusted shell. Protection against another process running as the same user requires stronger isolation.

## Provider and design

The first adapter runs Qwen2.5-1.5B-Instruct Q4_K_M locally through llama.cpp. The Nix package pins the weights and checksum. The first build downloads about 1.1 GB of weights. Installed inference runs offline without credentials, a listening server or another app's login. Model input is passed through a private temporary file descriptor and its diagnostic output is discarded. Natural-language interpretation can be imperfect. The settings service generates every success message from its own committed result. [Model and licence](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF).

The command input follows the 2026 **Guthrie Ask** variant. At 64 px its surface is 384 px wide, Arlo occupies the leading 40 px artwork slot, and the placeholder starts at 72 px. The implementation reuses the approved current Arlo illustration, shell typeface, dock material and Design System text controls. The activity panel, compact reopen button, History and placement above the dock are provisional. The corresponding Design System component is **Text link** under **Buttons**.

## Build and update

Develop from GNOME with `scripts/spaces-session nested`. The following commands run the focused service tests and build the complete login package.

```sh
nix --extra-experimental-features 'nix-command flakes' develop --command python3 -B arlo/test_service.py
nix --extra-experimental-features 'nix-command flakes' develop --command python3 -B arlo/test_live.py
nix --extra-experimental-features 'nix-command flakes' build .#session
./result/bin/spaces-session nested
```

For SpacesOS Install, point the existing host's SpacesOS input at `github:mattatgit/SpacesOS/codex/unified-launch`, retain its nixpkgs follow, and update just that input. From the host configuration directory:

```sh
nix --extra-experimental-features 'nix-command flakes' flake update spacesos
nix --extra-experimental-features 'nix-command flakes' build --no-link --print-out-paths .#nixosConfigurations.nixos.config.system.build.toplevel
```

Stage the printed system path with `sudo nixos-rebuild boot --no-reexec --store-path SYSTEM_PATH`. Coordinate the restart with the designer. After the agreed restart, select **Spaces OS** from the GDM gear. For the focused physical check, do the 80 px change, dismiss, reopen and undo, then check the Shared Space and Home. GNOME and the previous boot generation remain available. [Desktop recovery](daily-session.md).
