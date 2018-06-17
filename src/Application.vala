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
    public class Application: Gtk.Application {
        public static MainWindow window = null;

        construct {
            flags |= ApplicationFlags.HANDLES_OPEN;
            application_id = "com.github.lainsce.aesop";
        }

        protected override void activate () {
            if (window != null) {
                window.present ();
                return;
            }
            window = new MainWindow (this);
            window.show_all ();
        }

        public static int main (string[] args) {
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.textdomain (Build.GETTEXT_PACKAGE);

            var app = new Aesop.Application ();
            return app.run (args);
        }
    }
}