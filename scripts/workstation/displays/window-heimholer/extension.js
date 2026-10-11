import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// Nach einem Monitorwechsel kurz warten, bis Mutter das neue Layout fertig hat
const SETTLE_MS = 1500;

export default class WindowHeimholer extends Extension {
    enable() {
        this._settings = this.getSettings();
        Main.wm.addKeybinding('move-all', this._settings, Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW, () => this._moveAll('hotkey'));
        this._createdId = global.display.connect('window-created', (_d, win) => this._onCreated(win));
        this._monitorsId = Main.layoutManager.connect('monitors-changed', () => this._onMonitorsChanged());
        this._timeouts = new Set();
    }

    disable() {
        Main.wm.removeKeybinding('move-all');
        global.display.disconnect(this._createdId);
        Main.layoutManager.disconnect(this._monitorsId);
        for (const id of this._timeouts)
            GLib.source_remove(id);
        this._timeouts = null;
        this._settings = null;
    }

    _later(ms, fn) {
        const id = GLib.timeout_add(GLib.PRIORITY_DEFAULT, ms, () => {
            this._timeouts.delete(id);
            fn();
            return GLib.SOURCE_REMOVE;
        });
        this._timeouts.add(id);
    }

    // Nur echte App-Fenster; Dialoge folgen ihrem Elternfenster, gamescope gehoert dem partydeck-tiler
    _eligible(win) {
        if (win.is_override_redirect() || win.is_skip_taskbar() || win.get_transient_for())
            return false;
        if (win.get_window_type() !== Meta.WindowType.NORMAL)
            return false;
        const id = `${win.get_wm_class() ?? ''} ${win.get_title() ?? ''}`;
        return !/gamescope/i.test(id);
    }

    _bringHome(win) {
        const primary = global.display.get_primary_monitor();
        if (!this._eligible(win) || win.get_monitor() === primary)
            return false;
        win.move_to_monitor(primary);
        return true;
    }

    _moveAll(reason) {
        let n = 0;
        for (const actor of global.get_window_actors()) {
            if (this._bringHome(actor.meta_window))
                n++;
        }
        console.log(`[window-heimholer] ${reason}: ${n} Fenster auf Monitor ${global.display.get_primary_monitor()} geholt`);
    }

    _onMonitorsChanged() {
        if (this._settings.get_boolean('auto-monitors-changed'))
            this._later(SETTLE_MS, () => this._moveAll('monitors-changed'));
    }

    // wm_class/Titel/Typ sind beim Erzeugen evtl. noch leer -> erst beim ersten Frame pruefen
    _onCreated(win) {
        if (!this._settings.get_boolean('auto-new'))
            return;
        const check = () => {
            if (this._bringHome(win))
                console.log(`[window-heimholer] neu: ${win.get_wm_class()} / ${win.get_title()} geholt`);
        };
        const actor = win.get_compositor_private();
        if (actor) {
            const id = actor.connect('first-frame', () => {
                actor.disconnect(id);
                check();
            });
        } else {
            this._later(500, check);
        }
    }
}
