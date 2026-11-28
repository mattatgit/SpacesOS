{ pkgs, src }:
let
  paths = with pkgs; [ bash coreutils dbus gjs glib gtk3 gtk3.dev labwc nautilus quickshell nix util-linux
    python3 (import ../arlo/model.nix { inherit pkgs; })
    brightnessctl gnome-console kanshi libsecret mako networkmanager pavucontrol swayidle swaylock
    systemd upower wdisplays wireplumber wl-clipboard xdg-utils zenity gawk ];
in
pkgs.runCommand "spaces-wayland-session" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
  passthru.providedSessions = [ "spaces" ];
} ''
  mkdir -p $out/lib/spaces $out/bin $out/share/wayland-sessions
  cp -R ${src}/{arlo,dock,scripts,session,messaging,flake.nix,flake.lock} $out/lib/spaces
  patchShebangs $out/lib/spaces/scripts
  makeWrapper $out/lib/spaces/scripts/spaces-session $out/bin/spaces-session \
    --set SPACES_DOCK_DEVSHELL 1 \
    --set SPACES_NESTED_LABWC "${import ./nested-compositor.nix pkgs}/bin/labwc" \
    --set SPACES_POLKIT_AGENT "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1" \
    --prefix PATH : "${pkgs.lib.makeBinPath paths}" \
    --prefix GI_TYPELIB_PATH : "${import ./typelib-path.nix pkgs}"
  makeWrapper $out/lib/spaces/scripts/chat $out/bin/spaces-chat \
    --prefix PATH : "${pkgs.lib.makeBinPath paths}"
  cat > $out/share/wayland-sessions/spaces.desktop <<ENTRY
[Desktop Entry]
Name=Spaces OS
Comment=Spaces desktop development session
Type=Application
DesktopNames=Spaces;
Exec=$out/bin/spaces-session login
ENTRY
''
