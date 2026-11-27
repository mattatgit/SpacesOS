// Observe labwc's workspace protocol so the Shelf follows compositor shortcuts too.
imports.gi.versions.Gtk = '3.0';
const {Gio, GioUnix, GLib, Gtk, Libxfce4windowing: Xfw} = imports.gi;
Gtk.init(null);
const screen = Xfw.Screen.get_default();
const manager = screen.get_workspace_manager();
const ids = new Map([['Home', 'home'], ['Ithos Studio', 'ithos'], ['Overview', 'overview']]);
const group = manager.list_workspace_groups()[0];
if (!group || !group.list_workspaces().some(ws => ids.has(ws.get_name())))
    throw new Error('Spaces workspaces unavailable');

function report() {
    print(ids.get(group.get_active_workspace()?.get_name()) ?? 'unknown');
}
group.connect('active-workspace-changed', report);
const loop = new GLib.MainLoop(null, false);
const input = new Gio.DataInputStream({base_stream: new GioUnix.InputStream({fd: 0})});
function read() {
    input.read_line_async(GLib.PRIORITY_DEFAULT, null, (_stream, result) => {
        const [id] = input.read_line_finish_utf8(result);
        if (id === null) { loop.quit(); return; }
        const target = group.list_workspaces().find(ws => ids.get(ws.get_name()) === id);
        if (target && target !== group.get_active_workspace()) {
            try { target.activate(); } catch (error) { logError(error); report(); }
        } else {
            report();
        }
        read();
    });
}
print('ready');
read();
loop.run();
