// Read the opt-in GTK application menu on this session's bus. Watch the unique
// owner so that closing/restarting a client invalidates its actions.
const {Gio, GLib} = imports.gi;
const app = 'org.spacesos.Notes';
const path = '/org/spacesos/Notes';
let subscriptions = [], idle = 0, owner = '', root, actions;
function clearSubscriptions() {
    for (const [object, id] of subscriptions) object.disconnect(id);
    subscriptions = [];
}
function observe(object, signal) {
    subscriptions.push([object, object.connect(signal, schedule)]);
}
function attribute(model, index, name) {
    return model.get_item_attribute_value(index, name, null)?.deepUnpack() ?? '';
}
function items(model, depth = 0) {
    if (depth > 4) return [];
    observe(model, 'items-changed');
    const result = [];
    for (let i = 0; i < model.get_n_items(); i++) {
        const section = model.get_item_link(i, 'section');
        if (section) { result.push(...items(section, depth + 1)); continue; }
        const name = attribute(model, i, 'action');
        if (!name.startsWith('app.') || model.get_item_attribute_value(i, 'target', null)) continue;
        const action = name.slice(4);
        result.push({label: attribute(model, i, 'label'), action,
            enabled: actions.has_action(action) && actions.get_action_enabled(action)
                && !actions.get_action_parameter_type(action)});
    }
    return result;
}
function publish() {
    idle = 0;
    clearSubscriptions();
    const menus = [];
    if (owner) {
        observe(root, 'items-changed');
        for (const signal of ['action-added', 'action-removed', 'action-enabled-changed']) observe(actions, signal);
        for (let i = 0; i < root.get_n_items(); i++) {
            const sub = root.get_item_link(i, 'submenu');
            if (sub) menus.push({label: attribute(root, i, 'label'), items: items(sub)});
        }
    }
    print(JSON.stringify({owner, menus}));
    return GLib.SOURCE_REMOVE;
}
function schedule() { if (!idle) idle = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, publish); }
Gio.bus_watch_name(Gio.BusType.SESSION, app, Gio.BusNameWatcherFlags.NONE,
    (bus, name, unique) => {
        owner = unique;
        root = Gio.DBusMenuModel.get(bus, owner, path + '/menus/menubar');
        actions = Gio.DBusActionGroup.get(bus, owner, path);
        schedule();
    }, () => { owner = ''; schedule(); });
new GLib.MainLoop(null, false).run();
