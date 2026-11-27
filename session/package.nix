{ pkgs, src }:
let
  paths = with pkgs; [ bash coreutils dbus gjs glib gtk3.dev labwc nautilus quickshell nix util-linux ];
in
pkgs.runCommand "spaces-wayland-session" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
  passthru.providedSessions = [ "spaces" ];
} ''
  mkdir -p $out/lib/spaces $out/bin $out/share/wayland-sessions
  cp -R ${src}/{dock,scripts,session,messaging,flake.nix,flake.lock} $out/lib/spaces
  patchShebangs $out/lib/spaces/scripts
  makeWrapper $out/lib/spaces/scripts/spaces-session $out/bin/spaces-session \
    --set SPACES_DOCK_DEVSHELL 1 \
    --prefix PATH : "${pkgs.lib.makeBinPath paths}" \
    --prefix GI_TYPELIB_PATH : "${import ./typelib-path.nix pkgs}"
  cat > $out/share/wayland-sessions/spaces.desktop <<ENTRY
[Desktop Entry]
Name=Spaces OS
Comment=Spaces desktop development session
Type=Application
DesktopNames=Spaces;
Exec=$out/bin/spaces-session login
ENTRY
''
