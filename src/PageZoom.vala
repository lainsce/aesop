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
public class PageZoom: GLib.Object {
    double zoom;
    public void zoom_plus() {
        zoom = zoom + 0.25;
        var viewer = new Aesop.Viewer();
        viewer.render_page();
        var settings = AppSettings.get_default ();
        settings.zoom = zoom;
    }

    public void zoom_minus() {
        if (zoom < 0.25) {
            return;
        }
        zoom = zoom - 0.25;
        var viewer = new Aesop.Viewer();
        viewer.render_page();
        var settings = AppSettings.get_default ();
        settings.zoom = zoom;
    }

}
}
