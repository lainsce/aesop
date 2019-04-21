/*
 * Copyright (c) 2018 Lains
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 */

namespace Aesop {
    public class Widgets.LiveModeButton : Gtk.Bin {
        public Gtk.ModelButton button;
        public MainWindow win;

        public LiveModeButton () {
            var settings = AppSettings.get_default ();
            button = new Gtk.ModelButton ();
            button.label = _("Enable Live Mode");
            (button.get_child () as Gtk.Label).xalign = 0;
            button.role = Gtk.ButtonRole.CHECK;
            button.clicked.connect (() => {
                settings.live_mode = !settings.live_mode;
                if (win != null) {
                    if (settings.live_mode == true) {
                        Timeout.add_seconds (30, () => {
                            win.render_page (win.context);
                            return false;
                        });
                    }
                }
            });

            button.active = settings.live_mode;
            settings.changed.connect (() => {
                button.active = settings.live_mode;
            });

            add (button);
        }
    }
}
