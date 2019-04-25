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
        public Gtk.Stack stack;
        public Gtk.Box page_box;
        public Gtk.Box page_button_box;
        public Poppler.Document document;
        public double zoom = 1.00;
        public double SIZE_MAX = 2.00;
        public double SIZE_MIN = 0.25;
        public string filename;
        public int page_count = 1;
        public int total = 1;
        public int width;
        public int height;
        public Granite.Widgets.Welcome welcome;
        public Gtk.SpinButton page_button;
        public Gtk.Adjustment page_vertical_adjustment;
        public Granite.ModeSwitch mode_switch;

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_ZOOM_IN = "action_zoom_in";
        public const string ACTION_ZOOM_DEFAULT = "action_zoom_default";
        public const string ACTION_ZOOM_OUT = "action_zoom_out";
        public const string ACTION_SCROLL_UP = "action_scroll_up";
        public const string ACTION_SCROLL_DOWN = "action_scroll_down";
        public const string ACTION_FULLSCREEN = "action_fullscreen";
        public const string ACTION_PRINT = "action_print";
        public const string ACTION_OPEN = "action_open";
        public SimpleActionGroup actions { get; construct; }
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const GLib.ActionEntry[] action_entries = {
            { ACTION_ZOOM_IN,              action_zoom_in              },
            { ACTION_ZOOM_DEFAULT,         action_zoom_default         },
            { ACTION_ZOOM_OUT,             action_zoom_out             },
            { ACTION_SCROLL_UP,            action_previous_page        },
            { ACTION_SCROLL_DOWN,          action_next_page            },
            { ACTION_FULLSCREEN,           action_full_screen_toggle   },
            { ACTION_PRINT,                action_print                },
            { ACTION_OPEN,                 action_open                 }
        };

        public MainWindow (Gtk.Application application) {
            Object (application: application,
                    resizable: true,
                    default_width: 630,
                    default_height: 800);

            key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.plus, keycode)) {
                        action_zoom_in ();
                    }
                    if ((e.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
                        if (match_keycode (Gdk.Key.equal, keycode)) {
                            action_zoom_in ();
                        }
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.minus, keycode)) {
                        action_zoom_out ();
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

            welcome = new Granite.Widgets.Welcome(_("No PDF File Open"), _("Open a PDF file"));
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
            page.add (image);
            var page_context = page.get_style_context ();
            page_context.add_class ("aesop-page");

            page_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            page_box.pack_start (page, false, false, 0);
            page_box.set_valign (Gtk.Align.CENTER);

            stack = new Gtk.Stack ();
            stack.add_named (welcome, "welcome");
            stack.add_named (page_box, "page_box");

            if (settings.last_file != null) {
                page_box.show ();
                welcome.hide ();
                render_page.begin ();
			} else {
                welcome.show ();
                page_box.hide ();
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
				page_box.show ();
                welcome.hide ();
            });

            mode_switch = new Granite.ModeSwitch.from_icon_name ("display-brightness-symbolic", "weather-clear-night-symbolic");
            mode_switch.primary_icon_tooltip_text = _("Light background");
            mode_switch.secondary_icon_tooltip_text = _("Dark background");
            mode_switch.valign = Gtk.Align.CENTER;
            mode_switch.has_focus = false;
            mode_switch.set_sensitive (false);

            mode_switch.notify["active"].connect (() => {
                if (mode_switch.active) {
                    debug ("Get dark!");
                    settings.invert = true;
                    render_page.begin ();
                } else {
                    debug ("Get light!");
                    settings.invert = false;
                    render_page.begin ();
                }
            });

            var page_label = new Gtk.Label (_("Page:"));
            page_button = new Gtk.SpinButton.with_range (1.00, settings.pages_total, 1.00);
            page_button.set_value (page_count);
            page_button.has_focus = false;
            page_button.valign = Gtk.Align.CENTER;

            page_button.value_changed.connect (() => {
                int val = page_button.get_value_as_int ();
                page_count = val;
                render_page.begin ();
            });

            page_button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            page_button_box.set_sensitive (false);
            page_button_box.pack_start (page_label, false, false, 0);
            page_button_box.pack_start (page_button, false, false, 6);

            var print_button = new Gtk.ModelButton ();
            print_button.text = (_("Print…"));
            print_button.action_name = ACTION_PREFIX + ACTION_PRINT;

            var livemode_button = new Widgets.LiveModeButton ();
            livemode_button.tooltip_text = "Reload the pdf every 30s.";

            var zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU);
            zoom_out_button.action_name = ACTION_PREFIX + ACTION_ZOOM_OUT;
            zoom_out_button.tooltip_text = _("Zoom Out");

            var zoom_default_button = new Gtk.Button.with_label ("100%");
            zoom_default_button.action_name = ACTION_PREFIX + ACTION_ZOOM_DEFAULT;
            zoom_default_button.tooltip_text = _("Zoom 1:1");

            var zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
            zoom_in_button.action_name = ACTION_PREFIX + ACTION_ZOOM_IN;
            zoom_in_button.tooltip_text = _("Zoom In");

            var size_grid = new Gtk.Grid ();
            size_grid.column_homogeneous = true;
            size_grid.hexpand = true;
            size_grid.margin = 6;
            size_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
            size_grid.add (zoom_out_button);
            size_grid.add (zoom_default_button);
            size_grid.add (zoom_in_button);

            var menu_grid = new Gtk.Grid ();
            menu_grid.margin = 6;
            menu_grid.row_spacing = 6;
            menu_grid.column_spacing = 12;
            menu_grid.orientation = Gtk.Orientation.VERTICAL;
            menu_grid.add (size_grid);
            menu_grid.add (livemode_button);
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
            toolbar.pack_start (page_button_box);
            toolbar.pack_end (menu_button);
            toolbar.pack_end (mode_switch);

            int h = settings.height;
            int w = settings.width;

            if (w != 0 && h != 0) {
                this.resize (w, h);
            }

            settings.changed.connect (() => {
                render_page.begin ();
            });

            if (settings.last_file != "") {
                File file = File.new_for_path (settings.last_file);
                if (file.query_exists () == true) {
                    filename = settings.last_file;
                    page_count = settings.last_page;
                    page_button_box.set_sensitive (true);
                    mode_switch.set_sensitive (true);
                    render_page.begin ();
                }
            }

            this.window_position = Gtk.WindowPosition.CENTER;
            this.add (stack);
            this.set_titlebar (toolbar);
            this.set_icon_name ("com.github.lainsce.aesop");
            this.set_default_size (settings.width, settings.height);

            if (stack.get_visible_child_name () == "page_box") {
                this.set_title (("Aesop - %s").printf (GLib.Path.get_basename (settings.last_file)));
            } else {
                this.set_title ("Aesop");
            }

            this.show_all ();
        }

        public void action_zoom_default () {
            do_zoom ("reset");
        }

        public void action_zoom_in () {
            do_zoom ("up");
        }

        public void action_zoom_out () {
            do_zoom ("down");
        }

        private void do_zoom (string direction) {
            if (direction == "down") {
                if (zoom < SIZE_MIN) {
                    return;
                }
                zoom = zoom - 0.25;
                render_page.begin ();
                var settings = AppSettings.get_default ();
                settings.zoom = zoom;
            } else if (direction == "up") {
                if (zoom > SIZE_MAX) {
                    return;
                }
                zoom = zoom + 0.25;
                render_page.begin ();
                var settings = AppSettings.get_default ();
                settings.zoom = zoom;
            } else if (direction == "reset") {
                zoom = 1.00;
                render_page.begin ();
                var settings = AppSettings.get_default ();
                settings.zoom = zoom;
            }
        }

        private void action_previous_page () {
            if (page_count <= 1) {
                return;
            }
            page_count = page_count - 1;
            page_button.set_value (page_count);
            render_page.begin ();
        }

        private void action_next_page () {
            var settings = AppSettings.get_default ();
            if (page_count == settings.pages_total) {
                return;
            }
            page_count = page_count + 1;
            page_button.set_value (page_count);
            render_page.begin ();
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
            print_op.draw_page.connect (on_draw_page);
            print_op.set_n_pages (document.get_n_pages ());
            try {
                print_op.run (Gtk.PrintOperationAction.PRINT_DIALOG, this);
            } catch (Error e) {
                warning ("%s", e.message);
            }
        }

        public void show_open () {
            var settings = AppSettings.get_default ();
	    List<Gtk.FileFilter> filters = new List<Gtk.FileFilter> ();
            var dialog = new Gtk.FileChooserDialog ("Open", this,
                                                Gtk.FileChooserAction.OPEN,
                                                "Cancel", Gtk.ResponseType.CANCEL,
                                                "Open",   Gtk.ResponseType.ACCEPT);
            if (settings.last_file != null) {
                dialog.set_current_folder (Path.get_dirname (filename));
            }
            dialog.set_select_multiple (false);
            dialog.set_modal (true);
	    
	    var pdf_filter = new Gtk.FileFilter ();
            pdf_filter.set_filter_name (_("PDF File"));
            pdf_filter.add_mime_type ("application/pdf");
            pdf_filter.add_pattern ("*.pdf");
	    filters.append (pdf_filter);

	    dialog.add_filter (pdf_filter);
	    
            page_count = 1;
            dialog.show ();
            if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                filename = dialog.get_filename ();
                settings.last_file = filename;
                settings.last_page = this.total;
                render_page.begin ();
            }
            dialog.destroy ();
        }

        public override bool scroll_event (Gdk.EventScroll scr) {
            unowned Gdk.Device? device = scr.get_source_device ();

            if ((device == null || (device.input_source != Gdk.InputSource.MOUSE && device.input_source != Gdk.InputSource.KEYBOARD))) {
                return false;
            }

            switch (scr.direction.to_string ()) {
                case "GDK_SCROLL_UP":
                    action_previous_page ();
                    break;
                case "GDK_SCROLL_DOWN":
                    action_next_page ();
                    break;

            }
            return false;
        }

        public async void on_draw_page (Gtk.PrintContext context, int page_nr) {
            var settings = AppSettings.get_default ();

            try {
                document = new Poppler.Document.from_file (Filename.to_uri (filename), "");
                print ("%d\n".printf (page_nr));
                double page_width;
                double page_height;
                var pages = document.get_page (page_nr);
                pages.get_size (out page_width, out page_height);

                var context_light = context.get_cairo_context ();
                context_light.scale (settings.zoom, settings.zoom);
                pages.render (context_light);
            } catch (Error e) {
                warning ("%s", e.message);
            }
        }

        public async void render_page () {
            var settings = AppSettings.get_default ();
            if (settings.last_file != null && filename != null) {
                try {
                    document = new Poppler.Document.from_file (Filename.to_uri (filename), "");
                    double page_width;
                    double page_height;
                    var pages = document.get_page (page_count - 1);
                    pages.get_size (out page_width, out page_height);
                    this.total = document.get_n_pages ();
                    settings.last_page = this.total;

                    int width  = (int)(settings.zoom * page_width);
                    int height = (int)(settings.zoom * page_height);

                    // 20 here is margins.
                    page.width_request = (int) page_width + 20;
                    page.height_request = (int) page_height + 20;
                    this.width_request = width / 2;
                    this.height_request = height / 2;
                    page.set_halign (Gtk.Align.CENTER);
                    page.set_valign (Gtk.Align.CENTER);

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
                        var image_context = image.get_style_context ();
                        image_context.add_class ("aesop-image-dark");
                        image_context.remove_class ("aesop-image-light");
                    } else {
                        debug ("Get light!");
                        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
                        var context = new Cairo.Context (surface);
                        context.scale (settings.zoom, settings.zoom);
                        pages.render (context);
                        Gdk.Pixbuf pixbuf = Gdk.pixbuf_get_from_surface (surface, 0, 0, width, height);
                        this.image.set_from_pixbuf (pixbuf);
                        var image_context = image.get_style_context ();
                        image_context.remove_class ("aesop-image-dark");
                        image_context.add_class ("aesop-image-light");
                    }

                    this.set_title (("Aesop - %s").printf (GLib.Path.get_basename (filename)));
                    this.page.get_vadjustment ().set_value (0);
                } catch (Error e) {
                    warning ("%s", e.message);
                }
                page_box.show ();
                welcome.hide ();
                page_button_box.set_sensitive (true);
                mode_switch.set_sensitive (true);

                settings.last_file = filename;
            } else {
                welcome.show ();
                page_box.hide ();
            }
        }

    #if VALA_0_42
        protected bool match_keycode (uint keyval, uint code) {
    #else
        protected bool match_keycode (int keyval, uint code) {
    #endif
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
            settings.zoom = zoom;
            settings.last_page = page_count;
            settings.last_file = filename;
            settings.pages_total = this.total;

            return false;
        }
    }
}
