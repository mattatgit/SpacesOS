# The physical login uses stock labwc. Only its GNOME-hosted output needs
# to act as a fullscreen, fractionally scaled xdg_toplevel.
pkgs:
(pkgs.labwc.override {
  wlroots_0_19 = pkgs.wlroots_0_19.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ./nested-output.patch ];
  });
}).overrideAttrs (old: {
  patches = (old.patches or []) ++ [ ./nested-labwc.patch ];
})
