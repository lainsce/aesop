/*-
 * Copyright (c) 2018 Lains
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

namespace Aesop {
    public class AppSettings : GLib.Settings {
        public int width {
            get { return get_int ("width"); }
            set { set_int ("width", value); }
        }
        public int height {
            get { return get_int ("height"); }
            set { set_int ("height", value); }
        }
        public bool maximized {
            get { return get_boolean ("maximized"); }
            set { set_boolean ("maximized", value); }
        }
        public bool invert {
            get { return get_boolean ("invert"); }
            set { set_boolean ("invert", value); }
        }
        public bool live_mode {
            get { return get_boolean ("live-mode"); }
            set { set_boolean ("live-mode", value); }
        }
        public double zoom {
            get { return get_double ("zoom"); }
            set { set_double ("zoom", value); }
        }
        public string last_file {
            owned get { return get_string ("last-file"); }
            set { set_string ("last-file", value); }
        }
        public int last_page {
            get { return get_int ("last-page"); }
            set { set_int ("last-page", value); }
        }
        public int pages_total {
            get { return get_int ("pages-total"); }
            set { set_int ("pages-total", value); }
        }

        private static AppSettings? instance;
        public static unowned AppSettings get_default () {
            if (instance == null) {
                instance = new AppSettings ();
            }

            return instance;
        }

        private AppSettings () {
            Object (schema_id: "com.github.lainsce.aesop");
        }
    }
}
