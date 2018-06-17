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
    public class MainWindow : Gtk.Window {
        public Gtk.Image image;
        public Gtk.ScrolledWindow page;
        public Poppler.Document document;
        public double zoom;
        public string filename;
        public int page_count;
        public int total;
        public int width;
        public int height;

        public Gtk.Adjustment page_horizontal_adjustment;
        public Gtk.Adjustment page_vertical_adjustment;

        public SimpleActionGroup actions { get; construct; }
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] action_entries = {
            { "zoom-plus",            action_zoom_plus            },
            { "zoom-minus",           action_zoom_minus           },
            { "scroll-up",            action_previous_page        },
            { "scroll-down",          action_next_page            },
            { "full-screen-toggle",   action_full_screen_toggle   },
            { "open",                 action_open                 }
        };

        public MainWindow (Gtk.Application application) {
            Object (application: application,
                    resizable: true,
                    title: _("Aesop"),
                    height_request: 600,
                    width_request: 600);
        
            key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.q, keycode)) {
                        this.destroy ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.o, keycode)) {
                        action_open();
                    }
                }
                return false;
            });
        }

        construct {
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/lainsce/aesop/stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            var settings = AppSettings.get_default ();

            this.set_title(("Aesop - %s (%d/%d)").printf(GLib.Path.get_basename(settings.last_file), page_count, total));

            page_count = settings.last_page;
            filename = settings.last_file;

            // widgets
            image = new Gtk.Image();

            page = new Gtk.ScrolledWindow(null, null);
            page_vertical_adjustment = page.get_vadjustment();
            page.expand = true;
            page.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
            page.add(image);
            page.scroll_event.connect(button_scroll_event);
            var page_context = page.get_style_context ();
            page_context.add_class ("aesop-page");

            render_page ();

            var stack = new Gtk.Stack ();
            stack.add_named (page, "page");

            var grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.add (stack);
            grid.show_all ();

            this.window_position = Gtk.WindowPosition.CENTER;
            this.add (grid);
            this.set_icon_name("com.github.lainsce.aesop");
            this.set_default_size(settings.width, settings.height);

            var toolbar = new Gtk.HeaderBar();
            toolbar.title = this.title;
            toolbar.has_subtitle = false;
            toolbar.set_show_close_button (true);
            var toolbar_context = toolbar.get_style_context ();
            toolbar_context.add_class ("aesop-toolbar");
            this.set_titlebar (toolbar);

            var open_button = new Gtk.Button ();
            open_button.has_tooltip = true;
            open_button.set_image (new Gtk.Image.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR));
            open_button.tooltip_text = (_("Open…"));

            open_button.clicked.connect (() => {
                action_open ();
            });

            var page_label = new Gtk.Label (_("Page:"));
            var page_button = new Gtk.SpinButton.with_range (1, settings.pages_total, 1);
            page_button.set_value(page_count);
            page_button.has_focus = false;

            page_button.value_changed.connect (() => {
                int val = page_button.get_value_as_int ();
                page_count = val;
                
                render_page();
            });

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            box.pack_start (page_label, true, true, 0);
            box.pack_start (page_button, true, true, 0);

            toolbar.pack_start (open_button);
            toolbar.pack_end (box);

            this.show_all();

            if (settings.last_file != "") {
                File file = File.new_for_path(settings.last_file);
                if (file.query_exists() == true) {
                    filename = settings.last_file;
                    page_count = settings.last_page;
                    
                    render_page();
                }
            }

            int h = settings.height;
            int w = settings.width;

            if (w != 0 && h != 0) {
                this.resize (w, h);
            }
        }

        public void open(File[] files, string hint) {
            foreach (File f in files) {
                filename = f.get_path();
            }
            page_count = 1;
            
            render_page();
        }
    
        // Mouse EventButton Scroll
        private bool button_scroll_event (Gdk.EventScroll event) {
            Gdk.ScrollDirection direction;
            event.get_scroll_direction (out direction);
            if (direction == Gdk.ScrollDirection.DOWN) {
                action_scroll_down ();
            } else {
                action_scroll_up ();
            }
            return false;
        }
    
        private void action_zoom_plus() {
            zoom = zoom + 0.25;
            
            render_page();
            var settings = AppSettings.get_default ();
            settings.zoom = zoom;
        }
    
        private void action_zoom_minus() {
            if (zoom < 0.25) {
                return;
            }
            zoom = zoom - 0.25;
            
            render_page();
            var settings = AppSettings.get_default ();
            settings.zoom = zoom;
        }
    
        private void action_previous_page() {
            if (page_count < 2) {
                return;
            }
            page_count--;
            
            render_page();
        }
    
        private void action_next_page() {
            var settings = AppSettings.get_default ();
            if (page_count > settings.pages_total) {
                return;
            }
            page_count++;
            
            render_page();
        }
    
        private void action_scroll_up() {
            action_previous_page();
        }
    
        private void action_scroll_down() {
            action_next_page();
        }
    
        private void action_full_screen_toggle() {
            if ((this.get_window().get_state() & Gdk.WindowState.FULLSCREEN) == 0) {
                this.fullscreen();
            } else {
                this.unfullscreen();
            }
        }
    
        private void action_open() {
            show_open();
        }

        public void show_open() {
            var dialog = new Gtk.FileChooserDialog("Open", this,
                                                Gtk.FileChooserAction.OPEN,
                                                "Cancel", Gtk.ResponseType.CANCEL,
                                                "Open",   Gtk.ResponseType.ACCEPT);
            if (filename != null) {
                dialog.set_current_folder(Path.get_dirname(filename));
            }
            dialog.set_select_multiple(false);
            dialog.set_modal(true);
            dialog.show();
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                filename = dialog.get_filename();
                page_count = 1;
                this.render_page();
            }
            dialog.destroy();
        }

        public void render_page() {
            var settings = AppSettings.get_default ();
            
            try {
                document = new document.from_file(Filename.to_uri(filename), "");
            } catch(Error e) {
                error ("%s", e.message);
            }

            total = document.get_n_pages();

            // page size
            double page_width;
            double page_height;
            var pages = document.get_page(page_count - 1);
            pages.get_size(out page_width, out page_height);

            // image size
            int width  = (int)(settings.zoom * page_width) ;
            int height = (int)(settings.zoom * page_height);

            // render page to cairo context
            var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
            var context = new Cairo.Context(surface);
            context.scale(settings.zoom, settings.zoom);
            pages.render(context);

            // get pixbuf from surface
            Gdk.Pixbuf pixbuf = Gdk.pixbuf_get_from_surface(surface, 0, 0, width, height);

            // set title
            this.set_title(("Aesop - %s (%d/%d)").printf(GLib.Path.get_basename(filename), page_count,
                                                total));

            // image from pixbuf
            this.image.set_from_pixbuf(pixbuf);

            // move scrollbar's adjustment
            this.page.get_vadjustment().set_value(0);

            // save
            settings.last_file = filename;
            settings.last_page = page_count;
            settings.pages_total = total;
        }

        protected bool match_keycode (int keyval, uint code) {
            Gdk.KeymapKey [] keys;
            Gdk.Keymap keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
            if (keymap.get_entries_for_keyval (keyval, out keys)) {
                foreach (var key in keys) {
                    if (code == key.keycode)
                        return true;
                    }
                }

            return false;
        }
    
        public override bool delete_event (Gdk.EventAny event) {
            this.get_size(out width, out height);
            var settings = AppSettings.get_default ();
            settings.width = width;
            settings.height = height;
            settings.last_page = page_count;
            settings.last_file = filename;

            return false;
        }
    }
}