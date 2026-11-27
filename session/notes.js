// A native GTK client used to exercise the exported application menu.
imports.gi.versions.Gtk = '3.0';
const {Gio, GLib} = imports.gi;
GLib.set_prgname('org.spacesos.Notes');
const Gtk = imports.gi.Gtk;
GLib.set_application_name('Notes');
const app = new Gtk.Application({application_id: 'org.spacesos.Notes'});
let editor;
app.connect('startup', () => {
    const edit = new Gio.Menu();
    edit.append('Insert Timestamp', 'app.timestamp');
    const menu = new Gio.Menu();
    menu.append_submenu('Edit', edit);
    app.set_menubar(menu);
    const timestamp = new Gio.SimpleAction({name: 'timestamp'});
    timestamp.connect('activate', () => {
        const time = GLib.DateTime.new_now_local().format('%H:%M:%S');
        editor.buffer.insert_at_cursor(time + '\n', -1);
        app.active_window.title = 'Notes · ' + time;
    });
    app.add_action(timestamp);
});
app.connect('activate', () => {
    if (app.active_window) { app.active_window.present(); return; }
    const window = new Gtk.ApplicationWindow({
        application: app, title: 'Notes', default_width: 420, default_height: 240,
        show_menubar: false
    });
    editor = new Gtk.TextView({left_margin: 18, top_margin: 18, wrap_mode: Gtk.WrapMode.WORD_CHAR});
    window.add(editor);
    window.show_all();
});
app.run([]);
