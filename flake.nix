{
  description = "Spaces OS native Wayland development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs, ... }: {
    devShells.x86_64-linux.messagingTest =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux; in
      pkgs.mkShell {
        inputsFrom = [ self.devShells.x86_64-linux.messaging ];
        packages = [ pkgs.matrix-synapse pkgs.python3 pkgs.gnome-keyring pkgs.dbus ];
        SPACES_TEST_ENV = "1";
      };
    devShells.x86_64-linux.messaging =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux; in
      pkgs.mkShell {
        SPACES_MESSAGING_ENV = "1";
        packages = with pkgs; [ cargo rustc pkg-config cmake perl sqlite openssl libsecret xdg-utils ];
      };
    devShells.x86_64-linux.default =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in
      pkgs.mkShell {
        SPACES_DOCK_DEVSHELL = "1";
        SPACES_DOCK_QML_IMPORTS = "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml";
        SPACES_DOCK_TEST_PLUGINS = pkgs.lib.makeSearchPath "lib/qt-6/plugins" [
          pkgs.qt6.qtbase
          pkgs.qt6.qtsvg
          pkgs.qt6.qtwayland
        ];

        packages = with pkgs; [
          cmake
          git
          grim
          labwc
          ninja
          pkg-config
          qt6.qtdeclarative
          qt6.qttools
          quickshell
          wayland-scanner
          wayland-utils
          xdg-utils
        ];

        buildInputs = with pkgs; [
          qt6.qtbase
          qt6.qtsvg
          qt6.qtwayland
          wayland
          wayland-protocols
        ];
      };
  };
}
