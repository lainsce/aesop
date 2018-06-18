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
        public Granite.Widgets.Welcome welcome;

        public Gtk.Adjustment page_horizontal_adjustment;
        public Gtk.Adjustment page_vertical_adjustment;

        private const string LIGHT_ICON_SYMBOLIC = "display-brightness-symbolic";
        private const string DARK_ICON_SYMBOLIC = "weather-clear-night-symbolic";
        private ModeSwitch mode_switch;

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_ZOOM_PLUS = "action_zoom_plus";
        public const string ACTION_ZOOM_MINUS = "action_zoom_minus";
        public const string ACTION_SCROLL_UP = "action_scroll_up";
        public const string ACTION_SCROLL_DOWN = "action_scroll_down";
        public const string ACTION_FULLSCREEN = "action_fullscreen";
        public const string ACTION_PRINT = "action_print";
        public const string ACTION_OPEN = "action_open";
        public SimpleActionGroup actions { get; construct; }
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] action_entries = {
            { ACTION_ZOOM_PLUS,            action_zoom_plus            },
            { ACTION_ZOOM_MINUS,           action_zoom_minus           },
            { ACTION_SCROLL_UP,            action_previous_page        },
            { ACTION_SCROLL_DOWN,          action_next_page            },
            { ACTION_FULLSCREEN,           action_full_screen_toggle   },
            { ACTION_PRINT,                action_print                },
            { ACTION_OPEN,                 action_open                 }
        };

        public MainWindow (Gtk.Application application) {
            Object (application: application,
                    resizable: true,
                    height_request: 925,
                    width_request: 925);

            key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state) != 0) {
                    if (match_keycode (Gdk.Key.plus, keycode)) {
                        action_zoom_plus ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.minus, keycode)) {
                        action_zoom_minus ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.q, keycode)) {
                        this.destroy ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.o, keycode)) {
                        action_open ();
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

            actions = new SimpleActionGroup ();
            actions.add_action_entries (action_entries, this);
            insert_action_group ("win", actions);

            welcome = new Granite.Widgets.Welcome("No PDF File Open", _("Open a PDF file"));
            welcome.append("document-open", _("Open PDF"), _("Open a PDF for viewing."));
            welcome.activated.connect((index) => {
				switch (index){
                    case 0:
						action_open ();
						break;
				}
            });

            image = new Gtk.Image ();
            page = new Gtk.ScrolledWindow (null, null);
            page_vertical_adjustment = page.get_vadjustment ();
            page.expand = true;
            page.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
            page.add (image);
            var page_context = page.get_style_context ();
            page_context.add_class ("aesop-page");

            var stack = new Gtk.Stack ();
            stack.add_named (welcome, "welcome");
            stack.add_named (page, "page");

            if (settings.last_file != null) {
				welcome.hide();
                page.show();
                render_page ();
			} else {
				welcome.show();
				page.hide();
            }

            var toolbar = new Gtk.HeaderBar ();
            toolbar.title = this.title;
            toolbar.has_subtitle = false;
            toolbar.set_show_close_button (true);
            var toolbar_context = toolbar.get_style_context ();
            toolbar_context.add_class ("aesop-toolbar");

            var open_button = new Gtk.Button ();
            open_button.has_tooltip = true;
            open_button.set_image (new Gtk.Image.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR));
            open_button.tooltip_text = (_("Open…"));

            open_button.clicked.connect (() => {
                action_open ();
                welcome.hide();
				page.show();
            });

            mode_switch = new ModeSwitch (LIGHT_ICON_SYMBOLIC, DARK_ICON_SYMBOLIC);
            mode_switch.valign = Gtk.Align.CENTER;

            mode_switch.notify["active"].connect (() => {
                if (mode_switch.active) {
                    debug ("Get dark!");
                    settings.invert = true;
                    render_page ();
                } else {
                    debug ("Get light!");
                    settings.invert = false;
                    render_page ();
                }
            });

            var page_label = new Gtk.Label (_("Page:"));
            var page_button = new Gtk.SpinButton.with_range (1, settings.pages_total, 1);
            page_button.set_value (page_count);
            page_button.has_focus = false;
            page_button.valign = Gtk.Align.CENTER;

            page_button.value_changed.connect (() => {
                int val = page_button.get_value_as_int ();
                page_count = val;
                render_page ();
            });

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.pack_start (page_label, false, false, 0);
            box.pack_start (page_button, false, false, 6);

            var print_button = new Gtk.ModelButton ();
            print_button.text = (_("Print…"));
            print_button.action_name = ACTION_PREFIX + ACTION_PRINT;

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;
            menu_grid.add (print_button);
            menu_grid.show_all ();

            var menu = new Gtk.Popover (null);
            menu.add (menu_grid);

            var menu_button = new Gtk.MenuButton ();
            menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
            menu_button.has_tooltip = true;
            menu_button.tooltip_text = (_("Settings"));
            menu_button.popover = menu;

            toolbar.pack_start (open_button);
            toolbar.pack_start (box);
            toolbar.pack_end (menu_button);
            toolbar.pack_end (mode_switch);

            int h = settings.height;
            int w = settings.width;

            if (w != 0 && h != 0) {
                this.resize (w, h);
            }

            settings.changed.connect (() => {
                render_page ();
            });

            if (settings.last_file != "") {
                File file = File.new_for_path (settings.last_file);
                if (file.query_exists () == true) {
                    filename = settings.last_file;
                    page_count = settings.last_page;
                    render_page ();
                }
            }

            this.window_position = Gtk.WindowPosition.CENTER;
            this.add (stack);
            this.set_titlebar (toolbar);
            this.set_icon_name ("com.github.lainsce.aesop");
            this.set_default_size (settings.width, settings.height);
            
            if (stack.get_visible_child_name () == "page") {
                this.set_title (("Aesop - %s (%d/%d)").printf (GLib.Path.get_basename (settings.last_file), page_count, total));
            } else {
                this.set_title ("Aesop");
            }

            this.show_all ();
        }

        private void action_zoom_plus () {
            zoom = zoom + 0.25;
            render_page ();
            var settings = AppSettings.get_default ();
            settings.zoom = zoom;
        }

        private void action_zoom_minus () {
            if (zoom < 0.25) {
                return;
            }
            zoom = zoom - 0.25;
            render_page ();
            var settings = AppSettings.get_default ();
            settings.zoom = zoom;
        }

        private void action_previous_page () {
            if (page_count <= 1) {
                return;
            } else {
               page_count = page_count - 1; 
            }
            render_page ();
        }

        private void action_next_page () {
            var settings = AppSettings.get_default ();
            if (page_count < settings.pages_total) {
                page_count = page_count + 1;
            } else if (page_count == settings.pages_total) {
                return;
            }
            render_page ();
        }

        private void action_full_screen_toggle () {
            if ((this.get_window ().get_state () & Gdk.WindowState.FULLSCREEN) == 0) {
                this.fullscreen ();
            } else {
                this.unfullscreen ();
            }
        }

        private void action_open () {
            show_open ();
        }

        private void action_print () {
            var print_op = new Gtk.PrintOperation ();
            print_op.set_n_pages (total);
            print_op.draw_page.connect (render_page_for_print);
            try {
                print_op.run (Gtk.PrintOperationAction.PRINT_DIALOG, this);
            } catch (Error e) {
                warning ("%s", e.message);
            }
        }

        public void show_open () {
            var settings = AppSettings.get_default ();
            var dialog = new Gtk.FileChooserDialog ("Open", this,
                                                Gtk.FileChooserAction.OPEN,
                                                "Cancel", Gtk.ResponseType.CANCEL,
                                                "Open",   Gtk.ResponseType.ACCEPT);
            if (settings.last_file != null) {
                dialog.set_current_folder (Path.get_dirname (filename));
            }
            dialog.set_select_multiple (false);
            dialog.set_modal (true);
            dialog.show ();
            if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                filename = dialog.get_filename ();
                page_count = 1;
                this.render_page ();
            }
            dialog.destroy ();
        }

        public void render_page_for_print () {
            var settings = AppSettings.get_default ();
            try {
                document = new document.from_file (Filename.to_uri (filename), "");
                total = document.get_n_pages ();

                double page_width;
                double page_height;
                var pages = document.get_page (page_count - 1);
                pages.get_size (out page_width, out page_height);

                int width  = (int)(settings.zoom * page_width);
                int height = (int)(settings.zoom * page_height);

                if (settings.invert) {
                    debug ("Get dark!");
                    var surface_dark = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
                    var context_dark = new Cairo.Context (surface_dark);
                    context_dark.set_operator (Cairo.Operator.DIFFERENCE);
                    context_dark.set_source_rgba (1, 1, 1, 1);
                    context_dark.rectangle (0, 0, page_width, page_height);
                    context_dark.paint ();
                    context_dark.scale (settings.zoom, settings.zoom);
                    pages.render (context_dark);
                    context_dark.set_operator (Cairo.Operator.DIFFERENCE);
                    context_dark.set_source_rgba (1, 1, 1, 1);
                    context_dark.rectangle (0, 0, page_width, page_height);
                    context_dark.paint ();
                    context_dark.show_page();
                } else {
                    debug ("Get light!");
                    var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
                    var context = new Cairo.Context (surface);
                    context.scale (settings.zoom, settings.zoom);
                    context.show_page();
                    pages.render (context);
                }
            } catch (Error e) {
                warning ("%s", e.message);
            }
        }

        public void render_page () {
            var settings = AppSettings.get_default ();
            if (settings.last_file != null && filename != null) {
                try {
                    document = new document.from_file (Filename.to_uri (filename), "");
                    total = document.get_n_pages ();

                    double page_width;
                    double page_height;
                    var pages = document.get_page (page_count - 1);
                    pages.get_size (out page_width, out page_height);

                    int width  = (int)(settings.zoom * page_width);
                    int height = (int)(settings.zoom * page_height);

                    if (settings.invert) {
                        debug ("Get dark!");
                        var surface_dark = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
                        var context_dark = new Cairo.Context (surface_dark);
                        context_dark.set_operator (Cairo.Operator.DIFFERENCE);
                        context_dark.set_source_rgba (1, 1, 1, 1);
                        context_dark.rectangle (0, 0, page_width, page_height);
                        context_dark.paint ();
                        context_dark.scale (settings.zoom, settings.zoom);
                        pages.render (context_dark);
                        context_dark.set_operator (Cairo.Operator.DIFFERENCE);
                        context_dark.set_source_rgba (1, 1, 1, 1);
                        context_dark.rectangle (0, 0, page_width, page_height);
                        context_dark.paint ();
                        Gdk.Pixbuf pixbuf_dark = Gdk.pixbuf_get_from_surface (surface_dark, 0, 0, width, height);
                        this.image.set_from_pixbuf (pixbuf_dark);
                    } else {
                        debug ("Get light!");
                        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
                        var context = new Cairo.Context (surface);
                        context.scale (settings.zoom, settings.zoom);
                        pages.render (context);
                        Gdk.Pixbuf pixbuf = Gdk.pixbuf_get_from_surface (surface, 0, 0, width, height);
                        this.image.set_from_pixbuf (pixbuf);
                    }

                    this.set_title (("Aesop - %s (%d/%d)").printf (GLib.Path.get_basename (filename), page_count, total));
                    this.page.get_vadjustment ().set_value (0);
                } catch (Error e) {
                    warning ("%s", e.message);
                }
                welcome.hide ();
                page.show ();

                settings.last_file = filename;
                settings.last_page = page_count;
                settings.pages_total = total;
            } else {
                welcome.show ();
                page.hide ();
            }
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
            this.get_size (out width, out height);
            var settings = AppSettings.get_default ();
            settings.width = width;
            settings.height = height;
            settings.last_page = page_count;
            settings.last_file = filename;
            settings.pages_total = total;

            return false;
        }
    }
}