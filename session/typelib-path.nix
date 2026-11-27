pkgs:
pkgs.lib.makeSearchPath "lib/girepository-1.0" (with pkgs; [
  gtk3.out pango.out gdk-pixbuf.out harfbuzz.out at-spi2-core.out
  cairo.out glib.out gobject-introspection.out
])
