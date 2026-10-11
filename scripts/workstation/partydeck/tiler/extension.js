import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const CONFIG_DIR = GLib.build_filenamev([GLib.get_user_config_dir(), 'partydeck-tiler']);
const CONFIG = GLib.build_filenamev([CONFIG_DIR, 'monitor']);
// Inhalt: "oben-unten" oder "links-rechts" (gilt fuer 2 Spieler)
const LAYOUT = GLib.build_filenamev([CONFIG_DIR, 'layout']);

function readConfig(path, fallback) {
    try {
        const [ok, bytes] = GLib.file_get_contents(path);
        if (ok)
            return new TextDecoder().decode(bytes).trim() || fallback;
    } catch (_e) {}
    return fallback;
}

export default class PartydeckTiler extends Extension {
    enable() {
        this._wins = [];
        this._createdId = global.display.connect('window-created', (_d, win) => this._onCreated(win));
        // layout/monitor-Datei geaendert -> sofort neu anordnen
        GLib.mkdir_with_parents(CONFIG_DIR, 0o755);
        this._dirMonitor = Gio.File.new_for_path(CONFIG_DIR).monitor_directory(Gio.FileMonitorFlags.WATCH_MOVES, null);
        this._dirMonitorId = this._dirMonitor.connect('changed', () => this._tile());
    }

    disable() {
        global.display.disconnect(this._createdId);
        this._dirMonitor.disconnect(this._dirMonitorId);
        this._dirMonitor.cancel();
        this._dirMonitor = null;
        for (const w of this._wins)
            w.disconnect(w._pdUnmanagedId);
        this._wins = [];
    }

    _isGamescope(win) {
        const id = `${win.get_wm_class() ?? ''} ${win.get_title() ?? ''}`;
        return /gamescope/i.test(id);
    }

    // wm_class/Titel sind beim Erzeugen evtl. noch leer -> erst beim ersten Frame pruefen
    _onCreated(win) {
        const actor = win.get_compositor_private();
        const check = () => {
            if (!this._isGamescope(win) || this._wins.includes(win))
                return;
            this._wins.push(win);
            win._pdUnmanagedId = win.connect('unmanaged', () => {
                this._wins = this._wins.filter(w => w !== win);
                this._tile();
            });
            console.log(`[partydeck-tiler] Fenster ${this._wins.length}: ${win.get_wm_class()} / ${win.get_title()}`);
            this._tile();
        };
        if (actor) {
            const id = actor.connect('first-frame', () => {
                actor.disconnect(id);
                check();
            });
        } else {
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 500, () => {
                check();
                return GLib.SOURCE_REMOVE;
            });
        }
    }

    _monitorIndex() {
        const connector = readConfig(CONFIG, 'HDMI-1');
        const idx = global.backend.get_monitor_manager().get_monitor_for_connector(connector);
        return idx >= 0 ? idx : global.display.get_primary_monitor();
    }

    _tile() {
        const n = this._wins.length;
        if (n === 0)
            return;
        const m = this._monitorIndex();
        const g = global.display.get_monitor_geometry(m);
        const hw = Math.floor(g.width / 2), hh = Math.floor(g.height / 2);

        this._wins.forEach((w, i) => {
            let r;
            if (n === 1)
                r = [g.x, g.y, g.width, g.height];
            else if (n === 2 && readConfig(LAYOUT, 'oben-unten') === 'links-rechts')
                r = [g.x + i * hw, g.y, hw, g.height];
            else if (n === 2)
                r = [g.x, g.y + i * hh, g.width, hh];
            else
                r = [g.x + (i % 2) * hw, g.y + Math.floor(i / 2) * hh, hw, hh];

            try {
                if (w.is_fullscreen())
                    w.unmake_fullscreen();
                if (w.is_maximized?.() || w.get_maximized?.())
                    w.unmaximize();
            } catch (_e) {}
            w.move_to_monitor(m);
            w.move_resize_frame(false, ...r);
        });
    }
}
