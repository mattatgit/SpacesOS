# Spaces as a Framework login

## First login

Boot the generation that includes Spaces. At GDM, select your user, open the gear and choose **Spaces OS** before entering your password. The password login starts the regular user keyring. Open **Tools** in the dock for ChatGPT, Console, Centaur GTK4, LocalSend and Files. The strip uses installed desktop entries. Inkpad appears when it has its own installed launcher. A Firefox link to ChatGPT is available on machines that have Firefox in place of the native client.

**Super+Enter** opens Console even if the dock has no focus. Click the Spaces mark and choose **End Spaces Session** to return to GDM. Choose **GNOME** from the gear to use the fallback desktop. GDM can remember your own last selection. The module leaves the configured default alone.

## Working with windows and Spaces

| Action | Control |
| --- | --- |
| Move or resize | Drag the title bar or a window edge. Super+left drag moves and Super+right drag resizes from inside a client. |
| Maximise or restore | Double-click the title bar. Right-click a decorated title bar for window actions. |
| Minimise and recover a window | Use its minimise control or title-bar menu. Alt+Tab cycles windows in the Space, including minimised windows. |
| Switch Space | Click the Space name or the dock picker. Super+1 selects Home and Super+2 selects Ithos Studio. |
| Move a focused window to another Space | Super+Shift+1 or Super+Shift+2. Its position and process survive a Space switch. |
| Leave a Space | Spaces mark → Leave Space. The compositor moves to an empty overview workspace. Choose a Space to return. |
| Open My Devices | Select Home, then the far-right Sidebar button. The private view is enabled only after the compositor confirms Home. |
| Return from Tools or the Space picker | Click the strip below the icons or press Escape. |
| Lock | Super+L or Spaces mark → System → Lock Screen. Unlock with the login password. |
| Suspend or power | Spaces mark → System. Suspend acquires the lock first. Restart, shut down and logout ask for confirmation. |
| Recovery when the shell stops responding | Super+Shift+Escape ends the compositor immediately. Unsaved work can be lost. |

The top bar and dock reserve room for maximised windows. The desktop uses labwc for pointer and keyboard focus, clipboard, drag-and-drop and native client placement. The global menu follows the focused client. Notes exports its application actions. Third-party apps can still use their own menus. Spaces separate live windows during a login. Application relaunch and window positions across logouts depend on the application.

## Services and display

**System** includes Wi-Fi through NetworkManager, Sound through PipeWire, display controls and battery status. The Framework volume and backlight keys work through WirePlumber and brightnessctl. Notifications use mako and privileged operations use a polkit authentication dialog. Ten minutes of inactivity locks a Spaces login. Lock requests from logind and preparation for sleep also use swaylock. The NixOS module installs its PAM policy and selects GTK file dialogs and the wlroots capture portal for Spaces.

For persistent monitor settings, create a kanshi profile at `~/.config/SpacesOS/outputs`. Spaces reads it at login. For example, the Framework internal panel at 150% uses the following profile. **System → Displays** adjusts layout and scale for the current session. The shell panels currently use the compositor's default output.

```
profile {
    output eDP-1 enable scale 1.5
}
```

The real login uses the normal Matrix account, Secret Service and attachment picker. Run `spaces-chat setup` in Console if the account has yet to be paired. A nested session uses a temporary configuration and a separate bus. The encrypted test fixture covers attachments and retry. The physical Mac round trip needs a verified second device in My Devices. Keep LocalSend available during that transition. [Messaging setup and verification](messaging.md).

## Install, update and recover

In the host flake, declare the Spaces input, add `spacesos` to the outputs arguments and add `spacesos.nixosModules.session` to the existing machine's modules. Keep the machine's existing GNOME, GDM and boot configuration.

```nix
inputs.spacesos.url = "github:mattatgit/SpacesOS/feature/daily-session";
inputs.spacesos.inputs.nixpkgs.follows = "nixpkgs";
```

From the host configuration directory, run the following, substituting its actual configuration name for `nixos`. The lockfile pins the review branch revision. For later updates use `nix flake update spacesos`, then repeat the build and boot steps.

```sh
nix flake lock
nixos-rebuild build --flake .#nixos
sudo nixos-rebuild boot --flake .#nixos
```

Save your work and restart at a convenient time. A boot-only installation preserves the current login and lets the new GDM process discover both sessions. If the new generation fails to boot, select the previous NixOS generation from the boot menu. If Spaces alone fails, choose GNOME at GDM. Removing the module and its input from the host configuration and building another generation removes Spaces.

For development from a checkout, use `scripts/spaces-session nested`, `scripts/dock test` and `scripts/test-messaging`. For a packaged preview use `nix build .#session` and `./result/bin/spaces-session nested`. Physical password unlock, lid suspend/resume, file drag-and-drop between specific applications, external displays and the first signed-in ChatGPT launch should be checked at the first hardware login.
